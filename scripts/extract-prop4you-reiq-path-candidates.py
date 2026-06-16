#!/usr/bin/env python3
"""
Safe local REIQ JSON path scanner for LeadFinder modeling evidence.

Privacy/safety contract:
- reads only local JSON files under --root;
- never prints JSON values or payload snippets;
- emits path/type/frequency summaries plus byte/hash/file samples only;
- normalizes array indexes as [];
- hashes suspicious object-key path segments instead of printing arbitrary keys.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

DEFAULT_FOCUS_ROOT = Path(
    "/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/apps/system/matrix/registry/reiq/loan_modification/fl"
)
SAFE_KEY_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]{0,63}$")
MAX_SAMPLES_PER_PATH_TYPE = 5
MAX_MARKDOWN_ROWS = 200


@dataclass
class FileMeta:
    relpath: str
    artifact_class: str
    byte_size: int
    sha256_12: str
    root_type: str | None = None
    status: str = "ok"


@dataclass
class PathTypeAgg:
    path: str
    json_type: str
    occurrences: int = 0
    files: set[str] = field(default_factory=set)
    samples: list[dict[str, Any]] = field(default_factory=list)

    def add(self, meta: FileMeta) -> None:
        self.occurrences += 1
        self.files.add(meta.relpath)
        if len(self.samples) < MAX_SAMPLES_PER_PATH_TYPE:
            sample = {
                "relpath": meta.relpath,
                "artifact_class": meta.artifact_class,
                "byte_size": meta.byte_size,
                "sha256_12": meta.sha256_12,
            }
            if sample not in self.samples:
                self.samples.append(sample)


def classify(path: Path, root: Path) -> str:
    rel = path.relative_to(root).as_posix()
    if rel == "context.json":
        return "context"
    if rel.startswith("data/") and re.search(r"/\d{4}-\d{2}-\d{2}/", "/" + rel):
        return "provider_raw_payload"
    if rel.startswith("data/") and rel.endswith("_source_manifest.json"):
        return "source_manifest"
    if rel.startswith("contracts/"):
        return "matrix_contract"
    if rel.startswith("analysis/baseline-only/"):
        return "matrix_analysis_baseline_only"
    if rel.startswith("analysis/contextual/"):
        return "matrix_analysis_contextual"
    if rel.startswith("analysis/discrepancy/"):
        return "matrix_analysis_discrepancy"
    return "unknown"


def json_type(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, dict):
        return "object"
    if isinstance(value, list):
        return "array"
    if isinstance(value, int) and not isinstance(value, bool):
        return "integer"
    if isinstance(value, float):
        return "number"
    if isinstance(value, str):
        return "string"
    return type(value).__name__


def safe_key_segment(key: str) -> str:
    """Return a useful field-name segment without leaking arbitrary key text."""
    if SAFE_KEY_RE.match(key):
        return "." + key
    digest = hashlib.sha256(key.encode("utf-8", errors="replace")).hexdigest()[:12]
    return f"[<key_sha256_12:{digest}>]"


def walk_json(value: Any, path: str):
    yield path, json_type(value)
    if isinstance(value, dict):
        for key in sorted(value):
            yield from walk_json(value[key], path + safe_key_segment(str(key)))
    elif isinstance(value, list):
        for item in value:
            yield from walk_json(item, path + "[]")


def iter_json_files(root: Path) -> list[Path]:
    return sorted(p for p in root.rglob("*.json") if p.is_file())


def scan(root: Path, expected_count: int | None) -> dict[str, Any]:
    files = iter_json_files(root)
    path_type_aggs: dict[tuple[str, str], PathTypeAgg] = {}
    artifact_counts: Counter[str] = Counter()
    root_type_counts: Counter[str] = Counter()
    file_metas: list[FileMeta] = []
    errors: list[dict[str, str]] = []
    total_bytes = 0

    for path in files:
        relpath = path.relative_to(root).as_posix()
        raw = path.read_bytes()
        digest = hashlib.sha256(raw).hexdigest()
        meta = FileMeta(
            relpath=relpath,
            artifact_class=classify(path, root),
            byte_size=len(raw),
            sha256_12=digest[:12],
        )
        total_bytes += len(raw)
        artifact_counts[meta.artifact_class] += 1
        try:
            parsed = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            meta.status = "parse_error"
            errors.append({"relpath": relpath, "error_type": type(exc).__name__, "message": str(exc).splitlines()[0]})
            file_metas.append(meta)
            continue

        meta.root_type = json_type(parsed)
        root_type_counts[meta.root_type] += 1
        file_metas.append(meta)
        seen_in_file: set[tuple[str, str]] = set()
        for candidate_path, candidate_type in walk_json(parsed, "$"):
            key = (candidate_path, candidate_type)
            agg = path_type_aggs.get(key)
            if agg is None:
                agg = PathTypeAgg(path=candidate_path, json_type=candidate_type)
                path_type_aggs[key] = agg
            agg.add(meta)
            seen_in_file.add(key)

    path_type_rows = [
        {
            "path": agg.path,
            "json_type": agg.json_type,
            "occurrences": agg.occurrences,
            "file_frequency": len(agg.files),
            "samples": agg.samples,
        }
        for agg in path_type_aggs.values()
    ]
    path_type_rows.sort(key=lambda row: (-row["file_frequency"], row["path"], row["json_type"]))

    file_samples_by_artifact: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for meta in file_metas:
        bucket = file_samples_by_artifact[meta.artifact_class]
        if len(bucket) < 5:
            bucket.append(
                {
                    "relpath": meta.relpath,
                    "byte_size": meta.byte_size,
                    "sha256_12": meta.sha256_12,
                    "root_type": meta.root_type,
                    "status": meta.status,
                }
            )

    expected_count_ok = None if expected_count is None else len(files) == expected_count
    return {
        "scanner": "scripts/extract-prop4you-reiq-path-candidates.py",
        "privacy_contract": "No raw JSON values are emitted; only paths, JSON types, counts, byte sizes, and short SHA-256 samples.",
        "generated_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "root": str(root),
        "expected_count": expected_count,
        "expected_count_ok": expected_count_ok,
        "file_count": len(files),
        "parse_error_count": len(errors),
        "total_bytes": total_bytes,
        "artifact_class_counts": dict(sorted(artifact_counts.items())),
        "root_type_counts": dict(sorted(root_type_counts.items())),
        "unique_path_type_count": len(path_type_rows),
        "file_samples_by_artifact": dict(sorted(file_samples_by_artifact.items())),
        "path_type_summary": path_type_rows,
        "errors": errors,
    }


def render_markdown(summary: dict[str, Any]) -> str:
    lines = [
        "# Python REIQ path scanner review",
        "",
        "Status: generated by `scripts/extract-prop4you-reiq-path-candidates.py`.",
        "",
        "## Privacy contract",
        "",
        summary["privacy_contract"],
        "",
        "## Corpus summary",
        "",
        f"- Root: `{summary['root']}`",
        f"- Expected files: `{summary['expected_count']}`",
        f"- Files scanned: `{summary['file_count']}`",
        f"- Expected-count OK: `{summary['expected_count_ok']}`",
        f"- Parse errors: `{summary['parse_error_count']}`",
        f"- Total bytes: `{summary['total_bytes']}`",
        f"- Unique path/type pairs: `{summary['unique_path_type_count']}`",
        "",
        "## Artifact classes",
        "",
        "| Artifact class | Count |",
        "| --- | ---: |",
    ]
    for name, count in summary["artifact_class_counts"].items():
        lines.append(f"| `{name}` | {count} |")
    lines.extend([
        "",
        "## Root types",
        "",
        "| Root type | Count |",
        "| --- | ---: |",
    ])
    for name, count in summary["root_type_counts"].items():
        lines.append(f"| `{name}` | {count} |")
    lines.extend([
        "",
        f"## Top path/type candidates (first {MAX_MARKDOWN_ROWS})",
        "",
        "| Path | JSON type | File frequency | Occurrences | Sample byte/hash evidence |",
        "| --- | --- | ---: | ---: | --- |",
    ])
    for row in summary["path_type_summary"][:MAX_MARKDOWN_ROWS]:
        samples = "; ".join(
            f"`{sample['relpath']}` bytes={sample['byte_size']} sha256_12={sample['sha256_12']}"
            for sample in row["samples"][:3]
        )
        safe_path = str(row["path"]).replace("|", "\\|")
        lines.append(
            f"| `{safe_path}` | `{row['json_type']}` | {row['file_frequency']} | {row['occurrences']} | {samples} |"
        )
    if summary["errors"]:
        lines.extend(["", "## Parse errors", "", "| File | Error type |", "| --- | --- |"])
        for error in summary["errors"]:
            lines.append(f"| `{error['relpath']}` | `{error['error_type']}` |")
    lines.append("")
    return "\n".join(lines)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Safely summarize local REIQ JSON path/type candidates without values.")
    parser.add_argument("--root", type=Path, default=DEFAULT_FOCUS_ROOT, help="Focused REIQ corpus root to scan.")
    parser.add_argument(
        "--expected-count",
        type=int,
        default=97,
        help="Expected number of JSON files. Use -1 to disable count validation.",
    )
    parser.add_argument("--output-md", type=Path, help="Optional markdown report path.")
    parser.add_argument("--output-json", type=Path, help="Optional JSON report path.")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    root = args.root.expanduser().resolve()
    if not root.exists() or not root.is_dir():
        print(json.dumps({"ok": False, "error": "root_not_found", "root": str(root)}, indent=2), file=sys.stderr)
        return 2

    expected_count = None if args.expected_count < 0 else args.expected_count
    summary = scan(root, expected_count)

    if args.output_json:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    if args.output_md:
        args.output_md.parent.mkdir(parents=True, exist_ok=True)
        args.output_md.write_text(render_markdown(summary), encoding="utf-8")

    stdout_summary = {
        "ok": summary["parse_error_count"] == 0 and (summary["expected_count_ok"] is not False),
        "root": summary["root"],
        "expected_count": summary["expected_count"],
        "expected_count_ok": summary["expected_count_ok"],
        "file_count": summary["file_count"],
        "parse_error_count": summary["parse_error_count"],
        "total_bytes": summary["total_bytes"],
        "artifact_class_counts": summary["artifact_class_counts"],
        "root_type_counts": summary["root_type_counts"],
        "unique_path_type_count": summary["unique_path_type_count"],
        "output_json": str(args.output_json) if args.output_json else None,
        "output_md": str(args.output_md) if args.output_md else None,
        "privacy_contract": summary["privacy_contract"],
    }
    print(json.dumps(stdout_summary, indent=2, sort_keys=True))

    if summary["parse_error_count"] != 0:
        return 1
    if summary["expected_count_ok"] is False:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

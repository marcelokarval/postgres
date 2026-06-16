#!/usr/bin/env python3
"""
Ingest local REIQ JSON corpus into Prop4You SourceHub raw_records for lab use.

Safety defaults:
- dry-run by default;
- never prints raw JSON payloads;
- never commits payloads to repo;
- only prints counts, classes, byte sizes, and short hashes;
- requires --execute to write DB rows.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

DEFAULT_REIQ_ROOT = Path('/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/apps/system/matrix/registry/reiq')
DEFAULT_FOCUS_ROOT = DEFAULT_REIQ_ROOT / 'loan_modification' / 'fl'


@dataclass(frozen=True)
class JsonItem:
    path: Path
    relpath: str
    artifact_class: str
    sha256: str
    short_hash: str
    byte_size: int
    root_type: str
    top_level_key_count: int | None
    payload_text: str


def classify(path: Path, focus_root: Path) -> str:
    rel = path.relative_to(focus_root).as_posix() if path.is_relative_to(focus_root) else path.name
    if rel == 'context.json':
        return 'context'
    if rel.startswith('data/') and re.search(r'/\d{4}-\d{2}-\d{2}/', '/' + rel):
        return 'provider_raw_payload'
    if rel.startswith('data/') and rel.endswith('_source_manifest.json'):
        return 'source_manifest'
    if rel.startswith('contracts/'):
        return 'matrix_contract'
    if rel.startswith('analysis/baseline-only/'):
        return 'matrix_analysis_baseline_only'
    if rel.startswith('analysis/contextual/'):
        return 'matrix_analysis_contextual'
    if rel.startswith('analysis/discrepancy/'):
        return 'matrix_analysis_discrepancy'
    return 'unknown'


def iter_json(root: Path) -> Iterable[Path]:
    yield from sorted(p for p in root.rglob('*.json') if p.is_file())


def load_item(path: Path, focus_root: Path) -> JsonItem:
    raw = path.read_bytes()
    text = raw.decode('utf-8')
    parsed = json.loads(text)
    digest = hashlib.sha256(raw).hexdigest()
    root_type = 'array' if isinstance(parsed, list) else 'object' if isinstance(parsed, dict) else type(parsed).__name__
    top_count = len(parsed) if isinstance(parsed, dict) else None
    relpath = path.relative_to(focus_root).as_posix() if path.is_relative_to(focus_root) else path.name
    return JsonItem(
        path=path,
        relpath=relpath,
        artifact_class=classify(path, focus_root),
        sha256=digest,
        short_hash=digest[:12],
        byte_size=len(raw),
        root_type=root_type,
        top_level_key_count=top_count,
        payload_text=text,
    )


def sql_literal(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def build_insert_sql(items: list[JsonItem]) -> str:
    # payload_class_id: use property_search_result as coarse existing class for REIQ property raw/corpus evidence.
    values = []
    for item in items:
        metadata = {
            'provider': 'reiq',
            'list_type': 'loan_modification',
            'state': 'fl',
            'artifact_class': item.artifact_class,
            'source_relpath': item.relpath,
            'byte_size': item.byte_size,
            'content_sha256': item.sha256,
            'top_level_key_count': item.top_level_key_count,
            'ingested_by': 'scripts/ingest-prop4you-reiq-raws-lab.py',
            'privacy_note': 'raw JSONB lab ingestion; no repo payload commit',
        }
        source_kind = 'provider_export' if item.artifact_class == 'provider_raw_payload' else 'derived_review'
        contains_personal = 'true' if item.artifact_class == 'provider_raw_payload' else 'false'
        values.append(
            "("
            f"{sql_literal(source_kind)}, "
            f"{sql_literal('reiq.loan_modification.fl.' + item.artifact_class)}, "
            f"{sql_literal(item.payload_text)}::jsonb, "
            f"{sql_literal(item.sha256)}, "
            f"{sql_literal('local-reiq://' + item.relpath)}, "
            f"{sql_literal(str(item.path))}, "
            "'restricted', "
            f"{contains_personal}, "
            "'candidate_paths_detected', "
            f"{sql_literal(json.dumps(metadata, sort_keys=True))}::jsonb)"
        )
    values_sql = ',\n  '.join(values)
    return f"""
with provider as (
  select id from prop4you_provider.providers where provider_key = 'reiq'
), payload_class as (
  select id from prop4you_provider.payload_classes where class_key = 'property_search_result'
)
insert into prop4you_sourcehub.raw_records (
  provider_id,
  payload_class_id,
  source_kind,
  source_label,
  raw_payload,
  raw_payload_sha256,
  private_corpus_uri,
  private_corpus_path,
  privacy_classification,
  contains_personal_data,
  matrix_mapping_status,
  metadata
)
select provider.id, payload_class.id, v.*
from (values
  {values_sql}
) as v(
  source_kind, source_label, raw_payload, raw_payload_sha256,
  private_corpus_uri, private_corpus_path, privacy_classification, contains_personal_data,
  matrix_mapping_status, metadata
)
cross join provider
cross join payload_class
where not exists (
  select 1
  from prop4you_sourcehub.raw_records r
  where r.provider_id = provider.id
    and r.raw_payload_sha256 = v.raw_payload_sha256
    and r.private_corpus_path = v.private_corpus_path
);
"""


def run_psql(sql: str, args: argparse.Namespace) -> None:
    env = os.environ.copy()
    cmd = [
        'psql',
        '-q',
        '-v', 'ON_ERROR_STOP=1',
        '-h', args.pg_host,
        '-p', str(args.pg_port),
        '-U', args.pg_user,
        '-d', args.pg_database,
    ]
    with tempfile.NamedTemporaryFile('w', suffix='.sql', delete=False) as f:
        f.write(sql)
        tmp = f.name
    try:
        subprocess.run(cmd + ['-f', tmp], check=True, env=env)
    finally:
        try:
            os.unlink(tmp)
        except OSError:
            pass


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', default=str(DEFAULT_FOCUS_ROOT), help='REIQ focus root containing JSON files')
    parser.add_argument('--expected-count', type=int, default=97)
    parser.add_argument('--limit', type=int, default=0, help='Limit files for smoke tests; 0 means all')
    parser.add_argument('--execute', action='store_true', help='Actually insert into DB; default is dry-run')
    parser.add_argument('--pg-host', default=os.environ.get('PGHOST', '127.0.0.1'))
    parser.add_argument('--pg-port', default=os.environ.get('PGPORT', '54318'))
    parser.add_argument('--pg-user', default=os.environ.get('PGUSER', 'supabase_admin'))
    parser.add_argument('--pg-database', default=os.environ.get('PGDATABASE', 'pg18_prop4you_ddl_lab'))
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.exists():
        print(json.dumps({'status': 'error', 'error': 'root_not_found', 'root': str(root)}))
        return 2
    items = [load_item(p, root) for p in iter_json(root)]
    if args.limit:
        items = items[:args.limit]
    by_class: dict[str, int] = {}
    by_root_type: dict[str, int] = {}
    total_bytes = 0
    for item in items:
        by_class[item.artifact_class] = by_class.get(item.artifact_class, 0) + 1
        by_root_type[item.root_type] = by_root_type.get(item.root_type, 0) + 1
        total_bytes += item.byte_size

    summary = {
        'status': 'dry_run' if not args.execute else 'executed',
        'root': str(root),
        'file_count': len(items),
        'expected_count': args.expected_count if not args.limit else None,
        'expected_count_match': (len(items) == args.expected_count) if not args.limit else None,
        'by_class': by_class,
        'by_root_type': by_root_type,
        'total_bytes': total_bytes,
        'short_hashes_sample': [i.short_hash for i in items[:5]],
        'no_payload_values_printed': True,
    }
    print(json.dumps(summary, sort_keys=True))
    if not args.execute:
        return 0 if (args.limit or len(items) == args.expected_count) else 3
    if not items:
        return 4
    run_psql(build_insert_sql(items), args)
    print(json.dumps({'status': 'insert_sql_executed', 'file_count': len(items), 'no_payload_values_printed': True}, sort_keys=True))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

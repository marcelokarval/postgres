# DDL Installer Browser Proof

Status: PASS
Verdict: DELIVERED_LOCAL_DDL_BASE_PROOF

## Runtime evidence

Fresh temporary DB proof executed against local PG18 container:

```text
fresh apply: all 9 DDL files DONE
fresh reapply: all 9 DDL files SKIP
status: 9 applied rows
version=18.0
schemas=4
migrations=9
uuidv7_version=7
registered_prefix=usr
public_ref=usr_<uuid7>
parse_prefix=usr,uuid_version=7
resolve_schema=base,table=ddl_migrations
audit_id=<uuid7>
event_id=<uuid7>
api_health_ok=true
ddl_status=9
available_extensions=79
installed_extensions=2
```

## Browser proof target

```text
docs/proofs/ddl-installer-browser-proof.html
```

No secrets are embedded.

## Browser QA

Target served locally on agent-owned port 18086:

```text
http://127.0.0.1:18086/docs/proofs/ddl-installer-browser-proof.html
```

Checks:

```text
HTTP HEAD: 200 OK
Browser title: PG18 DDL Installer Browser Proof
Console: one expected log, zero JS errors
Vision: page visibly renders PASS verdict, six proof cards, SQL proof highlights, and delivered files table.
Server liveness: running before and during browser capture.
```

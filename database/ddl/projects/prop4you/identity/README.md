# prop4you/identity

Status: skeleton / non-final

Future identity package; not first frozen DDL slice in this corpus-driven plan.

Rules:

- Do not freeze final tables from Django models alone.
- Preserve raw evidence/lineage when provider payloads are involved.
- Add objective `COMMENT ON` statements for every future SQL object.
- Validate in `pg18_ddl_lab` or a clean lab DB before promotion.

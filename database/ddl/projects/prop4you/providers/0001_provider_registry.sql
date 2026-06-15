-- package: prop4you/providers
-- file: 0001_provider_registry.sql
-- status: experimental / non-final
-- purpose: provider registry, payload class catalog, and safe JSONB path helpers for Prop4You corpus review.
-- depends-on: database/ddl/projects/prop4you/0001_schemas.sql, database/ddl/base
-- idempotency: idempotent
-- destructive: false
-- review-gate: provider_payload_corpus_review

create schema if not exists prop4you_provider;
comment on schema prop4you_provider is
'Prop4You provider schema. Experimental non-final registry for external and internal payload origins, payload classes, and JSONB path helpers used before SourceHub/Matrix canonicalization is frozen.';

create table if not exists prop4you_provider.providers (
  id uuid primary key default uuidv7(),
  provider_key text not null,
  display_name text not null,
  provider_kind text not null,
  lifecycle_status text not null default 'candidate',
  description text,
  homepage_url text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint providers_provider_key_key unique (provider_key),
  constraint providers_provider_key_format_chk check (provider_key ~ '^[a-z][a-z0-9_]{1,63}$'),
  constraint providers_display_name_not_blank_chk check (length(btrim(display_name)) > 0),
  constraint providers_provider_kind_chk check (provider_kind in ('external_api','internal_product','manual_import','derived_dataset','unknown')),
  constraint providers_lifecycle_status_chk check (lifecycle_status in ('candidate','active','paused','retired','unknown')),
  constraint providers_homepage_url_format_chk check (homepage_url is null or homepage_url ~ '^https?://'),
  constraint providers_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

create index if not exists providers_provider_kind_status_idx
  on prop4you_provider.providers (provider_kind, lifecycle_status);

comment on table prop4you_provider.providers is
'Experimental catalog of external providers and internal/product payload origins used for Prop4You payload comparison. This table is not a provider runtime client and does not authorize network calls.';
comment on column prop4you_provider.providers.id is 'UUIDv7 primary key for one provider or internal payload origin catalog record.';
comment on column prop4you_provider.providers.provider_key is 'Stable lowercase key used by DDL and review artifacts, for example reiq, directskip, realtor_com, or prop4you_internal.';
comment on column prop4you_provider.providers.display_name is 'Human-readable provider or payload origin name.';
comment on column prop4you_provider.providers.provider_kind is 'Coarse origin category: external_api, internal_product, manual_import, derived_dataset, or unknown.';
comment on column prop4you_provider.providers.lifecycle_status is 'Experimental registry status for review gating; not a production integration status.';
comment on column prop4you_provider.providers.description is 'Objective note describing what the provider/origin contributes to corpus analysis.';
comment on column prop4you_provider.providers.homepage_url is 'Optional public HTTP(S) homepage URL for human reference only; no runtime endpoint or secret is stored here.';
comment on column prop4you_provider.providers.metadata is 'Non-secret JSONB review metadata for provider/origin classification; must remain a JSON object.';
comment on column prop4you_provider.providers.created_at is 'Timestamp when this registry row was inserted in the target database.';
comment on column prop4you_provider.providers.updated_at is 'Timestamp when this registry row was last updated by DDL or later controlled maintenance.';

create table if not exists prop4you_provider.payload_classes (
  id uuid primary key default uuidv7(),
  class_key text not null,
  display_name text not null,
  payload_domain text not null,
  payload_direction text not null,
  description text not null,
  expected_root_type text not null default 'object',
  schema_hint jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint payload_classes_class_key_key unique (class_key),
  constraint payload_classes_class_key_format_chk check (class_key ~ '^[a-z][a-z0-9_]{1,79}$'),
  constraint payload_classes_display_name_not_blank_chk check (length(btrim(display_name)) > 0),
  constraint payload_classes_payload_domain_chk check (payload_domain in ('property','owner','lead','skip_trace','search','enrichment','internal','unknown')),
  constraint payload_classes_payload_direction_chk check (payload_direction in ('ingress','egress','internal_snapshot','derived')),
  constraint payload_classes_description_not_blank_chk check (length(btrim(description)) > 0),
  constraint payload_classes_expected_root_type_chk check (expected_root_type in ('object','array','string','number','boolean','null','any')),
  constraint payload_classes_schema_hint_object_chk check (jsonb_typeof(schema_hint) = 'object'),
  constraint payload_classes_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

create index if not exists payload_classes_domain_direction_idx
  on prop4you_provider.payload_classes (payload_domain, payload_direction);

comment on table prop4you_provider.payload_classes is
'Experimental catalog of payload classes used to compare provider/internal JSONB documents before Matrix semantic mappings are finalized.';
comment on column prop4you_provider.payload_classes.id is 'UUIDv7 primary key for one payload class catalog record.';
comment on column prop4you_provider.payload_classes.class_key is 'Stable lowercase key for one payload class, independent of any provider-specific endpoint name.';
comment on column prop4you_provider.payload_classes.display_name is 'Human-readable payload class name.';
comment on column prop4you_provider.payload_classes.payload_domain is 'Coarse domain represented by the payload class, such as property, owner, lead, skip_trace, search, enrichment, internal, or unknown.';
comment on column prop4you_provider.payload_classes.payload_direction is 'Payload flow direction: ingress, egress, internal_snapshot, or derived.';
comment on column prop4you_provider.payload_classes.description is 'Objective explanation of what JSON documents in this class are expected to contain.';
comment on column prop4you_provider.payload_classes.expected_root_type is 'Expected jsonb_typeof root value for raw documents in this class, or any when not yet known.';
comment on column prop4you_provider.payload_classes.schema_hint is 'Non-authoritative JSONB notes about expected top-level keys or observed structure; not a final JSON Schema.';
comment on column prop4you_provider.payload_classes.metadata is 'Non-secret JSONB review metadata for payload class classification; must remain a JSON object.';
comment on column prop4you_provider.payload_classes.created_at is 'Timestamp when this payload class row was inserted in the target database.';
comment on column prop4you_provider.payload_classes.updated_at is 'Timestamp when this payload class row was last updated by DDL or later controlled maintenance.';

create table if not exists prop4you_provider.provider_payload_classes (
  id uuid primary key default uuidv7(),
  provider_id uuid not null references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid not null references prop4you_provider.payload_classes(id) on delete restrict,
  provider_payload_name text,
  active_for_review boolean not null default true,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint provider_payload_classes_provider_class_key unique (provider_id, payload_class_id),
  constraint provider_payload_classes_payload_name_chk check (provider_payload_name is null or length(btrim(provider_payload_name)) > 0),
  constraint provider_payload_classes_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

create index if not exists provider_payload_classes_class_idx
  on prop4you_provider.provider_payload_classes (payload_class_id, active_for_review);

comment on table prop4you_provider.provider_payload_classes is
'Experimental many-to-many bridge declaring which providers/origins may produce which payload classes for corpus review. It stores classification only, not payload samples.';
comment on column prop4you_provider.provider_payload_classes.id is 'UUIDv7 primary key for one provider-to-payload-class catalog link.';
comment on column prop4you_provider.provider_payload_classes.provider_id is 'Provider/origin catalog row that may produce the linked payload class.';
comment on column prop4you_provider.provider_payload_classes.payload_class_id is 'Payload class catalog row produced by the linked provider/origin.';
comment on column prop4you_provider.provider_payload_classes.provider_payload_name is 'Optional provider-specific human label for the payload, endpoint, export, or screen name; no URL or secret is stored.';
comment on column prop4you_provider.provider_payload_classes.active_for_review is 'Whether this provider/class link is in scope for the current non-final corpus comparison.';
comment on column prop4you_provider.provider_payload_classes.notes is 'Optional objective notes for reviewers about why this provider/class link exists.';
comment on column prop4you_provider.provider_payload_classes.metadata is 'Non-secret JSONB metadata about the provider/class link; must remain a JSON object.';
comment on column prop4you_provider.provider_payload_classes.created_at is 'Timestamp when this provider/class link was inserted in the target database.';
comment on column prop4you_provider.provider_payload_classes.updated_at is 'Timestamp when this provider/class link was last updated by DDL or later controlled maintenance.';

create or replace function prop4you_provider.jsonb_path_exists(payload jsonb, path text[])
returns boolean
language sql
immutable
strict
as $$
  select payload #> path is not null
$$;

comment on function prop4you_provider.jsonb_path_exists(jsonb, text[]) is
'Returns true when a JSONB payload contains a value at the supplied PostgreSQL text[] path, including a JSON null value. This helper does not evaluate JSONPath expressions.';

create or replace function prop4you_provider.jsonb_path_type(payload jsonb, path text[])
returns text
language sql
immutable
strict
as $$
  select jsonb_typeof(payload #> path)
$$;

comment on function prop4you_provider.jsonb_path_type(jsonb, text[]) is
'Returns jsonb_typeof for the value at a supplied PostgreSQL text[] path, or null when the path is absent. This supports Matrix path review without provider calls.';

create or replace function prop4you_provider.jsonb_path_text(payload jsonb, path text[])
returns text
language sql
immutable
strict
as $$
  select payload #>> path
$$;

comment on function prop4you_provider.jsonb_path_text(jsonb, text[]) is
'Returns a scalar/text representation for the value at a supplied PostgreSQL text[] path using the #>> operator. It is intended for review queries, not canonical DTO materialization.';

create or replace function prop4you_provider.jsonb_leaf_paths(payload jsonb, max_depth integer default 8)
returns table(path text[], value_type text)
language plpgsql
immutable
strict
as $$
declare
  effective_max_depth integer;
begin
  effective_max_depth := greatest(coalesce(max_depth, 8), 1);

  return query
  with recursive walk(path, node, depth) as (
    select array[]::text[] as path,
           payload as node,
           1 as depth
    union all
    select w.path || child.key,
           child.value,
           w.depth + 1
      from walk w
      cross join lateral (
        select e.key, e.value
          from jsonb_each(case when jsonb_typeof(w.node) = 'object' then w.node else '{}'::jsonb end) as e(key, value)
        union all
        select (a.ordinality - 1)::text as key, a.value
          from jsonb_array_elements(case when jsonb_typeof(w.node) = 'array' then w.node else '[]'::jsonb end)
          with ordinality as a(value, ordinality)
      ) as child(key, value)
     where w.depth < effective_max_depth
  )
  select w.path,
         coalesce(jsonb_typeof(w.node), 'null') as value_type
    from walk w
   where jsonb_typeof(w.node) not in ('object', 'array')
      or w.depth >= effective_max_depth;
end;
$$;

comment on function prop4you_provider.jsonb_leaf_paths(jsonb, integer) is
'Enumerates leaf paths and JSONB value types from a payload up to max_depth using PostgreSQL text[] paths. Array indexes are emitted as zero-based path components. It does not store payload data.';

insert into prop4you_provider.providers
  (provider_key, display_name, provider_kind, lifecycle_status, description, homepage_url, metadata)
values
  ('reiq', 'REIQ', 'external_api', 'candidate', 'External real-estate information provider/origin to be compared against Prop4You corpus payloads.', null, '{"seeded_by":"experimental_ddl","provider_call_allowed":false}'::jsonb),
  ('directskip', 'DirectSkip', 'external_api', 'candidate', 'External skip-trace enrichment provider/origin whose payloads must not define canonical owner/property truth.', null, '{"seeded_by":"experimental_ddl","provider_call_allowed":false}'::jsonb),
  ('realtor_com', 'Realtor.com', 'external_api', 'candidate', 'External listing/search provider/origin for payload comparison and Matrix path mapping review.', 'https://www.realtor.com', '{"seeded_by":"experimental_ddl","provider_call_allowed":false}'::jsonb),
  ('prop4you_internal', 'Prop4You internal/product payloads', 'internal_product', 'candidate', 'Internal and product-originated payloads used as comparison inputs; Lead Finder remains the canonical graph boundary.', null, '{"seeded_by":"experimental_ddl","provider_call_allowed":false}'::jsonb)
on conflict (provider_key) do update
  set display_name = excluded.display_name,
      provider_kind = excluded.provider_kind,
      lifecycle_status = excluded.lifecycle_status,
      description = excluded.description,
      homepage_url = excluded.homepage_url,
      metadata = excluded.metadata,
      updated_at = now();

insert into prop4you_provider.payload_classes
  (class_key, display_name, payload_domain, payload_direction, description, expected_root_type, schema_hint, metadata)
values
  ('property_search_result', 'Property search result', 'search', 'ingress', 'Provider or internal search result payload that may mention property candidates before SourceHub lineage and Matrix mapping.', 'object', '{"typical_root":"object_or_array_wrapped_result"}'::jsonb, '{"seeded_by":"experimental_ddl"}'::jsonb),
  ('property_detail', 'Property detail', 'property', 'ingress', 'Provider or internal payload containing property-level attributes for comparison against future canonical property DTOs.', 'object', '{"typical_root":"object"}'::jsonb, '{"seeded_by":"experimental_ddl"}'::jsonb),
  ('owner_profile', 'Owner profile', 'owner', 'ingress', 'Provider or internal payload containing owner/contact facts that require lineage and semantic mapping before use.', 'object', '{"typical_root":"object"}'::jsonb, '{"seeded_by":"experimental_ddl"}'::jsonb),
  ('skip_trace_result', 'Skip trace result', 'skip_trace', 'ingress', 'Skip-trace enrichment response. It can enrich owner/contact evidence but must not define owner or property canonical truth.', 'object', '{"typical_root":"object"}'::jsonb, '{"seeded_by":"experimental_ddl"}'::jsonb),
  ('leadfinder_candidate_snapshot', 'Lead Finder candidate snapshot', 'lead', 'internal_snapshot', 'Internal snapshot of a candidate in the Lead Finder graph boundary used for comparison with provider payloads.', 'object', '{"typical_root":"object"}'::jsonb, '{"seeded_by":"experimental_ddl"}'::jsonb)
on conflict (class_key) do update
  set display_name = excluded.display_name,
      payload_domain = excluded.payload_domain,
      payload_direction = excluded.payload_direction,
      description = excluded.description,
      expected_root_type = excluded.expected_root_type,
      schema_hint = excluded.schema_hint,
      metadata = excluded.metadata,
      updated_at = now();

insert into prop4you_provider.provider_payload_classes
  (provider_id, payload_class_id, provider_payload_name, active_for_review, notes, metadata)
select p.id,
       c.id,
       case c.class_key
         when 'property_search_result' then 'search/result payload'
         when 'property_detail' then 'property/detail payload'
         when 'owner_profile' then 'owner/profile payload'
         when 'skip_trace_result' then 'skip-trace result payload'
         when 'leadfinder_candidate_snapshot' then 'internal candidate snapshot'
       end,
       true,
       'Seeded non-final review relationship; no fixtures and no provider calls are included.',
       '{"seeded_by":"experimental_ddl"}'::jsonb
  from prop4you_provider.providers p
  join prop4you_provider.payload_classes c
    on (p.provider_key in ('reiq', 'realtor_com') and c.class_key in ('property_search_result', 'property_detail'))
    or (p.provider_key = 'directskip' and c.class_key in ('owner_profile', 'skip_trace_result'))
    or (p.provider_key = 'prop4you_internal' and c.class_key in ('property_search_result', 'property_detail', 'owner_profile', 'leadfinder_candidate_snapshot'))
on conflict (provider_id, payload_class_id) do update
  set provider_payload_name = excluded.provider_payload_name,
      active_for_review = excluded.active_for_review,
      notes = excluded.notes,
      metadata = excluded.metadata,
      updated_at = now();

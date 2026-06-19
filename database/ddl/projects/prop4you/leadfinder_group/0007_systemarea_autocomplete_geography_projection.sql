-- package: prop4you/leadfinder_group
-- file: 0007_systemarea_autocomplete_geography_projection.sql
-- status: experimental / geography real projection
-- purpose: SystemArea canonical geography/autocomplete projection for LFG location filtering.
-- depends-on: leadfinder_group/0006_projection_candidate_review_board.sql; base/0007_search_normalization.sql; postgis
-- idempotency: idempotent
-- destructive: false
-- [GATEWAY_AGNOSTIC]
-- [NO_PROVIDER_CALLS]
-- [NO_RAW_PAYLOAD_VALUES]
-- [GEOGRAPHY_FIRST]
-- [NO_FINAL_PRODUCT_TABLE_EXPLOSION]

set search_path = prop4you_leadfinder_group, public;

do $$
begin
  if not exists (select 1 from pg_extension where extname = 'postgis') then
    raise exception 'PostGIS extension is required for 0007_systemarea_autocomplete_geography_projection.sql';
  end if;
end;
$$;

create table if not exists prop4you_leadfinder_group.system_areas (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgsa', id)) stored,
  slug_id text not null,
  area_type text not null,
  name text not null,
  state_code text,
  country_code text not null default 'US',
  parent_id uuid references prop4you_leadfinder_group.system_areas(id) on delete set null,
  provider_slug text not null default 'realtor',
  provider_geo_id text,
  provider_area_ref text,
  realty_id text,
  provider_area_type text,
  centroid geometry(Point, 4326),
  bbox geometry(Polygon, 4326),
  boundary geometry(MultiPolygon, 4326),
  boundary_status text not null default 'unknown',
  viewport_status text not null default 'unknown',
  registration_status text not null default 'projected',
  search_label text not null,
  search_terms text[] not null default '{}'::text[],
  lineage jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  constraint system_areas_public_ref_key unique (public_ref),
  constraint system_areas_slug_type_state_country_key unique (slug_id, area_type, state_code, country_code),
  constraint system_areas_name_type_state_country_key unique (name, area_type, state_code, country_code),
  constraint system_areas_area_type_chk check (area_type in ('state','county','city','postal_code','neighborhood','street','school','school_district','university','park','mlsid','market_area')),
  constraint system_areas_state_chk check (state_code is null or state_code ~ '^[A-Z]{2}$'),
  constraint system_areas_country_chk check (country_code ~ '^[A-Z]{2}$'),
  constraint system_areas_boundary_status_chk check (boundary_status in ('unknown','not_available','pending','derived','validated','failed','restricted')),
  constraint system_areas_viewport_status_chk check (viewport_status in ('unknown','not_available','pending','derived','validated','failed')),
  constraint system_areas_registration_status_chk check (registration_status in ('canonical','projected','provider_only','pending_registration','created','already_installed','blocked','superseded','archived')),
  constraint system_areas_search_terms_nonempty_chk check (cardinality(search_terms) > 0),
  constraint system_areas_centroid_valid_chk check (centroid is null or (ST_SRID(centroid) = 4326 and ST_IsValid(centroid))),
  constraint system_areas_bbox_valid_chk check (bbox is null or (ST_SRID(bbox) = 4326 and ST_IsValid(bbox))),
  constraint system_areas_boundary_valid_chk check (boundary is null or (ST_SRID(boundary) = 4326 and ST_IsValid(boundary))),
  constraint system_areas_lineage_object_chk check (jsonb_typeof(lineage) = 'object'),
  constraint system_areas_metadata_object_chk check (jsonb_typeof(metadata) = 'object'),
  constraint system_areas_version_chk check (version > 0)
);

comment on table prop4you_leadfinder_group.system_areas is
'Real geography-first SystemArea projection for LFG location autocomplete and filtering. Stores normalized geography anchors, not raw provider payloads.';
comment on column prop4you_leadfinder_group.system_areas.public_ref is 'Opaque SystemArea public reference used as value/systemAreaId by the Lead Finder autocomplete contract.';
comment on column prop4you_leadfinder_group.system_areas.centroid is 'Map center point in SRID 4326. Public contract serializes [lng, lat].';
comment on column prop4you_leadfinder_group.system_areas.bbox is 'Viewport bounding box polygon in SRID 4326. Public contract serializes [west, south, east, north].';
comment on column prop4you_leadfinder_group.system_areas.boundary is 'Validated/restricted MultiPolygon boundary when available. Raw provider coordinate arrays stay outside this table.';

create table if not exists prop4you_leadfinder_group.system_area_provider_identities (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgsap', id)) stored,
  system_area_id uuid not null references prop4you_leadfinder_group.system_areas(id) on delete cascade,
  provider_slug text not null,
  provider_area_ref text,
  provider_geo_id text,
  provider_slug_id text,
  provider_area_type text,
  provider_confidence numeric(6,4),
  identity_status text not null default 'active',
  lineage jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  constraint system_area_provider_identities_public_ref_key unique (public_ref),
  constraint system_area_provider_identities_status_chk check (identity_status in ('active','candidate','conflicted','superseded','archived')),
  constraint system_area_provider_identities_confidence_chk check (provider_confidence is null or (provider_confidence >= 0 and provider_confidence <= 1)),
  constraint system_area_provider_identities_lineage_object_chk check (jsonb_typeof(lineage) = 'object'),
  constraint system_area_provider_identities_version_chk check (version > 0)
);

comment on table prop4you_leadfinder_group.system_area_provider_identities is
'Provider identity links for SystemArea projections. Stores refs and lineage metadata only, never raw provider payload values.';

create table if not exists prop4you_leadfinder_group.system_area_aliases (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgsaa', id)) stored,
  system_area_id uuid not null references prop4you_leadfinder_group.system_areas(id) on delete cascade,
  alias text not null,
  alias_kind text not null default 'search',
  locale text not null default 'en-US',
  search_terms text[] not null default '{}'::text[],
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  constraint system_area_aliases_public_ref_key unique (public_ref),
  constraint system_area_aliases_area_kind_alias_key unique (system_area_id, alias_kind, alias),
  constraint system_area_aliases_kind_chk check (alias_kind in ('primary','search','provider_label','display','legacy','synonym')),
  constraint system_area_aliases_terms_nonempty_chk check (cardinality(search_terms) > 0),
  constraint system_area_aliases_version_chk check (version > 0)
);

comment on table prop4you_leadfinder_group.system_area_aliases is
'Search/display aliases for SystemArea autocomplete, including state names, county suffix aliases, provider labels, and legacy synonyms.';

create table if not exists prop4you_leadfinder_group.system_area_feed_terms (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgsaft', id)) stored,
  term text not null,
  normalized_term text not null,
  expected_area_type text,
  state_code text,
  country_code text not null default 'US',
  provider_slug text not null default 'realtor',
  feed_status text not null default 'pending',
  provider_call_made boolean not null default false,
  search_started_at timestamptz,
  search_completed_at timestamptz,
  result_count integer not null default 0,
  created_count integer not null default 0,
  already_installed_count integer not null default 0,
  skipped_count integer not null default 0,
  failed_count integer not null default 0,
  last_error text,
  lineage jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  constraint system_area_feed_terms_public_ref_key unique (public_ref),
  constraint system_area_feed_terms_expected_type_chk check (expected_area_type is null or expected_area_type in ('state','county','city','postal_code')),
  constraint system_area_feed_terms_state_chk check (state_code is null or state_code ~ '^[A-Z]{2}$'),
  constraint system_area_feed_terms_country_chk check (country_code ~ '^[A-Z]{2}$'),
  constraint system_area_feed_terms_status_chk check (feed_status in ('pending','searching','completed','observed','matched','no_match','failed','blocked','archived')),
  constraint system_area_feed_terms_counts_chk check (result_count >= 0 and created_count >= 0 and already_installed_count >= 0 and skipped_count >= 0 and failed_count >= 0),
  constraint system_area_feed_terms_lineage_object_chk check (jsonb_typeof(lineage) = 'object'),
  constraint system_area_feed_terms_version_chk check (version > 0)
);

comment on table prop4you_leadfinder_group.system_area_feed_terms is
'Autocomplete/feed term ledger for SystemArea projection. The table stores normalized term metadata and counts only; no provider response payloads.';

create table if not exists prop4you_leadfinder_group.system_area_feed_results (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgsafr', id)) stored,
  feed_term_id uuid not null references prop4you_leadfinder_group.system_area_feed_terms(id) on delete restrict,
  system_area_id uuid references prop4you_leadfinder_group.system_areas(id) on delete set null,
  provider_slug text not null,
  provider_area_ref text,
  provider_geo_id text,
  provider_slug_id text,
  area_type text,
  name text,
  state_code text,
  rank integer,
  match_score numeric(8,4),
  result_status text not null default 'candidate',
  materialization_reason text,
  lineage jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  constraint system_area_feed_results_public_ref_key unique (public_ref),
  constraint system_area_feed_results_area_type_chk check (area_type is null or area_type in ('state','county','city','postal_code')),
  constraint system_area_feed_results_state_chk check (state_code is null or state_code ~ '^[A-Z]{2}$'),
  constraint system_area_feed_results_rank_chk check (rank is null or rank > 0),
  constraint system_area_feed_results_score_chk check (match_score is null or match_score >= 0),
  constraint system_area_feed_results_status_chk check (result_status in ('candidate','materialized','matched','created','already_installed','ignored','skipped_unsupported_type','skipped_invalid_payload','failed','blocked','superseded','archived')),
  constraint system_area_feed_results_lineage_object_chk check (jsonb_typeof(lineage) = 'object'),
  constraint system_area_feed_results_version_chk check (version > 0)
);

comment on table prop4you_leadfinder_group.system_area_feed_results is
'Sanitized provider/feed result ledger for SystemArea autocomplete. Links normalized refs to SystemArea rows; never stores raw provider payload values.';

create unique index if not exists system_areas_provider_geo_id_uniq_idx
  on prop4you_leadfinder_group.system_areas (provider_slug, provider_geo_id)
  where provider_geo_id is not null;
create index if not exists system_areas_autocomplete_state_idx
  on prop4you_leadfinder_group.system_areas (area_type, state_code, name)
  where active = true and deleted_at is null;
create index if not exists system_areas_autocomplete_name_idx
  on prop4you_leadfinder_group.system_areas (area_type, name)
  where active = true and deleted_at is null;
create index if not exists system_areas_search_terms_gin_idx
  on prop4you_leadfinder_group.system_areas using gin (search_terms);
create index if not exists system_areas_centroid_gist_idx
  on prop4you_leadfinder_group.system_areas using gist (centroid)
  where centroid is not null;
create index if not exists system_areas_bbox_gist_idx
  on prop4you_leadfinder_group.system_areas using gist (bbox)
  where bbox is not null;
create index if not exists system_areas_boundary_gist_idx
  on prop4you_leadfinder_group.system_areas using gist (boundary)
  where boundary is not null;
create index if not exists system_areas_lineage_gin_idx
  on prop4you_leadfinder_group.system_areas using gin (lineage jsonb_path_ops);

create unique index if not exists system_area_provider_identities_provider_geo_uniq_idx
  on prop4you_leadfinder_group.system_area_provider_identities (provider_slug, provider_geo_id)
  where provider_geo_id is not null and active = true;
create index if not exists system_area_provider_identities_area_idx
  on prop4you_leadfinder_group.system_area_provider_identities (system_area_id, provider_slug, identity_status);
create index if not exists system_area_provider_identities_lineage_gin_idx
  on prop4you_leadfinder_group.system_area_provider_identities using gin (lineage jsonb_path_ops);

create index if not exists system_area_aliases_area_kind_idx
  on prop4you_leadfinder_group.system_area_aliases (system_area_id, alias_kind)
  where active = true;
create index if not exists system_area_aliases_search_terms_gin_idx
  on prop4you_leadfinder_group.system_area_aliases using gin (search_terms);

create unique index if not exists system_area_feed_terms_normalized_uniq_idx
  on prop4you_leadfinder_group.system_area_feed_terms (
    provider_slug,
    normalized_term,
    coalesce(expected_area_type, ''),
    coalesce(state_code, ''),
    country_code
  );
create index if not exists system_area_feed_terms_status_idx
  on prop4you_leadfinder_group.system_area_feed_terms (feed_status, updated_at desc)
  where active = true;
create index if not exists system_area_feed_results_term_rank_idx
  on prop4you_leadfinder_group.system_area_feed_results (feed_term_id, rank);
create index if not exists system_area_feed_results_provider_geo_idx
  on prop4you_leadfinder_group.system_area_feed_results (provider_slug, provider_geo_id);
create index if not exists system_area_feed_results_area_idx
  on prop4you_leadfinder_group.system_area_feed_results (system_area_id, result_status);

create or replace function prop4you_leadfinder_group.system_area_public_type(p_area_type text)
returns text
language sql
immutable
as $$
  select case when p_area_type = 'postal_code' then 'zip' else p_area_type end
$$;

create or replace function prop4you_leadfinder_group.system_area_display_label(
  p_name text,
  p_area_type text,
  p_state_code text
)
returns text
language sql
immutable
as $$
  select case
    when p_area_type = 'state' then coalesce(nullif(p_state_code, ''), p_name)
    when p_area_type = 'county' and p_state_code is not null then
      (case when p_name ilike '% County' then p_name else p_name || ' County' end) || ', ' || p_state_code
    when p_area_type = 'postal_code' and p_state_code is not null then p_name || ', ' || p_state_code
    when p_state_code is not null then p_name || ', ' || p_state_code
    else p_name
  end
$$;

create or replace function prop4you_leadfinder_group.system_area_refresh_search_terms()
returns trigger
language plpgsql
as $$
declare
  parent_row prop4you_leadfinder_group.system_areas%rowtype;
  state_name text;
  county_alias text;
begin
  state_name := case upper(coalesce(new.state_code, ''))
    when 'AL' then 'Alabama' when 'AK' then 'Alaska' when 'AZ' then 'Arizona' when 'AR' then 'Arkansas'
    when 'CA' then 'California' when 'CO' then 'Colorado' when 'CT' then 'Connecticut' when 'DE' then 'Delaware'
    when 'FL' then 'Florida' when 'GA' then 'Georgia' when 'HI' then 'Hawaii' when 'ID' then 'Idaho'
    when 'IL' then 'Illinois' when 'IN' then 'Indiana' when 'IA' then 'Iowa' when 'KS' then 'Kansas'
    when 'KY' then 'Kentucky' when 'LA' then 'Louisiana' when 'ME' then 'Maine' when 'MD' then 'Maryland'
    when 'MA' then 'Massachusetts' when 'MI' then 'Michigan' when 'MN' then 'Minnesota' when 'MS' then 'Mississippi'
    when 'MO' then 'Missouri' when 'MT' then 'Montana' when 'NE' then 'Nebraska' when 'NV' then 'Nevada'
    when 'NH' then 'New Hampshire' when 'NJ' then 'New Jersey' when 'NM' then 'New Mexico' when 'NY' then 'New York'
    when 'NC' then 'North Carolina' when 'ND' then 'North Dakota' when 'OH' then 'Ohio' when 'OK' then 'Oklahoma'
    when 'OR' then 'Oregon' when 'PA' then 'Pennsylvania' when 'RI' then 'Rhode Island' when 'SC' then 'South Carolina'
    when 'SD' then 'South Dakota' when 'TN' then 'Tennessee' when 'TX' then 'Texas' when 'UT' then 'Utah'
    when 'VT' then 'Vermont' when 'VA' then 'Virginia' when 'WA' then 'Washington' when 'WV' then 'West Virginia'
    when 'WI' then 'Wisconsin' when 'WY' then 'Wyoming' when 'DC' then 'District of Columbia'
    else null
  end;
  county_alias := case when new.area_type = 'county' and new.name !~* ' County$' then new.name || ' County' else null end;
  new.search_label := prop4you_leadfinder_group.system_area_display_label(new.name, new.area_type, new.state_code);
  new.search_terms := base.normalize_search_terms(
    new.name,
    new.state_code,
    new.area_type,
    new.slug_id,
    new.realty_id,
    new.provider_geo_id,
    new.provider_area_ref,
    new.search_label,
    state_name,
    county_alias
  );
  if cardinality(new.search_terms) = 0 then
    new.search_terms := base.normalize_search_terms(new.slug_id, new.public_ref);
  end if;
  new.updated_at := now();
  if tg_op = 'UPDATE' then
    new.version := old.version + 1;
  end if;
  return new;
end;
$$;

drop trigger if exists system_areas_refresh_search_terms on prop4you_leadfinder_group.system_areas;
create trigger system_areas_refresh_search_terms
before insert or update on prop4you_leadfinder_group.system_areas
for each row execute function prop4you_leadfinder_group.system_area_refresh_search_terms();

create or replace function prop4you_leadfinder_group.upsert_system_area_projection(
  p_slug_id text,
  p_area_type text,
  p_name text,
  p_state_code text default null,
  p_provider_slug text default 'realtor',
  p_provider_geo_id text default null,
  p_provider_area_ref text default null,
  p_realty_id text default null,
  p_provider_area_type text default null,
  p_center_lng double precision default null,
  p_center_lat double precision default null,
  p_bbox_west double precision default null,
  p_bbox_south double precision default null,
  p_bbox_east double precision default null,
  p_bbox_north double precision default null,
  p_registration_status text default 'projected',
  p_boundary_status text default 'unknown',
  p_lineage jsonb default '{}'::jsonb,
  p_metadata jsonb default '{}'::jsonb
)
returns prop4you_leadfinder_group.system_areas
language plpgsql
as $$
declare
  v_area prop4you_leadfinder_group.system_areas%rowtype;
  v_centroid geometry(Point, 4326);
  v_bbox geometry(Polygon, 4326);
begin
  if base.clean_text(p_slug_id) is null or base.clean_text(p_area_type) is null or base.clean_text(p_name) is null then
    raise exception 'p_slug_id, p_area_type, and p_name are required';
  end if;
  if p_center_lng is not null or p_center_lat is not null then
    if p_center_lng is null or p_center_lat is null or p_center_lng < -180 or p_center_lng > 180 or p_center_lat < -90 or p_center_lat > 90 then
      raise exception 'invalid centroid coordinates';
    end if;
    v_centroid := ST_SetSRID(ST_MakePoint(p_center_lng, p_center_lat), 4326)::geometry(Point, 4326);
  end if;
  if p_bbox_west is not null or p_bbox_south is not null or p_bbox_east is not null or p_bbox_north is not null then
    if p_bbox_west is null or p_bbox_south is null or p_bbox_east is null or p_bbox_north is null then
      raise exception 'bbox requires west/south/east/north';
    end if;
    v_bbox := ST_MakeEnvelope(p_bbox_west, p_bbox_south, p_bbox_east, p_bbox_north, 4326)::geometry(Polygon, 4326);
  end if;

  insert into prop4you_leadfinder_group.system_areas (
    slug_id, area_type, name, state_code, provider_slug, provider_geo_id, provider_area_ref, realty_id, provider_area_type,
    centroid, bbox, boundary_status, viewport_status, registration_status, search_label, lineage, metadata
  ) values (
    base.clean_text(p_slug_id), base.clean_text(p_area_type), base.clean_text(p_name), upper(nullif(base.clean_text(p_state_code), '')),
    coalesce(base.clean_text(p_provider_slug), 'realtor'), base.clean_text(p_provider_geo_id), base.clean_text(p_provider_area_ref), base.clean_text(p_realty_id), base.clean_text(p_provider_area_type),
    v_centroid, v_bbox, coalesce(base.clean_text(p_boundary_status), 'unknown'), case when v_bbox is not null or v_centroid is not null then 'derived' else 'unknown' end,
    coalesce(base.clean_text(p_registration_status), 'projected'), base.clean_text(p_name), coalesce(p_lineage, '{}'::jsonb), coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict (slug_id, area_type, state_code, country_code) do update set
    name = excluded.name,
    provider_slug = excluded.provider_slug,
    provider_geo_id = coalesce(prop4you_leadfinder_group.system_areas.provider_geo_id, excluded.provider_geo_id),
    provider_area_ref = coalesce(prop4you_leadfinder_group.system_areas.provider_area_ref, excluded.provider_area_ref),
    realty_id = coalesce(prop4you_leadfinder_group.system_areas.realty_id, excluded.realty_id),
    provider_area_type = coalesce(prop4you_leadfinder_group.system_areas.provider_area_type, excluded.provider_area_type),
    centroid = coalesce(prop4you_leadfinder_group.system_areas.centroid, excluded.centroid),
    bbox = coalesce(prop4you_leadfinder_group.system_areas.bbox, excluded.bbox),
    boundary_status = case when prop4you_leadfinder_group.system_areas.boundary_status = 'unknown' then excluded.boundary_status else prop4you_leadfinder_group.system_areas.boundary_status end,
    viewport_status = case when prop4you_leadfinder_group.system_areas.viewport_status = 'unknown' then excluded.viewport_status else prop4you_leadfinder_group.system_areas.viewport_status end,
    registration_status = excluded.registration_status,
    lineage = prop4you_leadfinder_group.system_areas.lineage || excluded.lineage,
    metadata = prop4you_leadfinder_group.system_areas.metadata || excluded.metadata
  returning * into v_area;

  insert into prop4you_leadfinder_group.system_area_provider_identities (
    system_area_id, provider_slug, provider_area_ref, provider_geo_id, provider_slug_id, provider_area_type, identity_status, lineage
  ) values (
    v_area.id, v_area.provider_slug, v_area.provider_area_ref, v_area.provider_geo_id, v_area.slug_id, v_area.provider_area_type, 'active', coalesce(p_lineage, '{}'::jsonb)
  )
  on conflict do nothing;

  insert into prop4you_leadfinder_group.system_area_aliases (system_area_id, alias, alias_kind, search_terms)
  values (v_area.id, v_area.search_label, 'display', base.normalize_search_terms(v_area.search_label))
  on conflict (system_area_id, alias_kind, alias) do nothing;

  return v_area;
end;
$$;

comment on function prop4you_leadfinder_group.upsert_system_area_projection(text,text,text,text,text,text,text,text,text,double precision,double precision,double precision,double precision,double precision,double precision,text,text,jsonb,jsonb) is
'Insert/update normalized SystemArea geography projection without raw provider payloads. Creates centroid/bbox geometries and provider identity/alias rows.';

create or replace view prop4you_leadfinder_group.v_system_area_autocomplete_suggestions as
select
  a.public_ref as "systemAreaId",
  a.public_ref as value,
  a.search_label as label,
  prop4you_leadfinder_group.system_area_public_type(a.area_type) as type,
  a.state_code as meta,
  case when a.centroid is not null then jsonb_build_array(round(ST_X(a.centroid)::numeric, 6), round(ST_Y(a.centroid)::numeric, 6)) end as center,
  case when a.bbox is not null then jsonb_build_array(round(ST_XMin(a.bbox)::numeric, 6), round(ST_YMin(a.bbox)::numeric, 6), round(ST_XMax(a.bbox)::numeric, 6), round(ST_YMax(a.bbox)::numeric, 6))
       when a.boundary is not null then jsonb_build_array(round(ST_XMin(a.boundary)::numeric, 6), round(ST_YMin(a.boundary)::numeric, 6), round(ST_XMax(a.boundary)::numeric, 6), round(ST_YMax(a.boundary)::numeric, 6)) end as bbox,
  a.registration_status as "registrationStatus",
  a.area_type,
  a.state_code,
  a.search_terms,
  a.active,
  a.deleted_at
from prop4you_leadfinder_group.system_areas a
where a.active = true and a.deleted_at is null;

create or replace function prop4you_leadfinder_group.search_system_area_autocomplete(
  p_query text,
  p_area_types text[] default null,
  p_state_code text default null,
  p_limit integer default 20
)
returns table(
  label text,
  value text,
  type text,
  "systemAreaId" text,
  center jsonb,
  bbox jsonb,
  "registrationStatus" text
)
language sql
stable
as $$
  with params as (
    select
      base.clean_text(p_query) as q,
      lower(base.clean_text(p_query)) as q_lower,
      base.normalize_search_text(p_query) as q_terms,
      upper(nullif(base.clean_text(p_state_code), '')) as state_filter,
      least(greatest(coalesce(p_limit, 20), 1), 50) as max_limit
  ), scored as (
    select
      s.label, s.value, s.type, s."systemAreaId", s.center, s.bbox, s."registrationStatus",
      case
        when lower(s.label) = params.q_lower then 0
        when lower(s.label) like params.q_lower || '%' then 10
        when s.state_code = params.state_filter and params.state_filter is not null then 15
        when s.search_terms && params.q_terms then 20
        else 100
      end as rank_score,
      cardinality(array(select unnest(s.search_terms) intersect select unnest(params.q_terms))) as overlap_count
    from prop4you_leadfinder_group.v_system_area_autocomplete_suggestions s
    cross join params
    where params.q is not null
      and length(params.q) >= 2
      and (p_area_types is null or s.area_type = any(p_area_types))
      and (params.state_filter is null or s.state_code = params.state_filter)
      and (
        lower(s.label) like params.q_lower || '%'
        or s.search_terms && params.q_terms
      )
    order by rank_score asc, overlap_count desc, s.type asc, s.label asc
    limit (select max_limit from params)
  )
  select label, value, type, "systemAreaId", center, bbox, "registrationStatus"
  from scored
$$;

comment on function prop4you_leadfinder_group.search_system_area_autocomplete(text,text[],text,integer) is
'Local-only Lead Finder SystemArea autocomplete. Returns label/value/type/systemAreaId/center/bbox/registrationStatus and never calls providers.';

create or replace view prop4you_leadfinder_group.v_system_area_provider_lineage as
select
  a.public_ref as system_area_ref,
  a.slug_id,
  a.area_type,
  a.name,
  a.state_code,
  p.provider_slug,
  p.provider_area_ref,
  p.provider_geo_id,
  p.provider_slug_id,
  p.provider_area_type,
  p.identity_status,
  p.created_at as identity_created_at,
  p.updated_at as identity_updated_at
from prop4you_leadfinder_group.system_areas a
left join prop4you_leadfinder_group.system_area_provider_identities p on p.system_area_id = a.id and p.active = true;

create or replace view prop4you_leadfinder_group.v_system_area_projection_gate_status as
select
  c.candidate_key,
  c.json_path,
  c.projection_shape,
  c.review_status,
  c.proposed_table,
  c.proposed_column,
  case
    when c.json_path in ('$.results[].geo_id','$.results[].slug_id','$.results[].city','$.results[].state_code','$.results[].postal_code','$.results[].counties[].fips','$.results[].centroid') then true
    when c.json_path in ('$.boundary.result.areas[].id','$.boundary.result.areas[].name','$.boundary.result.areas[].center','$.boundary.result.boundary.type','$.boundary.result.boundary.coordinates') then true
    when c.json_path in ('$.property_id','$.property_city','$.property_state','$.property_zip_code','$.county','$.property_address') then true
    else false
  end as systemarea_projection_present,
  s.required_gate_count,
  s.passed_required_gate_count,
  s.all_required_gates_passed
from prop4you_leadfinder_group.projection_candidates c
join prop4you_leadfinder_group.v_projection_candidate_gate_status s on s.candidate_key = c.candidate_key
where c.canonical_envelope_key in ('realtor-evidence-envelope','property-envelope')
  and c.active = true;

comment on view prop4you_leadfinder_group.v_system_area_projection_gate_status is
'Compatibility view from the real SystemArea projection back to Slice 17 geography candidates and seven-gate status.';

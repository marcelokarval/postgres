-- package: prop4you
-- file: 0001_schemas.sql
-- status: skeleton
-- purpose: declares non-final Prop4You schemas and documents ownership boundaries.
-- depends-on: database/ddl/base
-- idempotency: idempotent
-- destructive: false
-- review-gate: provider_payload_corpus_review

create schema if not exists prop4you_sourcehub;
comment on schema prop4you_sourcehub is
'Prop4You SourceHub schema. Owns raw provider/internal payload ingress, corpus metadata, lineage, and future DTO publication boundaries. Skeleton only; final tables require provider corpus review.';

create schema if not exists prop4you_matrix;
comment on schema prop4you_matrix is
'Prop4You Matrix schema. Owns semantic dictionary, provider path mappings, aliases, drift/conflict review, and active mapping/genome decisions. Skeleton only.';

create schema if not exists prop4you_leadfinder;
comment on schema prop4you_leadfinder is
'Prop4You LeadFinder schema. Owns canonical graph materialization boundary after SourceHub DTOs are authorized by Matrix. Skeleton only.';

create schema if not exists prop4you_provider;
comment on schema prop4you_provider is
'Prop4You provider corpus schema. Shared contracts for REIQ, DirectSkip, Realtor.com and internal/product-originated payload analysis. Skeleton only.';

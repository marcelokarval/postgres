# Prop4You Inertia Backend App Inventory and Extraction Order

Status: analysis
Source backend: `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src`
Scope: static analysis of Django/Inertia backend apps, models, relations, services/tasks/commands, and database-centric extraction order.

## Installed/local Django apps found

Source: `config/settings/base.py` plus local `apps.py` files. `domains.marketplace` and `domains.reporting` have AppConfig files but are not currently listed in `DOMAIN_APPS`; treat them as candidates/stubs, not active extraction targets.

| app | config | label | status | role |
| --- | --- | --- | --- | --- |
| `apps.system.matrix` | `MatrixConfig` | `matrix` | installed | semantic/DTO/sourcehub matrix |
| `core.db` | `DbConfig` | `db` | installed | platform database core/mixins/audit |
| `domains.communication` | `CommunicationConfig` | `communication` | installed | campaign messaging |
| `domains.data` | `DataConfig` | `data` | installed | data integrations/sourcehub/skip trace/imports |
| `domains.finance` | `FinanceConfig` | `finance` | installed | billing/credits/subscription/usage |
| `domains.geography` | `GeographyConfig` | `geography` | installed | spatial areas/address substrate |
| `domains.identity` | `IdentityConfig` | `identity` | installed | identity/auth/profile/onboarding |
| `domains.invitations` | `InvitationsConfig` | `domain_invitations` | installed | invitation/onboarding adjunct |
| `domains.marketplace` | `MarketplaceConfig` | `marketplace` | candidate/not installed | support/disabled or not installed |
| `domains.real_estate` | `Real_estateConfig` | `real_estate` | installed | canonical property/owner/lead graph |
| `domains.reporting` | `ReportingConfig` | `reporting` | candidate/not installed | support/disabled or not installed |
| `domains.sales` | `SalesConfig` | `sales` | installed | CRM/deals/sales workflow |

Interface modules are explicitly not Django apps. `apps.public.*` and `interfaces.web.*` are facade/transport surfaces, not durable business-truth owners.

## App/module inventory

| module | Django models | service files | task files | management commands | direct FK/O2O/M2M deps |
| --- | ---: | ---: | ---: | ---: | --- |
| `communication` | 3 | 6 | 3 | 0 | identity |
| `core` | 13 | 3 | 7 | 0 | identity |
| `data` | 12 | 18 | 3 | 6 | identity, real_estate |
| `finance` | 13 | 25 | 3 | 5 | identity |
| `geography` | 6 | 22 | 8 | 12 | - |
| `identity` | 13 | 35 | 4 | 10 | - |
| `invitations` | 0 | 4 | 2 | 0 | - |
| `marketplace` | 0 | 1 | 1 | 0 | - |
| `real_estate` | 41 | 28 | 3 | 4 | geography, identity |
| `reporting` | 0 | 1 | 1 | 0 | - |
| `sales` | 12 | 7 | 1 | 0 | identity |
| `system.matrix` | 7 | 0 | 0 | 3 | identity |

Note: `core` count includes abstract mixins/BaseTagModel and `DbAuditLog`; it is platform substrate already mostly represented by PG18 base DDL, not a product app to extract as a Prop4You bounded context.

## Models by app

### `communication`
- `Campaign` (domains/communication/models/campaign_models.py): 9 fields; relations: owner->settings.AUTH_USER_MODEL; template->Template
- `CampaignRecipient` (domains/communication/models/campaign_models.py): 7 fields; relations: campaign->Campaign
- `Template` (domains/communication/models/campaign_models.py): 6 fields; relations: owner->settings.AUTH_USER_MODEL

### `core`
- `AbstractInvitation` (core/db/models/invitation.py): 11 fields; relations: accepted_by->settings.AUTH_USER_MODEL; provisioned_by->settings.AUTH_USER_MODEL; referred_by->User
- `ActivatableMixin` (core/db/mixins/django/activatable.py): 3 fields; relations: -
- `BaseTagModel` (core/db/models/base.py): 9 fields; relations: -
- `BoundaryGeoMixin` (core/db/mixins/django/geo.py): 1 fields; relations: -
- `DataMixin` (core/db/mixins/django/json_fields.py): 1 fields; relations: -
- `DbAuditLog` (core/db/audit/models.py): 13 fields; relations: user->settings.AUTH_USER_MODEL
- `MetadataMixin` (core/db/mixins/django/json_fields.py): 1 fields; relations: -
- `PointGeoMixin` (core/db/mixins/django/geo.py): 1 fields; relations: -
- `PublicIDMixin` (core/db/mixins/django/public_id.py): 1 fields; relations: -
- `SearchableMixin` (core/db/mixins/django/search.py): 1 fields; relations: -
- `SoftDeleteMixin` (core/db/mixins/django/soft_delete.py): 2 fields; relations: -
- `TimestampMixin` (core/db/mixins/django/timestamp.py): 2 fields; relations: -
- `VersionableMixin` (core/db/mixins/django/versionable.py): 3 fields; relations: last_modified_by->settings.AUTH_USER_MODEL

### `data`
- `DownloadHistory` (domains/data/models/download_history.py): 10 fields; relations: user->User; batch->data.SkipTraceBatch
- `LeadImport` (domains/data/models/lead_source.py): 12 fields; relations: owner->User; source->LeadSource
- `LeadSource` (domains/data/models/lead_source.py): 9 fields; relations: owner->User
- `SkipTraceBatch` (domains/data/models/skip_trace.py): 17 fields; relations: user->User
- `SkipTraceFinancialProjection` (domains/data/models/skip_trace_financial_projection.py): 29 fields; relations: request->data.SkipTraceRequest; user->settings.AUTH_USER_MODEL; result->data.SkipTraceResult
- `SkipTraceRequest` (domains/data/models/skip_trace.py): 26 fields; relations: user->User; batch->data.SkipTraceBatch; canonical_property->real_estate.Property; retry_of->self
- `SkipTraceResult` (domains/data/models/skip_trace.py): 14 fields; relations: request->SkipTraceRequest
- `SkipTraceSnapshot` (domains/data/models/system_cache.py): 10 fields; relations: provider->SystemSkipTraceProvider
- `SourceHubRawRecord` (domains/data/models/sourcehub.py): 11 fields; relations: -
- `SystemSkipTraceHit` (domains/data/models/system_cache.py): 6 fields; relations: result->SystemSkipTraceResult
- `SystemSkipTraceProvider` (domains/data/models/system_cache.py): 9 fields; relations: -
- `SystemSkipTraceResult` (domains/data/models/system_cache.py): 20 fields; relations: provider->SystemSkipTraceProvider

### `finance`
- `CheckoutSessionToken` (domains/finance/models/checkout_models.py): 12 fields; relations: user->settings.AUTH_USER_MODEL
- `PaymentMethod` (domains/finance/models/billing_models.py): 8 fields; relations: user->settings.AUTH_USER_MODEL
- `PaymentMethodMetadata` (domains/finance/models/payment_method_metadata.py): 5 fields; relations: user->settings.AUTH_USER_MODEL
- `PlanChangeLog` (domains/finance/models/plan_change_models.py): 22 fields; relations: user->settings.AUTH_USER_MODEL
- `PlanChangePolicy` (domains/finance/models/plan_change_policy_models.py): 10 fields; relations: -
- `PlanFeatures` (domains/finance/models/plan_features_models.py): 10 fields; relations: -
- `PropertyAccessLimit` (domains/finance/models/balance_models.py): 6 fields; relations: user->User
- `PurchasableProduct` (domains/finance/models/credit_models.py): 6 fields; relations: -
- `USDBalanceLedger` (domains/finance/models/balance_models.py): 7 fields; relations: user_balance->UserUSDBalance
- `UsageRecord` (domains/finance/models/billing_models.py): 7 fields; relations: user->settings.AUTH_USER_MODEL
- `UserCreditBalance` (domains/finance/models/credit_models.py): 3 fields; relations: user->User
- `UserCreditBalanceLedger` (domains/finance/models/credit_models.py): 10 fields; relations: user->User; credit_balance->UserCreditBalance
- `UserUSDBalance` (domains/finance/models/balance_models.py): 7 fields; relations: user->User

### `geography`
- `SystemAddress` (domains/geography/models/address_models.py): 20 fields; relations: city_area->geography.SystemArea; county_area->geography.SystemArea; postal_code_area->geography.SystemArea
- `SystemArea` (domains/geography/models/area_models.py): 12 fields; relations: parent->self
- `SystemAreaCandidate` (domains/geography/models/geokeo_candidate_models.py): 17 fields; relations: materialized_area->SystemArea
- `SystemAreaCandidateAttempt` (domains/geography/models/geokeo_candidate_models.py): 19 fields; relations: candidate->SystemAreaCandidate; materialized_area->SystemArea
- `SystemAreaFeedResult` (domains/geography/models/geokeo_candidate_models.py): 17 fields; relations: feed_term->SystemAreaFeedTerm; system_area->SystemArea
- `SystemAreaFeedTerm` (domains/geography/models/geokeo_candidate_models.py): 22 fields; relations: -

### `identity`
- `AccountDeletionRequest` (domains/identity/models/deletion_models.py): 11 fields; relations: user->settings.AUTH_USER_MODEL
- `CustomUser` (domains/identity/models/user_models.py): 5 fields; relations: -
- `EmailBlacklist` (domains/identity/models/blacklist_models.py): 4 fields; relations: -
- `EmailLog` (domains/identity/models/email_models.py): 9 fields; relations: recipient_user->settings.AUTH_USER_MODEL
- `EmailVerificationToken` (domains/identity/models/tokens/email_verification.py): 6 fields; relations: token->UserToken
- `FeatureFlag` (domains/identity/models/feature_flag_models.py): 6 fields; relations: -
- `LegalAcceptance` (domains/identity/models/legal_models.py): 11 fields; relations: user->settings.AUTH_USER_MODEL; document->LegalDocument
- `LegalDocument` (domains/identity/models/legal_models.py): 10 fields; relations: -
- `PasswordResetToken` (domains/identity/models/tokens/password_reset.py): 4 fields; relations: token->UserToken
- `TokenRateLimit` (domains/identity/models/tokens/rate_limiting.py): 7 fields; relations: user->settings.AUTH_USER_MODEL
- `UserMFA` (domains/identity/models/mfa_models.py): 6 fields; relations: user->settings.AUTH_USER_MODEL
- `UserProfile` (domains/identity/models/user_models.py): 30 fields; relations: user->CustomUser
- `UserToken` (domains/identity/models/tokens/base_token.py): 10 fields; relations: user->User

### `real_estate`
- `FilterPreset` (domains/real_estate/models/filter_preset_models.py): 8 fields; relations: user->settings.AUTH_USER_MODEL; folder->real_estate.FilterPresetFolder
- `FilterPresetFolder` (domains/real_estate/models/filter_preset_models.py): 5 fields; relations: user->settings.AUTH_USER_MODEL
- `LeadContactAttempt` (domains/real_estate/models/lead_intelligence_models.py): 8 fields; relations: intelligence->real_estate.LeadIntelligence; recorded_by->settings.AUTH_USER_MODEL
- `LeadIntelligence` (domains/real_estate/models/lead_intelligence_models.py): 16 fields; relations: property->real_estate.Property
- `LeadScore` (domains/real_estate/models/lead_score_models.py): 10 fields; relations: property->real_estate.Property
- `OwnerContactAddress` (domains/real_estate/models/canonical_party_graph.py): 12 fields; relations: entity->real_estate.OwnerEntity; system_address->geography.SystemAddress; property->real_estate.Property
- `OwnerEmail` (domains/real_estate/models/canonical_party_graph.py): 17 fields; relations: entity->real_estate.OwnerEntity
- `OwnerEmailTag` (domains/real_estate/models/workspace_contact_tags.py): 1 fields; relations: email->OwnerEmail
- `OwnerEntity` (domains/real_estate/models/canonical_party_graph.py): 15 fields; relations: -
- `OwnerEntityRepresentative` (domains/real_estate/models/canonical_party_graph.py): 10 fields; relations: company->real_estate.OwnerEntity; person->real_estate.OwnerEntity
- `OwnerEntityTag` (domains/real_estate/models/workspace_contact_tags.py): 1 fields; relations: entity->OwnerEntity
- `OwnerIdentityEvidence` (domains/real_estate/models/owner_resolution_evidence.py): 28 fields; relations: subject_entity->real_estate.OwnerEntity; property->real_estate.Property; ownership->real_estate.Ownership
- `OwnerPhone` (domains/real_estate/models/canonical_party_graph.py): 14 fields; relations: entity->real_estate.OwnerEntity
- `OwnerPhoneTag` (domains/real_estate/models/workspace_contact_tags.py): 1 fields; relations: phone->OwnerPhone
- `OwnerResolutionCandidate` (domains/real_estate/models/owner_resolution_case.py): 10 fields; relations: case->OwnerResolutionCase; candidate_entity->real_estate.OwnerEntity
- `OwnerResolutionCase` (domains/real_estate/models/owner_resolution_case.py): 12 fields; relations: subject_entity->real_estate.OwnerEntity; property->real_estate.Property; ownership->real_estate.Ownership
- `OwnerResolutionCaseEvidence` (domains/real_estate/models/owner_resolution_case.py): 5 fields; relations: case->OwnerResolutionCase; evidence->OwnerIdentityEvidence
- `OwnerResolutionDecision` (domains/real_estate/models/owner_resolution_decision.py): 12 fields; relations: case->OwnerResolutionCase; chosen_candidate->OwnerResolutionCandidate; subject_entity->real_estate.OwnerEntity
- `OwnerResolutionMaterialization` (domains/real_estate/models/owner_resolution_decision.py): 8 fields; relations: decision->OwnerResolutionDecision
- `Ownership` (domains/real_estate/models/canonical_party_graph.py): 17 fields; relations: entity->OwnerEntity; property->real_estate.Property
- `PartyRole` (domains/real_estate/models/canonical_party_graph.py): 9 fields; relations: entity->real_estate.OwnerEntity; property->real_estate.Property; related_owner->real_estate.OwnerEntity
- `PersonRelationship` (domains/real_estate/models/relationship_models.py): 6 fields; relations: from_person->real_estate.OwnerEntity; to_person->real_estate.OwnerEntity
- `Property` (domains/real_estate/models/canonical_graph.py): 3 fields; relations: location->PropertyLocation; system_address->geography.SystemAddress
- `PropertyActivity` (domains/real_estate/models/activity_models.py): 8 fields; relations: property->real_estate.Property; entity->real_estate.OwnerEntity; user->User
- `PropertyDetails` (domains/real_estate/models/detail_models.py): 27 fields; relations: property->real_estate.Property
- `PropertyEnrichmentOverlay` (domains/real_estate/models/canonical_graph_overlays.py): 6 fields; relations: property->real_estate.Property
- `PropertyEvent` (domains/real_estate/models/event_models.py): 7 fields; relations: property->real_estate.Property
- `PropertyHistory` (domains/real_estate/models/history_models.py): 2 fields; relations: property->real_estate.Property
- `PropertyList` (domains/real_estate/models/workspace_crm.py): 10 fields; relations: owner->User
- `PropertyListRegistry` (domains/real_estate/models/workspace_registry.py): 13 fields; relations: user->User
- `PropertyLocation` (domains/real_estate/models/canonical_graph.py): 15 fields; relations: system_address->geography.SystemAddress
- `PropertyNote` (domains/real_estate/models/note_models.py): 5 fields; relations: property->real_estate.Property; user->User
- `PropertySimple` (domains/real_estate/models/legacy_simple_property.py): 26 fields; relations: owner->identity.CustomUser
- `PropertySituation` (domains/real_estate/models/situation_models.py): 13 fields; relations: property->real_estate.Property
- `PropertyStatusRegistry` (domains/real_estate/models/workspace_registry.py): 7 fields; relations: user->User
- `PropertyTagRegistry` (domains/real_estate/models/workspace_registry.py): 11 fields; relations: user->User
- `PropertyValuation` (domains/real_estate/models/valuation_models.py): 11 fields; relations: property->real_estate.Property
- `SavedProperty` (domains/real_estate/models/workspace_crm.py): 6 fields; relations: user->User; property->real_estate.Property; lists->PropertyList; tags->PropertyTag
- `SystemPropertyListType` (domains/real_estate/models/semantic_base_models.py): 1 fields; relations: -
- `WorkspaceOwnedTag` (domains/real_estate/models/workspace_tag_base.py): 1 fields; relations: owner->User
- `_SemanticBaseModel` (domains/real_estate/models/semantic_base_models.py): 3 fields; relations: -

### `sales`
- `BuyerInterest` (domains/sales/models/buyer_interest.py): 23 fields; relations: buyer->Contact; deal->Deal; created_by->identity.CustomUser
- `Contact` (domains/sales/models/contact.py): 24 fields; relations: owner->identity.CustomUser
- `Deal` (domains/sales/models/deal.py): 21 fields; relations: owner->identity.CustomUser; tags->DealTag
- `DealActivity` (domains/sales/models/deal.py): 12 fields; relations: deal->Deal; user->identity.CustomUser
- `DealAnalytics` (domains/sales/models/analytics.py): 19 fields; relations: deal->Deal
- `DealDocument` (domains/sales/models/deal.py): 9 fields; relations: deal->Deal; uploaded_by->identity.CustomUser
- `DealMetrics` (domains/sales/models/analytics.py): 20 fields; relations: user->identity.CustomUser
- `DealStage` (domains/sales/models/deal.py): 7 fields; relations: -
- `DealTag` (domains/sales/models/tags.py): 9 fields; relations: created_by->identity.CustomUser
- `DealTagAssignment` (domains/sales/models/deal.py): 3 fields; relations: deal->Deal; tag->DealTag; assigned_by->identity.CustomUser
- `DealTask` (domains/sales/models/deal.py): 9 fields; relations: deal->Deal; assigned_to->identity.CustomUser; created_by->identity.CustomUser
- `HandoffRequest` (domains/sales/models/handoff.py): 18 fields; relations: deal->sales.Deal; from_user->CustomUser; target_user->CustomUser; created_by->CustomUser

### `system.matrix`
- `MatrixApprovalRecord` (apps/system/matrix/models.py): 8 fields; relations: schema_genome->MatrixSchemaGenome; requested_by->settings.AUTH_USER_MODEL; decided_by->settings.AUTH_USER_MODEL
- `MatrixCorpusSession` (apps/system/matrix/models.py): 17 fields; relations: linked_genome->MatrixSchemaGenome; default_baseline->MatrixLeadFinderDefaultBaseline
- `MatrixCorpusSessionStartForm` (apps/system/matrix/admin/forms.py): 5 fields; relations: -
- `MatrixFieldReview` (apps/system/matrix/models.py): 18 fields; relations: session->MatrixCorpusSession; merged_into_genome->MatrixSchemaGenome
- `MatrixGrowthPressureSignal` (apps/system/matrix/models.py): 20 fields; relations: submitted_by->settings.AUTH_USER_MODEL; linked_genome->MatrixSchemaGenome; approval_record->MatrixApprovalRecord
- `MatrixLeadFinderDefaultBaseline` (apps/system/matrix/models.py): 11 fields; relations: -
- `MatrixSchemaGenome` (apps/system/matrix/models.py): 30 fields; relations: lead_finder_default_baseline->MatrixLeadFinderDefaultBaseline; parent_genome->self; approved_by->settings.AUTH_USER_MODEL

## Cross-app FK/O2O/M2M dependency edges
- `communication` -> `identity` (2 relation fields): Template.owner->settings.AUTH_USER_MODEL; Campaign.owner->settings.AUTH_USER_MODEL
- `core` -> `identity` (5 relation fields): VersionableMixin.last_modified_by->settings.AUTH_USER_MODEL; AbstractInvitation.accepted_by->settings.AUTH_USER_MODEL; AbstractInvitation.provisioned_by->settings.AUTH_USER_MODEL; AbstractInvitation.referred_by->User; DbAuditLog.user->settings.AUTH_USER_MODEL
- `data` -> `identity` (6 relation fields): SkipTraceRequest.user->User; SkipTraceBatch.user->User; DownloadHistory.user->User; LeadSource.owner->User; LeadImport.owner->User
- `data` -> `real_estate` (1 relation fields): SkipTraceRequest.canonical_property->real_estate.Property
- `finance` -> `identity` (9 relation fields): UserCreditBalance.user->User; UserCreditBalanceLedger.user->User; UserUSDBalance.user->User; PropertyAccessLimit.user->User; PlanChangeLog.user->settings.AUTH_USER_MODEL
- `real_estate` -> `geography` (3 relation fields): PropertyLocation.system_address->geography.SystemAddress; Property.system_address->geography.SystemAddress; OwnerContactAddress.system_address->geography.SystemAddress
- `real_estate` -> `identity` (12 relation fields): FilterPreset.user->settings.AUTH_USER_MODEL; FilterPresetFolder.user->settings.AUTH_USER_MODEL; PropertyActivity.user->User; PropertyTagRegistry.user->User; PropertyStatusRegistry.user->User
- `sales` -> `identity` (13 relation fields): Contact.owner->identity.CustomUser; DealMetrics.user->identity.CustomUser; BuyerInterest.created_by->identity.CustomUser; DealTag.created_by->identity.CustomUser; HandoffRequest.from_user->CustomUser
- `system.matrix` -> `identity` (4 relation fields): MatrixSchemaGenome.approved_by->settings.AUTH_USER_MODEL; MatrixApprovalRecord.requested_by->settings.AUTH_USER_MODEL; MatrixApprovalRecord.decided_by->settings.AUTH_USER_MODEL; MatrixGrowthPressureSignal.submitted_by->settings.AUTH_USER_MODEL

## Recommended extraction order

0. **base/core substrate** — core.db/BaseModel/mixins/audit managers: already extracted into PG18 base; verify any remaining mixin semantics before product DDL.
1. **identity** — AUTH_USER_MODEL, profile, onboarding/legal/MFA/tokens. Almost every user/workspace/billing/CRM object points to user.
2. **geography** — SystemArea/SystemAddress spatial substrate. PropertyLocation and OwnerContactAddress depend on geography addresses/areas.
3. **finance/billing** — User balances, credits, plan features, usage and delinquency gates. It depends on identity, but real_estate access/billing and UI gates depend on it.
4. **real_estate canonical graph** — PropertyLocation/Property/OwnerEntity/Ownership/contacts/history/situations/lead intelligence. This is canonical business graph and depends on identity+geography; many later modules depend on it.
5. **data: SourceHub + skip trace + imports** — SkipTraceRequest/Result/Batch, SourceHubRawRecord, system skip-trace cache, lead imports. Depends on identity and real_estate; enriches but must not define property/owner truth.
6. **system.matrix** — Semantic schemas/genomes/DTO contracts/admission. Governs meaning and DTO publication; should be extracted after canonical graph + SourceHub boundaries are explicit.
7. **sales/CRM/deals** — Contacts/deals/stages/tasks/documents/handoffs/analytics. Depends heavily on identity and has conceptual dependency on property/owner graph even where FK is weak.
8. **communication/campaigns** — Templates/campaigns/recipients. Mostly identity/user and sales/lead activation dependent.
9. **invitations/onboarding adjunct** — No first-party models detected in AST; uses external invitations package and identity onboarding flows. Extract after identity if needed.
10. **interfaces/public + web** — Not database truth; action/query/presenter/API facades should be translated last into api.* functions/views after domain DDL is stable.

## Criterious dependency notes

- UUID7/public refs weaken deployment-time coupling, but they do not remove semantic dependency. Extract canonical truth before enrichment, projections, facades, and workflow modules.
- `identity` remains an early dependency because user/workspace/legal/billing/session ownership appears throughout the backend.
- `geography` should precede canonical property because `PropertyLocation`, `Property.system_address`, and owner contact addresses depend on `SystemAddress/SystemArea`.
- `real_estate` is the core business graph: property, owner entity, ownership, contacts, situations, notes, lead score/intelligence, workspace CRM.
- `data` includes SourceHub and Skip Trace. It should enrich and publish lineage/DTOs, not redefine canonical property/owner truth.
- `system.matrix` should be extracted as semantic governance after base canonical records and SourceHub boundaries are explicit; many files are Pydantic/TypedDict DTO contracts, not durable tables.
- `apps.public.*` and `interfaces.web.*` are transport/action/query/presenter layers. Translate them into `api.*` functions/views after domain functions exist.
- `sales` and `communication` can be delayed unless the current slice explicitly needs CRM/campaign features.

## Non-Django-app surfaces to treat as facade/integration

- `apps.public/*`: action/query/presenter modules for public/Inertia use cases; database-centric target is `api.*` facade plus domain functions.
- `interfaces/web/*`: routes/views/middleware; not business-truth owners.
- `infrastructure/integrations/*`: provider clients such as DirectSkip/Telnyx; database target is request/result/outbox tables plus provider execution outside the DB when appropriate.
- `core/tasks/schedules.py` and domain tasks: translate into `jobs.*`, `pgmq`, and central `postgres` `cron.schedule_in_database(...)` policy.

## Suggested first DDL extraction slices

1. `prop4you_identity_core`: account/user/profile/legal/token/onboarding state; map Django auth carefully rather than blindly reimplementing auth internals.
2. `prop4you_geography_core`: system areas, addresses, spatial indexes, boundary enrichment state.
3. `prop4you_property_graph_core`: PropertyLocation, Property, OwnerEntity, Ownership, contacts, party roles.
4. `prop4you_property_workspace`: lists, saved properties, notes, tags/status/list registries, filter presets.
5. `prop4you_lead_intelligence`: situations, lead score, lead intelligence/contact attempts, valuations/details.
6. `prop4you_sourcehub_skiptrace`: SourceHubRawRecord, SkipTraceRequest/Result/Batch, cache/snapshot/hits, promotion boundaries.
7. `prop4you_matrix_semantics`: MatrixSchemaGenome/baselines/approval/corpus/field review/growth signals + DTO contract storage if needed.
8. `prop4you_billing_usage`: credits/USD balances, plan features, usage, checkout/session/payment metadata; can move earlier if access gating blocks tests.
9. `prop4you_sales_communication`: deals/contacts/campaigns once property/lead graph exists.
10. `prop4you_api_facade`: PostgREST/RPC functions mirroring public Inertia actions/queries.

## Active app list for extraction

Active Django/product surfaces to consider, in practical groups:

```text
core.db             substrate/already-base
domains.identity    identity/auth/profile/onboarding
domains.geography   geography/address/spatial substrate
domains.finance     billing/credits/access gates
domains.real_estate canonical property-owner-lead graph
domains.data        SourceHub, skip trace, imports/cache
apps.system.matrix  semantic governance/DTO matrix
domains.sales       CRM/deals
domains.communication campaigns/messaging
domains.invitations invitation adjunct
apps.public.*       facade/action/query layer, not durable truth
interfaces.web.*    Inertia transport/presenter/middleware, not durable truth
```

## Evidence

- AppConfig files parsed: 12
- Django-model-like classes parsed: 120
- Relation fields parsed: 154
- Cross-app relation edges parsed: 55

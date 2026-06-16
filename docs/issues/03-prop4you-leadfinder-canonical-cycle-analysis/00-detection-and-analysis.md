# Detection — Prop4You LeadFinder canonical cycle analysis

Status: started
Date: 2026-06-16T12:00:23
Owner: Thor/default

## User correction captured

- LeadFinder is not one app; it is a group/container of apps that gives life to lead/opportunity generation.
- LeadFinder group is consumer final and canonical generator.
- Matrix receives canonical dictionary from LeadFinder group and analyzes raw/new data against it to generate transformation DTO.
- SourceHub consumes provider DTO + raw data and transforms into JSON consumable by LeadFinder group.
- This creates a dependency cycle: LeadFinder canonical -> Matrix mapper -> SourceHub DTO/translation -> LeadFinder canonical evolution.
- Need detect if current DDL path repeats Django project mistake by starting from providers/system logic before LeadFinder group canonical model.
- Answers: raw corpus first, enrichment worker both pgmq + polling, path extraction both SQL + Python.

## Safety

No provider calls. No raw/PII dumps in docs/chat. Analyze paths/types/shapes and code structure only.

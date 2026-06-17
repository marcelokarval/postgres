# Detection and analysis — Matrix field_mapping_set + prepare-only promotion

Status: active

## Architecture correction

Gateway/runtime is 100% agnostic. Django/PostgREST/ORM/direct SQL are interchangeable transports over database contracts.

Raw records have two simultaneous roles:

1. Generator/modeler of LFG apps and operational surfaces.
2. Generator/evolver of the LeadFinder canonical dictionary.

## Current decision

Proceed with Matrix-owned `field_mapping_set` artifact before SourceHub DTO publication. LeadFinder promotion must be prepare-only.

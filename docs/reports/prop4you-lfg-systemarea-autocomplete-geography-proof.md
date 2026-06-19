# Prop4You LFG SystemArea autocomplete geography proof

Status: PASS

## Lab DB

~~~text
pg18_prop4you_systemarea_autocomplete_lab
~~~

## Validation JSON

~~~json
{
    "bbox_count": 4,
    "alias_count": 4,
    "centroid_count": 4,
    "feed_term_count": 1,
    "autocomplete_rows": [
        {
            "bbox": [
                -81.600000,
                28.350000,
                -81.200000,
                28.700000
            ],
            "type": "city",
            "label": "Orlando, FL",
            "value": "p4ylfgsa_019ee1e2-175f-7d21-ae40-05cb6cc14dd9",
            "center": [
                -81.379200,
                28.538300
            ],
            "systemAreaId": "p4ylfgsa_019ee1e2-175f-7d21-ae40-05cb6cc14dd9",
            "registrationStatus": "created"
        }
    ],
    "feed_result_count": 1,
    "system_area_count": 4,
    "autocomplete_orl_count": 1,
    "autocomplete_zip_count": 1,
    "provider_identity_count": 4,
    "approved_candidate_count": 0,
    "autocomplete_state_count": 1,
    "autocomplete_rows_json_count": 1,
    "projected_gate_candidate_count": 18
}
~~~

## Assertions

~~~text
system_area_count = 4
provider_identity_count = 4
alias_count = 4
feed_term_count = 1
feed_result_count = 1
centroid_count = 4
bbox_count = 4
autocomplete_orl_count >= 1
autocomplete_zip_count >= 1
autocomplete_state_count >= 1
projected_gate_candidate_count >= 15
approved_candidate_count = 0
autocomplete rows use value == systemAreaId
autocomplete center is [lng, lat]
autocomplete bbox is [west, south, east, north]
~~~

## Guardrails

~~~text
no provider calls
no raw provider payload values
real geography projection DDL
no property/owner/workspace table explosion
~~~

# Prop4You LFG projection candidate board proof

Status: PASS

## Lab DB

~~~text
pg18_prop4you_projection_candidate_board_lab
~~~

## Validation JSON

~~~json
{
    "group_count": 9,
    "review_count": 53,
    "candidate_count": 53,
    "gate_eval_count": 371,
    "next_action_count": 53,
    "passed_gate_count": 0,
    "geography_group_count": 3,
    "active_candidate_count": 53,
    "directskip_group_count": 1,
    "postgis_candidate_count": 3,
    "approved_candidate_count": 0,
    "candidates_without_gates": 0,
    "first_geography_sequence": 10,
    "directskip_candidate_count": 14,
    "edge_table_candidate_count": 2,
    "join_table_candidate_count": 5
}
~~~

## Assertions

~~~text
group_count = 9
candidate_count = 53
gate_eval_count = 371
review_count = 53
approved_candidate_count = 0
next_action_count = 53
directskip_group_count = 1
directskip_candidate_count >= 14
geography_group_count = 3
first_geography_sequence = 10
postgis_candidate_count >= 3
join_table_candidate_count >= 3
edge_table_candidate_count >= 2
passed_gate_count = 0
candidates_without_gates = 0
~~~

## Guardrails

~~~text
no provider calls
no raw payload values
no final projection tables
review-board only
~~~

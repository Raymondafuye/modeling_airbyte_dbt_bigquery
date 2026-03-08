-- Test: Trip duration must be positive
-- Ensures completed trips have positive duration

select
    trip_id,
    trip_duration_minutes,
    status
from {{ ref('int_duration_min') }}
where trip_duration_minutes < 0
  and status = 'completed'

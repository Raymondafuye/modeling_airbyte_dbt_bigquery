-- Test: Completed trips must have successful payment
-- Ensures data integrity between trips and payments

select
    trip_id,
    payment_status,
    payment_id,
    rider_id,
    driver_id
from {{ ref('int_failed_payment_on_completed_trip') }}
where is_failed_payment_on_completed_trip = true



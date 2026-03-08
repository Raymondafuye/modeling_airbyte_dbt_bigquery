-- Test: No negative net revenue
-- Ensures that net_revenue is never negative

select
    payment_id,
    trip_id,
    amount,
    fee,
    net_revenue
from {{ ref('int_net_revenue') }}
where net_revenue < 0

{% snapshot snap_drivers %}

{{
    config(
        target_schema='snapshots',
        unique_key='driver_id',
        strategy='timestamp',
        updated_at='updated_at',
        hard_deletes='invalidate'
    )
}}

select
    driver_id,
    vehicle_id,
    driver_status,
    rating,
    updated_at
from {{ ref('stg_drivers') }}

{% endsnapshot %}

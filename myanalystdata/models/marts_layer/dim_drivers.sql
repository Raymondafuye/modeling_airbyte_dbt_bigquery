{{
    config(
        materialized='table',
        tags=['operations'],
        meta={'owner': 'data_engineering_team'}
    )
}}

with drivers as (
    select * from {{ ref('stg_drivers') }}
),

driver_lifetime_trips as (
    select * from {{ ref('int_driver_life_time_trips') }}
)

select
    d.driver_id,
    d.city_id,
    d.vehicle_id,
    d.driver_status,
    d.rating,
    d.onboarding_date,
    d.created_at,
    d.updated_at,
    coalesce(dlt.driver_lifetime_trips, 0) as lifetime_trips
from drivers d
left join driver_lifetime_trips dlt on d.driver_id = dlt.driver_id

{{
     config(
         materialized='view',
         tags='fraud',
         meta={'owner': 'data_engineering_team',
          'business_questions': 'Which trips had an extreme surge multiplier (greater than 10)?'}
     )
}}  


with trips as (

    select * from {{ ref('stg_trips') }}

)

select
    trip_id,
    driver_id,
    rider_id,
    city_id,
    status,
    surge_multiplier,
    actual_fare,
    requested_at,

    {{ classify_surge('surge_multiplier') }}    as surge_category,

    case
        when surge_multiplier > 10 then true
        else false
    end    as is_extreme_surge

from trips
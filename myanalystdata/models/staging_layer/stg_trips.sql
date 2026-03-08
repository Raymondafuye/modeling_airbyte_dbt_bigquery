with source as (
    select *
    from {{ source('Rider_Project', 'trips_raw') }}
),

deduplicated as (
    select
        *,
        row_number() over (partition by trip_id order by created_at desc) as row_num
    from source
    where trip_id is not null
),

cleaned_trips as (
    select
        cast(trip_id as int64)                      as trip_id,
        cast(rider_id as int64)                     as rider_id,
        cast(driver_id as int64)                    as driver_id,
        cast(city_id as int64)                      as city_id,
        cast(vehicle_id as string)                  as vehicle_id,
        cast(status as string)                      as status,
        cast(payment_method as string)              as payment_method,
        cast(is_corporate as boolean)               as is_corporate,
        cast(estimated_fare as numeric)             as estimated_fare,
        cast(actual_fare as numeric)                as actual_fare,
        cast(surge_multiplier as numeric)           as surge_multiplier,
        cast(requested_at as timestamp)             as requested_at,
        cast(pickup_at as timestamp)                as pickup_at,
        cast(dropoff_at as timestamp)               as dropoff_at,
        cast(created_at as timestamp)               as created_at,
        cast(updated_at as timestamp)               as updated_at
    from deduplicated
    where row_num = 1
)

select * from cleaned_trips





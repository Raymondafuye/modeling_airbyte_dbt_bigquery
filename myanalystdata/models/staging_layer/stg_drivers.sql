with source as (

    select * from {{ source('Rider_Project', 'drivers_raw') }}

),

deduplicated as (

    select *,
        row_number() over (
            partition by driver_id
            order by updated_at desc
        ) as row_num

    from source

    where driver_id is not null

),

cleaned_drivers as (

    select
        cast(driver_id as int64)                    as driver_id,
        cast(city_id as int64)                      as city_id,
        cast(vehicle_id as string)                  as vehicle_id,
        cast(driver_status as string)               as driver_status,
        cast(rating as numeric)                     as rating,
        cast(onboarding_date as date)               as onboarding_date,
        cast(created_at as timestamp)               as created_at,
        cast(updated_at as timestamp)               as updated_at
    from deduplicated
    where row_num = 1

)

select * from cleaned_drivers
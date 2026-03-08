
with source as (

    select * from {{ source('Rider_Project', 'driver_status_events_raw') }}

),

deduplicated as (

    select *,
        row_number() over (
            partition by event_id
            order by event_timestamp desc
        ) as row_num

    from source
    where event_id is not null

),

cleaned_driverstatus as (

    select
      
        cast(event_id as int64)  as event_id,
        cast(driver_id as int64) as driver_id,
        cast(status as string)    as status,
        cast(event_timestamp as timestamp) as event_timestamp,
    from deduplicated
    where row_num = 1
)

select * from cleaned_driverstatus
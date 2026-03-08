with source as (

    select * from {{ source('Rider_Project', 'riders_raw') }}

),

deduplicated as (

    select *,
        row_number() over (
            partition by rider_id
            order by created_at desc
        ) as row_num

    from source
    where rider_id is not null

),

cleaned_riders as (

    select
        cast(rider_id as int64)                     as rider_id,
        cast(country as string)                     as country,
        cast(signup_date as date)                   as signup_date,
        cast(referral_code as string)               as referral_code,
        cast(created_at as timestamp)               as created_at
    from deduplicated
    where row_num = 1

)

select * from cleaned_riders
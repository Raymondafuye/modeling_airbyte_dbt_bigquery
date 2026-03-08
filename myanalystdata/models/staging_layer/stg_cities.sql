with source as (
    select * from {{ source('Rider_Project', 'cities_raw') }}
),

deduplicated as (
    select *,
        row_number() over (partition by city_id order by launch_date desc) as row_num
    from source
    where city_id is not null
),

cleaned_cities as (
    select
        cast(city_id as int64) as city_id,
        cast(country as string) as country,
        cast(city_name as string) as city_name,
        cast(launch_date as date) as launch_date
    from deduplicated
    where row_num = 1
)

select * from cleaned_cities

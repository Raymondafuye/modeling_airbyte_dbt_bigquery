{{
    config(
        materialized='table',
        tags=['operations'],
        meta={'owner': 'data_engineering_team'}
    )
}}

select
    city_id,
    city_name,
    country,
    launch_date
from {{ ref('stg_cities') }}

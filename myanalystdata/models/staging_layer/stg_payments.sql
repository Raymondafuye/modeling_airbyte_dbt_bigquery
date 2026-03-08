with source as (

    select * from {{ source('Rider_Project', 'payments_raw') }}

),

deduplicated as (

    select *,
        row_number() over (
            partition by payment_id
            order by created_at desc
        ) as row_num

    from source
    where payment_id is not null

),

cleaned_payments as (

    select
        cast(payment_id as int64)                   as payment_id,
        cast(trip_id as int64)                      as trip_id,
        cast(payment_status as string)              as payment_status,
        cast(payment_provider as string)            as payment_provider,
        cast(currency as string)                    as currency,
        cast(amount as numeric)                     as amount,
        cast(fee as numeric)                        as fee,
        cast(created_at as timestamp)               as created_at

    from deduplicated
    where row_num = 1

)

select * from cleaned_payments
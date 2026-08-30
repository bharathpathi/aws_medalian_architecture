
delete from opt_transaction_t.e_b_payments;

insert into opt_transaction_t.e_b_payments
(
payment_id
,claim_id
,payment_date
,amount_paid
,payment_method
,payment_status
,adjustments
,source_file_dttm
,load_dttm
,error_msg
)


select payment_id
,claim_id
,payment_date
,amount_paid
,payment_method
,payment_status
,adjustments
,CAST(date_parse(regexp_extract("$path", '[0-9]{8}(?=\.json)', 0), '%Y%m%d') AS timestamp(6)) AS source_file_dttm
,CAST(current_timestamp AS timestamp(6)) AS load_dttm
,'Invalid data in payment_id column or claim_id column or payment_date column or amount_paid column' as error_msg
from landing.payments
where (payment_id is  null)
  or (claim_id is  null)
  or (not regexp_like(payment_date, '[0-9]{4}-[0-9]{2}-[0-9]{2}'))
;




SELECT CASE 
    WHEN COUNT(*) > 0 
    THEN fail('VALIDATION FAILED: ' || CAST(COUNT(*) AS VARCHAR) || ' rows in error table')
END
FROM opt_transaction_t.e_b_payments;






insert into opt_transaction_t.b_payments
(
payment_id
,claim_id
,payment_date
,amount_paid
,payment_method
,payment_status
,adjustments
,source_file_dttm
,load_dttm
)

select payment_id
,claim_id
,payment_date
,amount_paid
,payment_method
,payment_status
,adjustments
,CAST(date_parse(regexp_extract("$path", '[0-9]{8}(?=\.json)', 0), '%Y%m%d') AS timestamp(6)) AS source_file_dttm,
    CAST(current_timestamp AS timestamp(6)) AS load_dttm
from landing.payments
where (payment_id is not null)
  and (claim_id is not null)
  and (regexp_like(payment_date, '[0-9]{4}-[0-9]{2}-[0-9]{2}'))
;
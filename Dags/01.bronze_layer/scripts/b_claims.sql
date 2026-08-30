
delete from opt_transaction_t.e_b_claims ;

insert into opt_transaction_t.e_b_claims (
claim_id
,member_id
,provider_id
,service_date
,claim_status
,total_billed_amount
,total_paid_amount
,line_items
,diagnosis_codes
,source_file_dttm
,load_dttm
,error_msg
)
select claim_id
,member_id
,provider_id
,service_date
,claim_status
,total_billed_amount
,total_paid_amount
,line_items
,diagnosis_codes
,CAST(date_parse(regexp_extract("$path", '[0-9]{8}(?=\.json)', 0), '%Y%m%d') AS timestamp(6)) AS source_file_dttm
,CAST(current_timestamp AS timestamp(6)) AS load_dttm 
,'Invalid data in claim_id column or service_date column or total_billed_amount/total_paid_amount column' as error_msg
from landing.claims
where (claim_id is  null)
  and (not regexp_like(service_date, '[0-9]{4}-[0-9]{2}-[0-9]{2}'))
;




SELECT CASE 
    WHEN COUNT(*) > 0 
    THEN fail('VALIDATION FAILED: ' || CAST(COUNT(*) AS VARCHAR) || ' rows in error table')
END
FROM opt_transaction_t.e_b_claims;


insert into opt_transaction_t.b_claims (
claim_id
,member_id
,provider_id
,service_date
,claim_status
,total_billed_amount
,total_paid_amount
,line_items
,diagnosis_codes
,source_file_dttm
,load_dttm
)
select claim_id
,member_id
,provider_id
,service_date
,claim_status
,total_billed_amount
,total_paid_amount
,line_items
,diagnosis_codes
,CAST(date_parse(regexp_extract("$path", '[0-9]{8}(?=\.json)', 0), '%Y%m%d') AS timestamp(6)) AS source_file_dttm
,CAST(current_timestamp AS timestamp(6)) AS load_dttm from landing.claims
where (claim_id is not null)
  and (regexp_like(service_date, '[0-9]{4}-[0-9]{2}-[0-9]{2}'))
;

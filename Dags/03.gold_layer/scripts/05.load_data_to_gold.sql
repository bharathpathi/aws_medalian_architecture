
Truncate table cdw_opt_gold.opt_gold_t.gold_claims_summary;

insert into cdw_opt_gold.opt_gold_t.gold_claims_summary(
claim_id
,member_id
,member_name
,plan_id
,plan_name
,provider_id
,provider_name
,provider_type
,service_date
,claim_status
,total_billed_amount
,total_paid_amount
,procedure_code_1st_procedure
,procedure_code_2nd_procedure
,diagnosis_code_1st
,diagnosis_code_2nd
,payment_id
,payment_status
,amount_paid
,adjustment_code
,adjustment_reason
,adjustment_amount
,load_dttm
)
SELECT
    c.claim_id,
    m.member_id,
    m.first_name || ' ' || m.last_name AS member_name,
    m.plan_id,
    m.plan_name,
    p.provider_id,
    p.provider_name,
    p.provider_type,
    c.service_date,
    c.claim_status,
    c.total_billed_amount,
    c.total_paid_amount,
    c.procedure_code_1st_procedure,
    c.procedure_code_2nd_procedure,
    c.diagnosis_code_1st,
    c.diagnosis_code_2nd,
    pay.payment_id,
    pay.payment_status,
    pay.amount_paid,
    pay.adjustment_code,
    pay.adjustment_reason,
    pay.adjustment_amount,
    current_timestamp AS load_dttm
FROM cdw_opt_silver.opt_silver_t.s_claims c
JOIN cdw_opt_silver.opt_silver_t.S_MEMBERS m
    ON c.member_id = m.member_id AND m.is_current = 'Y'
JOIN cdw_opt_silver.opt_silver_t.s_providers p
    ON c.provider_id = p.provider_id AND p.is_current = 'Y'
LEFT JOIN cdw_opt_silver.opt_silver_t.s_payments pay
    ON c.claim_id = pay.claim_id;
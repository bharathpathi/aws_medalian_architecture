CREATE TEMP TABLE tmp_s_claims_delta AS
SELECT s.*
FROM cdw_opt_silver.opt_silver_t.I_s_claims s
LEFT JOIN cdw_opt_silver.opt_silver_t.s_claims t
  ON t.claim_id = s.claim_id
WHERE t.claim_id IS NULL
   OR COALESCE(t.claim_status, 'abcdef') <> COALESCE(s.claim_status, 'abcdef');

-- Step 2: merge from the temp table (no target reference inside USING now)
MERGE INTO cdw_opt_silver.opt_silver_t.s_claims
USING tmp_s_claims_delta AS s
ON s_claims.claim_id = s.claim_id
WHEN MATCHED THEN
  UPDATE SET
    claim_status = s.claim_status,
    total_billed_amount = s.total_billed_amount,
    total_paid_amount = s.total_paid_amount,
    billed_amount_1st_procedure = s.billed_amount_1st_procedure,
    line_item_id_1st_procedure = s.line_item_id_1st_procedure,
    paid_amount_1st_procedure = s.paid_amount_1st_procedure,
    procedure_code_1st_procedure = s.procedure_code_1st_procedure,
    billed_amount_2nd_procedure = s.billed_amount_2nd_procedure,
    line_item_id_2nd_procedure = s.line_item_id_2nd_procedure,
    paid_amount_2nd_procedure = s.paid_amount_2nd_procedure,
    procedure_code_2nd_procedure = s.procedure_code_2nd_procedure,
    diagnosis_code_1st = s.diagnosis_code_1st,
    diagnosis_description_1st = s.diagnosis_description_1st,
    is_primary_1st = s.is_primary_1st,
    diagnosis_code_2nd = s.diagnosis_code_2nd,
    diagnosis_description_2nd = s.diagnosis_description_2nd,
    is_primary_2nd = s.is_primary_2nd,
    update_dttm = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN
  INSERT (
    claim_id, member_id, provider_id, service_date, claim_status,
    total_billed_amount, total_paid_amount,
    billed_amount_1st_procedure, line_item_id_1st_procedure,
    paid_amount_1st_procedure, procedure_code_1st_procedure,
    billed_amount_2nd_procedure, line_item_id_2nd_procedure,
    paid_amount_2nd_procedure, procedure_code_2nd_procedure,
    diagnosis_code_1st, diagnosis_description_1st, is_primary_1st,
    diagnosis_code_2nd, diagnosis_description_2nd, is_primary_2nd,
    load_dttm, update_dttm
  )
  VALUES (
    s.claim_id, s.member_id, s.provider_id, s.service_date, s.claim_status,
    s.total_billed_amount, s.total_paid_amount,
    s.billed_amount_1st_procedure, s.line_item_id_1st_procedure,
    s.paid_amount_1st_procedure, s.procedure_code_1st_procedure,
    s.billed_amount_2nd_procedure, s.line_item_id_2nd_procedure,
    s.paid_amount_2nd_procedure, s.procedure_code_2nd_procedure,
    s.diagnosis_code_1st, s.diagnosis_description_1st, s.is_primary_1st,
    s.diagnosis_code_2nd, s.diagnosis_description_2nd, s.is_primary_2nd,
    CURRENT_TIMESTAMP, s.update_dttm
  );

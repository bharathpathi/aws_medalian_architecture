
DROP TABLE IF EXISTS tmp_s_payments_delta;

CREATE TEMP TABLE tmp_s_payments_delta AS
SELECT s.*
FROM cdw_opt_silver.opt_silver_t.I_s_payments s
LEFT JOIN cdw_opt_silver.opt_silver_t.s_payments t
  ON t.payment_id = s.payment_id
WHERE t.payment_id IS NULL
   OR COALESCE(t.payment_status, '') <> COALESCE(s.payment_status, '');

-- Step 2: merge from the temp table
MERGE INTO cdw_opt_silver.opt_silver_t.s_payments
USING tmp_s_payments_delta AS s
ON s_payments.payment_id = s.payment_id
WHEN MATCHED THEN
  UPDATE SET
    payment_status = s.payment_status,
    claim_id = s.claim_id,
    payment_date = s.payment_date,
    amount_paid = s.amount_paid,
    payment_method = s.payment_method,
    adjustment_amount = s.adjustment_amount,
    adjustment_code = s.adjustment_code,
    adjustment_id = s.adjustment_id,
    adjustment_reason = s.adjustment_reason,
    update_dttm = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN
  INSERT (
    payment_id, claim_id, payment_date, amount_paid, payment_method, payment_status,
    adjustment_amount, adjustment_code, adjustment_id, adjustment_reason,
    load_dttm, update_dttm
  )
  VALUES (
    s.payment_id, s.claim_id, s.payment_date, s.amount_paid, s.payment_method, s.payment_status,
    s.adjustment_amount, s.adjustment_code, s.adjustment_id, s.adjustment_reason,
    CURRENT_TIMESTAMP, s.update_dttm
  );


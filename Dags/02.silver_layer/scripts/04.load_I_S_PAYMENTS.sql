-- Step 1: Capture the watermark as a literal, outside the Spectrum scan
DROP TABLE IF EXISTS tmp_payments_watermark;

CREATE TEMP TABLE tmp_payments_watermark AS
SELECT
    COALESCE(
        MAX(LAST_BATCH_SOURCE_FILE_DTTM),
        '1900-01-01'::TIMESTAMP
    ) AS wm_dttm
FROM
    cdw_opt_silver.opt_audit_t.silver_tables_processed
WHERE
    UPPER(TABLE_NAME) = 'CDW_OPT_SILVER.OPT_SILVER_T.S_PAYMENTS';


-- Step 2: Capture the incremental payment records

DROP TABLE IF EXISTS tmp_b_payments;

CREATE TEMP TABLE tmp_b_payments AS
SELECT
    p.*
FROM
    stg_opt_bronze.opt_transaction_t.b_payments p
    CROSS JOIN tmp_payments_watermark w
WHERE
    p.source_file_dttm > w.wm_dttm;


-- Step 3: Truncate and reload the image table

TRUNCATE TABLE cdw_opt_silver.opt_silver_t.I_s_payments;

INSERT INTO cdw_opt_silver.opt_silver_t.I_s_payments (
    payment_id,
    claim_id,
    payment_date,
    amount_paid,
    payment_method,
    payment_status,
    adjustment_amount,
    adjustment_code,
    adjustment_id,
    adjustment_reason,
    source_file_dttm,
    load_dttm,
    update_dttm
)
SELECT
    payment_id,
    claim_id,
    cast(payment_date as date),
    amount_paid,
    payment_method,
    payment_status,
    adjustments[0].adjustment_amount::DECIMAL(12,2)   AS adjustment_amount,
    adjustments[0].adjustment_code::VARCHAR(50)       AS adjustment_code,
    adjustments[0].adjustment_id::VARCHAR(50)         AS adjustment_id,
    adjustments[0].adjustment_reason::VARCHAR(255)    AS adjustment_reason,
    source_file_dttm,
    load_dttm,
    NULL AS update_dttm
FROM
    tmp_b_payments p;


-- Step 4: Update the watermark based on what was actually just loaded

UPDATE cdw_opt_silver.opt_audit_t.silver_tables_processed
SET LAST_BATCH_SOURCE_FILE_DTTM = (SELECT MAX(source_file_dttm) FROM stg_opt_bronze.opt_transaction_t.b_payments)
WHERE UPPER(TABLE_NAME) = 'CDW_OPT_SILVER.OPT_SILVER_T.S_PAYMENTS';



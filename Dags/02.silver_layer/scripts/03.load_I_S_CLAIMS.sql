-- Step 1: Capture the watermark as a literal, outside the Spectrum scan
DROP TABLE IF EXISTS tmp_claims_watermark;

CREATE TEMP TABLE tmp_claims_watermark AS
SELECT
    COALESCE(
        MAX(LAST_BATCH_SOURCE_FILE_DTTM),
        '1900-01-01'::TIMESTAMP
    ) AS wm_dttm
FROM
    cdw_opt_silver.opt_audit_t.silver_tables_processed
WHERE
    UPPER(TABLE_NAME) = 'CDW_OPT_SILVER.OPT_SILVER_T.S_CLAIMS';


-- Step 2: Capture the incremental claim records

DROP TABLE IF EXISTS tmp_b_claims;

CREATE TEMP TABLE tmp_b_claims AS
SELECT
    c.*
FROM
    stg_opt_bronze.opt_transaction_t.b_claims c
    CROSS JOIN tmp_claims_watermark w
WHERE
    c.source_file_dttm > w.wm_dttm;


-- Step 3: Truncate and reload the image table

TRUNCATE TABLE cdw_opt_silver.opt_silver_t.I_s_claims;

INSERT INTO cdw_opt_silver.opt_silver_t.I_s_claims (
    claim_id,
    member_id,
    provider_id,
    service_date,
    claim_status,
    total_billed_amount,
    total_paid_amount,
    billed_amount_1st_procedure,
    line_item_id_1st_procedure,
    paid_amount_1st_procedure,
    procedure_code_1st_procedure,
    billed_amount_2nd_procedure,
    line_item_id_2nd_procedure,
    paid_amount_2nd_procedure,
    procedure_code_2nd_procedure,
    diagnosis_code_1st,
    diagnosis_description_1st,
    is_primary_1st,
    diagnosis_code_2nd,
    diagnosis_description_2nd,
    is_primary_2nd,
    load_dttm,
    update_dttm
)
SELECT
    claim_id,
    member_id,
    provider_id,
    cast(service_date as date),
    claim_status,
    total_billed_amount,
    total_paid_amount,
    line_items[0].billed_amount::DECIMAL(12,2)      AS billed_amount_1st_procedure,
    line_items[0].line_item_id::VARCHAR(50)         AS line_item_id_1st_procedure,
    line_items[0].paid_amount::DECIMAL(12,2)        AS paid_amount_1st_procedure,
    line_items[0].procedure_code::INT               AS procedure_code_1st_procedure,
    line_items[1].billed_amount::DECIMAL(12,2)      AS billed_amount_2nd_procedure,
    line_items[1].line_item_id::VARCHAR(50)         AS line_item_id_2nd_procedure,
    line_items[1].paid_amount::DECIMAL(12,2)        AS paid_amount_2nd_procedure,
    line_items[1].procedure_code::INT               AS procedure_code_2nd_procedure,
    diagnosis_codes[0].diagnosis_code::VARCHAR(20)          AS diagnosis_code_1st,
    diagnosis_codes[0].diagnosis_description::VARCHAR(255)  AS diagnosis_description_1st,
    diagnosis_codes[0].is_primary::BOOLEAN                  AS is_primary_1st,
    diagnosis_codes[1].diagnosis_code::VARCHAR(20)          AS diagnosis_code_2nd,
    diagnosis_codes[1].diagnosis_description::VARCHAR(255)  AS diagnosis_description_2nd,
    diagnosis_codes[1].is_primary::BOOLEAN                  AS is_primary_2nd,
    CURRENT_TIMESTAMP AS load_dttm,
    NULL AS update_dttm
FROM
    tmp_b_claims p;


-- Step 4: Update the watermark based on what was actually just loaded

UPDATE cdw_opt_silver.opt_audit_t.silver_tables_processed
SET LAST_BATCH_SOURCE_FILE_DTTM = (SELECT MAX(source_file_dttm) FROM stg_opt_bronze.opt_transaction_t.b_claims)
WHERE UPPER(TABLE_NAME) = 'CDW_OPT_SILVER.OPT_SILVER_T.S_CLAIMS';


-- Step 1: capture the watermark as a literal, outside the Spectrum scan

CREATE  TEMP TABLE tmp_watermark
 AS
SELECT
    COALESCE(
        MAX(LAST_BATCH_SOURCE_FILE_DTTM),
        '1900-01-01':: TIMESTAMP
    ) AS wm_dttm
FROM
    cdw_opt_silver.opt_audit_t.silver_tables_processed
WHERE
    TABLE_NAME = 'cdw_opt_silver.opt_silver_t.S_MEMBERS';




CREATE TEMP TABLE tmp_b_members AS
SELECT
    *
FROM
    stg_opt_bronze.opt_enrollment_t.b_members b
    CROSS JOIN tmp_watermark w
WHERE
    b.source_file_dttm > w.wm_dttm;
-- Step 2: truncate and reload the image table
TRUNCATE TABLE cdw_opt_silver.opt_silver_t.I_S_MEMBERS;

INSERT INTO
    cdw_opt_silver.opt_silver_t.I_S_MEMBERS (
        member_id,
        first_name,
        last_name,
        date_of_birth,
        gender,
        plan_id,
        plan_name,
        enrollment_effective_date,
        home_street,
        home_city,
        home_state,
        home_zip,
        mail_street,
        mail_city,
        mail_state,
        mail_zip,
        eff_start_dttm,
        eff_end_dttm,
        is_current,
        load_dttm
    )
SELECT
    b.member_id,
    b.first_name,
    b.last_name,
    CAST(b.date_of_birth AS DATE),
    b.gender,
    b.plan_id,
    b.plan_name,
    CAST(b.enrollment_effective_date AS DATE),
    b.addresses [ 0 ].street:: VARCHAR(50),
    b.addresses [ 0 ].city:: VARCHAR(50),
    b.addresses [ 0 ].state:: VARCHAR(50),
    b.addresses [ 0 ].zip_code:: VARCHAR(50),
    b.addresses [ 1 ].street:: VARCHAR(50),
    -- confirm this should be addresses[1] for mail
    b.addresses [ 1 ].city:: VARCHAR(50),
    b.addresses [ 1 ].state:: VARCHAR(50),
    b.addresses [ 1 ].zip_code:: VARCHAR(50),
    b.source_file_dttm,
    NULL,
    'Y',
    CURRENT_TIMESTAMP
FROM
    tmp_b_members b;
-- Step 3: update the watermark based on what was actually just loaded
UPDATE
    cdw_opt_silver.opt_audit_t.silver_tables_processed
SET
    LAST_BATCH_SOURCE_FILE_DTTM = (SELECT MAX(source_file_dttm) FROM stg_opt_bronze.opt_enrollment_t.b_members)
WHERE
    TABLE_NAME = 'cdw_opt_silver.opt_silver_t.S_MEMBERS';
    

-- Step 1: Capture the watermark as a literal, outside the Spectrum scan
DROP TABLE IF EXISTS tmp_provider_watermark;

CREATE  TEMP TABLE tmp_provider_watermark
AS
SELECT
    COALESCE(
        MAX(LAST_BATCH_SOURCE_FILE_DTTM),
        '1900-01-01'::TIMESTAMP
    ) AS wm_dttm
FROM
    cdw_opt_silver.opt_audit_t.silver_tables_processed
WHERE
   upper(TABLE_NAME) = 'CDW_OPT_SILVER.OPT_SILVER_T.S_PROVIDERS';


-- Step 2: Capture the incremental provider records

CREATE TEMP TABLE tmp_b_providers AS
SELECT
    *
FROM
    stg_opt_bronze.opt_enrollment_t.b_providers p
    CROSS JOIN tmp_provider_watermark w
WHERE
    p.source_file_dttm > w.wm_dttm;


-- Step 3: Truncate and reload the image table


TRUNCATE TABLE cdw_opt_silver.opt_silver_t.I_S_PROVIDERS;

INSERT INTO
    cdw_opt_silver.opt_silver_t.I_S_PROVIDERS (
        provider_id,
        provider_name,
        npi,
        provider_type,
        specialty_code,
        specialty_name,
        affiliation_start_date,
        network_id,
        network_name,
        eff_start_dttm,
        eff_end_dttm,
        is_current,
        load_dttm
    )
SELECT
provider_id
,provider_name
,npi
,provider_type
,cast(specialties[0].specialty_code as VARCHAR(50))  AS specialty_code 
,cast(specialties[0].specialty_name as VARCHAR(50))  AS specialty_name
,network_affiliations[0].affiliation_start_date::DATE AS affiliation_start_date
,network_affiliations[0].network_id::VARCHAR(50) AS network_id
,network_affiliations[0].network_name::VARCHAR(50) AS network_name
,SOURCE_FILE_DTTM AS EFF_START_DTTM
,null as eff_end_dttm
,'Y' as is_current
,current_timestamp as load_dttm
FROM
    tmp_b_providers p;



-- Step 4: Update the watermark based on what was actually just loaded

UPDATE cdw_opt_silver.opt_audit_t.silver_tables_processed
SET LAST_BATCH_SOURCE_FILE_DTTM = ( SELECT MAX(source_file_dttm) FROM stg_opt_bronze.opt_enrollment_t.b_providers  )
WHERE upper(TABLE_NAME) = 'CDW_OPT_SILVER.OPT_SILVER_T.S_PROVIDERS';






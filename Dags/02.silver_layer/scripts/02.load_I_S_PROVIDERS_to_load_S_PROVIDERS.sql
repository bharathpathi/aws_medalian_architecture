
DROP TABLE IF EXISTS v_i_s_providers;

CREATE TEMP TABLE v_i_s_providers AS
SELECT
    s.*,
    LEAD(s.eff_start_dttm) OVER (PARTITION BY s.provider_id ORDER BY s.eff_start_dttm) AS next_eff_start_dttm,
    ROW_NUMBER()      OVER (PARTITION BY s.provider_id ORDER BY s.eff_start_dttm DESC) AS rn_desc
FROM cdw_opt_silver.opt_silver_t.i_s_providers s
LEFT JOIN (
    SELECT *
    FROM cdw_opt_silver.opt_silver_t.s_providers
    WHERE is_current = 'Y'
) t
  ON s.provider_id = t.provider_id
WHERE t.provider_id IS NULL
   OR (
        s.eff_start_dttm > t.eff_start_dttm
        AND (s.provider_name <> t.provider_name OR s.provider_type <> t.provider_type)
      );

-- Step 2: close target's current row — using earliest new change
UPDATE cdw_opt_silver.opt_silver_t.s_providers t
SET is_current   = 'N',
    eff_end_dttm = DATEADD(day, -1, s.first_change_dttm)
FROM (
    SELECT provider_id, MIN(eff_start_dttm) AS first_change_dttm
    FROM v_i_s_providers
    GROUP BY provider_id
) s
WHERE t.provider_id = s.provider_id
  AND t.is_current = 'Y';

-- Step 3: insert the new/history rows
INSERT INTO cdw_opt_silver.opt_silver_t.s_providers (
    provider_id, provider_name, npi, provider_type,
    specialty_code, specialty_name,
    affiliation_start_date, network_id, network_name,
    eff_start_dttm, eff_end_dttm, is_current, load_dttm
)
SELECT
    provider_id, provider_name, npi, provider_type,
    specialty_code, specialty_name,
    affiliation_start_date, network_id, network_name,
    eff_start_dttm,
    CASE
        WHEN next_eff_start_dttm IS NULL THEN TIMESTAMP '9999-12-31 00:00:00'
        ELSE DATEADD(day, -1, next_eff_start_dttm)
    END AS eff_end_dttm,
    CASE WHEN rn_desc = 1 THEN true ELSE false END AS is_current,
    GETDATE() AS load_dttm
FROM v_i_s_providers;

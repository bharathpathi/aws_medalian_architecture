DROP TABLE IF EXISTS v_i_s_members;



CREATE TEMP TABLE v_i_s_members AS
SELECT
    s.*,
    LEAD(s.eff_start_dttm) OVER (PARTITION BY s.member_id ORDER BY s.eff_start_dttm) AS next_eff_start_dttm,
    ROW_NUMBER()      OVER (PARTITION BY s.member_id ORDER BY s.eff_start_dttm DESC) AS rn_desc
FROM cdw_opt_silver.opt_silver_t.i_s_members s
LEFT JOIN (
    SELECT *
    FROM cdw_opt_silver.opt_silver_t.s_members
    WHERE is_current = 'Y'
) t
  ON s.member_id = t.member_id
WHERE t.member_id IS NULL
   OR (
        s.eff_start_dttm > t.eff_start_dttm
        AND (s.plan_id <> t.plan_id OR s.plan_name <> t.plan_name)
      );

-- Step 2: expire current rows that have an incoming change
UPDATE cdw_opt_silver.opt_silver_t.s_members t
SET is_current   = 'N',
    eff_end_dttm = DATEADD(day, -1, s.first_change_dttm)
FROM (
    SELECT member_id, MIN(eff_start_dttm) AS first_change_dttm
    FROM v_i_s_members
    GROUP BY member_id
) s
WHERE t.member_id = s.member_id
  AND t.is_current = 'Y';

-- Step 3: insert the new/history rows
INSERT INTO cdw_opt_silver.opt_silver_t.s_members (
    member_id, first_name, last_name, date_of_birth, gender,
    plan_id, plan_name, enrollment_effective_date,
    home_street, home_city, home_state, home_zip,
    mail_street, mail_city, mail_state, mail_zip,
    eff_start_dttm, eff_end_dttm, is_current, load_dttm
)
SELECT
    member_id, first_name, last_name, date_of_birth, gender,
    plan_id, plan_name, enrollment_effective_date,
    home_street, home_city, home_state, home_zip,
    mail_street, mail_city, mail_state, mail_zip,
    eff_start_dttm,
    CASE
        WHEN next_eff_start_dttm IS NULL THEN TIMESTAMP '9999-12-31 00:00:00'
        ELSE DATEADD(day, -1, next_eff_start_dttm)
    END AS eff_end_dttm,
    CASE WHEN rn_desc = 1 THEN true ELSE false END AS is_current,
    GETDATE() AS load_dttm
FROM v_i_s_members;


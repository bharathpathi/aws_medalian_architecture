
DELETE FROM opt_enrollment_t.E_B_providers;

insert into opt_enrollment_t.E_B_providers(
   provider_id    ,
  provider_name    ,
  npi    ,
  provider_type    ,
  specialties   ,
  network_affiliations   ,
  source_file_dttm    ,
  load_dttm  
)
select     provider_id    ,
  provider_name    ,
  npi    ,
  provider_type    ,
  specialties   ,
  network_affiliations   ,
CAST(date_parse(regexp_extract("$path", '[0-9]{8}(?=\.json)', 0), '%Y%m%d') AS timestamp(6)) AS source_file_dttm,
    CAST(current_timestamp AS timestamp(6)) AS load_dttm
  from landing.providers
  where (provider_id is  null)
  OR (NOT regexp_like(npi, '^[0-9]{10}$'))
  ;
  

SELECT CASE 
    WHEN COUNT(*) > 0 
    THEN fail('VALIDATION FAILED: ' || CAST(COUNT(*) AS VARCHAR) || ' rows in error table')
END
FROM opt_enrollment_t.E_B_providers;

insert into opt_enrollment_t.B_providers(
   provider_id    ,
  provider_name    ,
  npi    ,
  provider_type    ,
  specialties   ,
  network_affiliations   ,
  source_file_dttm    ,
  load_dttm  
)
select     provider_id    ,
  provider_name    ,
  npi    ,
  provider_type    ,
  specialties   ,
  network_affiliations   ,
CAST(date_parse(regexp_extract("$path", '[0-9]{8}(?=\.json)', 0), '%Y%m%d') AS timestamp(6)) AS source_file_dttm,
    CAST(current_timestamp AS timestamp(6)) AS load_dttm
  from landing.providers
  where (provider_id is not null)
  and (regexp_like(npi, '^[0-9]{10}$'))
  ;
  
  
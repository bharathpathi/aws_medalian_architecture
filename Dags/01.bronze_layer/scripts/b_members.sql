
delete from opt_enrollment_t.e_b_members;


insert into  opt_enrollment_t.e_b_members(member_id
,first_name
,last_name
,date_of_birth
,gender
,plan_id
,plan_name
,enrollment_effective_date
,addresses
,source_file_dttm
,load_dttm
, error_msg      )


select  member_id
,first_name
,last_name
,date_of_birth
,gender
,plan_id
,plan_name
,enrollment_effective_date
,addresses
,CAST(date_parse(regexp_extract("$path", '[0-9]{8}(?=\.json)', 0), '%Y%m%d') AS timestamp(6)) AS source_file_dttm,
CAST(current_timestamp AS timestamp(6)) AS load_dttm
,'Invalid data in member_id column or date_of_birth column or enrollment_effective_date column'  as error_msg
from landing.members
where (member_id is  null) or ( not regexp_like(date_of_birth,'[0-9]{4}-[0-9]{2}-[0-9]{2}')
or not regexp_like(enrollment_effective_date ,'[0-9]{4}-[0-9]{2}-[0-9]{2}')
);



SELECT CASE 
    WHEN COUNT(*) > 0 
    THEN fail('VALIDATION FAILED: ' || CAST(COUNT(*) AS VARCHAR) || ' rows in error table')
END
FROM opt_enrollment_t.e_b_members;


insert into  opt_enrollment_t.b_members
select  member_id
,first_name
,last_name
,date_of_birth
,gender
,plan_id
,plan_name
,enrollment_effective_date
,addresses
,CAST(date_parse(regexp_extract("$path", '[0-9]{8}(?=\.json)', 0), '%Y%m%d') AS timestamp(6)) AS source_file_dttm,
CAST(current_timestamp AS timestamp(6)) AS load_dttm
from landing.members
where (member_id is not null) and (  regexp_like(date_of_birth,'[0-9]{4}-[0-9]{2}-[0-9]{2}')
and  regexp_like(enrollment_effective_date ,'[0-9]{4}-[0-9]{2}-[0-9]{2}')
);
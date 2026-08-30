CREATE SCHEMA IF NOT EXISTS opt_enrollment_t
LOCATION 's3://aws-medalion-project/bronze/enrollment_opt/'
;

CREATE SCHEMA IF NOT EXISTS opt_transaction_t
LOCATION 's3://aws-medalion-project/bronze/transaction_opt/'
;

CREATE TABLE opt_enrollment_t.B_providers (
   provider_id  STRING,
  provider_name  STRING,
  npi  STRING,
  provider_type  STRING,
  specialties ARRAY< STRUCT<specialty_code: STRING, specialty_name: STRING>>,
  network_affiliations ARRAY<STRUCT<network_id: STRING, network_name: STRING, affiliation_start_date: STRING>>,
  source_file_dttm  timestamp,
  load_dttm  TIMESTAMP
)
LOCATION 's3://aws-medalion-project/bronze/enrollment_opt/providers'
TBLPROPERTIES (
    'table_type' = 'ICEBERG',
    'format' = 'parquet'
);

  CREATE TABLE opt_enrollment_t.e_B_providers (
   provider_id  STRING,
  provider_name  STRING,
  npi  STRING,
  provider_type  STRING,
  specialties ARRAY< STRUCT<specialty_code: STRING, specialty_name: STRING>>,
  network_affiliations ARRAY<STRUCT<network_id: STRING, network_name: STRING, affiliation_start_date: STRING>>,
  source_file_dttm  timestamp,
  load_dttm  TIMESTAMP,
 error_msg string
)
LOCATION 's3://aws-medalion-project/bronze/enrollment_opt/e_b_providers'
TBLPROPERTIES (
    'table_type' = 'ICEBERG',
    'format' = 'parquet'
);


 CREATE TABLE opt_enrollment_t.b_members (
  member_id string,
  first_name string,
  last_name string,
  date_of_birth string,
  gender  STRING,
  plan_id  STRING,
  plan_name  STRING,
  enrollment_effective_date  STRING,
  addresses ARRAY< STRUCT<address_type: STRING, street: STRING, city: STRING, state: STRING,zip_code: STRING>>,
  source_file_dttm  timestamp,
  load_dttm  timestamp
)
LOCATION 's3://aws-medalion-project/bronze/enrollment_opt/b_members'
TBLPROPERTIES (
    'table_type' = 'ICEBERG',
    'format' = 'parquet'
);

CREATE TABLE IF NOT EXISTS opt_enrollment_t.e_b_members (
member_id string,
  first_name string,
  last_name string,
  date_of_birth string,
  gender  STRING,
  plan_id  STRING,
  plan_name  STRING,
  enrollment_effective_date  STRING,
  addresses ARRAY< STRUCT<address_type: STRING, street: STRING, city: STRING, state: STRING,zip_code: STRING>>,
  source_file_dttm  timestamp,
  load_dttm  timestamp,
  error_msg string
)
LOCATION 's3://aws-medalion-project/bronze/enrollment_opt/e_b_members'
TBLPROPERTIES (
    'table_type' = 'ICEBERG',
    'format' = 'parquet'
);


CREATE TABLE IF NOT EXISTS opt_transaction_t.b_claims (
  claim_id  STRING,
  member_id  STRING,
  provider_id  STRING,
  service_date  STRING,
  claim_status  STRING,
  total_billed_amount  STRING,
  total_paid_amount  STRING,
  line_items array<struct<line_item_id:string,procedure_code:string,billed_amount:string,paid_amount:string ,quantity:string>>,
  diagnosis_codes array<struct<diagnosis_code:string,diagnosis_description:string,is_primary:string >>,
  source_file_dttm  timestamp,
   load_dttm  timestamp
)
location 's3://aws-medalion-project/bronze/transaction_opt/b_claims'
tblproperties(
'table_type'='ICEBERG',
'FORMAT'='parquet'
);



CREATE TABLE IF NOT EXISTS opt_transaction_t.e_b_claims (
  claim_id  STRING,
  member_id  STRING,
  provider_id  STRING,
  service_date  STRING,
  claim_status  STRING,
  total_billed_amount  STRING,
  total_paid_amount  STRING,
  line_items array<struct<line_item_id:string,procedure_code:string,billed_amount:string,paid_amount:string ,quantity:string>>,
  diagnosis_codes array<struct<diagnosis_code:string,diagnosis_description:string,is_primary:string >>,
  source_file_dttm  timestamp,
   load_dttm  timestamp,
    error_msg string
)
location 's3://aws-medalion-project/bronze/transaction_opt/e_b_claims'
tblproperties(
'table_type'='ICEBERG',
'FORMAT'='parquet'
);



CREATE TABLE IF NOT EXISTS opt_transaction_t.b_payments (
  payment_id  STRING,
  claim_id  STRING,
  payment_date  STRING,
  amount_paid  STRING,
  payment_method  STRING,
  payment_status  STRING,
  adjustments array<struct<adjustment_id:string,adjustment_code:string,adjustment_reason:string,adjustment_amount:string>>,
  source_file_dttm  timestamp,
   load_dttm  timestamp
)
location "s3://aws-medalion-project/bronze/transaction_opt/b_payments"
tblproperties(
'table_type'='ICEBERG',
'FORMAT'='parquet'
)
;

CREATE TABLE IF NOT EXISTS opt_transaction_t.e_b_payments (
  payment_id  STRING,
  claim_id  STRING,
  payment_date  STRING,
  amount_paid  STRING,
  payment_method  STRING,
  payment_status  STRING,
  adjustments array<struct<adjustment_id:string,adjustment_code:string,adjustment_reason:string,adjustment_amount:string>>,
  source_file_dttm  timestamp,
   load_dttm  timestamp,
   error_msg string
)
location "s3://aws-medalion-project/bronze/transaction_opt/e_b_payments"
tblproperties(
'table_type'='ICEBERG',
'FORMAT'='parquet'
);


create database cdw_opt_silver;
create schema cdw_opt_silver.opt_audit_t;
create schema cdw_opt_silver.opt_silver_t;

CREATE TABLE  cdw_opt_silver.opt_audit_t.Silver_tables_processed (
serial_no int,    
TABLE_NAME varchar(50),
LAST_BATCH_SOURCE_FILE_DTTM TIMESTAMP
);



CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.I_S_MEMBERS (
  member_id  VARCHAR(50),
  first_name VARCHAR(50),
  last_name  VARCHAR(50),
  date_of_birth DATE,
  gender     VARCHAR(5),
  plan_id    VARCHAR(50),
  plan_name  VARCHAR(50),
  enrollment_effective_date DATE,
  home_street  VARCHAR(50),
  home_city    VARCHAR(50),
  home_state   VARCHAR(50),
  home_zip     VARCHAR(50),
  mail_street  VARCHAR(50),
  mail_city    VARCHAR(50),
  mail_state   VARCHAR(50),
  mail_zip     VARCHAR(50),
  eff_start_dttm TIMESTAMP,
  eff_end_dttm TIMESTAMP,
  is_current BOOLEAN,
  load_dttm TIMESTAMP
);


CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.I_s_providers (
  provider_id VARCHAR(50),
  provider_name VARCHAR(50),
  npi VARCHAR(50),
  provider_type VARCHAR(50),
  specialty_code VARCHAR(50),
  specialty_name VARCHAR(50),
  affiliation_start_date DATE,
  network_id VARCHAR(50),
  network_name VARCHAR(50),
  eff_start_dttm TIMESTAMP,
  eff_end_dttm TIMESTAMP,
  is_current BOOLEAN,
  load_dttm TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.I_s_claims (
  claim_id VARCHAR(50),
  member_id VARCHAR(50),
  provider_id VARCHAR(50),
  service_date DATE,
  claim_status VARCHAR(50),
  total_billed_amount DECIMAL(12,2),
  total_paid_amount DECIMAL(12,2),
  billed_amount_1st_procedure DECIMAL(12,2),
  line_item_id_1st_procedure VARCHAR(50),
  paid_amount_1st_procedure DECIMAL(12,2),
  procedure_code_1st_procedure INT,
  billed_amount_2nd_procedure DECIMAL(12,2),
  line_item_id_2nd_procedure VARCHAR(50),
  paid_amount_2nd_procedure DECIMAL(12,2),
  procedure_code_2nd_procedure INT,
  diagnosis_code_1st VARCHAR(50),
  diagnosis_description_1st VARCHAR(50),
  is_primary_1st BOOLEAN,
  diagnosis_code_2nd VARCHAR(50),
  diagnosis_description_2nd VARCHAR(50),
  is_primary_2nd BOOLEAN,
  load_dttm TIMESTAMP,
  update_dttm TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.I_s_payments (
  payment_id VARCHAR(50),
  claim_id VARCHAR(50),
  payment_date DATE,
  amount_paid DECIMAL(12,2),
  payment_method VARCHAR(50),
  payment_status VARCHAR(50),
  adjustment_amount DECIMAL(12,2),
  adjustment_code VARCHAR(50),
  adjustment_id VARCHAR(50),
  adjustment_reason VARCHAR(50),
  source_file_dttm TIMESTAMP,
  load_dttm TIMESTAMP,
  update_dttm TIMESTAMP
);


insert into cdw_opt_silver.opt_audit_t.Silver_tables_processed(serial_no,TABLE_NAME,LAST_BATCH_SOURCE_FILE_DTTM)
values (1,'cdw_opt_silver.opt_silver_t.s_payments','2024-08-02T21:29:12.952+00:00' ),
 (2,'cdw_opt_silver.opt_silver_t.s_claims','2024-08-02T21:29:12.952+00:00' ),
  (3,'cdw_opt_silver.opt_silver_t.S_MEMBERS','2024-08-02T21:29:12.952+00:00' ),
  (4,'cdw_opt_silver.opt_silver_t.s_providers','2024-08-02T21:29:12.952+00:00' );
  
  CREATE TABLE  cdw_opt_silver.opt_audit_t.Silver_tables_processed (
serial_no int,    
TABLE_NAME varchar(50),
LAST_BATCH_SOURCE_FILE_DTTM TIMESTAMP
);


insert into cdw_opt_silver.opt_audit_t.Silver_tables_processed(serial_no,TABLE_NAME,LAST_BATCH_SOURCE_FILE_DTTM)
values (1,'cdw_opt_silver.opt_silver_t.s_payments','2024-08-02T21:29:12.952+00:00' ),
 (2,'cdw_opt_silver.opt_silver_t.s_claims','2024-08-02T21:29:12.952+00:00' ),
  (3,'cdw_opt_silver.opt_silver_t.S_MEMBERS','2024-08-02T21:29:12.952+00:00' ),
  (4,'cdw_opt_silver.opt_silver_t.s_providers','2024-08-02T21:29:12.952+00:00' );
  
  
 create database stg_opt_bronze;



create external schema opt_enrollment_t
from data catalog
database 'opt_enrollment_t'
iam_role 'arn:aws:iam::421856466943:role/AWSGlueServiceRole-';


create external schema opt_transaction_t
from data catalog
database 'opt_transaction_t'
iam_role 'arn:aws:iam::421856466943:role/AWSGlueServiceRole-';



CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.I_S_MEMBERS (
  member_id  VARCHAR(50),
  first_name VARCHAR(50),
  last_name  VARCHAR(50),
  date_of_birth DATE,
  gender     VARCHAR(5),
  plan_id    VARCHAR(50),
  plan_name  VARCHAR(50),
  enrollment_effective_date DATE,
  home_street  VARCHAR(50),
  home_city    VARCHAR(50),
  home_state   VARCHAR(50),
  home_zip     VARCHAR(50),
  mail_street  VARCHAR(50),
  mail_city    VARCHAR(50),
  mail_state   VARCHAR(50),
  mail_zip     VARCHAR(50),
  eff_start_dttm TIMESTAMP,
  eff_end_dttm TIMESTAMP,
  is_current BOOLEAN,
  load_dttm TIMESTAMP
);


CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.I_s_providers (
  provider_id VARCHAR(50),
  provider_name VARCHAR(50),
  npi VARCHAR(50),
  provider_type VARCHAR(50),
  specialty_code VARCHAR(50),
  specialty_name VARCHAR(50),
  affiliation_start_date DATE,
  network_id VARCHAR(50),
  network_name VARCHAR(50),
  eff_start_dttm TIMESTAMP,
  eff_end_dttm TIMESTAMP,
  is_current BOOLEAN,
  load_dttm TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.I_s_claims (
  claim_id VARCHAR(50),
  member_id VARCHAR(50),
  provider_id VARCHAR(50),
  service_date DATE,
  claim_status VARCHAR(50),
  total_billed_amount DECIMAL(12,2),
  total_paid_amount DECIMAL(12,2),
  billed_amount_1st_procedure DECIMAL(12,2),
  line_item_id_1st_procedure VARCHAR(50),
  paid_amount_1st_procedure DECIMAL(12,2),
  procedure_code_1st_procedure INT,
  billed_amount_2nd_procedure DECIMAL(12,2),
  line_item_id_2nd_procedure VARCHAR(50),
  paid_amount_2nd_procedure DECIMAL(12,2),
  procedure_code_2nd_procedure INT,
  diagnosis_code_1st VARCHAR(50),
  diagnosis_description_1st VARCHAR(50),
  is_primary_1st BOOLEAN,
  diagnosis_code_2nd VARCHAR(50),
  diagnosis_description_2nd VARCHAR(50),
  is_primary_2nd BOOLEAN,
  load_dttm TIMESTAMP,
  update_dttm TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.I_s_payments (
  payment_id VARCHAR(50),
  claim_id VARCHAR(50),
  payment_date DATE,
  amount_paid DECIMAL(12,2),
  payment_method VARCHAR(50),
  payment_status VARCHAR(50),
  adjustment_amount DECIMAL(12,2),
  adjustment_code VARCHAR(50),
  adjustment_id VARCHAR(50),
  adjustment_reason VARCHAR(50),
  source_file_dttm TIMESTAMP,
  load_dttm TIMESTAMP,
  update_dttm TIMESTAMP
);


CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.S_MEMBERS (
  member_id  VARCHAR(50),
  first_name VARCHAR(50),
  last_name  VARCHAR(50),
  date_of_birth DATE,
  gender     VARCHAR(5),
  plan_id    VARCHAR(50),
  plan_name  VARCHAR(50),
  enrollment_effective_date DATE,
  home_street  VARCHAR(50),
  home_city    VARCHAR(50),
  home_state   VARCHAR(50),
  home_zip     VARCHAR(50),
  mail_street  VARCHAR(50),
  mail_city    VARCHAR(50),
  mail_state   VARCHAR(50),
  mail_zip     VARCHAR(50),
  eff_start_dttm TIMESTAMP,
  eff_end_dttm TIMESTAMP,
  is_current BOOLEAN,
  load_dttm TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.s_providers (
  provider_id VARCHAR(50),
  provider_name VARCHAR(50),
  npi VARCHAR(50),
  provider_type VARCHAR(50),
  specialty_code VARCHAR(50),
  specialty_name VARCHAR(50),
  affiliation_start_date DATE,
  network_id VARCHAR(50),
  network_name VARCHAR(50),
  eff_start_dttm TIMESTAMP,
  eff_end_dttm TIMESTAMP,
  is_current BOOLEAN,
  load_dttm TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.s_claims (
  claim_id VARCHAR(50),
  member_id VARCHAR(50),
  provider_id VARCHAR(50),
  service_date DATE,
  claim_status VARCHAR(50),
  total_billed_amount DECIMAL(12,2),
  total_paid_amount DECIMAL(12,2),
  billed_amount_1st_procedure DECIMAL(12,2),
  line_item_id_1st_procedure VARCHAR(50),
  paid_amount_1st_procedure DECIMAL(12,2),
  procedure_code_1st_procedure INT,
  billed_amount_2nd_procedure DECIMAL(12,2),
  line_item_id_2nd_procedure VARCHAR(50),
  paid_amount_2nd_procedure DECIMAL(12,2),
  procedure_code_2nd_procedure INT,
  diagnosis_code_1st VARCHAR(50),
  diagnosis_description_1st VARCHAR(50),
  is_primary_1st BOOLEAN,
  diagnosis_code_2nd VARCHAR(50),
  diagnosis_description_2nd VARCHAR(50),
  is_primary_2nd BOOLEAN,
  load_dttm TIMESTAMP,
  update_dttm TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.s_payments (
  payment_id VARCHAR(50),
  claim_id VARCHAR(50),
  payment_date DATE,
  amount_paid DECIMAL(12,2),
  payment_method VARCHAR(50),
  payment_status VARCHAR(50),
  adjustment_amount DECIMAL(12,2),
  adjustment_code VARCHAR(50),
  adjustment_id VARCHAR(50),
  adjustment_reason VARCHAR(50),
  source_file_dttm TIMESTAMP,
  load_dttm TIMESTAMP,
  update_dttm TIMESTAMP
);
     

CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.S_MEMBERS (
  member_id  VARCHAR(50),
  first_name VARCHAR(50),
  last_name  VARCHAR(50),
  date_of_birth DATE,
  gender     VARCHAR(5),
  plan_id    VARCHAR(50),
  plan_name  VARCHAR(50),
  enrollment_effective_date DATE,
  home_street  VARCHAR(50),
  home_city    VARCHAR(50),
  home_state   VARCHAR(50),
  home_zip     VARCHAR(50),
  mail_street  VARCHAR(50),
  mail_city    VARCHAR(50),
  mail_state   VARCHAR(50),
  mail_zip     VARCHAR(50),
  eff_start_dttm TIMESTAMP,
  eff_end_dttm TIMESTAMP,
  is_current BOOLEAN,
  load_dttm TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.s_providers (
  provider_id VARCHAR(50),
  provider_name VARCHAR(50),
  npi VARCHAR(50),
  provider_type VARCHAR(50),
  specialty_code VARCHAR(50),
  specialty_name VARCHAR(50),
  affiliation_start_date DATE,
  network_id VARCHAR(50),
  network_name VARCHAR(50),
  eff_start_dttm TIMESTAMP,
  eff_end_dttm TIMESTAMP,
  is_current BOOLEAN,
  load_dttm TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.s_claims (
  claim_id VARCHAR(50),
  member_id VARCHAR(50),
  provider_id VARCHAR(50),
  service_date DATE,
  claim_status VARCHAR(50),
  total_billed_amount DECIMAL(12,2),
  total_paid_amount DECIMAL(12,2),
  billed_amount_1st_procedure DECIMAL(12,2),
  line_item_id_1st_procedure VARCHAR(50),
  paid_amount_1st_procedure DECIMAL(12,2),
  procedure_code_1st_procedure INT,
  billed_amount_2nd_procedure DECIMAL(12,2),
  line_item_id_2nd_procedure VARCHAR(50),
  paid_amount_2nd_procedure DECIMAL(12,2),
  procedure_code_2nd_procedure INT,
  diagnosis_code_1st VARCHAR(50),
  diagnosis_description_1st VARCHAR(50),
  is_primary_1st BOOLEAN,
  diagnosis_code_2nd VARCHAR(50),
  diagnosis_description_2nd VARCHAR(50),
  is_primary_2nd BOOLEAN,
  load_dttm TIMESTAMP,
  update_dttm TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cdw_opt_silver.opt_silver_t.s_payments (
  payment_id VARCHAR(50),
  claim_id VARCHAR(50),
  payment_date DATE,
  amount_paid DECIMAL(12,2),
  payment_method VARCHAR(50),
  payment_status VARCHAR(50),
  adjustment_amount DECIMAL(12,2),
  adjustment_code VARCHAR(50),
  adjustment_id VARCHAR(50),
  adjustment_reason VARCHAR(50),
  source_file_dttm TIMESTAMP,
  load_dttm TIMESTAMP,
  update_dttm TIMESTAMP
);



CREATE DATABASE cdw_opt_gold;
create schema cdw_opt_gold.opt_gold_t;

CREATE TABLE IF NOT EXISTS cdw_opt_gold.opt_gold_t.gold_claims_summary (
  claim_id VARCHAR(50),
  member_id VARCHAR(50),
  member_name VARCHAR(100),
  plan_id VARCHAR(50),
  plan_name VARCHAR(50),
  provider_id VARCHAR(50),
  provider_name VARCHAR(50),
  provider_type VARCHAR(50),
  service_date DATE,
  claim_status VARCHAR(50),
  total_billed_amount DECIMAL(12,2),
  total_paid_amount DECIMAL(12,2),
  procedure_code_1st_procedure INT,
  procedure_code_2nd_procedure INT,
  diagnosis_code_1st VARCHAR(50),
  diagnosis_code_2nd VARCHAR(50),
  payment_id VARCHAR(50),
  payment_status VARCHAR(50),
  amount_paid DECIMAL(12,2),
  adjustment_code VARCHAR(50),
  adjustment_reason VARCHAR(50),
  adjustment_amount DECIMAL(12,2),
  load_dttm TIMESTAMP
);


##################

GRANT USAGE ON SCHEMA opt_audit_t TO "IAMR:AWSGlueServiceRole-";
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA opt_audit_t TO "IAMR:AWSGlueServiceRole-";
GRANT USAGE ON SCHEMA stg_opt_bronze.opt_enrollment_t TO "IAMR:AWSGlueServiceRole-";
GRANT USAGE ON SCHEMA opt_silver_t TO "IAMR:AWSGlueServiceRole-";
GRANT USAGE ON SCHEMA opt_transaction_t TO "IAMR:AWSGlueServiceRole-";
GRANT SELECT, INSERT, UPDATE, TRUNCATE ON ALL TABLES IN SCHEMA opt_silver_t TO "IAMR:AWSGlueServiceRole-";
GRANT USAGE ON SCHEMA opt_gold_t TO "IAMR:AWSGlueServiceRole-";
GRANT SELECT, INSERT, UPDATE, TRUNCATE ON ALL TABLES IN SCHEMA opt_gold_t TO "IAMR:AWSGlueServiceRole-";
use role sysadmin;
use warehouse compute_wh;

create database if not exists cricket;
create or replace schema cricket.land;
create or replace schema cricket.raw;
create or replace schema cricket.clean;
create or replace schema cricket.consumption;

use schema cricket.land;


-- json file format
create or replace file format cricket.my_json_format
	type = json
	null_if = ('\\n', 'null', '')
	strip_outer_array = true
	comment = 'Json File Format with outer strip array flag true'
	
-- Creating an Internal Storage
create or replace stage cricket.land.my_stg;

list @cricket.land.my_stg;


list @my_stg/cricket/land;

select 
	t.$1:meta::variant as meta,
	t.$1:info::variant as info,
	t.$1:innings::array as innings,
	metadata$filename as file_name,
	metadata$file_row_number int,
	metadata$file_content_key text,
	metadata$file_last_modified stg_modified_ts
from @my_stg/cricket/json/66358.json (file_format => 'my_json_format') t;


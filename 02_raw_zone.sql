use role sysadmin;		
use warehouse compute_wh; 
use schema cricket.raw;	

	
-- lets create a table inside the raw layer		
create or replace transient table cricket.raw.match_raw_tbl(
	meta object not null,
	info variant not null, 
	innings ARRAY not null, 
	stg_fite_name text not null,
	stg_fite_row_number int not null, 
	stg_fite_hashkey text not null, 
	stg_modified_ts timestamp not null
)

comment = 'This is raw table to store all the json data file with root elements extracted'	


copy into cricket.raw.match_raw_tbl from		
	(
		select	
			t.$1:meta::object as meta, 
			t.$1:info::variant as info,		
			t.$1:info::variant as info,		
			metadata$filename,
			metadata$file_row_number,
			metadata$file_content_key,
			metadata$file_last_modified
		from @cricket.land.my_stg/cricket/json (file_format => 'cricket.land.my_json_format') t
	)
	on_error = continue;

select count(*) from cricket.raw.match;

	
select * from cricket.raw.match limit 10;


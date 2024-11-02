use role sysadmin;
use warehouse compute_wh;
use schema cricket.clean;

-- extract players
-- version 1
select 
    raw.info:match_type_number::int as match_type_number,
    raw.info:players,
    raw.info:teams from cricket.raw.match_raw_tbl raw;

-- version 2
select 
    raw.info:match_type_number::int as match_type_number,
    raw.info:players,
    raw.info:teams 
from cricket.raw.match_raw_tbl raw
where match_type_number = 2319;

-- version 3
select 
    raw.info:match_type_number::int as match_type_number,
    p.*
from cricket.raw.match_raw_tbl raw,
lateral flatten (input => raw.info:players) p
where match_type_number = 2319;


-- version 4
select 
    raw.info:match_type_number::int as match_type_number,
    p.key::text as country,
    team.*
from cricket.raw.match_raw_tbl raw,
lateral flatten (input => raw.info:players) p,
lateral flatten (input => p.value) team
where match_type_number = 2319;

-- version 4
select 
    raw.info:match_type_number::int as match_type_number,
    p.key::text as country,
    team.*
from cricket.raw.match_raw_tbl raw,
lateral flatten (input => raw.info:players) p,
lateral flatten (input => p.value) team
where match_type_number = 2319;

-- version 5
create or replace table cricket.clean.player_clean_tbl as
select 
    raw.info:match_type_number::int as match_type_number,
    p.key::text as country,
    stg_file_name,
    stg_file_row_number,
    stg_file_hashkey,
    stg_modified_ts
from cricket.raw.match_raw_tbl raw,
lateral flatten (input => raw.info:players) p,
lateral flatten (input => p.value) team;

-- let's desc table
desc table cricket.clean.player_clean_tbl;

-- add not null and fk relationships
alter table cricket.clean.player_clean_tbl
modify column match_type_number set not null;

alter table cricket.clean.player_clean_tbl
modify column country set not null;

alter table cricket.clean.player_clean_tbl
modify column player_name set not null;

alter table cricket.clean.match_detail_clean
add constraint pk_match_type_number primary key (match_type_number);

alter table cricket.clean.player_clean_tbl
add constraint fk_match_id
foreign key (match_type_number)
references cricket.clean.match_detail_clean (match_type_number);


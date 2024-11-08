use role sysadmin;
use warehouse compute_wh;
use schema cricket.consumption;


select * from cricket.clean.delivery_clean_tbl 
where match_type_number = 4686;

-- v1 with team
select
	d.match_type_number as match_id,
	td.team_id, td.team_name
from cricket.clean.delivery_clean_tbl d
join team_dim td on d.team_name = td.team_name
where d.match_type_number = 4686;


-- v2 get the player id
select
	d.match_type_number as match_id,
	td.team_id, td.team_name,
	bpd.player_id as bowler_id, bpd.player_name,
	spd.player_id as batter_id, spd.player_name,
	nspd.player_id as non_stricker_id, nspd.player_name,
from cricket.clean.delivery_clean_tbl d
	join team_dim td on d.team_name = td.team_name
	join player_dim bpd on d.bowler = bpd.player_name
	join player_dim spd on d.batter = spd.player_name
	join player_dim npsd on d.non_stricker = nspd.player_name
where d.match_type_number = 4686;


-- v3 add measurements
select
	d.match_type_number as match_id,
	td.team_id, 
	bpd.player_id as bowler_id, bpd.player_name,
	spd.player_id as batter_id, spd.player_name,
	nspd.player_id as non_stricker_id, nspd.player_name,
	d.over, d.runs, d.extra_runs, d.extra_type
from cricket.clean.delivery_clean_tbl d
	join team_dim td on d.team_name = td.team_name
	join player_dim bpd on d.bowler = bpd.player_name
	join player_dim spd on d.batter = spd.player_name
	join player_dim npsd on d.non_stricker = nspd.player_name
where d.match_type_number = 4686;
	
	
-- v4 remove unwanted columns
select
	d.match_type_number as match_id,
	td.team_id, 
	bpd.player_id as bowler_id, bpd.player_name,
	spd.player_id as batter_id, spd.player_name,
	nspd.player_id as non_stricker_id, nspd.player_name,
	d.over, d.runs,
	case when d.extra_runs is null then 0 else d.extra_runs end as extra_runs,
	case when d.extra_type is null then 0 else d.extra_type end as extra_type,
	case when d.player_out is null then 0 else d.player_out end as player_out,
	case when d.player_out_kind is null then 0 else d.player_out_kind end as player_out_kind,
from cricket.clean.delivery_clean_tbl d
	join team_dim td on d.team_name = td.team_name
	join player_dim bpd on d.bowler = bpd.player_name
	join player_dim spd on d.batter = spd.player_name
	join player_dim npsd on d.non_stricker = nspd.player_name
where d.match_type_number = 4686;


CREATE or replace TABLE delivery_fact (
    match_id INT ,
    team_id INT,
    bowler_id INT,
    batter_id INT,
    non_striker_id INT,
    over INT,
    runs INT,
    extra_runs INT,
    extra_type VARCHAR(255),
    player_out VARCHAR(255),
    player_out_kind VARCHAR(255),

    CONSTRAINT fk_del_match_id FOREIGN KEY (match_id) REFERENCES match_fact (match_id),
    CONSTRAINT fk_del_team FOREIGN KEY (team_id) REFERENCES team_dim (team_id),
    CONSTRAINT fk_bowler FOREIGN KEY (bowler_id) REFERENCES player_dim (player_id),
    CONSTRAINT fk_batter FOREIGN KEY (batter_id) REFERENCES player_dim (player_id),
    CONSTRAINT fk_stricker FOREIGN KEY (non_striker_id) REFERENCES player_dim (player_id)
);

-- insert record
insert into delivery_fact
select 
    d.match_type_number as match_id,
    td.team_id,
    bpd.player_id as bower_id, 
    spd.player_id batter_id, 
    nspd.player_id as non_stricker_id,
    d.over,
    d.runs,
    case when d.extra_runs is null then 0 else d.extra_runs end as extra_runs,
    case when d.extra_type is null then 'None' else d.extra_type end as extra_type,
    case when d.player_out is null then 'None' else d.player_out end as player_out,
    case when d.player_out_kind is null then 'None' else d.player_out_kind end as player_out_kind
from 
    cricket.clean.delivery_clean_tbl d
    join team_dim td on d.team_name = td.team_name
    join player_dim bpd on d.bowler = bpd.player_name
    join player_dim spd on d.batter = spd.player_name
    join player_dim nspd on d.non_striker = nspd.player_name;

-- 2000 matches * 600 balls per match = 1,200,000
use role sysadmin;
use warehouse compute_wh;
use schema cricket.consumption;

create or replace table date_dim (
    date_id int primary key autoincrement,
    full_dt date,
    day int,
    month int,
    year int,
    quarter int,
    dayofweek int,
    dayofmonth int,
    dayofyear int,
    dayofweekname varchar(3), -- to store day names (e.g., "Mon")
    isweekend boolean -- to indicate if it's a weekend (True/False Sat/Sun both falls under weekend)
);


create or replace table referee_dim (
    referee_id int primary key autoincrement,
    referee_name text not null,
    referee_type text not null
);


create or replace table team_dim (
    team_id int primary key autoincrement,
    team_name text not null
);

-- player..
create or replace table player_dim (
    player_id int primary key autoincrement,
    team_id int not null,
    player_name text not null
);

alter table cricket.consumption.player_dim
add constraint fk_team_player_id
foreign key (team_id)
references cricket.consumption.team_dim (team_id);


create or replace table venue_dim (
    venue_id int primary key autoincrement,
    venue_name text not null,
    city text not null,
    state text,
    country text,
    continent text,
    end_Names text,
    capacity number,
    pitch text,
    flood_light boolean,
    established_dt date,
    playing_area text,
    other_sports text,
    curator text,
    lattitude number(10,6),
    longitude number(10,6)
);

create or replace table match_type_dim (
    match_type_id int primary key autoincrement,
    match_type text not null
);


CREATE or replace TABLE match_fact (
    match_id INT PRIMARY KEY,
    date_id INT NOT NULL,
    referee_id INT NOT NULL,
    team_a_id INT NOT NULL,
    team_b_id INT NOT NULL,
    match_type_id INT NOT NULL,
    venue_id INT NOT NULL,
    total_overs number(3),
    balls_per_over number(1),

    overs_played_by_team_a number(2),
    bowls_played_by_team_a number(3),
    extra_bowls_played_by_team_a number(3),
    extra_runs_scored_by_team_a number(3),
    fours_by_team_a number(3),
    sixes_by_team_a number(3),
    total_score_by_team_a number(3),
    wicket_lost_by_team_a number(2),

    overs_played_by_team_b number(2),
    bowls_played_by_team_b number(3),
    extra_bowls_played_by_team_b number(3),
    extra_runs_scored_by_team_b number(3),
    fours_by_team_b number(3),
    sixes_by_team_b number(3),
    total_score_by_team_b number(3),
    wicket_lost_by_team_b number(2),

    toss_winner_team_id int not null, 
    toss_decision text not null, 
    match_result text not null, 
    winner_team_id int not null,

    CONSTRAINT fk_date FOREIGN KEY (date_id) REFERENCES date_dim (date_id),
    CONSTRAINT fk_referee FOREIGN KEY (referee_id) REFERENCES referee_dim (referee_id),
    CONSTRAINT fk_team1 FOREIGN KEY (team_a_id) REFERENCES team_dim (team_id),
    CONSTRAINT fk_team2 FOREIGN KEY (team_b_id) REFERENCES team_dim (team_id),
    CONSTRAINT fk_match_type FOREIGN KEY (match_type_id) REFERENCES match_type_dim (match_type_id),
    CONSTRAINT fk_venue FOREIGN KEY (venue_id) REFERENCES venue_dim (venue_id),

    CONSTRAINT fk_toss_winner_team FOREIGN KEY (toss_winner_team_id) REFERENCES team_dim (team_id),
    CONSTRAINT fk_winner_team FOREIGN KEY (winner_team_id) REFERENCES team_dim (team_id)
);

-- lets populate data
-- we will extract the dimension table data using our detail table from clean layer
-- and it will be based on description field as we don't have any master data set
-- in real world, you may also get master data set as separate entities.

-- lets start with team dim, and for simplicity, it is just team name

select distinct team_name from (
select first_team as team_name from cricket.clean.match_detail_clean
union all
select second_team as team_name from cricket.clean.match_detail_clean
);

-- v2
insert into cricket.consumption.team_dim (team_name)
select distinct team_name from (
select first_team as team_name from cricket.clean.match_detail_clean
union all
select second_team as team_name from cricket.clean.match_detail_clean
) order by team_name;


-- v3
select * from cricket.consumption.team_dim order by team_name;

-- ***************
-- team player
    -- v1
    select * from cricket.clean.player_clean_tbl limit 10;

    -- v2   
    select country, player_name from cricket.clean.player_clean_tbl group by country, player_name;

    -- v3
    select a.country, b.team_id, a.player_name from 
    cricket.clean.player_clean_tbl a join cricket.consumption.team_dim b
    on a.country = b.team_name
    group by a.country, b.team_id, a.player_name;

    -- v4
    insert into cricket.consumption.player_dim (team_id, player_name)
    select b.team_id, a.player_name from cricket.clean.player_clean_tbl a
    join cricket.consumption.team_dim b
    on a.country = b.team_name
    group by b.team_id, a.player_name;

    -- v5 Check the data
    select * from cricket.consumption.player_dim;


-- ******************************************************
--  Referee Dimension

-- since we have not populated the referee detail in previous layer
-- we will skip it for now. we need to understand 
-- before we can design the referee

    -- v1
    select * from cricket.clean.match_detail_clean limit 10;

    -- v2
    select info from cricket.raw.match_raw_tbl limit 10;

    -- v3
    select
        info:officials.match_referees[0]:: text as match_referee,
        info:officials.reserve_umpires[0]:: text as reserve_umpire,
        info:officials.tv_umpires[0]:: text as tv_umpire,
        info:officials.umpires[0]:: text as first_umpire,
        info:officials.umpires[1]:: text as second_umpire
    from 
        cricket.raw.match_raw_tbl limit 1;

    
-- *************************************************
-- Venue Dimension

    -- v1
    select * from cricket.clean.match_detail_clean limit 10;

    -- v2
    select venue, city from cricket.clean.match_detail_clean limit 10;
    

    -- v3
    select venue, city from cricket.clean.match_detail_clean group by venue, city;

    -- v4
    insert into cricket.consumption.venue_dim (venue_name,city)
    select venue, city from (
    select venue,
        case when city is null then 'NA'
        else city
        end as city
    from cricket.clean.match_detail_clean
    )
    group by venue, city;

    -- v6
    select * from cricket.consumption.venue_dim where city='Bengaluru';

    select city from cricket.consumption.venue_dim group by city having count(1) > 1;
        

-- ******************************************
-- Match Type Dimension
    -- v1
    select * from cricket.clean.match_detail_clean limit 10;

    -- v2
    select match_type from cricket.clean.match_detail_clean group by match_type;

    -- v3
    insert into cricket.consumption.match_type_dim (match_type)
    select match_type from cricket.clean.match_detail_clean group by match_type;


--***************************************************


    
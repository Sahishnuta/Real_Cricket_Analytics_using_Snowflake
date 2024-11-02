-- lets quickly validate the dataset

select * from cricket.clean.match_detail_clean
where match_type_number = 2319;

-- by batsman
select team_name, batter, sum(runs) from delivery_clean_tbl
where match_type_number = 2319
group by team_name, batter
order by 1,2,3 desc;

-- by team
select team_name, sum(runs) + sum(extra_runs) from delivery_clean_tbl
where match_type_number = 2319
group by team_name
order by 1,2,3 desc;

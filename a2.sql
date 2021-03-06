SET search_path TO A2;
-- Add below your SQL statements.
-- For each of the queries below, your final statement should populate the respective answer table (queryX) with the correct tuples. It should look something like:
-- INSERT INTO queryX (SELECT … <complete your SQL query here> …)
-- where X is the correct index [1, …,10].
-- You can create intermediate views (as needed). Remember to drop these views after you have populated the result tables query1, query2, ...
-- You can use the "\i a2.sql" command in psql to execute the SQL commands in this file.
-- Good Luck!


delete from query2;
delete from query4;
delete from query6;
delete from query10;

--Query 1 statements
INSERT INTO query1 (
    select player.pname, country.cname, tournament.tname
    from a2.player, a2.country, a2.tournament, a2.champion
    where champion.pid = player.pid and champion.tid = tournament.tid AND
    tournament.cid = player.cid and player.cid = country.cid
    order by player.pname asc
);

--Query 2 statements
INSERT INTO query2 (
    select tournament.tname,sum(court.capacity) as totalCapacity
    from a2.tournament, a2.court
    where tournament.tid = court.tid
    group by tournament.tid
    order by sum(court.capacity) desc
    LIMIT 1
);

--Query 3 statements
CREATE VIEW minGlobalRank AS ( --to find the highest ranked player each player has faced
  select p1.pid, p1.pname, MIN(p2.globalrank) minRank
  from A2.player p1, A2.event, A2.player p2
  where (p1.pid = event.winid and event.lossid = p2.pid) or (event.winid = p2.pid and event.lossid = p1.pid)
  group by p1.pid
);
INSERT INTO query3 (
  select p1.pid p1id, p1.pname p1name, p2.pid p2id, p2.pname p2name
  from A2.player p1, minGlobalRank min, A2.player p2
  where p1.pid = min.pid and p2.globalrank = min.minRank
  order by p1.pname asc
);
DROP VIEW minGlobalRank;

--Query 4 statements
-- temp view that contains all the champions
create or replace view allChamps as
select player.pid, player.pname, champion.tid
from player, champion
where (champion.pid = player.pid);

--count the number of all tournaments and number of all tournaments champs have won and see which ones have the same number
insert into query4 (
select pid , pname
from allChamps
where allChamps.tid in (select tournament.tid from tournament)
group by allChamps.pid, allChamps.pname
having count(distinct tid) = (select count(*) from tournament)
order by allChamps.pname
);
drop view allChamps;

--Query 5 statements
INSERT INTO query5 (
  select p1.pid, p1.pname, AVG(wins) avgwins
  from a2.player p1,a2.record r
  where r.year >= 2011 and r.year <= 2014 and r.pid = p1.pid
  group by p1.pid
  order by avgwins desc
  LIMIT 10
);

--Query 6 statements
--Any play that as a record from 2011 and 2014
create or replace view rangeOfYears as
select p.pid, r.year, r.wins
from player p, record r
where (p.pid = r.pid) and (year between 2011 and 2014);
--All the players with only the 4 consecuituve years
create or replace view between11and14 as
select *
from rangeOfYears
where pid in (
    select pid
    from rangeOfYears
    group by pid
    having count(pid) > 3
)
group by pid,year, wins;

create or replace view y2011 as ( select * from between11and14 where between11and14.year = 2011);
create or replace view y2012 as ( select * from between11and14 where between11and14.year = 2012);
create or replace view y2013 as ( select * from between11and14 where between11and14.year = 2013);
create or replace view y2014 as ( select * from between11and14 where between11and14.year = 2014);


create or replace view playsandyearwins as (
select p.pname, b.pid, max(y2011.wins) w2011, max(y2012.wins) w2012, max(y2013.wins) w2013, max(y2014.wins) w2014
from between11and14 b
left join player p on p.pid = b.pid
left join y2011 on y2011.pid=b.pid and y2011.year=b.year
left join y2012 on y2012.pid=b.pid and y2012.year=b.year
left join y2013 on y2013.pid=b.pid and y2013.year=b.year
left join y2014 on y2014.pid=b.pid and y2014.year=b.year
group by b.pid, p.pname );

insert into query6(
select pay.pid, pay.pname
from playsandyearwins pay
where (w2011 < w2012) and (w2012 < w2013) and (w2013 < w2014)
order by pay.pname asc);
--drop views for q6
drop view playsandyearwins, y2014, y2013, y2012, y2011, between11and14,rangeOfYears;

--Query 7 statements
INSERT INTO query7 (
  select p1.pname, c.year
  from a2.player p1, a2.champion c
  where p1.pid = c.pid
  group by p1.pid, c.year
  having COUNT(c.pid) >= 2
  order by p1.pname, c.year DESC
);

--Query 8 statements
INSERT INTO query8(
select distinct p1.pname p1name,p2.pname p2name,c.cname cname from event e
left join player p1 on e.winid=p1.pid
left join player p2 on e.lossid=p2.pid
left join country c on c.cid = p1.cid and c.cid = p2.cid
where p1.cid=p2.cid
order by c.cname asc, p1.pname desc
);

--Query 9 statements
CREATE VIEW maxChampionships AS (
  select max(sub.cnt)
  from (select count(p.pid) as cnt from a2.country ctry, a2.champion ch, a2.player p
  where p.pid = ch.pid and p.cid = ctry.cid
  group by ctry.cname) AS sub
);
INSERT INTO query9 (
  select ctry.cname, COUNT(p.pid) champions
  from a2.country ctry, a2.champion ch, a2.player p
  where p.pid = ch.pid and p.cid = ctry.cid
  group by ctry.cname
  HAVING COUNT(p.pid) = (select * from maxChampionships)
  order by ctry.cname desc
);
DROP VIEW maxChampionships;

--Query 10 statements
--view of all players and their time played
create or replace view timeplayed as (
select lossid, duration from event
union all
select winid, duration from eventP
group by lossid, winid, duration

);

--sum of duration of each player avg over 200 
create or replace view sumTime as (
    select tp.lossid, avg(tp.duration)
    from timeplayed tp
    group by tp.lossid
    having avg(tp.duration) > 200

);

Insert into query10 (
    select pn.pname
    from player pn
    left join sumTime st on pn.pid = st.lossid
    left join record r on st.lossid = r.pid
    where r.wins > r.losses
    group by pn.pname
    order by pn.pname desc
);

drop view sumTime, timeplayed;
    

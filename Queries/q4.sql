-- Do drivers improve?

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q4 cascade;

create table q4(
	type VARCHAR(9),
	number INTEGER,
	early FLOAT,
	late FLOAT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
-- needs to be fixed shtill
-- use dropoff instead of request table in from join
DROP VIEW IF EXISTS all_rides CASCADE;
DROP VIEW IF EXISTS atleastten CASCADE;
DROP VIEW IF EXISTS atleasttenAndDate CASCADE;
DROP VIEW IF EXISTS driverstartdate CASCADE;
DROP VIEW IF EXISTS earlyfive CASCADE;
DROP VIEW IF EXISTS laterrides CASCADE;
DROP VIEW IF EXISTS earlyfiveratings CASCADE;
DROP VIEW IF EXISTS laterridesratings CASCADE;
DROP VIEW IF EXISTS earlytotalaverages CASCADE;
DROP VIEW IF EXISTS laterridestotalaverages CASCADE;
DROP VIEW IF EXISTS ANS CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW all_rides as 
select dispatch.driver_id as driver_id, request.datetime as startdate, dropoff.datetime as enddate, dropoff.request_id as request_id
from driver join dispatch on driver.driver_id = dispatch.driver_id join dropoff on dispatch.request_id = dropoff.request_id join request on dropoff.request_id = request.request_id
order by dispatch.driver_id;


CREATE VIEW atleastten AS
select driver_id, request_id
from all_rides where driver_id in 
	(select driver_id
	from all_rides 
	Group by driver_id having count(DISTINCT CONCAT (date_part('year', all_rides.startdate), '-', date_part('month', all_rides.startdate), '-', date_part('day', all_rides.startdate))) >= 10); 


CREATE VIEW atleasttenAndDate AS
SELECT atleastten.driver_id as driver_id, all_rides.startdate as startdate, all_rides.enddate as enddate, all_rides.request_id as request_id
FROM atleastten join all_rides on atleastten.driver_id = all_rides.driver_id AND
atleastten.request_id = all_rides.request_id;


CREATE VIEW driverstartdate AS
SELECT driver_id, min(startdate) as mini
FROM (SELECT atleastten.driver_id, all_rides.startdate
FROM atleastten join all_rides on atleastten.driver_id = all_rides.driver_id) as theMin
GROUP by driver_id;


CREATE VIEW earlyfive AS
SELECT distinct atleasttenAndDate.driver_id as driver_id, request_id
FROM atleasttenAndDate, driverstartdate
WHERE atleasttenAndDate.driver_id = driverstartdate.driver_id
AND mini::date + Integer '5' - enddate::date >= Integer '0';

--have to now get the ones not in earlyfive


CREATE VIEW laterrides AS
SELECT driver_id, request_id
FROM ((SELECT driver_id, request_id FROM atleasttenAndDate) EXCEPT (SELECT driver_id, request_id from earlyfive)) as foo;

--we got all the earlies and lates
--need to computer the average rating for earlies and lates while grouping by each driver first

CREATE VIEW earlyfiveratings as 
SELECT earlyfive.driver_id, avg(rating) as driver_avg_rating
FROM earlyfive join driverrating on earlyfive.request_id = driverrating.request_id
GROUP by earlyfive.driver_id;


CREATE VIEW laterridesratings AS
SELECT laterrides.driver_id, avg(rating) as driver_avg_rating
FROM laterrides join driverrating on laterrides.request_id = driverrating.request_id
GROUP BY laterrides.driver_id;

--matching to trained and untrained drivers

CREATE VIEW earlytotalaverages AS
SELECT trained, avg(driver_avg_rating) as totalavgratings, count(trained) as number
FROM earlyfiveratings JOIN driver on earlyfiveratings.driver_id = driver.driver_id
GROUP by trained;


CREATE VIEW laterridestotalaverages AS
SELECT trained, avg(driver_avg_rating) as totalavgratings, count(trained) as number
FROM laterridesratings JOIN driver on laterridesratings.driver_id = driver.driver_id
GROUP BY trained;

CREATE VIEW ANS AS
SELECT 'trained' as type, earlytotalaverages.number + laterridestotalaverages.number as number, earlytotalaverages.totalavgratings as early, laterridestotalaverages.totalavgratings as late
FROM earlytotalaverages, laterridestotalaverages
WHERE earlytotalaverages.trained and laterridestotalaverages.trained
UNION
SELECT 'untrained' as type, earlytotalaverages.number + laterridestotalaverages.number as number, earlytotalaverages.totalavgratings as early, laterridestotalaverages.totalavgratings as late
FROM earlytotalaverages, laterridestotalaverages
WHERE NOT earlytotalaverages.trained and NOT laterridestotalaverages.trained;



-- Your query that answers the question goes below the "insert into" line:
insert into q4
SELECT * FROM ANS;

-- Rainmakers

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q10 cascade;

create table q10(
	driver_id INTEGER,
	month CHAR(2),
	mileage_2014 FLOAT,
	billings_2014 FLOAT,
	mileage_2015 FLOAT,
	billings_2015 FLOAT,
	billings_increase FLOAT,
	mileage_increase FLOAT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS mastertable CASCADE;
DROP VIEW IF EXISTS completemastertable CASCADE;
DROP VIEW IF EXISTS rides2015 CASCADE;
DROP VIEW IF EXISTS rides2014 CASCADE;
DROP VIEW IF EXISTS Months CASCADE;
DROP VIEW IF EXISTS ansp1 CASCADE;
DROP VIEW IF EXISTS sumBillsMiles2015 CASCADE;
DROP VIEW IF EXISTS sumBillsMiles2014 CASCADE;
DROP VIEW IF EXISTS notzeros2014 CASCADE;
DROP VIEW IF EXISTS complete2014;
DROP VIEW IF EXISTS notzeros2015 CASCADE;
DROP VIEW IF EXISTS complete2015;
DROP VIEW IF EXISTS finalsans CASCADE;


-- Define views for your intermediate steps here:

CREATE VIEW Months as
SELECT to_char(DATE '2014-01-01' + (interval '1' month * generate_series(0,11)), 'MM') as mo;

CREATE VIEW mastertable AS
SELECT request.request_id, request.datetime as date, request.source as startplace, request.destination as destination, driver_id
FROM request, dispatch, dropoff
WHERE request.request_id = dispatch.request_id and dispatch.request_id = dropoff.request_id;


CREATE VIEW completemastertable AS
SELECT mastertable.request_id as request_id, mastertable.date as date, p1.location as b, p2.location as e, amount, mastertable.driver_id as driver_id
FROM mastertable, billed, place p1, place p2
WHERE mastertable.request_id = billed.request_id and
startplace = p1.name and destination = p2.name;

--All the rides for the year 2015
CREATE VIEW rides2015 AS
SELECT * 
FROM completemastertable
WHERE date_part('YEAR', date) = 2015;

--all the rides for the year 2014
CREATE VIEW rides2014 AS
SELECT * 
FROM completemastertable
WHERE date_part('YEAR', date) = 2014;

--Need to get the dates people DID 
CREATE VIEW ansp1 AS
SELECT driver_id, mo
FROM driver, Months;

--total billings and distances per month per driver for 2015 (not including zero vals)
CREATE VIEW sumBillsMiles2015 as
SELECT driver_id, date_part('MONTH', date) as d2015, sum(amount) as billings_2015, sum(b <@> e) as mileage_2015 
FROM rides2015
GROUP BY driver_id, date_part('MONTH', date);

--total billings and distances per month per driver for 2015 (not including zero vals)
CREATE VIEW sumBillsMiles2014 as
SELECT driver_id, date_part('MONTH', date) as d2014, sum(amount) as billings_2014, sum(b <@> e) as mileage_2014 
FROM rides2014
GROUP BY driver_id, date_part('MONTH', date);


CREATE VIEW notzeros2014 AS
SELECT distinct ansp1.driver_id, mo, billings_2014, mileage_2014 
FROM ansp1, sumBillsMiles2014
WHERE ansp1.driver_id = sumBillsMiles2014.driver_id and 
mo::int = d2014;


CREATE VIEW complete2014 AS
SELECT ansp1.driver_id as driver_id, ansp1.mo as mo, 0 as billings_2014, 0 as mileage_2014
FROM ansp1,
((SELECT driver_id, mo FROM ansp1)
EXCEPT
(SELECT driver_id, mo FROM notzeros2014))foo
WHERE ansp1.driver_id = foo.driver_id AND 
ansp1.mo = foo.mo 
UNION
SELECT * FROM notzeros2014 ORDER BY driver_id, mo;
------------------------------------------------------------
CREATE VIEW notzeros2015 AS
SELECT distinct ansp1.driver_id, mo, billings_2015, mileage_2015 
FROM ansp1, sumBillsMiles2015
WHERE ansp1.driver_id = sumBillsMiles2015.driver_id and 
mo::int = d2015;

CREATE VIEW complete2015 AS
SELECT ansp1.driver_id as driver_id, ansp1.mo as mo, 0 as billings_2015, 0 as mileage_2015
FROM ansp1,
((SELECT driver_id, mo FROM ansp1)
EXCEPT
(SELECT driver_id, mo FROM notzeros2015))foo
WHERE ansp1.driver_id = foo.driver_id AND 
ansp1.mo = foo.mo 
UNION
SELECT * FROM notzeros2015 ORDER BY driver_id, mo;

CREATE VIEW finalans AS
SELECT complete2014.driver_id, complete2014.mo, 
mileage_2014, billings_2014, mileage_2015, billings_2015, 
billings_2015 - billings_2014 as billings_increase, 
mileage_2015 - mileage_2014 as mileage_increase
FROM complete2014, complete2015
WHERE complete2014.driver_id = complete2015.driver_id AND
complete2014.mo = complete2015.mo;

-- Your query that answers the question goes below the "insert into" line:
insert into q10
SELECT * FROM finalans;

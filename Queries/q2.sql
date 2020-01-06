-- Lure them back`

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q2 cascade;

create table q2(
    client_id INTEGER,
    name VARCHAR(41),
    email VARCHAR(30),
    billed FLOAT,
    decline INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS Billed_500_Before_2014 CASCADE;
CREATE VIEW Billed_500_Before_2014 AS
  SELECT r.client_id as client_id, sum(amount) as billed_amount
  FROM uber.request r, uber.billed b
  WHERE r.request_id = b.request_id
  AND date_part('year', r.datetime) < 2014
  GROUP BY r.client_id
  HAVING sum(amount) >= 500;

DROP VIEW IF EXISTS Client_Requests_2014 CASCADE;
CREATE VIEW Client_Requests_2014 AS
  SELECT r.client_id as client_id, date_part('year', r.datetime) as year_date, r.request_id as request_id
  FROM uber.request r, uber.dropoff d
  WHERE r.request_id = d.request_id
  AND date_part('year', r.datetime) = 2014;

DROP VIEW IF EXISTS One_to_Ten_Requests_2014 CASCADE;
CREATE VIEW One_to_Ten_Requests_2014 AS
  SELECT client_id, count(request_id) as num_rides
  FROM Client_Requests_2014
  GROUP BY client_id
  HAVING count(request_id) >= 1 AND count(request_id) <= 10;

DROP VIEW IF EXISTS Client_Requests_2015 CASCADE;
CREATE VIEW Client_Requests_2015 AS
  SELECT r.client_id as client_id, date_part('year', r.datetime) as year_date, r.request_id as request_id
  FROM uber.request r, uber.dropoff d
  WHERE r.request_id = d.request_id
  AND date_part('year', r.datetime) = 2015;

DROP VIEW IF EXISTS One_to_Ten_Requests_2015 CASCADE;
CREATE VIEW One_to_Ten_Requests_2015 AS
  SELECT client_id, count(request_id) as num_rides
  FROM Client_Requests_2015
  GROUP BY client_id;

DROP VIEW IF EXISTS Dropoff_2015 CASCADE;
CREATE VIEW Dropoff_2015 AS
  SELECT b.client_id as client_id, CONCAT(c.firstname, ' ', c.surname) as name,
    CASE WHEN c.email IS NOT NULL THEN c.email
         WHEN c.email IS NULL THEN 'unknown'
    END as email,
  billed.billed_amount as billed, a.num_rides - b.num_rides as decline
  FROM One_to_Ten_Requests_2014 a, One_to_Ten_Requests_2015 b, uber.client c, Billed_500_Before_2014 billed
  WHERE a.client_id = b.client_id AND b.client_id = c.client_id AND c.client_id = billed.client_id
  AND a.num_rides >= b.num_rides;

-- Your query that answers the question goes below the "insert into" line:
insert into q2
SELECT * from Dropoff_2015;

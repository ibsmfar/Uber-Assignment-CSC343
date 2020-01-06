-- Months

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q1 cascade;

create table q1(
    client_id INTEGER,
    email VARCHAR(30),
    months INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:


-- Your query that answers the question goes below the "insert into" line:
insert into q1

(select c.client_id as client_id, c.email as email, count(DISTINCT CONCAT (date_part('year', r.datetime), '-', date_part('month', r.datetime))) as year_month
from uber.client c, uber.request r
WHERE c.client_id = r.client_id
GROUP BY c.client_id)
	UNION
(select client_id, email, 0 as year_month
from uber.client
WHERE client_id not in (
	select c1.client_id as client_id
	from uber.client c1, uber.request r1
	WHERE c1.client_id = r1.client_id));



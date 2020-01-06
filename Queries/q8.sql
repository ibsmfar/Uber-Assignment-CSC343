-- Scratching backs?

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q8 cascade;

create table q8(
	client_id INTEGER,
	reciprocals INTEGER,
	difference FLOAT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS dispatch_request CASCADE;
CREATE VIEW dispatch_request AS
  SELECT request.request_id as request_id, request.client_id, dispatch.driver_id
  FROM uber.dispatch dispatch JOIN uber.request request ON dispatch.request_id = request.request_id;

DROP VIEW IF EXISTS reciprocal_ratings CASCADE;
CREATE VIEW reciprocal_ratings AS
  SELECT dis_req.request_id, dis_req.client_id, uber.clientrating.rating as client_rating, dis_req.driver_id, uber.driverrating.rating as driver_rating
  FROM dispatch_request dis_req JOIN uber.clientrating ON dis_req.request_id = uber.clientrating.request_id
  JOIN uber.driverrating ON dis_req.request_id = uber.driverrating.request_id;

DROP VIEW IF EXISTS avg_ratings CASCADE;
CREATE VIEW avg_ratings AS
  SELECT client_id, count(distinct request_id) as num_reciprocals, avg(client_rating) as avg_client_rating,  avg(driver_rating) as avg_driver_rating
  FROM reciprocal_ratings
  GROUP BY client_id;

DROP VIEW IF EXISTS avg_ratings_difference CASCADE;
CREATE VIEW avg_ratings_difference AS
  SELECT client_id, num_reciprocals as reciprocals, avg_driver_rating - avg_client_rating as difference
  FROM avg_ratings;


-- Your query that answers the question goes below the "insert into" line:
insert into q8
SELECT * FROM avg_ratings_difference;

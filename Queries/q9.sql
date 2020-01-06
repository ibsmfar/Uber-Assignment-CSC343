-- Consistent raters

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q9 cascade;

create table q9(
	client_id INTEGER,
	email VARCHAR(30)
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

DROP VIEW IF EXISTS all_ratings CASCADE;
CREATE VIEW all_ratings AS
  SELECT dis_req.request_id, dis_req.client_id, dis_req.driver_id, uber.driverrating.rating as driver_rating
  FROM dispatch_request dis_req JOIN uber.driverrating ON dis_req.request_id = uber.driverrating.request_id;

DROP VIEW IF EXISTS num_ratings_for_rides CASCADE;
CREATE VIEW num_ratings_for_rides AS
  SELECT client_id, count(request_id) as num_requests, count(driver_rating) as num_ratings
  FROM all_ratings
  GROUP BY client_id;

DROP VIEW IF EXISTS ratings_for_all_rides CASCADE;
CREATE VIEW ratings_for_all_rides AS
  SELECT client_id
  FROM num_ratings_for_rides
  WHERE num_ratings = num_requests;

DROP VIEW IF EXISTS consistent_raters CASCADE;
CREATE VIEW consistent_raters AS
  SELECT ratings_for_all_rides.client_id, email
  FROM ratings_for_all_rides JOIN uber.client ON ratings_for_all_rides.client_id = uber.client.client_id;


-- Your query that answers the question goes below the "insert into" line:
insert into q9
SELECT * FROM consistent_raters;

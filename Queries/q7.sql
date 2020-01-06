-- Ratings histogram

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q7 cascade;

create table q7(
	driver_id INTEGER,
	r5 INTEGER,
	r4 INTEGER,
	r3 INTEGER,
	r2 INTEGER,
	r1 INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS Driver_Dispatch CASCADE;
CREATE VIEW Driver_Dispatch AS
  SELECT driver.driver_id, dispatch.request_id
  FROM uber.driver as driver LEFT JOIN uber.dispatch as dispatch
  ON driver.driver_id = dispatch.driver_id;

DROP VIEW IF EXISTS Driver_Request CASCADE;
CREATE VIEW Driver_Request AS
  SELECT driver.driver_id, request.request_id
  FROM Driver_Dispatch driver LEFT JOIN uber.request as request
  ON driver.request_id = request.request_id;

DROP VIEW IF EXISTS Driver_Ratings CASCADE;
CREATE VIEW Driver_Ratings AS
  SELECT driver.driver_id, driver.request_id, rating
  FROM Driver_Request driver LEFT JOIN uber.driverrating as rating
  ON driver.request_id = rating.request_id;

DROP VIEW IF EXISTS Five_Star_Driver_Ratings CASCADE;
CREATE VIEW Five_Star_Driver_Ratings AS
  SELECT driver.driver_id, count(request_id) as r5
  FROM uber.driver driver LEFT JOIN Driver_Ratings ON driver.driver_id = Driver_Ratings.driver_id
  WHERE rating = 5
  GROUP BY (driver.driver_id);

DROP VIEW IF EXISTS Four_Star_Driver_Ratings CASCADE;
CREATE VIEW Four_Star_Driver_Ratings AS
  SELECT driver.driver_id, count(request_id) as r4
  FROM uber.driver driver LEFT JOIN Driver_Ratings ON driver.driver_id = Driver_Ratings.driver_id
  WHERE rating = 4
  GROUP BY (driver.driver_id);

DROP VIEW IF EXISTS Three_Star_Driver_Ratings CASCADE;
CREATE VIEW Three_Star_Driver_Ratings AS
  SELECT driver.driver_id, count(request_id) as r3
  FROM uber.driver driver LEFT JOIN Driver_Ratings ON driver.driver_id = Driver_Ratings.driver_id
  WHERE rating = 3
  GROUP BY (driver.driver_id);

DROP VIEW IF EXISTS Two_Star_Driver_Ratings CASCADE;
CREATE VIEW Two_Star_Driver_Ratings AS
  SELECT driver.driver_id, count(request_id) as r2
  FROM uber.driver driver LEFT JOIN Driver_Ratings ON driver.driver_id = Driver_Ratings.driver_id
  WHERE rating = 2
  GROUP BY (driver.driver_id);

DROP VIEW IF EXISTS One_Star_Driver_Ratings CASCADE;
CREATE VIEW One_Star_Driver_Ratings AS
  SELECT driver.driver_id, count(request_id) as r1
  FROM uber.driver driver LEFT JOIN Driver_Ratings ON driver.driver_id = Driver_Ratings.driver_id
  WHERE rating = 1
  GROUP BY (driver.driver_id);

DROP VIEW IF EXISTS Formatted_Driver_Ratings CASCADE;
CREATE VIEW Formatted_Driver_Ratings AS
  SELECT DISTINCT driver.driver_id, r5, r4, r3, r2, r1
  FROM uber.driver driver LEFT JOIN Five_Star_Driver_Ratings a ON driver.driver_id = a.driver_id LEFT JOIN Four_Star_Driver_Ratings b on
  driver.driver_id = b.driver_id LEFT JOIN Three_Star_Driver_Ratings c on driver.driver_id = c.driver_id LEFT JOIN Two_Star_Driver_Ratings d ON
  driver.driver_id = d.driver_id LEFT JOIN One_Star_Driver_Ratings e ON driver.driver_id = e.driver_id;
-- Your query that answers the question goes below the "insert into" line:
insert into uber.q7
select * from Formatted_Driver_Ratings;

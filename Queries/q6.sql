-- Frequent riders

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q6 cascade;

create table q6(
	client_id INTEGER,
	year CHAR(4),
	rides INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS client_rides CASCADE;
CREATE VIEW client_rides AS
  SELECT client_id, r.request_id, date_part('year', d.datetime) as ride_year
  FROM uber.request r JOIN uber.dropoff d
  ON r.request_id = d.request_id;

DROP VIEW IF EXISTS add_clients CASCADE;
CREATE VIEW add_clients AS
  SELECT client_rides.client_id as id1, ride_year, count(distinct request_id) as rides, client.client_id as id2
  FROM client_rides, client
  GROUP BY (client_rides.client_id, ride_year, client.client_id);

DROP VIEW IF EXISTS add_clients_no_rides CASCADE;
CREATE VIEW add_clients_no_rides AS
  SELECT id2 as client_id, ride_year,
   CASE WHEN id1 = id2 THEN rides
   		ELSE 0
   END as rides
  FROM add_clients;

DROP VIEW IF EXISTS num_rides_per_year CASCADE;
CREATE VIEW num_rides_per_year AS
  SELECT client_id, ride_year, sum(rides) as rides
  FROM add_clients_no_rides
  GROUP BY (client_id, ride_year)
  ORDER BY ride_year;

DROP VIEW IF EXISTS max_rides_per_year CASCADE;
CREATE VIEW max_rides_per_year AS
  SELECT client_id, num1.ride_year, rides
  FROM num_rides_per_year num1,
    (SELECT max(num2.rides) as max_rides, num2.ride_year
     FROM num_rides_per_year num2
     GROUP BY num2.ride_year) non_max
  WHERE num1.ride_year = non_max.ride_year
  AND num1.rides = non_max.max_rides;

DROP VIEW IF EXISTS min_rides_per_year CASCADE;
CREATE VIEW min_rides_per_year AS
  SELECT client_id, num1.ride_year, rides
  FROM num_rides_per_year num1,
    (SELECT min(num2.rides) as min_rides, num2.ride_year
     FROM num_rides_per_year num2
     GROUP BY num2.ride_year) non_min
  WHERE num1.ride_year = non_min.ride_year
  AND num1.rides = non_min.min_rides;

DROP VIEW IF EXISTS non_max_rides_per_year CASCADE;
CREATE VIEW non_max_rides_per_year AS
  SELECT * FROM num_rides_per_year
    EXCEPT
  SELECT * FROM max_rides_per_year;

DROP VIEW IF EXISTS non_min_rides_per_year CASCADE;
CREATE VIEW non_min_rides_per_year AS
  SELECT * FROM num_rides_per_year
    EXCEPT
  SELECT * FROM min_rides_per_year;

DROP VIEW IF EXISTS second_max_rides_per_year CASCADE;
CREATE VIEW second_max_rides_per_year AS
  SELECT client_id, num1.ride_year, rides
  FROM non_max_rides_per_year num1,
    (SELECT max(num2.rides) as max_rides, num2.ride_year
     FROM non_max_rides_per_year num2
     GROUP BY num2.ride_year) non_max
  WHERE num1.ride_year = non_max.ride_year
  AND num1.rides = non_max.max_rides;

DROP VIEW IF EXISTS second_min_rides_per_year CASCADE;
CREATE VIEW second_min_rides_per_year AS
  SELECT client_id, num1.ride_year, rides
  FROM non_min_rides_per_year num1,
    (SELECT min(num2.rides) as min_rides, num2.ride_year
     FROM non_min_rides_per_year num2
     GROUP BY num2.ride_year) non_min
  WHERE num1.ride_year = non_min.ride_year
  AND num1.rides = non_min.min_rides;

DROP VIEW IF EXISTS non_second_max_rides_per_year CASCADE;
CREATE VIEW non_second_max_rides_per_year AS
  SELECT * FROM non_max_rides_per_year
    EXCEPT
  SELECT * FROM second_max_rides_per_year;

DROP VIEW IF EXISTS non_second_min_rides_per_year CASCADE;
CREATE VIEW non_second_min_rides_per_year AS
  SELECT * FROM non_min_rides_per_year
    EXCEPT
  SELECT * FROM second_min_rides_per_year;

DROP VIEW IF EXISTS third_max_rides_per_year CASCADE;
CREATE VIEW third_max_rides_per_year AS
  SELECT client_id, num1.ride_year, rides
  FROM non_second_max_rides_per_year num1,
    (SELECT max(num2.rides) as max_rides, num2.ride_year
     FROM non_second_max_rides_per_year num2
     GROUP BY num2.ride_year) non_max
  WHERE num1.ride_year = non_max.ride_year
  AND num1.rides = non_max.max_rides;

DROP VIEW IF EXISTS third_min_rides_per_year CASCADE;
CREATE VIEW third_min_rides_per_year AS
  SELECT client_id, num1.ride_year, rides
  FROM non_second_min_rides_per_year num1,
    (SELECT min(num2.rides) as min_rides, num2.ride_year
     FROM non_second_min_rides_per_year num2
     GROUP BY num2.ride_year) non_min
  WHERE num1.ride_year = non_min.ride_year
  AND num1.rides = non_min.min_rides;

DROP VIEW IF EXISTS top_three CASCADE;
CREATE VIEW top_three AS
  SELECT * FROM max_rides_per_year
    UNION
  SELECT * FROM second_max_rides_per_year
    UNION
  SELECT * FROM third_max_rides_per_year;

DROP VIEW IF EXISTS bottom_three CASCADE;
CREATE VIEW bottom_three AS
  SELECT * FROM min_rides_per_year
    UNION
  SELECT * FROM second_min_rides_per_year
    UNION
  SELECT * FROM third_min_rides_per_year;

DROP VIEW IF EXISTS cumulative_results CASCADE;
CREATE VIEW cumulative_results AS
  SELECT * FROM top_three
  	UNION
  SELECT * FROM bottom_three;


-- Your query that answers the question goes below the "insert into" line:
insert into uber.q6
SELECT * FROM cumulative_results;

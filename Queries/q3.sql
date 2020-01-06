DROP VIEW IF EXISTS all_rides CASCADE;
DROP VIEW IF EXISTS rideduration1 CASCADE;
DROP VIEW IF EXISTS totalrideduration1 CASCADE;
DROP VIEW IF EXISTS all_rides_with_date CASCADE;

CREATE VIEW all_rides AS
SELECT pickup.request_id as request_id, driver_id, pickup.datetime as pickuptime,
		dropoff.datetime as droptime
FROM uber.pickup, uber.dropoff, uber.dispatch
WHERE pickup.request_id = dropoff.request_id AND
dispatch.request_id = pickup.request_id AND
date_part('YEAR', pickup.datetime) = date_part ('YEAR', dropoff.datetime) AND
date_part('MONTH', pickup.datetime) = date_part ('MONTH', dropoff.datetime) AND
date_part('DAY', pickup.datetime) = date_part ('DAY', dropoff.datetime);

CREATE VIEW rideduration1 AS
SELECT request_id, pickuptime, driver_id, (droptime - pickuptime) as ride_duration
FROM all_rides;

CREATE VIEW totalrideduration1 AS
SELECT driver_id, sum(ride_duration) as total_ride_duration, 
CONCAT(date_part('year', rideduration1.pickuptime), '-', date_part('month', rideduration1.pickuptime), '-', date_part('day', rideduration1.pickuptime))
as total_date
FROM rideduration1
GROUP BY driver_id, 
CONCAT(date_part('year', rideduration1.pickuptime), '-', date_part('month', rideduration1.pickuptime), '-', date_part('day', rideduration1.pickuptime));

--SELECT * FROM totalrideduration1;

CREATE VIEW all_rides_with_date AS
SELECT *, CONCAT(date_part('year', pickuptime), '-', date_part('month', pickuptime), '-', date_part('day', pickuptime))
FROM all_rides;

--SELECT * FROM totalrideduration1;

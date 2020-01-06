-- Bigger and smaller spenders

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q5 cascade;

create table q5(
	client_id INTEGER,
	months VARCHAR(7),      -- The handout called this "month", which made more sense.
	total FLOAT,
	comparison VARCHAR(30)  -- This could have been lower.
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS billed_by_month CASCADE;
CREATE VIEW billed_by_month AS
  SELECT d.request_id, b.amount, CONCAT(date_part('year', d.datetime), ' ', to_char(d.datetime, 'MM')) as year_month
  FROM uber.dropoff d JOIN uber.billed b on d.request_id = b.request_id;

DROP VIEW IF EXISTS client_month CASCADE;
CREATE VIEW client_month AS
  SELECT client_id, billed_by_month.request_id, amount, year_month
  FROM billed_by_month JOIN uber.request on billed_by_month.request_id = uber.request.request_id;

DROP VIEW IF EXISTS monthly_client_amount CASCADE;
CREATE VIEW monthly_client_amount AS
  SELECT year_month, sum(amount) as month_sum, count(DISTINCT client_id) as num_clients_per_month
  FROM client_month
  GROUP BY year_month;

DROP VIEW IF EXISTS avg_client_amount CASCADE;
CREATE VIEW avg_client_amount AS
  SELECT year_month, month_sum, num_clients_per_month, (month_sum / num_clients_per_month) as avg_monthly
  FROM monthly_client_amount;

DROP VIEW IF EXISTS client_monthly_bill CASCADE;
CREATE VIEW client_monthly_bill AS
  SELECT client_id, sum(amount) as amount, year_month
  FROM client_month
  GROUP BY (client_id, year_month);

DROP VIEW IF EXISTS all_clients_each_month CASCADE;
CREATE VIEW all_clients_each_month AS
  SELECT client.client_id,
  sum(CASE WHEN client_monthly_bill.client_id = client.client_id THEN amount
         ELSE 0
  END) as amount, year_month
  FROM client_monthly_bill, client
  GROUP BY (client.client_id, year_month)
  ORDER BY year_month;

DROP VIEW IF EXISTS big_small_spenders CASCADE;
CREATE VIEW big_small_spenders AS
  SELECT a.client_id, a.year_month, a.amount,
    CASE WHEN a.amount < avg_monthly THEN 'below'
         ELSE 'at or above'
    END as comparison
  FROM all_clients_each_month a JOIN avg_client_amount b ON a.year_month = b.year_month
  ORDER BY a.year_month;

 SELECT * FROM big_small_spenders order by year_month;
-- Your query that answers the question goes below the "insert into" line:
insert into uber.q5
 SELECT * FROM big_small_spenders;

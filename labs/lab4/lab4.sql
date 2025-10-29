-- 4 variant
DROP TABLE IF EXISTS deps CASCADE;
DROP SEQUENCE IF EXISTS deps_id_seq CASCADE;

-- Task 1
CREATE TABLE deps (
    id     INTEGER     PRIMARY KEY,
    name   VARCHAR(64) NOT NULL,
    region VARCHAR(64) NOT NULL
);

-- Task 2
CREATE SEQUENCE deps_id_seq 
       START WITH 1
       CYCLE
       INCREMENT BY 4
       CACHE 1;

-- Task 3
INSERT INTO deps (id, name, region)
VALUES (nextval('deps_id_seq'), 'Direction', 'Mars');

-- Task 4
INSERT INTO deps (id, name, region)
SELECT nextval('deps_id_seq'), d.department_name, LEFT(r.region_name, 2)
  FROM departments d 
       JOIN locations l USING (location_id)
       JOIN countries c USING (country_id)
       JOIN regions r USING (region_id);

-- Task 5
UPDATE deps
   SET region = 'Europe'
 WHERE name = 'Sales';

-- Task 6
DELETE FROM deps
 WHERE id % 2 = 0;

-- Task 7
WITH RECURSIVE managers_cte AS (
    SELECT 
        e.employee_id,
        e.manager_id,
        e.department_id
    FROM employees e
    WHERE e.employee_id = 107 -- Place your employee id here

    UNION ALL

    SELECT 
        m.employee_id,
        m.manager_id,
        m.department_id
    FROM employees m
    INNER JOIN managers_cte mc
        ON m.employee_id = mc.manager_id
)
SELECT 
    mgr.employee_id AS manager_id,
    mgr.last_name,
    mgr.first_name,
    r.region_name
FROM managers_cte mc
JOIN employees mgr ON mc.manager_id = mgr.employee_id
JOIN departments d ON mgr.department_id = d.department_id
       JOIN locations l USING (location_id)
       JOIN countries c USING (country_id)
       JOIN regions r USING (region_id);

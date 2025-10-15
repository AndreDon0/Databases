-- 5 variant
BEGIN;

-- Task 1
SELECT 
    e.first_name AS "FIRST_NAME",
    e.last_name AS "LAST_NAME",
    j.job_title AS "JOB_TITLE"
FROM 
    employees AS e
NATURAL LEFT JOIN 
    jobs AS j
WHERE 
    j.job_title = 'Programmer';

SAVEPOINT T1;

-- Task 2
SELECT 
    e.first_name AS "FIRST_NAME",
    e.last_name AS "LAST_NAME",
    d.department_name AS "DEPARTMENT_NAME",
    c.country_name AS "COUNTRY_NAME"
FROM 
    employees AS e
NATURAL LEFT JOIN 
    departments AS d
NATURAL LEFT JOIN 
    locations AS l 
NATURAL LEFT JOIN 
    countries AS c
WHERE 
    c.country_name = 'United States of America' AND
    d.department_name IN ('Shipping', 'Finance');

SAVEPOINT T2;

-- Task 3
SELECT 
    e.first_name AS "Имя",
    e.last_name AS "Фамилия",
    REPLACE(e.salary::text, '.', ',') AS "Оклад",
    ROUND(j.min_salary) AS "Мин. оклад"
FROM 
    employees AS e
NATURAL LEFT JOIN 
    jobs AS j
WHERE 
    e.salary < j.min_salary * 1.20;

SAVEPOINT T3;

-- Task 4
SELECT e.last_name AS Фамилия_Р, 
       TO_CHAR(e.hire_date, 'DD.MM.YYYY') AS Дата_Р,
       m.last_name AS Фамилия_М,
       TO_CHAR(m.hire_date, 'DD.MM.YYYY') AS Дата_М
  FROM employees AS e,
       employees AS m
 WHERE e.manager_id = m.employee_id AND
       e.hire_date < m.hire_date;

SAVEPOINT T4;

-- Task 5
SELECT first_name AS Имя,
       last_name AS Фамилия,
       job_id AS Должность,
       ROUND(salary) AS Оклад
  FROM employees
 WHERE employee_id IN (
       SELECT e.employee_id
         FROM employees AS e,
              jobs AS j
        WHERE e.salary = j.min_salary
       );

SAVEPOINT T5;

COMMIT;
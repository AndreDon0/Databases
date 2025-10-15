-- Task 1
SELECT 
    CONCAT(first_name, ' ', last_name) AS ФИО,
    REPLACE(salary::text, '.', ',') AS ОКЛАД,
    ROUND(salary * 0.87) AS "Оклад минус подоходный"
FROM employees;

-- Task 2
SELECT 
    first_name AS "Имя",
    last_name AS "Фамилия", 
    job_id AS "Должность",
    TO_CHAR(hire_date, 'dd.MM.yyyy') AS "Дата приема на работу"
FROM employees
WHERE 
    (EXTRACT(YEAR FROM hire_date) NOT BETWEEN 1995 AND 1999)
    OR job_id IN ('AD_PRES', 'AD_VP', 'AD_ASST')
LIMIT 5;

-- Task 3
SELECT first_name AS "Имя", last_name AS "Фамилия",
       LOWER(CONCAT(
           SUBSTRING(first_name, LENGTH(first_name) - 1, 2), 
           SUBSTRING(last_name, 1, 3))
       ) AS "Идентификатор"
  FROM employees;

-- Task 4
SELECT 
    job_id AS "Должность",
    ROUND(MAX(salary)) AS "Максимальная зарплата",
    ROUND(MIN(salary)) AS "Минимальная зарплата",
    ROUND(AVG(salary), 2) AS "Средняя зарплата"
FROM employees
GROUP BY job_id
ORDER BY job_id;

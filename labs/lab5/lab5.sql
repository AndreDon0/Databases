-- variant 4

-- Task 1
SELECT last_name, first_name, phone_number
  FROM bd_employees
 WHERE phone_number ~ '^8-\(49[59]\)-\d{3}-\d{2}-\d{2}$'
 ORDER BY last_name, first_name;

-- Task 2
SELECT last_name, first_name, phone_number
  FROM bd_employees
 WHERE phone_number ~ '^.+\d{4}.+$'
 ORDER BY last_name, first_name;

-- Task 3
SELECT last_name,
       CASE
          WHEN REGEXP_INSTR(email, '@') <= 3
          THEN email
          ELSE REGEXP_REPLACE(email, '^(.{2})[^@]*@', '\1_@')
       END AS email
  FROM bd_employees
 ORDER BY last_name, email;

-- Task 4
UPDATE deps
   SET name = 'Innov. Marketing'
 WHERE region = (
    SELECT LEFT(r.region_name, 2)
      FROM employees e
      JOIN departments d ON e.department_id = d.department_id
      JOIN locations l ON d.location_id = l.location_id
      JOIN countries c ON l.country_id = c.country_id
      JOIN regions r ON c.region_id = r.region_id
     WHERE e.last_name = 'Kochhar' AND e.first_name = 'Neena'
);

-- Task 5
SELECT last_name, first_name, 
       REGEXP_COUNT(first_name, '[oaeiuy]', 1, 'i') AS vowel_count
  FROM bd_employees
 WHERE REGEXP_COUNT(first_name, '[oaeiuy]', 1, 'i') <= 3
 ORDER BY last_name, first_name;

-- Task 6
WITH RECURSIVE bd_letter_sum AS (
    SELECT
        last_name,
        first_name,
        1 AS pos,
        CASE 
          WHEN ASCII(UPPER(SUBSTR(last_name, 1, 1))) BETWEEN ASCII('A') AND ASCII('Z') 
          THEN ASCII(UPPER(SUBSTR(last_name, 1, 1))) - ASCII('A') + 1
          WHEN ASCII(UPPER(SUBSTR(last_name, 1, 1))) BETWEEN ASCII('А') AND ASCII('Е')
          THEN ASCII(UPPER(SUBSTR(last_name, 1, 1))) - ASCII('А') + 1
          WHEN UPPER(SUBSTR(last_name, 1, 1)) = 'Ё' 
          THEN 7
          WHEN ASCII(UPPER(SUBSTR(last_name, 1, 1))) BETWEEN ASCII('Ж') AND ASCII('Я')
          THEN ASCII(UPPER(SUBSTR(last_name, 1, 1))) - ASCII('Ж') + 8
          ELSE 0
        END AS sum_letters,
        CASE 
          WHEN ASCII(UPPER(SUBSTR(last_name, 1, 1))) BETWEEN ASCII('A') AND ASCII('Z') 
          THEN SUBSTR(last_name, 1, 1)
          WHEN ASCII(UPPER(SUBSTR(last_name, 1, 1))) BETWEEN ASCII('А') AND ASCII('Е')
          THEN SUBSTR(last_name, 1, 1)
          WHEN UPPER(SUBSTR(last_name, 1, 1)) = 'Ё'
          THEN SUBSTR(last_name, 1, 1)
          WHEN ASCII(UPPER(SUBSTR(last_name, 1, 1))) BETWEEN ASCII('Ж') AND ASCII('Я')
          THEN SUBSTR(last_name, 1, 1)
          ELSE ''
        END AS letters,
        CASE 
          WHEN ASCII(UPPER(SUBSTR(last_name, 1, 1))) BETWEEN ASCII('A') AND ASCII('Z') 
          THEN (ASCII(UPPER(SUBSTR(last_name, 1, 1))) - ASCII('A') + 1)::text
          WHEN ASCII(UPPER(SUBSTR(last_name, 1, 1))) BETWEEN ASCII('А') AND ASCII('Е')
          THEN (ASCII(UPPER(SUBSTR(last_name, 1, 1))) - ASCII('А') + 1)::text
          WHEN UPPER(SUBSTR(last_name, 1, 1)) = 'Ё'
          THEN '7'
          WHEN ASCII(UPPER(SUBSTR(last_name, 1, 1))) BETWEEN ASCII('Ж') AND ASCII('Я')
          THEN (ASCII(UPPER(SUBSTR(last_name, 1, 1))) - ASCII('Ж') + 8)::text
          ELSE ''
        END AS numbers
    FROM bd_employees
    WHERE LENGTH(last_name) > 0

    UNION ALL

    SELECT
        last_name,
        first_name,
        pos + 1,
        sum_letters + CASE 
          WHEN ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) BETWEEN ASCII('A') AND ASCII('Z') 
          THEN ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) - ASCII('A') + 1
          WHEN ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) BETWEEN ASCII('А') AND ASCII('Е')
          THEN ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) - ASCII('А') + 1
          WHEN UPPER(SUBSTR(last_name, pos + 1, 1)) = 'Ё'
          THEN 7
          WHEN ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) BETWEEN ASCII('Ж') AND ASCII('Я')
          THEN ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) - ASCII('Ж') + 8
          ELSE 0
        END,
        letters || '+' || CASE 
          WHEN ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) BETWEEN ASCII('A') AND ASCII('Z') 
          THEN SUBSTR(last_name, pos + 1, 1)
          WHEN ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) BETWEEN ASCII('А') AND ASCII('Е')
          THEN SUBSTR(last_name, pos + 1, 1)
          WHEN UPPER(SUBSTR(last_name, pos + 1, 1)) = 'Ё'
          THEN SUBSTR(last_name, pos + 1, 1)
          WHEN ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) BETWEEN ASCII('Ж') AND ASCII('Я')
          THEN SUBSTR(last_name, pos + 1, 1)
          ELSE ''
        END,
        numbers || '+' || CASE 
          WHEN ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) BETWEEN ASCII('A') AND ASCII('Z') 
          THEN (ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) - ASCII('A') + 1)::text
          WHEN ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) BETWEEN ASCII('А') AND ASCII('Е')
          THEN (ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) - ASCII('А') + 1)::text
          WHEN UPPER(SUBSTR(last_name, pos + 1, 1)) = 'Ё'
          THEN '7'
          WHEN ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) BETWEEN ASCII('Ж') AND ASCII('Я')
          THEN (ASCII(UPPER(SUBSTR(last_name, pos + 1, 1))) - ASCII('Ж') + 8)::text
          ELSE ''
        END
    FROM bd_letter_sum
    WHERE pos < LENGTH(last_name)
)
SELECT 
    last_name, 
    first_name, 
    MAX(sum_letters) AS total_alpha_sum,
    MAX(letters) AS letters_expression,
    MAX(numbers) || '='|| MAX(sum_letters) AS numbers_expression
FROM bd_letter_sum
GROUP BY last_name, first_name
ORDER BY last_name, first_name;

-- variant 5

-- Task 1
WITH RECURSIVE piramide AS (
    SELECT id, CAST(id AS TEXT) AS path, manager_id, first_name, last_name
    FROM bd6_employees
    WHERE id = 1
    
    UNION ALL
    
    SELECT e.id, p.path || '->' || CAST(e.id AS TEXT), e.manager_id, e.first_name, e.last_name
    FROM piramide p
    JOIN bd6_employees e ON p.id = e.manager_id
)
SELECT * FROM piramide;

CREATE OR REPLACE FUNCTION print_employee_hierarchy_rec(emp_id INT)
RETURNS VOID AS $$
DECLARE
    emp RECORD;
    sub_id INT;
BEGIN
    SELECT id, last_name, first_name INTO emp FROM bd6_employees WHERE id = emp_id;
    IF FOUND THEN
        RAISE NOTICE 'Surname: %, Name: %', emp.last_name, emp.first_name;
        FOR sub_id IN SELECT id FROM bd6_employees WHERE manager_id = emp_id
        LOOP
            PERFORM print_employee_hierarchy_rec(sub_id);
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql;
SELECT print_employee_hierarchy_rec(1);


-- Task 2
CREATE OR REPLACE PROCEDURE print_employee_sorted_salary()
LANGUAGE plpgsql
AS $$
DECLARE
    name_salary RECORD;
    my_cursor CURSOR FOR 
        SELECT last_name, first_name, salary_in_euro 
        FROM bd6_employees 
        ORDER BY salary_in_euro DESC;
    remains DECIMAL(4,2) := 0;
BEGIN
    OPEN my_cursor;
    LOOP
        FETCH my_cursor INTO name_salary;
        EXIT WHEN NOT FOUND;

        name_salary.salary_in_euro := name_salary.salary_in_euro + remains;
        remains := name_salary.salary_in_euro % 100;
        name_salary.salary_in_euro := name_salary.salary_in_euro - remains;

        RAISE NOTICE 'Surname: %, Name: %, Salary %',
            name_salary.last_name, name_salary.first_name, name_salary.salary_in_euro;
    END LOOP;
    CLOSE my_cursor;
END;
$$;
CALL print_employee_sorted_salary();


-- Task 3
CREATE OR REPLACE PROCEDURE firing()
AS $$
DECLARE
    first_rec RECORD;
    last_rec RECORD;
    cur_first CURSOR FOR SELECT id, salary_in_euro FROM bd6_employees ORDER BY salary_in_euro DESC LIMIT 10;
    cur_last CURSOR FOR SELECT id, salary_in_euro FROM bd6_employees ORDER BY salary_in_euro LIMIT 10;
BEGIN
    OPEN cur_first;
    OPEN cur_last;

    LOOP
        FETCH cur_first INTO first_rec;
        FETCH cur_last INTO last_rec;
        EXIT WHEN NOT FOUND;

        first_rec.salary_in_euro := first_rec.salary_in_euro + last_rec.salary_in_euro;
        UPDATE bd6_employees SET salary_in_euro = first_rec.salary_in_euro WHERE id = first_rec.id;

        UPDATE bd6_employees SET manager_id = NULL WHERE id = last_rec.id;
    END LOOP;

    CLOSE cur_first;
    CLOSE cur_last;

    DELETE FROM bd6_employees WHERE id IN (SELECT id FROM bd6_employees ORDER BY salary_in_euro LIMIT 10);
END;
$$ LANGUAGE plpgsql;
CALL firing();
SELECT * FROM bd6_employees;


-- Task 4
DROP TABLE IF EXISTS spiral CASCADE;
CREATE TABLE spiral (
    f1 INT,
    f2 INT,
    f3 INT,
    f4 INT,
    f5 INT
);
CREATE OR REPLACE FUNCTION spiral_insert()
RETURNS VOID AS $$
DECLARE
    i INT := 1;
BEGIN
    WHILE i <= 1000 * 5 LOOP
        IF i % 10 = 1 THEN
            INSERT INTO spiral (f1, f2, f3, f4, f5) 
            VALUES (i, i + 1, i + 2, i + 3, i + 4);
        ELSE
            INSERT INTO spiral (f1, f2, f3, f4, f5) 
            VALUES (i + 4, i + 3, i + 2, i + 1, i);
        END IF;
        i := i + 5;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
SELECT spiral_insert();
SELECT * FROM spiral;
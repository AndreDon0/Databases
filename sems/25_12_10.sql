/*********************************************************************/
/*                          КУРСОРЫ: ЗАДАЧИ                          */
/*********************************************************************/

/* Создание и заполнение таблиц */
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS employees CASCADE;

CREATE TABLE employees (
    emp_id      SERIAL PRIMARY KEY,
    full_name   TEXT NOT NULL,
    department  TEXT NOT NULL,
    salary      INT NOT NULL,
    hire_date   DATE NOT NULL
);

INSERT INTO employees (full_name, department, salary, hire_date) VALUES
('Иван Петров',      'IT',       120000, '2020-01-10'),
('Мария Сидорова',   'IT',       150000, '2019-06-01'),
('Антон Волков',     'HR',        90000, '2021-03-15'),
('Ольга Иванова',    'HR',        95000, '2018-09-20'),
('Павел Козлов',     'Sales',     80000, '2022-02-10'),
('Дмитрий Орлов',    'Sales',     85000, '2020-11-11');

CREATE TABLE sales (
    sale_id     SERIAL PRIMARY KEY,
    emp_id      INT REFERENCES employees(emp_id),
    sale_sum    INT NOT NULL,
    sale_date   DATE NOT NULL
);

INSERT INTO sales (emp_id, sale_sum, sale_date) VALUES
(5, 200000, '2023-01-01'),
(5, 150000, '2023-01-15'),
(6,  90000, '2023-02-01'),
(6, 110000, '2023-02-10'),
(1,  50000, '2023-03-03'),
(2,  70000, '2023-03-05');

CREATE TABLE audit_log (
    id          SERIAL PRIMARY KEY,
    event_time  TIMESTAMP DEFAULT now(),
    message     TEXT
);




/* 1. Напишите процедуру, которая печатает имена сотрудников
 * и их зарпалты 
 * 
 * Подсказка: используйте курсор и бесконечный цикл 
 * LOOP … EXIT WHEN NOT FOUND. */
CREATE OR REPLACE PROCEDURE print_employees()
LANGUAGE plpgsql
AS $$
DECLARE
    my_cursor refcursor;
    my_row RECORD;
BEGIN
    OPEN my_cursor FOR SELECT full_name, salary FROM employees;
    LOOP
        FETCH my_cursor INTO my_row;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE '%: %', my_row.full_name, my_row.salary;
    END LOOP;
    CLOSE my_cursor;
END;
$$




/* 2. Напишите процедуру, которая принимает название отдела и выводит
 * выводит характиристику зарпалты: 'Высокая зарплата' / 'Обычная зарплата'.
 * Предложите градацию на основе щаполненной таблицы.
 * 
 * Подсказка: используйте CASE. */

CREATE OR REPLACE PROCEDURE check_salary(department TEXT, salary_pivot INT)
LANGUAGE plpgsql
AS $$
DECLARE
    my_cursor refcursor;
    my_row RECORD;
BEGIN
    OPEN my_cursor FOR SELECT full_name, salary FROM employees WHERE department = department;
    LOOP
        FETCH my_cursor INTO my_row;
        EXIT WHEN NOT FOUND;
        CASE
            WHEN my_row.salary > salary_pivot THEN
                RAISE NOTICE '%: Высокая зарплата', my_row.full_name;
            ELSE
                RAISE NOTICE '%: Обычная зарплата', my_row.full_name;
        END CASE;
    END LOOP;
    CLOSE my_cursor;
END;
$$

/* 3. Напишите процедуру, которая заносит сообщение об обработке
 * очередного сотрудника в таблицу audit_log.
 * 
 * Подсказка: используйте FOR r IN cursor LOOP. */

CREATE OR REPLACE PROCEDURE log_employees()
LANGUAGE plpgsql
AS $$
DECLARE
    my_cursor cursor FOR SELECT full_name, salary FROM employees;
    my_row RECORD; 
BEGIN
    FOR my_row IN my_cursor LOOP
        insert into audit_log (message) VALUES (CONCAT(my_row.full_name, ': ', my_row.salary));
    END LOOP;
END;
$$



/* 4. Напишите процедуру, которая увеличивает зарплаты сотрудников
 * отдела IT на 10%, записывая соответствующие сообщения в audit_log.
 * Для перебора сотрудников используйте курсор. 
 * 
 * Дполнительно: измените процедуру так, чтобы обновление происходило
 * для заданного отдела на указанный процент.
 * Реализуйте проверки на допустимые значения: верно указан департамент,
 * процентное значение лежит в диапазоне от 1 до 100.
 * 
 * Подсказка: используйте цикл WHILE. */

CREATE OR REPLACE PROCEDURE increase_IT_salary()
LANGUAGE plpgsql
AS $$
DECLARE
    my_cursor refcursor;
    my_row RECORD;
BEGIN
    OPEN my_cursor FOR SELECT full_name, salary FROM employees WHERE department = 'IT';
    FETCH my_cursor INTO my_row;
    WHILE FOUND LOOP
        UPDATE employees SET salary = salary * 1.1 WHERE full_name = my_row.full_name;
        insert into audit_log (message) VALUES (CONCAT(my_row.full_name, ': ', my_row.salary));
        FETCH my_cursor INTO my_row;
    END LOOP;
END;
$$



/* 5. Напишите процедуру, которая анализирует суммарные продажи 
 * сотрудника и разделяет сотрудников на категории: больше 300000 -- 
 * 'мастер', иначе 'обычный', -- и заносит эту информацию в таблицу
 * audit_log.
 * 
 * Дополнительно: реализуйте проверку на то, что сотрудник работает
 * в отделье продаж. Если это не так, выведите соответсвующее сообщение
 * в audit_log.
 * 
 * Подсказка: используйте курсор и конструкцию IF / ELSE. */


CREATE OR REPLACE PROCEDURE analyze_sales()
LANGUAGE plpgsql
AS $$
DECLARE
    my_cursor refcursor;
    my_row RECORD;
BEGIN
    OPEN my_cursor FOR SELECT full_name, emp_id, department, salary FROM employees;
    FETCH my_cursor INTO my_row;
    WHILE FOUND LOOP
        IF EXISTS (SELECT 1 FROM sales WHERE emp_id = my_row.emp_id) THEN
            IF (SELECT SUM(sale_sum) FROM sales WHERE emp_id = my_row.emp_id) > 300000 THEN
                insert into audit_log (message) VALUES (CONCAT(my_row.full_name, ': мастер'));
            ELSE
                insert into audit_log (message) VALUES (CONCAT(my_row.full_name, ': обычный'));
            END IF;
        END IF;
    END LOOP;
END;
$$


/* 6. Напишите процедуру, которая на вход получает массив отделов
 * и для каждого из них выводит число сотрудников.
 * 
 * Подсказка: используйте курсор цикл FOREACH. */

CREATE OR REPLACE PROCEDURE count_employees(departments TEXT[])
LANGUAGE plpgsql
AS $$
DECLARE
    my_cursor refcursor;
    my_row RECORD;
BEGIN
    OPEN my_cursor FOR SELECT department, COUNT(*) FROM employees GROUP BY department;
    FETCH my_cursor INTO my_row;
    WHILE FOUND LOOP
        IF my_row.department = ANY(departments) THEN
            RAISE NOTICE '%: %', my_row.department, my_row.count;
        END IF;
    END LOOP;
END;
$$



/* 7. Напишите процедуру, которая проходит по всем сотрудникам, 
 * находит все продажи и для каждой в таблицу audit_log записывает
 * сообщение, содержащие информацию о сотруднике и информацию
 * о продаже с соответствующей характеристикой:
 * если продажа >= 100000 -- 'курпная', если от 50000 до 100000
 * (не включительно) -- 'средняя', если <= 50000 -- 'мелкая'.
 * Соответвующие сообщения должны также сохраняться в таблице audit_log.
 * 
 * Подсказка: используйте два курсора и CASE. */

CREATE OR REPLACE PROCEDURE analyze_sales()
LANGUAGE plpgsql
AS $$
DECLARE
    my_cursor1 refcursor;
    my_cursor2 refcursor;
    my_row1 RECORD;
    my_row2 RECORD;
BEGIN
    OPEN my_cursor1 FOR SELECT full_name, emp_id FROM employees;
    FETCH my_cursor1 INTO my_row1;
    WHILE FOUND LOOP
        OPEN my_cursor2 FOR SELECT sale_sum FROM sales WHERE emp_id = XXXXXXX.emp_id;
        FETCH my_cursor2 INTO my_row2;
        WHILE FOUND LOOP
            CASE
                WHEN my_row2.sale_sum >= 100000 THEN
                    insert into audit_log (message) VALUES (CONCAT(my_row1.full_name, ': курпная продажа'));
                WHEN my_row2.sale_sum BETWEEN 50000 AND 100000 THEN
                    insert into audit_log (message) VALUES (CONCAT(my_row1.full_name, ': средняя продажа'));
                WHEN my_row2.sale_sum <= 50000 THEN
                    insert into audit_log (message) VALUES (CONCAT(my_row1.full_name, ': мелкая продажа'));
            END CASE;
        END LOOP;
        CLOSE my_cursor2;
    END LOOP;
END;
$$ 



/* 8. Напишите процедуру, которая на вход принимает занчение зарплаты
 * выполняет строит динамический SQL-запрос и печатает имена сотрудников,
 * зарпалты которых меньше поданной. 
 * 
 * Подсказка: используйте цикл WHILE, динамический SQL-запрос
 * и курсор. */

CREATE OR REPLACE PROCEDURE print_employees(salary_pivot INT)
LANGUAGE plpgsql
AS $$
DECLARE
    my_cursor refcursor;
    my_row    RECORD;
    sql_text  text;
BEGIN
    sql_text := 'SELECT full_name, salary FROM employees WHERE salary < $1';

    OPEN my_cursor FOR EXECUTE sql_text USING salary_pivot;
    FETCH my_cursor INTO my_row;

    WHILE FOUND LOOP
        RAISE NOTICE '%: %', my_row.full_name, my_row.salary;
    END LOOP;

    CLOSE my_cursor;
END;
$$;




/* 9. Напишите процедуру, которая определяет сотрудников, чей суммарный
 * оборот продаж превышает 250000 и увеличивает их зарплату на 15%.
 * Действия по ихменению зарпалты должны быть зафиксированы в таблице
 * audit_log.
 * 
 * Подсказка: курсор. */

CREATE OR REPLACE PROCEDURE increase_salary()
LANGUAGE plpgsql
AS $$
DECLARE
    my_cursor refcursor;
    my_row RECORD;
BEGIN
    OPEN my_cursor FOR SELECT full_name, salary FROM employees WHERE emp_id IN 
        (SELECT emp_id FROM sales GROUP BY emp_id HAVING SUM(sale_sum) > 250000);
    FETCH my_cursor INTO my_row;
    WHILE FOUND LOOP
        UPDATE employees SET salary = salary * 1.15 WHERE full_name = my_row.full_name;
        insert into audit_log (message) VALUES (CONCAT(my_row.full_name, ': ', my_row.salary));
        FETCH my_cursor INTO my_row;
    END LOOP;
END;
$$



/* 10. Напишите процедуру, которая создает временную таблицу 
 * emp_totals(emp_id, total_sales). Для каждого сотрудников рассчитайте
 * сумму его продаж (используйте вложенный курсор) и внесите
 * эту информацию во временную таблицу.
 * На основе созданной таблицы emp_totals классифицируйте сотрудников:
 * сильный продажник (сумма продаж более 200000), средний 
 * (сумма продаж от 50000 до 200000 (включительно), слабый (менее 
 * 50000).
 * Итоговую характеристику занесите в таблицу audit_log.
 * 
 * Подсказка: курсоры и CASE. */

CREATE OR REPLACE PROCEDURE analyze_sales()
LANGUAGE plpgsql
AS $$
BEGIN
    CREATE TEMPORARY TABLE emp_totals (
        emp_id INT,
        total_sales INT
    );

    insert into emp_totals (emp_id, total_sales)
    SELECT emp_id, SUM(sale_sum) AS total_sales
    FROM sales
    GROUP BY emp_id;

    insert into audit_log (message)
    SELECT
        CASE
            WHEN total_sales > 200000 THEN CONCAT('Сильный продажник: ', emp_id)
            WHEN total_sales BETWEEN 50000 AND 200000 THEN CONCAT('Средний продажник: ', emp_id)
            ELSE CONCAT('Слабый продажник: ', emp_id)
        END
    FROM emp_totals;
END;
$$


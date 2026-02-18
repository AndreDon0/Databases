DROP TYPE IF EXISTS sex_type CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP SEQUENCE IF EXISTS staff_id_seq CASCADE;
DROP PROCEDURE IF EXISTS birthday_boys CASCADE;

-- Task 1
CREATE TYPE sex_type AS ENUM ('м', 'ж');

CREATE TABLE staff (
    id BIGINT PRIMARY KEY,
    last_name VARCHAR(64) NOT NULL,
    first_name VARCHAR(64) NOT NULL,
    second_name VARCHAR(64),
    sex sex_type NOT NULL,
    birthday DATE NOT NULL,
    post VARCHAR(128) NOT NULL,
    department VARCHAR(128) NOT NULL,
    head_id BIGINT,
    UNIQUE (post, department),
    FOREIGN KEY (head_id) REFERENCES staff(id)
);

CREATE SEQUENCE staff_id_seq;

-- Task 2
INSERT INTO staff (id, last_name, first_name, second_name, sex, birthday, post, department, head_id)
VALUES (
    nextval('staff_id_seq'),
    'Сталин',
    'Иосиф',
    'Виссарионович',
    'м',
    '1879-12-21',
    'Председатель',
    'ГКО',
    NULL
);

INSERT INTO staff (id, last_name, first_name, second_name, sex, birthday, post, department, head_id)
VALUES 
(
    nextval('staff_id_seq'),
    'Молотов',
    'Вячеслав',
    'Михайлович',
    'м',
    '1890-03-09',
    'Заместитель председателя',
    'ГКО',
    (SELECT id FROM staff WHERE post = 'Председатель' and department = 'ГКО')
);

INSERT INTO staff (id, last_name, first_name, second_name, sex, birthday, post, department, head_id)
VALUES 
(
    nextval('staff_id_seq'),
    'Маленков',
    'Георгий',
    'Максимилианович',
    'м',
    '1902-01-08',
    'Начальник',
    'УК ЦК ВКП(б)',
    (SELECT id FROM staff WHERE post = 'Заместитель председателя' and department = 'ГКО')
),
(
    nextval('staff_id_seq'),
    'Ворошилов',
    'Климент',
    'Ефремович',
    'м',
    '1881-02-04',
    'Председатель КО',
    'СНК',
    (SELECT id FROM staff WHERE post = 'Заместитель председателя' and department = 'ГКО')
),
(
    nextval('staff_id_seq'),
    'Микоян',
    'Анастас',
    'Иванович',
    'м',
    '1895-11-25',
    'Председатель',
    'КП-ВС РККА',
    (SELECT id FROM staff WHERE post = 'Заместитель председателя' and department = 'ГКО')
);

-- Task 3
SELECT
    boss.last_name,
    boss.first_name,
    boss.second_name,
    boss.post,
    sub.last_name AS hLast_name,
    sub.first_name AS hFirst_name,
    sub.second_name AS hSecond_name,
    sub.post AS hPost
FROM
    staff boss
LEFT JOIN
    staff sub ON boss.id = sub.head_id;

-- Task 4
UPDATE staff
SET head_id = (SELECT id FROM staff ORDER BY id LIMIT 1)
WHERE id NOT IN (
    SELECT DISTINCT head_id
    FROM staff
    WHERE head_id IS NOT NULL
);

-- Task 5
CREATE OR REPLACE PROCEDURE birthday_boys(p_month INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    r_emp RECORD;
    v_count INTEGER;
    v_min_age NUMERIC;
    v_max_age NUMERIC;
    v_avg_age NUMERIC;
    v_age INTEGER;
BEGIN
    IF p_month < 1 OR p_month > 12 THEN
        RAISE EXCEPTION 'Номер месяца должен быть от 1 до 12';
    END IF;

    SELECT
        COUNT(*),
        MIN(EXTRACT(YEAR FROM AGE(CURRENT_DATE, birthday))),
        MAX(EXTRACT(YEAR FROM AGE(CURRENT_DATE, birthday))),
        AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, birthday)))
    INTO
        v_count, v_min_age, v_max_age, v_avg_age
    FROM staff
    WHERE EXTRACT(MONTH FROM birthday) = p_month;

    IF v_count > 0 THEN
        RAISE NOTICE '---------------------------------------------------';
        RAISE NOTICE 'Именинники в месяце №%: ', p_month;
        RAISE NOTICE '---------------------------------------------------';

        FOR r_emp IN 
            SELECT last_name, first_name, second_name, birthday 
            FROM staff 
            WHERE EXTRACT(MONTH FROM birthday) = p_month 
        LOOP
            v_age := EXTRACT(YEAR FROM AGE(CURRENT_DATE, r_emp.birthday));
            
            RAISE NOTICE '% % % (Дата рождения: %, Возраст: %)', 
                r_emp.last_name, 
                r_emp.first_name, 
                COALESCE(r_emp.second_name, ''), 
                r_emp.birthday, 
                v_age;
        END LOOP;

        RAISE NOTICE '---------------------------------------------------';
        RAISE NOTICE 'Статистика:';
        RAISE NOTICE 'Всего людей: %', v_count;
        RAISE NOTICE 'Минимальный возраст: %', v_min_age;
        RAISE NOTICE 'Максимальный возраст: %', v_max_age;
        RAISE NOTICE 'Средний возраст: %', ROUND(v_avg_age, 2);
        RAISE NOTICE '---------------------------------------------------';
    ELSE
        RAISE NOTICE 'В указанном месяце именинников не найдено.';
    END IF;
END;
$$;

-- Task 6
WITH RECURSIVE hierarchy AS (
    SELECT id, head_id, 1 AS level
    FROM staff
    WHERE head_id IS NULL
    UNION ALL
    SELECT s.id, s.head_id, h.level + 1
    FROM staff s
    JOIN hierarchy h ON s.head_id = h.id
)
SELECT MAX(level) AS max_chain_length
FROM hierarchy;

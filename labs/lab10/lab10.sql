-- Функции никогда не приводят к ошибкам!

-- 0. Триггер (или несколько триггеров) не позволяет добавлять на стеллаж больше товаров, чем количество мест в нём (если полки или места
-- реализованы отдельно, то не позволяет добавлять и на полку и на стеллаж больше товаров, чем можно или не позволяет создавать мест
-- более, чем можно) и не позволяет изменять его максимальную нагрузку на значение меньшее, чем суммарный вес всех хранящихся на нём товаров.

CREATE OR REPLACE FUNCTION check_slots_on_rack()
RETURNS TRIGGER AS $$
DECLARE
    max_slots integer;
    occupied_slots integer;
BEGIN
    IF NEW.id_tenancy IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT r.storage_slots
    INTO max_slots
    FROM tenancy t
    JOIN rack r USING (id_rack)
    WHERE t.id_tenancy = NEW.id_tenancy;

    SELECT COUNT(*)
    INTO occupied_slots
    FROM placement p
    WHERE p.id_tenancy = NEW.id_tenancy;

    IF TG_OP = 'UPDATE' AND OLD.id_tenancy = NEW.id_tenancy THEN
        occupied_slots := occupied_slots - 1;
    END IF;

    IF COALESCE(occupied_slots, 0) + 1 > COALESCE(max_slots, 0) THEN
        RAISE WARNING 'Not enough slots on the rack. Didn\'t add the tenancy_id to the placement table.';
        NEW.id_tenancy = NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_slots_on_rack_trigger
BEFORE INSERT OR UPDATE ON placement
FOR EACH ROW
EXECUTE PROCEDURE check_slots_on_rack();

CREATE OR REPLACE FUNCTION check_rack_max_load()
RETURNS TRIGGER AS $$
DECLARE
    current_weight numeric(10, 2);
BEGIN
    SELECT COALESCE(SUM(weight), 0) AS current_weight
    FROM rack JOIN tenancy USING (id_rack)
              JOIN placement USING (id_tenancy)
              JOIN product USING (id_product)
    WHERE rack.id_rack = NEW.id_rack
    INTO current_weight;
              
    IF current_weight > NEW.max_load THEN
        RAISE WARNING 'Max load is exceeded. Didn\'t update the rack table.';
        RETURN NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_rack_max_load_trigger 
BEFORE UPDATE ON rack 
FOR EACH ROW
EXECUTE PROCEDURE check_rack_max_load();

-- Создаем стелаж с одним местом
INSERT INTO rack (rack_number, storage_slots, max_load, height, width, length, id_room)
VALUES ('TST-L10-R-001', 1, 500.00, 2.000, 1.000, 1.000, 1);

-- Проверка триггеров выше: в клиенте — WARNING, не ERROR. Нужна хотя бы одна строка в client.
INSERT INTO contract (contract_number, end_date)
VALUES ('TST-L10-TRIG-DEMO', DATE '2035-06-01');

INSERT INTO product (description, length, width, height, weight, arrival_date, temp_conditions, humidity_conditions, "position", id_contract)
SELECT 'TST-L10-TRIG-P1', 0.10, 0.10, 0.10, 25.00, CURRENT_DATE, 5, 50, 1, id_contract
FROM contract WHERE contract_number = 'TST-L10-TRIG-DEMO';

INSERT INTO product (description, length, width, height, weight, arrival_date, temp_conditions, humidity_conditions, "position", id_contract)
SELECT 'TST-L10-TRIG-P2', 0.10, 0.10, 0.10, 25.00, CURRENT_DATE, 5, 50, 2, id_contract
FROM contract WHERE contract_number = 'TST-L10-TRIG-DEMO';

INSERT INTO tenancy (id_client, id_rack)
SELECT (SELECT MIN(id_client) FROM client), id_rack
FROM rack WHERE rack_number = 'TST-L10-R-001';

INSERT INTO placement (id_product, id_tenancy)
SELECT p.id_product, t.id_tenancy
FROM product p
CROSS JOIN tenancy t
JOIN rack r ON r.id_rack = t.id_rack
WHERE p.description = 'TST-L10-TRIG-P1'
  AND r.rack_number = 'TST-L10-R-001';

-- Превышение числа мест (второй товар): WARNING, id_tenancy станет NULL.
INSERT INTO placement (id_product, id_tenancy)
SELECT p.id_product, t.id_tenancy
FROM product p
CROSS JOIN tenancy t
JOIN rack r ON r.id_rack = t.id_rack
WHERE p.description = 'TST-L10-TRIG-P2'
  AND r.rack_number = 'TST-L10-R-001';

SELECT * FROM placement WHERE id_tenancy IS NULL;

-- max_load меньше суммарного веса на стеллаже: WARNING, UPDATE не применится.
UPDATE rack SET max_load = 10.00 WHERE rack_number = 'TST-L10-R-001';

SELECT * FROM rack WHERE rack_number = 'TST-L10-R-001';

-- 1. По указанному имени клиента и дате вычисляет количество товаров, срок договора которых истекает до переданной в качестве аргумента
-- даты, хранящихся на складе и принадлежащих данному клиенту. Возвращает целое число.

CREATE OR REPLACE FUNCTION get_expiring_products(
    p_company_name varchar,
    p_end_date     date
)
RETURNS integer AS $$
DECLARE
    expiring_products integer;
BEGIN
    SELECT COUNT(*)
    INTO expiring_products
    FROM client cl
        JOIN tenancy   t  USING (id_client)
        JOIN placement pl USING (id_tenancy)
        JOIN product   pr USING (id_product)
        JOIN contract  ct USING (id_contract)
    WHERE cl.company_name = p_company_name
      AND ct.end_date     < p_end_date;

    RETURN COALESCE(expiring_products, 0);
END;
$$ LANGUAGE plpgsql;

SELECT get_expiring_products('рога и копыта', DATE '2027-12-31');

-- 2. Для множества строк, содержащих длину, ширину и высоту хранящихся на складе товаров, вычисляет максимальные габариты
-- места, необходимые для того, чтобы поместился любой из хранящихся товаров, и представляет их в виде одной строки в формате «высота X
-- ширина X длина». Обратите внимание! Требуется агрегатная функция. Никаких массивов в аргументах функции.

DROP TYPE IF EXISTS max_size_type CASCADE;
CREATE TYPE max_size_type AS (
    height numeric,
    width  numeric,
    length numeric
);

CREATE OR REPLACE FUNCTION max_size_sfunc(
    state max_size_type,
    h numeric, w numeric, l numeric
) RETURNS max_size_type
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE AS $$
BEGIN
    state.height := GREATEST(state.height, h);
    state.width  := GREATEST(state.width,  w);
    state.length := GREATEST(state.length, l);
    RETURN state;
END;
$$;

CREATE OR REPLACE FUNCTION max_size_combinefunc(
    a max_size_type,
    b max_size_type
) RETURNS max_size_type
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE AS $$
BEGIN
    a.height := GREATEST(a.height, b.height);
    a.width  := GREATEST(a.width,  b.width);
    a.length := GREATEST(a.length, b.length);
    RETURN a;
END;
$$;

CREATE OR REPLACE FUNCTION max_size_finalfunc(state max_size_type)
RETURNS text
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE AS $$
BEGIN
    RETURN format('%s X %s X %s', state.height, state.width, state.length);
END;
$$;

CREATE OR REPLACE AGGREGATE max_size(numeric, numeric, numeric) (
    SFUNC       = max_size_sfunc,
    STYPE       = max_size_type,
    FINALFUNC   = max_size_finalfunc,
    COMBINEFUNC = max_size_combinefunc,
    INITCOND    = '(0,0,0)',
    PARALLEL    = SAFE
);

SELECT max_size(height, width, length) AS max_size
FROM product;

-- 3. Создайте представление, отображающее описания клиентов, ключевые поля таблицы клиенты, и описание их товаров.
-- Реализуйте возможность изменения описания клиентов через это представление в реальной таблице.

CREATE OR REPLACE VIEW client_view AS
SELECT c.company_name, c.bank_details, STRING_AGG(pr.description, ', ' ORDER BY pr.description) AS descriptions
FROM client c
    LEFT JOIN tenancy t USING (id_client)
    LEFT JOIN placement p USING (id_tenancy)
    LEFT JOIN product pr USING (id_product)
GROUP BY c.company_name, c.bank_details;

CREATE OR REPLACE FUNCTION update_client_view()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE client 
    SET company_name = NEW.company_name,
        bank_details = NEW.bank_details
    WHERE company_name = OLD.company_name
      AND bank_details = OLD.bank_details;
    IF NOT FOUND THEN
        RAISE WARNING 'Client not found. Please check the company name and bank details.';
        RETURN NULL;
    END IF;

    IF OLD.descriptions IS DISTINCT FROM NEW.descriptions THEN
        RAISE WARNING 'You are trying to change the description of the client, but this is not allowed.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_client_view_trigger
INSTEAD OF UPDATE ON client_view
FOR EACH ROW
EXECUTE PROCEDURE update_client_view();

SELECT * FROM client_view;

-- 4. При помощи таблицы и набора функций реализуйте структуру представления данных неограниченная по длине однонаправленная
-- очередь. Структура должна позволять сохранять в очередь строки, длиной не более 64 символов. Должны быть доступны следующие действия:
--a. enqueue(строка) – добавление элемента (строка) в конец очереди - результат функции – сам элемент;
--b. dequeue() – удаление элемента из начала очереди - результат функции - сам элемент или null, если очередь пуста;
--c. empty() – очистка очереди - результат функции - число удаленных элементов;
--d. init() – инициализация очереди - создает все необходимые таблицы, удаляет старые (если очередь уже создавалась ранее), обнуляет последовательности - результат - null;
--e. tail() – просмотр конца очереди - результат - последний элемент очереди, если он есть, иначе null.
-- Напишите пример работы с очередью.

CREATE OR REPLACE FUNCTION enqueue(p_data VARCHAR(64))
RETURNS VARCHAR(64) AS $$
BEGIN
    INSERT INTO queue (data) VALUES (p_data);
    RETURN p_data;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION dequeue()
RETURNS VARCHAR(64) AS $$
DECLARE
    v_data VARCHAR(64);
BEGIN
    WITH next_item AS (
        SELECT id
        FROM queue
        ORDER BY id ASC
        LIMIT 1
        FOR UPDATE SKIP LOCKED
    )
    DELETE FROM queue q
    USING next_item ni
    WHERE q.id = ni.id
    RETURNING q.data INTO v_data;

    RETURN v_data;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION empty()
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    DELETE FROM queue;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION init()
RETURNS VOID AS $$
BEGIN
    CREATE TABLE IF NOT EXISTS queue (
        id BIGSERIAL PRIMARY KEY,
        data VARCHAR(64) NOT NULL
    );
    TRUNCATE TABLE queue RESTART IDENTITY;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tail()
RETURNS VARCHAR(64) AS $$
BEGIN
    RETURN (SELECT data FROM queue ORDER BY id DESC LIMIT 1);
END;
$$ LANGUAGE plpgsql;


SELECT init();
SELECT enqueue('first');
SELECT enqueue('second');
SELECT enqueue('third');
SELECT tail();
SELECT dequeue();
SELECT dequeue();
SELECT tail();
SELECT empty();
SELECT dequeue();

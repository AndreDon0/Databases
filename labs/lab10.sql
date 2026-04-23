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
        RETURN NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_rack_max_load_trigger 
BEFORE UPDATE ON rack 
FOR EACH ROW
EXECUTE PROCEDURE check_rack_max_load();

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

-- 3. Создайте представление, отображающее описания клиентов, ключевые поля таблицы клиенты, и описание их товаров. Реализуйте
-- возможность изменения описания клиентов через это представление в реальной таблице.

CREATE OR REPLACE VIEW client_view AS
SELECT c.company_name, c.bank_details, pr.description
FROM client c
    JOIN tenancy t USING (id_client)
    JOIN placement p USING (id_tenancy)
    JOIN product pr USING (id_product);

CREATE OR REPLACE FUNCTION update_client_view()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE client 
    SET company_name = NEW.company_name,
        bank_details = NEW.bank_details
    WHERE company_name = OLD.company_name
      AND bank_details = OLD.bank_details;

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
    DELETE FROM queue
    WHERE id = (
        SELECT id
        FROM queue
        ORDER BY id ASC
        LIMIT 1
    )
    RETURNING data INTO v_data;

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
    DROP TABLE IF EXISTS queue CASCADE;
    CREATE TABLE queue (
        id BIGSERIAL PRIMARY KEY,
        data VARCHAR(64) NOT NULL
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tail()
RETURNS VARCHAR(64) AS $$
BEGIN
    RETURN (SELECT data FROM queue ORDER BY id DESC LIMIT 1);
END;
$$ LANGUAGE plpgsql;

-- Powered by Cursor
-- Comprehensive tests for labs/lab10.sql
-- Usage:
--   1) Run schema and seed scripts first (tables + lab10 objects + data).
--   2) Execute this file in one session.
--
-- The script raises EXCEPTION on any failed check.

ROLLBACK;
BEGIN;

SET search_path TO public;

DO $$
DECLARE
    v_room_id integer;
    v_client_id integer;
    v_contract_id integer;
    v_rack_id integer;
    v_tenancy_id integer;
    v_product_1 integer;
    v_product_2 integer;
    v_second_tenancy integer;
BEGIN
    -- Preconditions: required objects from lab10 should exist.
    IF to_regprocedure('check_slots_on_rack()') IS NULL THEN
        RAISE EXCEPTION 'Missing function check_slots_on_rack()';
    END IF;
    IF to_regprocedure('check_rack_max_load()') IS NULL THEN
        RAISE EXCEPTION 'Missing function check_rack_max_load()';
    END IF;
    IF to_regprocedure('get_expiring_products(character varying,date)') IS NULL THEN
        RAISE EXCEPTION 'Missing function get_expiring_products(varchar, date)';
    END IF;
    IF to_regprocedure('enqueue(character varying)') IS NULL THEN
        RAISE EXCEPTION 'Missing function enqueue(varchar)';
    END IF;
    IF to_regprocedure('dequeue()') IS NULL THEN
        RAISE EXCEPTION 'Missing function dequeue()';
    END IF;
    IF to_regprocedure('empty()') IS NULL THEN
        RAISE EXCEPTION 'Missing function empty()';
    END IF;
    IF to_regprocedure('init()') IS NULL THEN
        RAISE EXCEPTION 'Missing function init()';
    END IF;
    IF to_regprocedure('tail()') IS NULL THEN
        RAISE EXCEPTION 'Missing function tail()';
    END IF;
    IF to_regclass('client_view') IS NULL THEN
        RAISE EXCEPTION 'Missing view client_view';
    END IF;
    IF to_regprocedure('max_size(numeric,numeric,numeric)') IS NULL THEN
        RAISE EXCEPTION 'Missing aggregate max_size(numeric,numeric,numeric)';
    END IF;

    SELECT MIN(id_room) INTO v_room_id FROM room;
    SELECT MIN(id_client) INTO v_client_id FROM client;
    IF v_room_id IS NULL OR v_client_id IS NULL THEN
        RAISE EXCEPTION 'room/client tables are empty; seed data first';
    END IF;

    INSERT INTO contract (contract_number, end_date)
    VALUES ('TST-L10-C-001', DATE '2030-01-01')
    RETURNING id_contract INTO v_contract_id;

    -- Test #0a: slot trigger must prevent overflow (sets id_tenancy = NULL).
    INSERT INTO rack (rack_number, storage_slots, max_load, height, width, length, id_room)
    VALUES ('TST-L10-R-001', 1, 500.00, 2.000, 1.000, 1.000, v_room_id)
    RETURNING id_rack INTO v_rack_id;

    INSERT INTO tenancy (id_client, id_rack)
    VALUES (v_client_id, v_rack_id)
    RETURNING id_tenancy INTO v_tenancy_id;

    INSERT INTO product (description, length, width, height, weight, arrival_date, temp_conditions, humidity_conditions, "position", id_contract)
    VALUES ('TEST-LAB10-PRODUCT-A', 0.10, 0.10, 0.10, 5.00, CURRENT_DATE, 5, 50, 1, v_contract_id)
    RETURNING id_product INTO v_product_1;

    INSERT INTO product (description, length, width, height, weight, arrival_date, temp_conditions, humidity_conditions, "position", id_contract)
    VALUES ('TEST-LAB10-PRODUCT-B', 0.10, 0.10, 0.10, 5.00, CURRENT_DATE, 5, 50, 2, v_contract_id)
    RETURNING id_product INTO v_product_2;

    INSERT INTO placement (id_product, id_tenancy)
    VALUES (v_product_1, v_tenancy_id);

    INSERT INTO placement (id_product, id_tenancy)
    VALUES (v_product_2, v_tenancy_id)
    RETURNING id_tenancy INTO v_second_tenancy;

    IF v_second_tenancy IS NOT NULL THEN
        RAISE EXCEPTION 'Slot overflow test failed: second product still has tenancy id %', v_second_tenancy;
    END IF;

    -- Test #0b: rack max_load update must be blocked if less than total placed weight.
    UPDATE rack
    SET max_load = 4.00
    WHERE id_rack = v_rack_id;

    -- BEFORE UPDATE trigger returns NULL => update skipped, value should remain 500.00
    IF (SELECT max_load FROM rack WHERE id_rack = v_rack_id) <> 500.00 THEN
        RAISE EXCEPTION 'check_rack_max_load failed: max_load was updated below current weight';
    END IF;
END;
$$;

DO $$
DECLARE
    v_expected integer;
    v_actual integer;
BEGIN
    -- Test #1: get_expiring_products should match equivalent manual query.
    SELECT COUNT(*)
    INTO v_expected
    FROM client cl
    JOIN tenancy t USING (id_client)
    JOIN placement pl USING (id_tenancy)
    JOIN product pr USING (id_product)
    JOIN contract ct USING (id_contract)
    WHERE cl.company_name = 'рога и копыта'
      AND ct.end_date < DATE '2027-12-31';

    SELECT get_expiring_products('рога и копыта', DATE '2027-12-31')
    INTO v_actual;

    IF v_actual <> v_expected THEN
        RAISE EXCEPTION 'get_expiring_products mismatch: expected %, got %', v_expected, v_actual;
    END IF;

    IF get_expiring_products('NO_SUCH_CLIENT', DATE '2027-12-31') <> 0 THEN
        RAISE EXCEPTION 'get_expiring_products should return 0 for unknown client';
    END IF;
END;
$$;

DO $$
DECLARE
    v_expected text;
    v_actual text;
BEGIN
    -- Test #2: aggregate max_size should match direct MAX() projection.
    SELECT format('%s X %s X %s', MAX(height), MAX(width), MAX(length))
    INTO v_expected
    FROM product;

    SELECT max_size(height, width, length)
    INTO v_actual
    FROM product;

    IF v_actual IS DISTINCT FROM v_expected THEN
        RAISE EXCEPTION 'max_size mismatch: expected "%", got "%"', v_expected, v_actual;
    END IF;
END;
$$;

DO $$
DECLARE
    v_old_bank_details text;
    v_new_bank_details text := 'TEST-LAB10-BANK-DETAILS';
BEGIN
    -- Test #3: update through client_view should change underlying client row.
    SELECT bank_details
    INTO v_old_bank_details
    FROM client
    WHERE company_name = 'ООО СеверТорг'
    LIMIT 1;

    IF v_old_bank_details IS NULL THEN
        RAISE EXCEPTION 'Test client for client_view not found';
    END IF;

    UPDATE client_view
    SET bank_details = v_new_bank_details
    WHERE company_name = 'ООО СеверТорг'
      AND bank_details = v_old_bank_details;

    IF (SELECT bank_details FROM client WHERE company_name = 'ООО СеверТорг' LIMIT 1) <> v_new_bank_details THEN
        RAISE EXCEPTION 'client_view update did not propagate to client table';
    END IF;

    -- Restore original value to keep dataset stable.
    UPDATE client
    SET bank_details = v_old_bank_details
    WHERE company_name = 'ООО СеверТорг'
      AND bank_details = v_new_bank_details;
END;
$$;

DO $$
DECLARE
    v_item text;
    v_deleted_count integer;
BEGIN
    -- Test #4: queue API behavior
    PERFORM init();

    IF dequeue() IS NOT NULL THEN
        RAISE EXCEPTION 'dequeue() on empty queue should return NULL';
    END IF;

    IF tail() IS NOT NULL THEN
        RAISE EXCEPTION 'tail() on empty queue should return NULL';
    END IF;

    IF enqueue('first') <> 'first' THEN
        RAISE EXCEPTION 'enqueue("first") returned unexpected value';
    END IF;
    IF enqueue('second') <> 'second' THEN
        RAISE EXCEPTION 'enqueue("second") returned unexpected value';
    END IF;
    IF enqueue('third') <> 'third' THEN
        RAISE EXCEPTION 'enqueue("third") returned unexpected value';
    END IF;

    IF tail() <> 'third' THEN
        RAISE EXCEPTION 'tail() should return last element "third"';
    END IF;

    SELECT dequeue() INTO v_item;
    IF v_item <> 'first' THEN
        RAISE EXCEPTION 'FIFO violated: first dequeue expected "first", got "%"', v_item;
    END IF;

    SELECT dequeue() INTO v_item;
    IF v_item <> 'second' THEN
        RAISE EXCEPTION 'FIFO violated: second dequeue expected "second", got "%"', v_item;
    END IF;

    SELECT empty() INTO v_deleted_count;
    IF v_deleted_count <> 1 THEN
        RAISE EXCEPTION 'empty() expected to remove 1 item, removed %', v_deleted_count;
    END IF;

    IF dequeue() IS NOT NULL THEN
        RAISE EXCEPTION 'dequeue() after empty() should return NULL';
    END IF;

    -- Length limit check (more than 64 chars must fail).
    BEGIN
        PERFORM enqueue(repeat('x', 65));
        RAISE EXCEPTION 'enqueue() accepted value longer than 64 chars';
    EXCEPTION
        WHEN SQLSTATE '22001' THEN
            NULL;
    END;
END;
$$;

ROLLBACK;

SELECT 'lab10 tests passed' AS result;

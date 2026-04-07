BEGIN;

-- 1) room: 4 rows
INSERT INTO public.room (id_room, room_name, capacity_volume, temp_conditions, humidity_conditions)
VALUES
    (1, 'Камера А', 1200.00, 6, 60),
    (2, 'Камера Б', 950.00, 4, 58),
    (3, 'Сухой склад 1', 1800.00, 18, 45),
    (4, 'Сухой склад 2', 2100.00, 20, 40);

-- 2) client: 11 rows
INSERT INTO public.client (id_client, company_name, bank_details)
VALUES
    (1, 'ООО СеверТорг', 'р/с 40702810000000000001, БИК 044525001, АО Банк Развития'),
    (2, 'АО Городской Ритейл', 'р/с 40702810000000000002, БИК 044525002, ПАО Надежный Банк'),
    (3, 'ООО Вектор Логистик', 'р/с 40702810000000000003, БИК 044525003, ПАО Банк Партнер'),
    (4, 'ООО ФермаПлюс', 'р/с 40702810000000000004, БИК 044525004, АО Аграрный Банк'),
    (5, 'ЗАО ПродуктИмпорт', 'р/с 40702810000000000005, БИК 044525005, АО Финанс Групп'),
    (6, 'ООО АльфаПоставка', 'р/с 40702810000000000006, БИК 044525006, ПАО Столичный Банк'),
    (7, 'ООО БетаСервис', 'р/с 40702810000000000007, БИК 044525007, АО Опорный Банк'),
    (8, 'ООО ГаммаТрейд', 'р/с 40702810000000000008, БИК 044525008, ПАО Содействие'),
    (9, 'ООО ДельтаМаркет', 'р/с 40702810000000000009, БИК 044525009, АО Универсал Банк'),
    (10, 'ООО ЕнисейСнаб', 'р/с 40702810000000000010, БИК 044525010, ПАО Федеральный Банк'),
    (11, 'рога и копыта', 'р/с 40702810000000000011, БИК 044525011, АО Народный Банк');

-- 3) contract: 40 rows
INSERT INTO public.contract (id_contract, contract_number, end_date)
SELECT
    g AS id_contract,
    'ДОГ-' || to_char(g, 'FM0000') AS contract_number,
    CURRENT_DATE + (365 + g) AS end_date
FROM generate_series(1, 40) AS g;

-- 4) rack: 100 rows
INSERT INTO public.rack (id_rack, rack_number, storage_slots, max_load, height, width, length, id_room)
SELECT
    g AS id_rack,
    'Стеллаж-' || to_char(g, 'FM000') AS rack_number,
    20 + (g % 11) AS storage_slots,
    CASE
        WHEN g <= 20 THEN 70.00 + (g * 1.20)
        ELSE 220.00 + (g * 3.00)
    END AS max_load,
    2.500 + ((g % 5) * 0.100) AS height,
    1.200 + ((g % 4) * 0.050) AS width,
    0.900 + ((g % 3) * 0.050) AS length,
    ((g - 1) % 4) + 1 AS id_room
FROM generate_series(1, 100) AS g;

-- 5) tenancy: 100 rows
-- one tenancy per rack because tenancy.id_rack is unique
INSERT INTO public.tenancy (id_tenancy, id_client, id_rack)
SELECT
    g AS id_tenancy,
    ((g - 1) % 11) + 1 AS id_client,
    g AS id_rack
FROM generate_series(1, 100) AS g;

-- 6) product: 1000 rows
INSERT INTO public.product (
    id_product,
    description,
    length,
    width,
    height,
    weight,
    arrival_date,
    temp_conditions,
    humidity_conditions,
    "position",
    id_contract
)
SELECT
    g AS id_product,
    'Товар партия №' || to_char(g, 'FM000000') AS description,
    0.200 + ((g % 7) * 0.050) AS length,
    0.150 + ((g % 6) * 0.040) AS width,
    0.100 + ((g % 5) * 0.030) AS height,
    2.00 + ((g % 20) * 0.75) AS weight,
    CURRENT_DATE - (g % 365) AS arrival_date,
    2 + (g % 25) AS temp_conditions,
    30 + (g % 50) AS humidity_conditions,
    ((g - 1) % 10) + 1 AS "position",
    ((g - 1) % 40) + 1 AS id_contract
FROM generate_series(1, 1000) AS g;

-- 7) placement: 1000 rows
-- one placement per product because placement.id_product is unique
-- deterministic pseudo-random tenancy assignment for uneven rack utilization
INSERT INTO public.placement (id_placement, id_product, id_tenancy)
SELECT
    g AS id_placement,
    g AS id_product,
    (((g * g + 31 * g + 7) % 1000) / 10)::integer + 1 AS id_tenancy
FROM generate_series(1, 1000) AS g;

COMMIT;

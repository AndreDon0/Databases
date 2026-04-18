-- 0. Выберите суммарный вес товаров, хранящихся на складе.
SELECT SUM(weight) AS total_weight 
FROM product;

-- 1. Выберите трёх клиентов, хранящих наибольшее число товаров по суммарному объёму.
SELECT bank_details,
       company_name,
       COALESCE(SUM(pr.length * pr.width * pr.height), 0) AS total_volume
FROM client cl
     LEFT JOIN tenancy ten USING (id_client)
     LEFT JOIN placement pl USING (id_tenancy)
     LEFT JOIN product pr USING (id_product)
GROUP BY id_client, bank_details, company_name
ORDER BY total_volume DESC
LIMIT 3;

-- 2. Выберите все стеллажи с указанием их загруженности по количество товаров, включая пустые стеллажи.
SELECT rack_number, COUNT(pl.id_product) AS total_products
FROM rack r LEFT JOIN tenancy ten USING (id_rack)
             LEFT JOIN placement pl USING (id_tenancy)
GROUP BY id_rack, rack_number  -- так как двойной ключ
ORDER BY total_products DESC, rack_number;

-- 3. Удалите все товары, лежащие на стеллажах с максимальной нагрузкой меньше 100 кг, включая ссылки на них.
WITH target_products_to_delete AS (
    SELECT pl.id_product
    FROM placement pl 
            JOIN tenancy ten USING (id_tenancy)
            JOIN rack r USING (id_rack)
    WHERE r.max_load < 100
), deleted_products AS (
    DELETE FROM placement
    WHERE id_product IN (SELECT id_product FROM target_products_to_delete)
    RETURNING id_product
)
DELETE FROM product
WHERE id_product IN (SELECT id_product FROM deleted_products);

-- 4. Измените даты окончания договора у всех товаров фирмы «рога и копыта», добавив к ним один дополнительный месяц.
UPDATE contract
SET end_date = end_date + INTERVAL '1 month'
WHERE id_contract IN (
    SELECT id_contract
    FROM contract JOIN product USING (id_contract)
                  JOIN placement USING (id_product)
                  JOIN tenancy USING (id_tenancy)
                  JOIN client USING (id_client)
    WHERE client.company_name = 'рога и копыта'
);

-- 5. Добавьте в базу данных информацию о хрупкости товаров, не создавая новых таблиц.
ALTER TABLE product ADD COLUMN IF NOT EXISTS is_fragile BOOLEAN DEFAULT FALSE;

-- 6. Добавьте в базу данных ограничение целостности, контролирующие, чтобы вес товара не превышал 500 кг.
DO $$ BEGIN
    ALTER TABLE product ADD CONSTRAINT ck_product_weight_max_500 CHECK (weight <= 500);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
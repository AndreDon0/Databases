-- 0. Запрос, выбирающий без повторений номер стеллажа, название помещения, 
-- суммарный вес товаров на стеллаже, средний вес товаров в помещении.

SELECT DISTINCT ON (r.id_rack)
    r.rack_number AS shelf_number,
    rm.room_name,
    SUM(p.weight) OVER (PARTITION BY r.id_rack) AS shelf_weight,
    AVG(p.weight) OVER (PARTITION BY rm.id_room) AS avg_room_weight
FROM room rm
JOIN rack r ON r.id_room = rm.id_room
JOIN tenancy t USING (id_rack)
JOIN placement pl USING (id_tenancy)
JOIN product p USING (id_product)
ORDER BY r.id_rack;

-- 1. Запрос, выбирающий название помещения и в виде одного столбца через запятую
-- юридческие адреса клиентов – владельцев данных товаров.

SELECT
    rm.room_name,
    STRING_AGG(DISTINCT c.bank_details, ', ' ORDER BY c.bank_details)
        FILTER (WHERE pl.id_placement IS NOT NULL) AS bank_details
FROM room rm
LEFT JOIN rack r ON r.id_room = rm.id_room
LEFT JOIN tenancy t USING (id_rack)
LEFT JOIN placement pl USING (id_tenancy)
LEFT JOIN client c ON c.id_client = t.id_client
GROUP BY rm.room_name;
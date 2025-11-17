CREATE MATERIALIZED VIEW total_laundry_rooms_per_dormitory AS
    SELECT dormitory_number, 
        SUM(laundry_exists::int) AS total_laundry_rooms
    FROM dormitories JOIN floors USING (dormitory_number)
    GROUP BY dormitory_number;

SELECT * FROM total_laundry_rooms_per_dormitory;

CREATE VIEW total_laundry_rooms_per_dormitory2 AS
    SELECT dormitory_number, 
        SUM(laundry_exists::int) AS total_laundry_rooms
    FROM dormitories JOIN floors USING (dormitory_number)
    GROUP BY dormitory_number;

SELECT * FROM total_laundry_rooms_per_dormitory2;

INSERT INTO floors (floor_id, dormitory_number, floor_number, laundry_exists, rooms_count) 
    VALUES (813, 3, 5, TRUE, 123);

REFRESH MATERIALIZED VIEW total_laundry_rooms_per_dormitory;
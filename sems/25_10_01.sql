/*
SELECT re.first_name, re.second_name, re.last_name, d.dormitory_number, fla.flat_number
  FROM residents AS re
       LEFT JOIN rooms AS ro ON re.room_id = ro.room_id
       LEFT JOIN flats AS fla ON ro.flat_id = fla.flat_id
       LEFT JOIN floors AS flo ON fla.floor_id = flo.floor_id
       LEFT JOIN dormitories AS d ON flo.dormitory_number = d.dormitory_number;
*/

SELECT d.dormitory_number, COUNT(*)
  FROM residents AS re
       LEFT JOIN rooms AS ro ON re.room_id = ro.room_id
       LEFT JOIN flats AS fla ON ro.flat_id = fla.flat_id
       LEFT JOIN floors AS flo ON fla.floor_id = flo.floor_id
       LEFT JOIN dormitories AS d ON flo.dormitory_number = d.dormitory_number
GROUP BY d.dormitory_number;

SELECT flo.floor_id, COUNT(*)
  FROM flats AS fla
       LEFT JOIN floors AS flo ON fla.floor_id = flo.floor_id
GROUP BY flo.floor_id;

SELECT re.first_name AS residents_first_name,
       re.second_name AS residents_second_name,
       re.last_name AS residents_last_name,
       co.first_name AS commandants_first_name,
       co.second_name AS commandants_second_name,
       co.last_name AS commandants_last_name
  FROM residents AS re
       LEFT JOIN rooms AS ro ON re.room_id = ro.room_id
       LEFT JOIN flats AS fla ON ro.flat_id = fla.flat_id
       LEFT JOIN floors AS flo ON fla.floor_id = flo.floor_id
       LEFT JOIN dormitories AS d ON flo.dormitory_number = d.dormitory_number
       RIGHT JOIN commandants AS co ON d.dormitory_number = co.dormitory_number;

  SELECT d.dormitory_number, AVG(ro.residents_count)
    FROM rooms AS ro
         LEFT JOIN flats AS fla ON ro.flat_id = fla.flat_id
         LEFT JOIN floors AS flo ON fla.floor_id = flo.floor_id
         LEFT JOIN dormitories AS d ON flo.dormitory_number = d.dormitory_number
GROUP BY d.dormitory_number;
--   SELECT room_id, COUNT(room_id) AS count_students
--     FROM residents
-- GROUP BY room_id
--   HAVING COUNT(room_id) > 1;

SELECT first_name, second_name, last_name
  FROM residents
 WHERE room_id IN (
       SELECT room_id
         FROM residents
     GROUP BY room_id
       HAVING COUNT(room_id) > AVG(room_id)  
       );
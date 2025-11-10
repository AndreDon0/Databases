/* Задачи по теме "Рекурсивные запросы" */

/* Таблицы этапов работ 
 * id -- идентификатор текущего этапа 
 * stage_name -- название текущего этапа 
 * duration -- длительность текущего этапа 
 * next_stage_id -- идентификатор следующего этапа */

CREATE TABLE work_stages (
    id SERIAL PRIMARY KEY,
    stage_name TEXT NOT NULL,
    duration INTERVAL NOT NULL,
    next_stage_id INT REFERENCES work_stages(id)
);

INSERT INTO work_stages (id, stage_name, duration, next_stage_id)
VALUES
(1, 'Подготовка площадки', INTERVAL '4 hours', 2),
(2, 'Сборка основы', INTERVAL '5 hours', 3),
(3, 'Монтаж электроники', INTERVAL '6 hours', 4),
(4, 'Тестирование', INTERVAL '4 hours', 5),
(5, 'Упаковка', INTERVAL '2 hours', NULL),
(6, 'Производство корпуса', INTERVAL '10 hours', 3),
(7, 'Производство кабеля', INTERVAL '8 hours', 3);

SELECT *
  FROM work_stages;

/* 1. Определите все начальные этапы (коревые узлы) и заключительные этапы (листовые узлы).
 * * Задачу необходимо выполнить без использования рекурсивных выражений. */
CREATE VIEW end_stages AS
SELECT *
  FROM work_stages
 WHERE next_stage_id IS NULL;

CREATE VIEW start_stages AS
SELECT *
  FROM work_stages
 WHERE id NOT IN (SELECT next_stage_id
                    FROM work_stages
                   WHERE next_stage_id IS NOT NULL);

SELECT * FROM end_stages;

SELECT * FROM start_stages;

/* 2. Напишите запрос, выводящий все этапы, предшествующие тестированию. */
WITH RECURSIVE test_stages AS (
    SELECT *
      FROM work_stages
     WHERE stage_name = 'Тестирование'

    UNION ALL

    SELECT ws.*
      FROM work_stages ws
           JOIN test_stages ts ON ws.next_stage_id = ts.id
)
SELECT *
  FROM test_stages
 WHERE stage_name != 'Тестирование';

/* 3. Напишите запрос, который выводит все сквозные цепочки и суммарное время их выполнения. 
 * Под сквозной цепочкой понимается путь от первого этапа (этапа, на который не 
 * ссылается ни один этап) до заключительного (этап, который не ссылается на другие). */

WITH RECURSIVE chains AS (
    SELECT id, 
           stage_name AS chain_name, 
           duration AS chain_duration, 
           next_stage_id
      FROM start_stages
    
    UNION ALL

    SELECT ws.id, 
           c.chain_name|| ' -> ' || ws.stage_name AS chain_name, 
           chain_duration + duration AS chain_duration, 
           ws.next_stage_id
      FROM work_stages ws
           JOIN chains c ON ws.id = c.next_stage_id
)
SELECT chain_name, chain_duration FROM chains;

/* 4. Напишите запрос, который позволяет определить, на каком "уровне" относительно корня
 * располагаются все этапы. Исходный уровень примите равным 0. */

WITH RECURSIVE levels AS (
    SELECT *,
           4 AS level
      FROM end_stages

    UNION ALL

    SELECT ws.*, 
           l.level - 1 AS level
      FROM work_stages ws
           JOIN levels l ON ws.next_stage_id = l.id
)
  SELECT stage_name, duration, level
    FROM levels
ORDER BY level;

/* 5. Напишите запрос, определяющий время ожидания начала каждого из этапов. */

WITH RECURSIVE chains AS (
    SELECT id, 
           stage_name AS chain_name, 
           INTERVAL '0 hours' AS chain_duration, 
           next_stage_id
      FROM start_stages
    
    UNION ALL

    SELECT ws.id, 
           c.chain_name|| ' -> ' || ws.stage_name AS chain_name, 
           chain_duration + duration AS chain_duration, 
           ws.next_stage_id
      FROM work_stages ws
           JOIN chains c ON ws.id = c.next_stage_id
)
SELECT chain_name, chain_duration FROM chains;

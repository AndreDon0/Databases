DROP TABLE IF EXISTS accomodations CASCADE;

DROP TABLE IF EXISTS residents CASCADE;
DROP TABLE IF EXISTS dormitories CASCADE;
DROP TABLE IF EXISTS floors CASCADE;
DROP TABLE IF EXISTS flats CASCADE;
DROP TABLE IF EXISTS rooms CASCADE;
DROP TABLE IF EXISTS commandants CASCADE;
DROP TABLE IF EXISTS groups CASCADE;


CREATE TABLE groups (
	group_name varchar(32) PRIMARY KEY,
	department_name varchar(256) NOT NULL
);

CREATE TABLE dormitories(
	dormitory_number integer PRIMARY KEY,
	city varchar(32) NOT NULL,
	street varchar(32) NOT NULL,
	house varchar(32) NOT NULL,
	dormitory_type varchar(32) NOT NULL,
	places_count integer NOT NULL,
	students_count integer NOT NULL,
	rooms_count integer NOT NULL,
	CHECK(dormitory_type IN(
		'Коридорная',
		'Блочная',
		'Квартирная'
	)),
	CHECK(places_count >= 0),
	CHECK(students_count >= 0),
	CHECK(rooms_count >= 0),
	UNIQUE(city, street, house)
);

CREATE TABLE floors (
	floor_id SMALLINT PRIMARY KEY,
	floor_number SMALLINT NOT NULL,
	laundry_exists boolean NOT NULL,
	rooms_count integer NOT NULL,
	dormitory_number integer REFERENCES dormitories(dormitory_number),
	CHECK(rooms_count >= 0)
);

CREATE TABLE flats(
	flat_id integer PRIMARY key,
	flat_number integer NOT NULL,
	rooms_count integer NOT NULL,
	residents_count integer NOT NULL,
	floor_id integer REFERENCES floors(floor_id),
	CHECK(rooms_count >= 0),
	CHECK(residents_count >= 0)
);

CREATE TABLE rooms(
	room_id integer PRIMARY key,
	room_number integer NOT NULL,
	residents_count integer NOT NULL,
	places_count integer NOT NULL,
	flat_id integer,
	FOREIGN KEY (flat_id) REFERENCES flats(flat_id),
	CHECK(residents_count >= 0),
	CHECK(places_count >= 0)
);

CREATE TABLE residents (
  first_name varchar(64) NOT NULL,
  second_name varchar(64) NOT NULL,
  last_name varchar(64),
  birth_date date NOT NULL,
  passport_series varchar(4),
  passport_number varchar(6),
  snils varchar(11) NOT NULL UNIQUE,
  inn varchar(12) NOT NULL UNIQUE,
  group_name varchar(32) REFERENCES GROUPS(group_name),
  room_id integer REFERENCES rooms(room_id),
  PRIMARY KEY (passport_series, passport_number)
);



CREATE TABLE commandants (
	first_name varchar(64),
	second_name varchar(64),
	last_name varchar(64),
	dormitory_number integer REFERENCES dormitories(dormitory_number),
	PRIMARY KEY (first_name, second_name, last_name)
); 

INSERT INTO groups (group_name, department_name) VALUES
('ИТ-101', 'Информационные технологии и программирование'),
('ИТ-102', 'Информационные технологии и программирование'),
('МЕД-201', 'Лечебное дело'),
('ЭКО-301', 'Экономика и бухгалтерский учет'),
('СТР-401', 'Строительство и эксплуатация зданий');
INSERT INTO dormitories (dormitory_number, city, street, house, dormitory_type, places_count, students_count, rooms_count) VALUES
(1, 'Москва', 'Ленинградский проспект', '25к1', 'Коридорная', 200, 180, 50),
(2, 'Москва', 'Профсоюзная', '12', 'Квартирная', 120, 115, 30),
(3, 'Москва', 'Мичуринский проспект', '8', 'Блочная', 150, 140, 40);
INSERT INTO floors (floor_id, floor_number, laundry_exists, rooms_count, dormitory_number) VALUES
(1, 1, true, 12, 1),
(2, 2, false, 12, 1),
(3, 3, true, 13, 1),
(4, 4, false, 13, 1),
(5, 1, true, 8, 2),
(6, 2, true, 7, 2),
(7, 3, false, 8, 2),
(8, 1, true, 10, 3),
(9, 2, false, 10, 3),
(10, 3, true, 10, 3),
(11, 4, false, 10, 3);
INSERT INTO flats (flat_id, flat_number, rooms_count, residents_count, floor_id) VALUES
-- Коридорное общежитие №1 (каждая комната = квартира)
(1, 101, 1, 2, 1),
(2, 102, 1, 3, 1),
(3, 103, 1, 2, 1),
(4, 104, 1, 3, 1),
(5, 105, 1, 2, 1),
(6, 106, 1, 3, 1),
(7, 201, 1, 2, 2),
(8, 202, 1, 2, 2),
(9, 203, 1, 3, 2),
(10, 301, 1, 2, 3),
(11, 302, 1, 3, 3),
-- Квартирное общежитие №2 (многокомнатные квартиры)
(12, 101, 3, 6, 5),
(13, 102, 2, 4, 5),
(14, 201, 3, 5, 6),
(15, 202, 2, 4, 6),
(16, 301, 3, 6, 7),
(17, 302, 2, 3, 7),
-- Блочное общежитие №3 (каждая комната = квартира)
(18, 101, 1, 2, 8),
(19, 102, 1, 2, 8),
(20, 103, 1, 2, 8),
(21, 104, 1, 2, 8),
(22, 201, 1, 2, 9),
(23, 202, 1, 2, 9),
(24, 301, 1, 2, 10),
(25, 302, 1, 2, 10);
INSERT INTO rooms (room_id, room_number, residents_count, places_count, flat_id) VALUES
-- Коридорное общежитие №1 (одна комната в каждой квартире)
(1, 1, 2, 3, 1),
(2, 1, 3, 3, 2),
(3, 1, 2, 3, 3),
(4, 1, 3, 3, 4),
(5, 1, 2, 3, 5),
(6, 1, 3, 3, 6),
(7, 1, 2, 3, 7),
(8, 1, 2, 3, 8),
(9, 1, 3, 3, 9),
(10, 1, 2, 3, 10),
(11, 1, 3, 3, 11),
-- Квартирное общежитие №2 (несколько комнат в квартире)
(12, 1, 2, 2, 12),
(13, 2, 2, 2, 12),
(14, 3, 2, 2, 12),
(15, 1, 2, 2, 13),
(16, 2, 2, 2, 13),
(17, 1, 2, 2, 14),
(18, 2, 2, 2, 14),
(19, 3, 1, 2, 14),
(20, 1, 2, 2, 15),
(21, 2, 2, 2, 15),
(22, 1, 2, 2, 16),
(23, 2, 2, 2, 16),
(24, 3, 2, 2, 16),
(25, 1, 2, 2, 17),
(26, 2, 1, 2, 17),
-- Блочное общежитие №3 (одна комната в каждой квартире)
(27, 1, 2, 2, 18),
(28, 1, 2, 2, 19),
(29, 1, 2, 2, 20),
(30, 1, 2, 2, 21),
(31, 1, 2, 2, 22),
(32, 1, 2, 2, 23),
(33, 1, 2, 2, 24),
(34, 1, 2, 2, 25);
INSERT INTO commandants (first_name, second_name, last_name, dormitory_number) VALUES
('Ирина', 'Петровна', 'Смирнова', 1),
('Ольга', 'Владимировна', 'Козлова', 2),
('Сергей', 'Иванович', 'Петров', 3);
INSERT INTO residents (first_name, second_name, last_name, birth_date, passport_series, passport_number, snils, inn, group_name, room_id) VALUES
('Александр', 'Иванов', 'Петрович', '2000-03-15', '4510', '123456', '12345678901', '123456789012', 'ИТ-101', 1),
('Мария', 'Петрова', 'Сергеевна', '2001-07-22', '4511', '654321', '12345678902', '123456789013', 'ИТ-101', 1),
('Дмитрий', 'Сидоров', 'Алексеевич', '2000-11-30', '4512', '789123', '12345678903', '123456789014', 'ИТ-101', 2),
('Екатерина', 'Кузнецова', 'Дмитриевна', '2001-02-14', '4513', '456789', '12345678904', '123456789015', 'МЕД-201', 2),
('Артем', 'Васильев', 'Олегович', '2000-09-08', '4514', '987654', '12345678905', '123456789016', 'ИТ-102', 2),
('Анна', 'Попова', 'Игоревна', '2001-12-03', '4515', '321654', '12345678906', '123456789017', 'МЕД-201', 3),
('Михаил', 'Соколов', 'Викторович', '2000-05-19', '4516', '654987', '12345678907', '123456789018', 'ЭКО-301', 4),
('Ольга', 'Морозова', 'Андреевна', '2001-08-25', '4517', '147258', '12345678908', '123456789019', 'ЭКО-301', 4),
('Иван', 'Новиков', 'Павлович', '2000-01-11', '4518', '258369', '12345678909', '123456789020', 'СТР-401', 4),
('София', 'Федорова', 'Романовна', '2001-04-17', '4519', '369147', '12345678910', '123456789021', 'СТР-401', 5),
('Павел', 'Волков', 'Денисович', '2000-06-23', '4520', '741852', '12345678911', '123456789022', 'ИТ-102', 6),
('Наталья', 'Алексеева', 'Витальевна', '2001-10-29', '4521', '852963', '12345678912', '123456789023', 'МЕД-201', 7),
('Кирилл', 'Лебедев', 'Сергеевич', '2000-02-04', '4522', '963741', '12345678913', '123456789024', 'ЭКО-301', 8),
('Виктория', 'Семенова', 'Анатольевна', '2001-05-10', '4523', '159753', '12345678914', '123456789025', 'СТР-401', 9),
('Роман', 'Егоров', 'Михайлович', '2000-08-16', '4524', '357159', '12345678915', '123456789026', 'ИТ-101', 10),
('Алина', 'Павлова', 'Олеговна', '2001-11-21', '4525', '753951', '12345678916', '123456789027', 'МЕД-201', 11),
('Андрей', 'Ковалев', 'Владимирович', '2000-04-27', '4526', '951357', '12345678917', '123456789028', 'ЭКО-301', 12),
('Елена', 'Орлова', 'Борисовна', '2001-09-02', '4527', '284617', '12345678918', '123456789029', 'СТР-401', 13),
('Владимир', 'Андреев', 'Геннадьевич', '2000-12-08', '4528', '617284', '12345678919', '123456789030', 'ИТ-102', 27),
('Татьяна', 'Макарова', 'Юрьевна', '2001-03-14', '4529', '739185', '12345678920', '123456789031', 'МЕД-201', 28);




select * from residents;

select * from residents
order by last_name 
offset 5 rows
limit 5
;


--1. Вывести всех студентов с номером комнаты и квартиры.
SELECT first_name, second_name, last_name, room_number, flat_number
  FROM residents AS re 
       INNER JOIN rooms AS ro ON ro.room_id = re.room_id
       INNER JOIN flats AS fl ON ro.flat_id = fl.flat_id;

SELECT first_name, second_name, last_name, room_number, flat_number
  FROM residents AS re
       NATURAL JOIN rooms AS ro
       NATURAL JOIN flats AS fl;

--2. Вывести комендантов и номера их общежитий.
select first_name, second_name, last_name, co.dormitory_number,
CONCAT(city, ', ', street, ', ', house) AS address
from commandants co
inner join dormitories dom on dom.dormitory_number = co.dormitory_number;

INSERT INTO commandants (first_name, second_name, last_name, dormitory_number) VALUES 
('Олег', 'Владимирович', 'Некозлов', NULL);

-- select first_name, second_name, last_name, co.dormitory_number
-- from commandants co
-- left join dormitories dom on dom.dormitory_number = co.dormitory_number
-- WHERE dom.c IS NULL;


--3. Вывести студентов с информацией о корпусе и этаже.
select first_name, second_name, last_name, CONCAT(city, ', ', street, ', ', house), flo.floor_id
from residents as re
inner join rooms as ro on ro.room_id = re.room_id
inner join flats as fl on fl.flat_id = ro.flat_id
inner join floors as flo on flo.floor_id = fl.floor_id
inner join dormitories as dom on dom.dormitory_number = flo.dormitory_number;

--4. Количество студентов в каждой комнате с деталями квартиры.


--5. Список этажей и количества квартир на каждом.


--6. Студенты с их комендантом.


--7. Список студентов с числом мест в их комнате.





--1. Количество студентов в каждом общежитии.
select count(residents) as cnt, concat(city, ', ', street, ', ', house) from residents
inner join rooms on residents.room_id = rooms.room_id
inner join flats on rooms.flat_id = flats.flat_id
inner join floors on flats.floor_id = floors.floor_id
inner join dormitories on floors.dormitory_number = dormitories.dormitory_number
group by concat(city, ', ', street, ', ', house)
having count(residents) > 5;

--2. Количество квартир на каждом этаже.
select concat(dormitories.city, ', ', dormitories.street, ', ', dormitories.house)
,count(flats.flat_id)
,floors.floor_number
from flats
-- inner join flats on rooms.flat_id = flats.flat_id
inner join floors on flats.floor_id = floors.floor_id
inner join dormitories on dormitories.dormitory_number = floors.dormitory_number
group by floors.floor_id, dormitories.dormitory_number
;

--3. Среднее количество студентов на комнату для каждого общежития.


--4. Общее количество студентов по отделам (groups).


--5. Количество студентов на каждом этаже.


--6. Количество комнат на этаж с хотя бы одним студентом.


--7. Посчитать количество студентов в каждой комнате и вывести только комнаты, где больше 1 студента.




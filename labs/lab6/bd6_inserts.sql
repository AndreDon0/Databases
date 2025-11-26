DROP TABLE IF EXISTS bd6_departments CASCADE;
DROP TABLE IF EXISTS bd6_employees CASCADE;

CREATE TABLE bd6_departments(
  id integer PRIMARY KEY,
  name varchar(64),
  postal_code varchar(6),
  street varchar(64),
  building varchar(16),
  city varchar(32)
);
CREATE TABLE bd6_employees(
  id integer PRIMARY KEY,
  last_name varchar(64) NOT NULL,
  first_name varchar(64) NOT NULL,
  phone_number varchar(18),
  email varchar(32),
  department_id integer REFERENCES bd6_departments(id) NOT NULL,
  manager_id integer REFERENCES bd6_employees(id),
  salary_in_euro numeric(8, 2)  DEFAULT 0 NOT NULL,
  UNIQUE(last_name, first_name, department_id)
);

INSERT INTO bd6_departments 
VALUES(10, 'Administration', '109658', 'Leningradskoe shosse', '1', 'Moscow'),
(20, 'Marketing', '107701', 'Lenina', '22a', 'Volgograd'),
(30, 'Purchasing', '109901', 'Mikluho-Maklaya', '8', 'Bryansk'),
(40, 'Human Resources', '10967', '5-ya parkovaya', '16', 'Moscow'),
(50, 'Shipping', '109659', '38 Bakinskih komissarov', '77', 'Moscow'),
(60, 'IT', '109902', 'Pervomajskaya', '33', 'Kirov');

INSERT INTO bd6_employees VALUES(1, 'Radygin', 'Victor', '8-(495)-567-7788', 'vr@e.mail.mephi.ru', 10, NULL, 8000),
(2, 'Kuprijanov', 'Dmitrij', '8-(495)-567-7794', 'kd@e.mail.mephi.ru', 60, 1, 6534.33),
(3, 'Ivanov-Skladovskij', 'Ivan', '8-(495)-567-7799', 'ii1@mail.mephi.ru', 20, 1, 4404.14),
(4, 'Petrov', 'Petr', '8-(495)-567-7794', 'petrovpetr@m.gmail.ru', 60, 2, 3456.43),
(5, 'kozlov', 'Konstantin', '8-(495)-567-7794', 'kkozlov@mephi.ru', 60, 2, 2300),
(6, 'Abramov', 'Abram', '8-(495)-567-7794', 'abramova@k75.mephi.ru', 60, 2, 2200.11),
(7, 'Ivanovа-Sklаdovskаya-Petrova', 'Ivanka', '8-(495)-567-7794', 'ii2@mail.mephi.ru', 60, 4, 3756.33),
(8, 'Petrov', 'Ivan', '8-(495)-567-7799', 'petrovivan@m.gmail.ru', 20, 3, 4850),
(9, 'kozlov', 'Ivan', '8-(495)-567-7799', 'ikozlov@mephi.ru', 20, 3, 3460),
(10, 'Abramov', 'Moisej', '8-(495)-567-7794', 'abramovm@k75.mephi.ru', 60, 4, 2345),
(11, 'Petrov', 'Alex', '8-(495)-567-7799', 'petroval@m.gmail.ru', 20, 3, 2465),
(12, 'kozlov', 'Maxim', '8-(495)-567-7799', 'mkozlov@mephi.ru', 20, 3, 2788),
(13, 'Abramov', 'Isyaslav', '8-(495)-567-7738', 'abramovi@k75.mephi.ru', 30, 1, 6500);
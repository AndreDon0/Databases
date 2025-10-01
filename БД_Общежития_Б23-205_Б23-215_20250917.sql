DROP TABLE IF EXISTS residents CASCADE;
DROP TABLE IF EXISTS accomodations CASCADE;
DROP TABLE IF EXISTS floors CASCADE;
DROP TABLE IF EXISTS flats CASCADE;
DROP TABLE IF EXISTS rooms CASCADE;
DROP TABLE IF EXISTS commandants CASCADE;
DROP TABLE IF EXISTS groups CASCADE;


CREATE TABLE groups (
	group_name varchar(32) PRIMARY key,
	department_name varchar(256)
);

CREATE TABLE accomodations(
	accomodation_number integer PRIMARY key,
	city varchar(32),
	street varchar(32),
	house varchar(32),
	accomodation_type varchar(32),
	places_count integer,
	students_count integer,
	rooms_count integer
);

CREATE TABLE floors (
	floor_id SMALLINT PRIMARY key,
	floor_number SMALLINT,
	laundary_exists boolean,
	rooms_count integer,
	accomodation_number integer REFERENCES accomodations(accomodation_number)
);

CREATE TABLE flats(
	flat_id integer PRIMARY key,
	flat_number integer,
	rooms_count integer,
	residents_count integer,
	floor_id integer REFERENCES floors(floor_id)
);

CREATE TABLE rooms(
	room_id integer PRIMARY key,
	room_number integer,
	residents_count integer,
	places_count integer,
	flat_id integer,
	FOREIGN KEY (flat_id) REFERENCES flats(flat_id)
);

CREATE TABLE residents (
  first_name varchar(64),
  second_name varchar(64),
  last_name varchar(64),
  birth_date date,
  passport_series varchar(4),
  passport_number varchar(6),
  snils varchar(11),
  inn varchar(12),
  group_name varchar(32) REFERENCES GROUPS(group_name),
  room_id integer REFERENCES rooms(room_id),
  PRIMARY KEY (passport_series, passport_number)
);

CREATE TABLE commandants (
	first_name varchar(64),
	second_name varchar(64),
	last_name varchar(64),
	accomodation_number integer REFERENCES accomodations(accomodation_number),
	PRIMARY KEY (first_name, second_name, last_name)
);
--****PLEASE ENTER YOUR DETAILS BELOW****
--T3-oo-dm.sql

--Student ID:36436763
--Student Name:Keshu Zhang

--(a)
DROP SEQUENCE address_seq;
CREATE SEQUENCE address_seq START with 500 INCREMENT by 5;

DROP SEQUENCE passenger_seq;
CREATE SEQUENCE passenger_seq START with 500 INCREMENT by 5;

DROP SEQUENCE manifest_seq;
CREATE SEQUENCE manifest_seq START with 500 INCREMENT by 5;


--(b)
SAVEPOINT kohl_book;

-- address
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) 
    VALUES (ADDRESS_SEQ.nextval, '23 Banksia Avenue', 'Melbourne', '3000', 'AUS');

--Dominik
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) 
    VALUES (PASSENGER_SEQ.nextval, 'Dominik', 'Kohl', TO_DATE('12-Oct-1985','dd-Mon-yyyy'), 'M', '+61493336312', 'N', 
                (select address_id from address where upper(address_street) = upper('23 Banksia Avenue') and upper(address_town) = upper('Melbourne') and upper(address_pcode) = upper('3000')), NULL);

--Stella
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) 
    VALUES (PASSENGER_SEQ.nextval, 'Stella', 'Kohl', TO_DATE('26-Jun-2012','dd-Mon-yyyy'), 'F',NULL, 'N', 
                (select address_id from address where upper(address_street) = upper('23 Banksia Avenue') and upper(address_town) = upper('Melbourne') and upper(address_pcode) = upper('3000')),
                (select passenger_id from passenger where upper(passenger_fname) = upper('Dominik') and upper(passenger_lname) = upper('Kohl')) );

--Poppy
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) 
    VALUES (PASSENGER_SEQ.nextval, 'Poppy', 'Kohl', TO_DATE('9-Dec-2015','dd-Mon-yyyy'), 'F',NULL, 'N', 
                (select address_id from address where upper(address_street) = upper('23 Banksia Avenue') and upper(address_town) = upper('Melbourne') and upper(address_pcode) = upper('3000')),
                (select passenger_id from passenger where upper(passenger_fname) = upper('Dominik') and upper(passenger_lname) = upper('Kohl') ));

--manifest
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) 
    VALUES (manifest_seq.nextval, 
                (select passenger_id from passenger where upper(passenger_fname) = upper('Dominik') and upper(passenger_lname) = upper('Kohl')),
                (select cruise_id from cruise where upper(cruise_name) = upper('MELBOURNE TO SINGAPORE')),
                TO_DATE('30-Nov-2025 9:30','dd-Mon-yyyy hh24:mi'),
                (select SHIP_CODE from CABIN where CABIN_NO = '8035'),
                '8035');

INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) 
    VALUES (manifest_seq.nextval, 
                (select passenger_id from passenger where upper(passenger_fname) = upper('Stella') and upper(passenger_lname) = upper('Kohl')),
                (select cruise_id from cruise where upper(cruise_name) = upper('MELBOURNE TO SINGAPORE')),
                TO_DATE('30-Nov-2025 9:30','dd-Mon-yyyy hh24:mi'),
                (select SHIP_CODE from CABIN where CABIN_NO = '8035'),
                '8035');

INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) 
    VALUES (manifest_seq.nextval, 
                (select passenger_id from passenger where upper(passenger_fname) = upper('Poppy') and upper(passenger_lname) = upper('Kohl')),
                (select cruise_id from cruise where upper(cruise_name) = upper('MELBOURNE TO SINGAPORE')),
                TO_DATE('30-Nov-2025 9:30','dd-Mon-yyyy hh24:mi'),
                (select SHIP_CODE from CABIN where CABIN_NO = '8035'),
                '8035');

commit;

--(c)
DELETE FROM manifest
WHERE passenger_id = (
    SELECT passenger_id FROM passenger
    WHERE passenger_fname='Stella' AND passenger_lname='Kohl'
 );

UPDATE MANIFEST set cabin_no = '9015'
where passenger_id in (
        select passenger_id from passenger
        where passenger_fname in ('Dominik', 'Poppy') and passenger_lname = 'Kohl'
);

commit;

--(d)
DELETE FROM manifest
WHERE passenger_id in (
        select passenger_id from passenger
        where passenger_fname in ('Dominik', 'Poppy') and passenger_lname = 'Kohl'
);

commit;

/*****PLEASE ENTER YOUR DETAILS BELOW*****/
--T2-oo-insert.sql

--Student ID:36436763
--Student Name:Keshu Zhang

/* GenAI Acknowledgement and Prompts:
I acknowledge the use of M365 Copliot(https://m365.cloud.microsoft/) 
to generate materials that were included within my final assessment in modified form. 
I entered the following prompts on 24 Oct 2025:
"generate data for address table(address_id, address_street, address_town, address_pcode, country_code), 
passenger table(passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed,address_id,guardian_id)
and manifest table(manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no)
minimum include (i)  15 ADDRESS entries ○ Includes 4 different countries (ii) 30 PASSENGERS entries ○ Includes 5 passengers who are under 18 years of age (iii) 40 MANIFEST entries ○ Includes 5 cruises which uses at least 3 different ships ○ Includes 3 passengers who completed more than 1 cruise ○ Includes 4 passengers who did not show up ○ Includes 5 passengers who book future cruises"

*/

-- Task 2 Load the ADDRESS, PASSENGER and MANIFEST tables with your own
-- test data following the data requirements expressed in the brief

-- =======================================
-- ADDRESS
-- =======================================
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (1, '123 George St', 'Sydney', '2000', 'AUS');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (2, '45 Collins St', 'Melbourne', '3000', 'AUS');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (3, '78 Queen St', 'Brisbane', '4000', 'AUS');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (4, '12 Maple Rd', 'Toronto', 'M5H', 'CAN');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (5, '90 King St', 'Vancouver', 'V6B', 'CAN');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (6, '101 Elm St', 'Ottawa', 'K1A', 'CAN');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (7, '56 Baker St', 'London', 'NW1', 'GBR');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (8, '89 Oxford St', 'London', 'W1D', 'GBR');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (9, '34 High St', 'Manchester', 'M1', 'GBR');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (10, '123 Main St', 'New York', '10001', 'USA');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (11, '88 Wall St', 'New York', '10005', 'USA');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (12, '101 Market St', 'San Francisco', '94103', 'USA');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (13, '77 Broadway', 'Chicago', '60601', 'USA');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (14, '66 Regent St', 'London', 'W1B', 'GBR');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (15, '55 Collins Ave', 'Melbourne', '3001', 'AUS');
INSERT INTO address (address_id, address_street, address_town, address_pcode, country_code) VALUES (16, '10 Queen St', 'Auckland', '1010', 'NZL');

-- =======================================
-- PASSENGER
-- =======================================
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (1, 'John', 'Smith', TO_DATE('15-Jun-1985','dd-Mon-yyyy'), 'M', '555-1234', 'N', 7, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (2, 'Emily', 'Brown', TO_DATE('20-Sep-1990','dd-Mon-yyyy'), 'F', '555-5678', 'Y', 12, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (3, 'Michael', 'Johnson', TO_DATE('12-Mar-2008','dd-Mon-yyyy'), 'M', '555-8765', 'N', 7, 1);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (4, 'Sarah', 'Williams', TO_DATE('25-Jul-2010','dd-Mon-yyyy'), 'F', '555-4321', 'Y', 12, 2);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (5, 'David', 'Jones', TO_DATE('05-Nov-1982','dd-Mon-yyyy'), 'M', '555-1111', 'N', 3, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (6, 'Laura', 'Taylor', TO_DATE('18-Feb-1978','dd-Mon-yyyy'), 'F', '555-2222', 'N', 15, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (7, 'Chris', 'Martin', TO_DATE('30-Dec-2009','dd-Mon-yyyy'), 'X', '555-3333', 'N', 9, 5);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (8, 'Anna', 'Lee', TO_DATE('14-Aug-2012','dd-Mon-yyyy'), 'F', '555-4444', 'N', 15, 6);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (9, 'Robert', 'Clark', TO_DATE('09-Apr-1988','dd-Mon-yyyy'), 'M', '555-5555', 'N', 4, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (10, 'Jessica', 'Hall', TO_DATE('22-Jan-1995','dd-Mon-yyyy'), 'F', '555-6666', 'N', 10, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (11, 'Daniel', 'Allen', TO_DATE('17-May-1980','dd-Mon-yyyy'), 'M', '555-7777', 'N', 8, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (12, 'Sophia', 'Young', TO_DATE('03-Oct-1975','dd-Mon-yyyy'), 'F', '555-8888', 'Y', 14, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (13, 'James', 'King', TO_DATE('11-Jun-2007','dd-Mon-yyyy'), 'M', '555-9999', 'N', 8, 11);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (14, 'Olivia', 'Scott', TO_DATE('29-Sep-2011','dd-Mon-yyyy'), 'F', '555-0000', 'N', 14, 12);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (15, 'Henry', 'Adams', TO_DATE('08-Mar-1983','dd-Mon-yyyy'), 'M', '555-1212', 'N', 6, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (16, 'Grace', 'Evans', TO_DATE('19-Jul-1986','dd-Mon-yyyy'), 'F', '555-1313', 'N', 9, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (17, 'Ethan', 'Turner', TO_DATE('02-Dec-1992','dd-Mon-yyyy'), 'M', '555-1414', 'N', 3, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (18, 'Mia', 'Parker', TO_DATE('23-Aug-1989','dd-Mon-yyyy'), 'F', '555-1515', 'N', 10, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (19, 'Lucas', 'Collins', TO_DATE('30-Apr-1977','dd-Mon-yyyy'), 'M', '555-1616', 'Y', 4, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (20, 'Ella', 'Stewart', TO_DATE('11-Nov-1998','dd-Mon-yyyy'), 'F', '555-1717', 'N', 6, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (21, 'Jack', 'Morris', TO_DATE('14-Feb-1984','dd-Mon-yyyy'), 'X', '555-1818', 'N', 13, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (22, 'Chloe', 'Rogers', TO_DATE('06-Jun-1991','dd-Mon-yyyy'), 'F', '555-1919', 'N', 13, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (23, 'Ryan', 'Cook', TO_DATE('09-Sep-1987','dd-Mon-yyyy'), 'M', '555-2020', 'N', 2, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (24, 'Zoe', 'Bailey', TO_DATE('05-May-1993','dd-Mon-yyyy'), 'F', '555-2121', 'Y', 11, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (25, 'Leo', 'Carter', TO_DATE('03-Mar-1981','dd-Mon-yyyy'), 'M', '555-2223', 'N', 1, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (26, 'Isla', 'Mitchell', TO_DATE('07-Jul-1996','dd-Mon-yyyy'), 'F', '555-2323', 'N', 5, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (27, 'Nathan', 'Perez', TO_DATE('12-Dec-1985','dd-Mon-yyyy'), 'M', '555-2424', 'N', 2, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (28, 'Ruby', 'Roberts', TO_DATE('10-Oct-1994','dd-Mon-yyyy'), 'F', '555-2525', 'N', 7, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (29, 'Oscar', 'Ward', TO_DATE('01-Jan-1979','dd-Mon-yyyy'), 'M', '555-2626', 'Y', 15, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (30, 'Lily', 'Ward', TO_DATE('08-Aug-2018','dd-Mon-yyyy'), 'F', '555-2727', 'Y', 15, 29);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (31, 'Noah', 'Walker', TO_DATE('02-Feb-1988','dd-Mon-yyyy'), 'M', '555-3030', 'N', 1, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (32, 'Ava', 'Green', TO_DATE('10-Oct-1992','dd-Mon-yyyy'), 'F', '555-4040', 'N', 2, NULL);
INSERT INTO passenger (passenger_id, passenger_fname, passenger_lname, passenger_dob, passenger_gender, passenger_contact, passenger_specialneed, address_id, guardian_id) VALUES (33, 'Liam', 'Bennett', TO_DATE('15-May-1985','dd-Mon-yyyy'), 'M', '555-5050', 'N', 16, NULL);



-- =======================================
-- MANIFEST
-- =======================================
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (1, 15, 4, TO_DATE('07-Jul-2025 14:15','dd-Mon-yyyy hh24:mi'), 101, '2023');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (2, 3, 1, TO_DATE('02-Jun-2025 09:50','dd-Mon-yyyy hh24:mi'), 101, '1011');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (3, 1, 3, TO_DATE('16-Jun-2025 08:30','dd-Mon-yyyy hh24:mi'), 103, '110');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (4, 24, 8, TO_DATE('30-Nov-2025 09:30','dd-Mon-yyyy hh24:mi'), 105, '8031');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (5, 4, 1, NULL, 101, '1012');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (6, 9, 2, TO_DATE('16-Jun-2025 09:00','dd-Mon-yyyy hh24:mi'), 102, '2004');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (7, 2, 10, TO_DATE('20-Dec-2025 09:15','dd-Mon-yyyy hh24:mi'), 102, '4033');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (8, 7, 2, TO_DATE('16-Jun-2025 08:45','dd-Mon-yyyy hh24:mi'), 102, '2002');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (9, 6, 9, TO_DATE('06-Dec-2025 14:30','dd-Mon-yyyy hh24:mi'), 101, '2001');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (10, 13, 4, TO_DATE('07-Jul-2025 13:30','dd-Mon-yyyy hh24:mi'), 101, '2001');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (11, 5, 1, TO_DATE('02-Jun-2025 10:00','dd-Mon-yyyy hh24:mi'), 101, '1013');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (12, 26, 10, TO_DATE('20-Dec-2025 09:00','dd-Mon-yyyy hh24:mi'), 102, '4031');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (13, 2, 3, TO_DATE('16-Jun-2025 08:45','dd-Mon-yyyy hh24:mi'), 103, '111');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (14, 3, 10, TO_DATE('20-Dec-2025 09:30','dd-Mon-yyyy hh24:mi'), 102, '4034');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (15, 8, 2, NULL, 102, '2003');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (16, 11, 3, TO_DATE('16-Jun-2025 09:15','dd-Mon-yyyy hh24:mi'), 103, '113');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (17, 27, 8, TO_DATE('30-Nov-2025 09:45','dd-Mon-yyyy hh24:mi'), 105, '8032');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (18, 18, 5, TO_DATE('08-Jul-2025 10:00','dd-Mon-yyyy hh24:mi'), 102, '2012');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (19, 22, 5, TO_DATE('08-Jul-2025 11:00','dd-Mon-yyyy hh24:mi'), 102, '4004');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (20, 1, 9, TO_DATE('06-Dec-2025 14:15','dd-Mon-yyyy hh24:mi'), 101, '1013');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (21, 12, 3, NULL, 103, '114');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (22, 25, 9, TO_DATE('06-Dec-2025 14:00','dd-Mon-yyyy hh24:mi'), 101, '3001');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (23, 19, 5, TO_DATE('08-Jul-2025 10:15','dd-Mon-yyyy hh24:mi'), 102, '2013');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (24, 28, 6, TO_DATE('18-Sep-2025 16:00','dd-Mon-yyyy hh24:mi'), 101, '3002');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (25, 5, 8, TO_DATE('30-Nov-2025 10:00','dd-Mon-yyyy hh24:mi'), 105, '8033');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (26, 14, 4, TO_DATE('07-Jul-2025 13:45','dd-Mon-yyyy hh24:mi'), 101, '2002');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (27, 29, 6, TO_DATE('18-Sep-2025 16:15','dd-Mon-yyyy hh24:mi'), 101, '1011');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (28, 30, 6, TO_DATE('18-Sep-2025 16:30','dd-Mon-yyyy hh24:mi'), 101, '1012');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (29, 21, 5, TO_DATE('08-Jul-2025 10:45','dd-Mon-yyyy hh24:mi'), 102, '4002');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (30, 7, 10, TO_DATE('20-Dec-2025 09:45','dd-Mon-yyyy hh24:mi'), 102, '4034');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (31, 20, 5, TO_DATE('08-Jul-2025 10:30','dd-Mon-yyyy hh24:mi'), 102, '2014');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (32, 16, 4, TO_DATE('07-Jul-2025 14:00','dd-Mon-yyyy hh24:mi'), 101, '2003');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (33, 23, 7, TO_DATE('23-Oct-2025 15:00','dd-Mon-yyyy hh24:mi'), 103, '210');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (34, 10, 2, TO_DATE('16-Jun-2025 09:15','dd-Mon-yyyy hh24:mi'), 102, '2011');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (35, 4, 7, TO_DATE('23-Oct-2025 15:15','dd-Mon-yyyy hh24:mi'), 103, '211');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (36, 17, 4, TO_DATE('07-Jul-2025 14:30','dd-Mon-yyyy hh24:mi'), 101, '2022');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (37, 31, 1, TO_DATE('02-Jun-2025 09:30','dd-Mon-yyyy hh24:mi'), 101, '1001'); 
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (38, 31, 4, TO_DATE('07-Jul-2025 14:10','dd-Mon-yyyy hh24:mi'), 101, '1002');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (39, 31, 9, TO_DATE('06-Dec-2025 14:20','dd-Mon-yyyy hh24:mi'), 101, '1003');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (40, 32, 2, TO_DATE('16-Jun-2025 09:05','dd-Mon-yyyy hh24:mi'), 102, '4002');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (41, 32, 6, TO_DATE('18-Sep-2025 16:10','dd-Mon-yyyy hh24:mi'), 101, '2001');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (42, 32, 8, TO_DATE('30-Nov-2025 09:50','dd-Mon-yyyy hh24:mi'), 105, '8033');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (43, 33, 3, TO_DATE('16-Jun-2025 09:25','dd-Mon-yyyy hh24:mi'), 103, '113');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (44, 33, 7, TO_DATE('23-Oct-2025 15:10','dd-Mon-yyyy hh24:mi'), 103, '210');
INSERT INTO manifest (manifest_id, passenger_id, cruise_id, manifest_board_datetime, ship_code, cabin_no) VALUES (45, 33, 10, TO_DATE('20-Dec-2025 09:10','dd-Mon-yyyy hh24:mi'), 102, '2014');
commit;
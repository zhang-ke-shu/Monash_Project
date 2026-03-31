/*****PLEASE ENTER YOUR DETAILS BELOW*****/
--T6-oo-json.sql

--Student ID:36436763
--Student Name:Keshu Zhang



-- PLEASE PLACE REQUIRED SQL SELECT STATEMENT FOR THIS PART HERE
-- ENSURE that your query is formatted and has a semicolon
-- (;) at the end of this answer
SET PAGESIZE 100

/*****PLEASE ENTER YOUR DETAILS BELOW*****/
--T6-oo-view.sql
--Student ID: 36436763
--Student Name: Keshu Zhang


-- T6-oo-json.sql
-- Student ID: 36436763
-- Student Name: Keshu Zhang
-- Generate JSON documents for each passenger and their cruises

SELECT JSON_OBJECT(
    '_id' VALUE p.passenger_id,
    'passenger_name' VALUE p.passenger_fname || ' ' || p.passenger_lname,
    'passenger_dob' VALUE TO_CHAR(p.passenger_dob, 'DD-Mon-YYYY'),
    'passenger_contact' VALUE NVL(p.passenger_contact, '-'),
    'guardian_name' VALUE NVL((SELECT g.passenger_fname || ' ' || g.passenger_lname
                                FROM passenger g
                                WHERE g.passenger_id = p.guardian_id), '-'),
    'address' VALUE JSON_OBJECT(
                                'street' VALUE a.address_street,
                                'town' VALUE a.address_town,
                                'postcode' VALUE a.address_pcode,
                                'country' VALUE co.country_name),
    'no_of_cruises' VALUE (SELECT COUNT(*) FROM manifest m WHERE m.passenger_id = p.passenger_id),
    'cruises' VALUE (SELECT JSON_ARRAYAGG(JSON_OBJECT(
                'cruise_id' VALUE c.cruise_id,
                'cruise_name' VALUE c.cruise_name,
                'board_datetime' VALUE NVL(TO_CHAR(m.manifest_board_datetime, 'DD-Mon-YYYY HH24:MI'), '-'),
                'cabin_no' VALUE m.cabin_no,
                'cabin_class' VALUE CASE ca.cabin_class WHEN 'O' THEN 'Ocean View'
                                                        WHEN 'B' THEN 'Balcony'
                                                        WHEN 'I' THEN 'Interior'
                                                        WHEN 'S' THEN 'Suite'
                                                        ELSE '-'
                                                        END))
        from cruise c join MANIFEST m on c.CRUISE_ID = m.cruise_ID
        join CABIN ca on ca.CABIN_NO = m.CABIN_NO and ca.SHIP_CODE = m.SHIP_CODE
        WHERE m.passenger_id = p.passenger_id))||','
FROM passenger p
JOIN address a ON p.address_id = a.address_id
JOIN country co ON a.country_code = co.country_code;


        
        
/*****PLEASE ENTER YOUR DETAILS BELOW*****/
--T5-oo-select.sql

--Student ID:36436763
--Student Name:Keshu Zhang


/* (a) */
-- PLEASE PLACE REQUIRED SQL SELECT STATEMENT FOR THIS PART HERE
-- ENSURE that your query is formatted and has a semicolon
-- (;) at the end of this answer

/* List which country or countries have the highest number of registered cruise passengers based
on their home addresses. For each country that has the maximum number of passengers,
display the country code, the country name, the total count of passengers from that country,
and the percentage that this count represents out of all passengers in the system.
Order the output by country code
*/
select COUNTRY_CODE,COUNTRY_name, count(passenger_id) as no_passengers, 
    lpad(round(count(passenger_id)*100/(select count(passenger_id) from PASSENGER), 1) || '%', 30, ' ') as percent_passengers
from passenger NATURAL join address NATURAL join COUNTRY
group by COUNTRY_CODE,COUNTRY_name
HAVING count(passenger_id) = (
                        select max(count(passenger_id))
                        from passenger NATURAL join address NATURAL join COUNTRY
                        group by COUNTRY_CODE)
order by country_code
;

/* (b) */
-- PLEASE PLACE REQUIRED SQL SELECT STATEMENT FOR THIS PART HERE
-- ENSURE that your query is formatted and has a semicolon
-- (;) at the end of this answer

/* List passenger booking information for all cruises, showing both a breakdown by gender and
overall totals. For each cruise, list the cruise id and cruise name, the departure date and a
combined ship identifier that includes the ship code and ship name, the gender category, where
male passengers are labelled as "Male", female passengers as "Female", and non-binary/other
passengers as "Other" and then a total count of all passengers labelled as "Total Count". For
each row, show a count of the gender/total represented in that row. If a category has no
passengers for a particular cruise, then no row will be displayed in the output (see the sample
output below - for cruise five, there are no "Other" passengers, so no output row for "Other" is
produced).
Order the output by the cruise id and then within a cruise by the gender category as shown
below


*/
select  CRUISE_ID, CRUISE_NAME, 
        TO_CHAR(CRUISE_DEPART_DT, 'Dy DD Month YYYY HH:MI AM') AS DEPARTURE_DATE_TIME,
        SHIP_CODE ||' '|| SHIP_NAME as ship_details, 
        decode(PASSENGER_GENDER, 'M', 'Male', 'F', 'Female', 'X', 'Other') as category,
        COUNT(*) AS PASSENGER_COUNT
from CRUISE 
    natural join PASSENGER 
    natural join MANIFEST 
    natural join ship
group by cruise_id, cruise_name, cruise_depart_dt, ship_code, ship_name, decode(PASSENGER_GENDER, 'M', 'Male', 'F', 'Female', 'X', 'Other')

UNION ALL

SELECT  
    CRUISE_ID, CRUISE_NAME, 
    TO_CHAR(CRUISE_DEPART_DT, 'Dy DD Month YYYY HH:MI AM') AS DEPARTURE_DATE_TIME,
    SHIP_CODE ||' '|| SHIP_NAME as ship_details,
    'Total Count',
    COUNT(*) AS PASSENGER_COUNT
FROM cruise 
    NATURAL JOIN manifest 
    NATURAL JOIN passenger 
    NATURAL JOIN ship
GROUP BY cruise_id, cruise_name, cruise_depart_dt, ship_code, ship_name
ORDER BY CRUISE_ID, CATEGORY
;


/* (c) */
-- PLEASE PLACE REQUIRED SQL SELECT STATEMENT FOR THIS PART HERE
-- ENSURE that your query is formatted and has a semicolon
-- (;) at the end of this answer

/*List all cruises that have more booked passengers than the average number of booked
passengers across all cruises in the system.
For each cruise that meets this condition, show the cruise ID, the cruise name, and how long
the cruise lasts in days and hours. Display how many passengers are booked on the cruise,
how many of those passengers are minors (children travelling with a guardian), the average
age of all passengers on that cruise, and how many different countries the passengers come
from based on their home addresses. Include the cost per person for the cruise. Also, list
information about the ship: the ship's name, the name of the company that operates the ship,
and the country where the ship is registered.
Order the output by showing the most popular cruises (those with the most passengers) first. If
several cruises have the same number of passengers, order them by the cruise id
*/

select c.CRUISE_ID ||':'|| c.CRUISE_NAME as cruise,
    TRUNC(c.cruise_arrive_dt - c.cruise_depart_dt) || ' days ' || 
    TRUNC(MOD((c.cruise_arrive_dt - c.cruise_depart_dt) * 24, 24)) || ' hours' AS cruise_duration,
    COUNT(DISTINCT m.passenger_id) AS total_passengers,
    sum(case when months_between(c.cruise_depart_dt , p.PASSENGER_DOB) < 216
                then 1
            else 0
            end) as minors,
    to_char(avg( months_between(c.cruise_depart_dt, p.PASSENGER_DOB)/12),'90.9') as AVG_AGE,
    count(distinct a.country_code) as countries,
    to_char(c.CRUISE_COST_PP, '$999,990.99') as cruiscost,
    s.ship_name,
    o.OPER_COMP_NAME,
    co.COUNTRY_NAME as ship_country
from cruise c join MANIFEST m on c.CRUISE_ID = m.cruise_ID
    join ship s on c.SHIP_CODE = s.SHIP_CODE
    join OPERATOR o on s.OPER_ID = o.OPER_ID
    join PASSENGER p on m.PASSENGER_ID = p.PASSENGER_ID
    join country co on co.COUNTRY_CODE = s.COUNTRY_CODE
    join address a on a.address_id = p.address_id
GROUP BY c.cruise_id, c.cruise_name, c.cruise_depart_dt, c.cruise_arrive_dt, 
         c.cruise_cost_pp, s.ship_name, o.oper_comp_name, co.country_name
HAVING COUNT(DISTINCT m.passenger_id) > (
        SELECT AVG(passenger_count)
        FROM 
        (SELECT COUNT(DISTINCT m1.passenger_id) AS passenger_count
        FROM manifest m1
        GROUP BY m1.cruise_id)
        )
ORDER BY - TOTAL_PASSENGERS, c.CRUISE_id;    
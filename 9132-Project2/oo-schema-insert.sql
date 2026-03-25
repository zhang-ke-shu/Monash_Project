/*
  Databases 2025 S2 Assignment 2
  -- Ocean Odyssey Schema File and Initial Data --

  Description:
  This file creates the Ocean Odyssey tables
  and populates several of the tables (those shown in purple on the supplied model).
  You should read this schema file carefully
  and be sure you understand the various data requirements.

Author: FIT Database Teaching Team
License: Copyright Monash University, unless otherwise stated. All Rights Reserved.
COPYRIGHT WARNING
Warning
This material is protected by copyright. For use within Monash University only. NOT FOR RESALE.
Do not remove this notice.

*/


DROP TABLE cabin CASCADE CONSTRAINTS PURGE;

DROP TABLE country CASCADE CONSTRAINTS PURGE;

DROP TABLE cruise CASCADE CONSTRAINTS PURGE;

DROP TABLE operator CASCADE CONSTRAINTS PURGE;

DROP TABLE ship CASCADE CONSTRAINTS PURGE;


CREATE TABLE cabin (
    ship_code      NUMBER(4) NOT NULL,
    cabin_no       VARCHAR2(5) NOT NULL,
    cabin_capacity NUMBER(2) NOT NULL,
    cabin_class    CHAR(1) NOT NULL
);

ALTER TABLE cabin
    ADD CONSTRAINT cabin_class_chk
        CHECK ( cabin_class IN ( 'B',
                                 'I',
                                 'O',
                                 'S' ) );

COMMENT ON COLUMN cabin.ship_code IS
    'Identifier for ship';

COMMENT ON COLUMN cabin.cabin_no IS
    'Cabin number on given ship';

COMMENT ON COLUMN cabin.cabin_capacity IS
    'Sleeping capacity for cabin (some cruise ships - Royal Caribbean
Ultimate Family Suite - allow up to 10)';

COMMENT ON COLUMN cabin.cabin_class IS
    'Class of the cabin ( B: Balcony, I: Interior, O: Ocean View, S: Suite)';

ALTER TABLE cabin ADD CONSTRAINT cabin_pk PRIMARY KEY ( ship_code,
                                                        cabin_no );

CREATE TABLE country (
    country_code CHAR(3) NOT NULL,
    country_name VARCHAR2(80) NOT NULL
);

COMMENT ON COLUMN country.country_code IS
    'ISO 3166-1 Alpha-3 Country code';

COMMENT ON COLUMN country.country_name IS
    'Country name';

ALTER TABLE country ADD CONSTRAINT country_pk PRIMARY KEY ( country_code );

CREATE TABLE cruise (
    cruise_id          NUMBER(6) NOT NULL,
    cruise_name        VARCHAR2(80) NOT NULL,
    cruise_description VARCHAR2(200) NOT NULL,
    cruise_depart_dt   DATE NOT NULL,
    cruise_arrive_dt   DATE NOT NULL,
    cruise_cost_pp     NUMBER(8,2) NOT NULL,
    ship_code          NUMBER(4) NOT NULL
);

COMMENT ON COLUMN cruise.cruise_id IS
    'Cruise identifier - used only for a single cruise';

COMMENT ON COLUMN cruise.cruise_name IS
    'Name of cruise';

COMMENT ON COLUMN cruise.cruise_description IS
    'Description of cruise';

COMMENT ON COLUMN cruise.cruise_depart_dt IS
    'Cruise scheduled departure date and time';

COMMENT ON COLUMN cruise.cruise_arrive_dt IS
    'Cruise scheduled departure date and time';

COMMENT ON COLUMN cruise.cruise_cost_pp IS
    'Cruise cost per person';

COMMENT ON COLUMN cruise.ship_code IS
    'Identifier for ship';

ALTER TABLE cruise ADD CONSTRAINT cruise_pk PRIMARY KEY ( cruise_id );

CREATE TABLE operator (
    oper_id        NUMBER(4) NOT NULL,
    oper_comp_name VARCHAR2(50) NOT NULL,
    oper_ceo_gname VARCHAR2(25),
    oper_ceo_fname VARCHAR2(25)
);

COMMENT ON COLUMN operator.oper_id IS
    'Identifier for ship operator';

COMMENT ON COLUMN operator.oper_comp_name IS
    'Name of ship operator';

COMMENT ON COLUMN operator.oper_ceo_gname IS
    'Given name of CEO';

COMMENT ON COLUMN operator.oper_ceo_fname IS
    'Family name of CEO';

ALTER TABLE operator ADD CONSTRAINT operator_pk PRIMARY KEY ( oper_id );

CREATE TABLE ship (
    ship_code           NUMBER(4) NOT NULL,
    ship_name           VARCHAR2(50) NOT NULL,
    ship_date_commiss   DATE NOT NULL,
    ship_tonnage        NUMBER(6) NOT NULL,
    ship_guest_capacity NUMBER(4) NOT NULL,
    oper_id             NUMBER(4) NOT NULL,
    country_code        CHAR(3) NOT NULL
);

COMMENT ON COLUMN ship.ship_code IS
    'Identifier for ship';

COMMENT ON COLUMN ship.ship_name IS
    'Name of ship';

COMMENT ON COLUMN ship.ship_date_commiss IS
    'Date began operation';

COMMENT ON COLUMN ship.ship_tonnage IS
    'Gross tonnage of ship';

COMMENT ON COLUMN ship.ship_guest_capacity IS
    'Ships passenger capacity';

COMMENT ON COLUMN ship.oper_id IS
    'Identifier for ship operator';

COMMENT ON COLUMN ship.country_code IS
    'ISO 3166-1 Alpha-3 Country code';

ALTER TABLE ship ADD CONSTRAINT ship_pk PRIMARY KEY ( ship_code );

ALTER TABLE ship
    ADD CONSTRAINT country_ship_fk FOREIGN KEY ( country_code )
        REFERENCES country ( country_code );

ALTER TABLE ship
    ADD CONSTRAINT operator_ship_fk FOREIGN KEY ( oper_id )
        REFERENCES operator ( oper_id );

ALTER TABLE cabin
    ADD CONSTRAINT ship_cabin_fk FOREIGN KEY ( ship_code )
        REFERENCES ship ( ship_code );

ALTER TABLE cruise
    ADD CONSTRAINT ship_cruise_fk FOREIGN KEY ( ship_code )
        REFERENCES ship ( ship_code );

-- *****************************************************************
-- NO FURTHER DATA MAY BE ADDED TO THESE TABLES NOR THE SUPPPLIED
-- DATA MODIFIED IN ANY WAY
-- *****************************************************************

-- INSERTING into COUNTRY
INSERT INTO country (country_code, country_name) VALUES ('AFG', 'Afghanistan');
INSERT INTO country (country_code, country_name) VALUES ('ALA', 'Åland Islands');
INSERT INTO country (country_code, country_name) VALUES ('ALB', 'Albania');
INSERT INTO country (country_code, country_name) VALUES ('DZA', 'Algeria');
INSERT INTO country (country_code, country_name) VALUES ('ASM', 'American Samoa');
INSERT INTO country (country_code, country_name) VALUES ('AND', 'Andorra');
INSERT INTO country (country_code, country_name) VALUES ('AGO', 'Angola');
INSERT INTO country (country_code, country_name) VALUES ('AIA', 'Anguilla');
INSERT INTO country (country_code, country_name) VALUES ('ATA', 'Antarctica');
INSERT INTO country (country_code, country_name) VALUES ('ATG', 'Antigua and Barbuda');
INSERT INTO country (country_code, country_name) VALUES ('ARG', 'Argentina');
INSERT INTO country (country_code, country_name) VALUES ('ARM', 'Armenia');
INSERT INTO country (country_code, country_name) VALUES ('ABW', 'Aruba');
INSERT INTO country (country_code, country_name) VALUES ('AUS', 'Australia');
INSERT INTO country (country_code, country_name) VALUES ('AUT', 'Austria');
INSERT INTO country (country_code, country_name) VALUES ('AZE', 'Azerbaijan');
INSERT INTO country (country_code, country_name) VALUES ('BHS', 'Bahamas');
INSERT INTO country (country_code, country_name) VALUES ('BHR', 'Bahrain');
INSERT INTO country (country_code, country_name) VALUES ('BGD', 'Bangladesh');
INSERT INTO country (country_code, country_name) VALUES ('BRB', 'Barbados');
INSERT INTO country (country_code, country_name) VALUES ('BLR', 'Belarus');
INSERT INTO country (country_code, country_name) VALUES ('BEL', 'Belgium');
INSERT INTO country (country_code, country_name) VALUES ('BLZ', 'Belize');
INSERT INTO country (country_code, country_name) VALUES ('BEN', 'Benin');
INSERT INTO country (country_code, country_name) VALUES ('BMU', 'Bermuda');
INSERT INTO country (country_code, country_name) VALUES ('BTN', 'Bhutan');
INSERT INTO country (country_code, country_name) VALUES ('BOL', 'Bolivia (Plurinational State of)');
INSERT INTO country (country_code, country_name) VALUES ('BES', 'Bonaire, Sint Eustatius and Saba');
INSERT INTO country (country_code, country_name) VALUES ('BIH', 'Bosnia and Herzegovina');
INSERT INTO country (country_code, country_name) VALUES ('BWA', 'Botswana');
INSERT INTO country (country_code, country_name) VALUES ('BVT', 'Bouvet Island');
INSERT INTO country (country_code, country_name) VALUES ('BRA', 'Brazil');
INSERT INTO country (country_code, country_name) VALUES ('IOT', 'British Indian Ocean Territory');
INSERT INTO country (country_code, country_name) VALUES ('BRN', 'Brunei Darussalam');
INSERT INTO country (country_code, country_name) VALUES ('BGR', 'Bulgaria');
INSERT INTO country (country_code, country_name) VALUES ('BFA', 'Burkina Faso');
INSERT INTO country (country_code, country_name) VALUES ('BDI', 'Burundi');
INSERT INTO country (country_code, country_name) VALUES ('CPV', 'Cabo Verde');
INSERT INTO country (country_code, country_name) VALUES ('KHM', 'Cambodia');
INSERT INTO country (country_code, country_name) VALUES ('CMR', 'Cameroon');
INSERT INTO country (country_code, country_name) VALUES ('CAN', 'Canada');
INSERT INTO country (country_code, country_name) VALUES ('CYM', 'Cayman Islands');
INSERT INTO country (country_code, country_name) VALUES ('CAF', 'Central African Republic');
INSERT INTO country (country_code, country_name) VALUES ('TCD', 'Chad');
INSERT INTO country (country_code, country_name) VALUES ('CHL', 'Chile');
INSERT INTO country (country_code, country_name) VALUES ('CHN', 'China');
INSERT INTO country (country_code, country_name) VALUES ('CXR', 'Christmas Island');
INSERT INTO country (country_code, country_name) VALUES ('CCK', 'Cocos (Keeling) Islands');
INSERT INTO country (country_code, country_name) VALUES ('COL', 'Colombia');
INSERT INTO country (country_code, country_name) VALUES ('COM', 'Comoros');
INSERT INTO country (country_code, country_name) VALUES ('COG', 'Congo');
INSERT INTO country (country_code, country_name) VALUES ('COD', 'Congo, Democratic Republic of the');
INSERT INTO country (country_code, country_name) VALUES ('COK', 'Cook Islands');
INSERT INTO country (country_code, country_name) VALUES ('CRI', 'Costa Rica');
INSERT INTO country (country_code, country_name) VALUES ('CIV', 'Côte d''Ivoire');
INSERT INTO country (country_code, country_name) VALUES ('HRV', 'Croatia');
INSERT INTO country (country_code, country_name) VALUES ('CUB', 'Cuba');
INSERT INTO country (country_code, country_name) VALUES ('CUW', 'Curaçao');
INSERT INTO country (country_code, country_name) VALUES ('CYP', 'Cyprus');
INSERT INTO country (country_code, country_name) VALUES ('CZE', 'Czechia');
INSERT INTO country (country_code, country_name) VALUES ('DNK', 'Denmark');
INSERT INTO country (country_code, country_name) VALUES ('DJI', 'Djibouti');
INSERT INTO country (country_code, country_name) VALUES ('DMA', 'Dominica');
INSERT INTO country (country_code, country_name) VALUES ('DOM', 'Dominican Republic');
INSERT INTO country (country_code, country_name) VALUES ('ECU', 'Ecuador');
INSERT INTO country (country_code, country_name) VALUES ('EGY', 'Egypt');
INSERT INTO country (country_code, country_name) VALUES ('SLV', 'El Salvador');
INSERT INTO country (country_code, country_name) VALUES ('GNQ', 'Equatorial Guinea');
INSERT INTO country (country_code, country_name) VALUES ('ERI', 'Eritrea');
INSERT INTO country (country_code, country_name) VALUES ('EST', 'Estonia');
INSERT INTO country (country_code, country_name) VALUES ('SWZ', 'Eswatini');
INSERT INTO country (country_code, country_name) VALUES ('ETH', 'Ethiopia');
INSERT INTO country (country_code, country_name) VALUES ('FLK', 'Falkland Islands (Malvinas)');
INSERT INTO country (country_code, country_name) VALUES ('FRO', 'Faroe Islands');
INSERT INTO country (country_code, country_name) VALUES ('FJI', 'Fiji');
INSERT INTO country (country_code, country_name) VALUES ('FIN', 'Finland');
INSERT INTO country (country_code, country_name) VALUES ('FRA', 'France');
INSERT INTO country (country_code, country_name) VALUES ('GUF', 'French Guiana');
INSERT INTO country (country_code, country_name) VALUES ('PYF', 'French Polynesia');
INSERT INTO country (country_code, country_name) VALUES ('ATF', 'French Southern Territories');
INSERT INTO country (country_code, country_name) VALUES ('GAB', 'Gabon');
INSERT INTO country (country_code, country_name) VALUES ('GMB', 'Gambia');
INSERT INTO country (country_code, country_name) VALUES ('GEO', 'Georgia');
INSERT INTO country (country_code, country_name) VALUES ('DEU', 'Germany');
INSERT INTO country (country_code, country_name) VALUES ('GHA', 'Ghana');
INSERT INTO country (country_code, country_name) VALUES ('GIB', 'Gibraltar');
INSERT INTO country (country_code, country_name) VALUES ('GRC', 'Greece');
INSERT INTO country (country_code, country_name) VALUES ('GRL', 'Greenland');
INSERT INTO country (country_code, country_name) VALUES ('GRD', 'Grenada');
INSERT INTO country (country_code, country_name) VALUES ('GLP', 'Guadeloupe');
INSERT INTO country (country_code, country_name) VALUES ('GUM', 'Guam');
INSERT INTO country (country_code, country_name) VALUES ('GTM', 'Guatemala');
INSERT INTO country (country_code, country_name) VALUES ('GGY', 'Guernsey');
INSERT INTO country (country_code, country_name) VALUES ('GIN', 'Guinea');
INSERT INTO country (country_code, country_name) VALUES ('GNB', 'Guinea-Bissau');
INSERT INTO country (country_code, country_name) VALUES ('GUY', 'Guyana');
INSERT INTO country (country_code, country_name) VALUES ('HTI', 'Haiti');
INSERT INTO country (country_code, country_name) VALUES ('HMD', 'Heard Island and McDonald Islands');
INSERT INTO country (country_code, country_name) VALUES ('VAT', 'Holy See');
INSERT INTO country (country_code, country_name) VALUES ('HND', 'Honduras');
INSERT INTO country (country_code, country_name) VALUES ('HKG', 'Hong Kong');
INSERT INTO country (country_code, country_name) VALUES ('HUN', 'Hungary');
INSERT INTO country (country_code, country_name) VALUES ('ISL', 'Iceland');
INSERT INTO country (country_code, country_name) VALUES ('IND', 'India');
INSERT INTO country (country_code, country_name) VALUES ('IDN', 'Indonesia');
INSERT INTO country (country_code, country_name) VALUES ('IRN', 'Iran (Islamic Republic of)');
INSERT INTO country (country_code, country_name) VALUES ('IRQ', 'Iraq');
INSERT INTO country (country_code, country_name) VALUES ('IRL', 'Ireland');
INSERT INTO country (country_code, country_name) VALUES ('IMN', 'Isle of Man');
INSERT INTO country (country_code, country_name) VALUES ('ISR', 'Israel');
INSERT INTO country (country_code, country_name) VALUES ('ITA', 'Italy');
INSERT INTO country (country_code, country_name) VALUES ('JAM', 'Jamaica');
INSERT INTO country (country_code, country_name) VALUES ('JPN', 'Japan');
INSERT INTO country (country_code, country_name) VALUES ('JEY', 'Jersey');
INSERT INTO country (country_code, country_name) VALUES ('JOR', 'Jordan');
INSERT INTO country (country_code, country_name) VALUES ('KAZ', 'Kazakhstan');
INSERT INTO country (country_code, country_name) VALUES ('KEN', 'Kenya');
INSERT INTO country (country_code, country_name) VALUES ('KIR', 'Kiribati');
INSERT INTO country (country_code, country_name) VALUES ('PRK', 'Korea (Democratic People''s Republic of)');
INSERT INTO country (country_code, country_name) VALUES ('KOR', 'Korea, Republic of');
INSERT INTO country (country_code, country_name) VALUES ('KWT', 'Kuwait');
INSERT INTO country (country_code, country_name) VALUES ('KGZ', 'Kyrgyzstan');
INSERT INTO country (country_code, country_name) VALUES ('LAO', 'Lao People''s Democratic Republic');
INSERT INTO country (country_code, country_name) VALUES ('LVA', 'Latvia');
INSERT INTO country (country_code, country_name) VALUES ('LBN', 'Lebanon');
INSERT INTO country (country_code, country_name) VALUES ('LSO', 'Lesotho');
INSERT INTO country (country_code, country_name) VALUES ('LBR', 'Liberia');
INSERT INTO country (country_code, country_name) VALUES ('LBY', 'Libya');
INSERT INTO country (country_code, country_name) VALUES ('LIE', 'Liechtenstein');
INSERT INTO country (country_code, country_name) VALUES ('LTU', 'Lithuania');
INSERT INTO country (country_code, country_name) VALUES ('LUX', 'Luxembourg');
INSERT INTO country (country_code, country_name) VALUES ('MAC', 'Macao');
INSERT INTO country (country_code, country_name) VALUES ('MDG', 'Madagascar');
INSERT INTO country (country_code, country_name) VALUES ('MWI', 'Malawi');
INSERT INTO country (country_code, country_name) VALUES ('MYS', 'Malaysia');
INSERT INTO country (country_code, country_name) VALUES ('MDV', 'Maldives');
INSERT INTO country (country_code, country_name) VALUES ('MLI', 'Mali');
INSERT INTO country (country_code, country_name) VALUES ('MLT', 'Malta');
INSERT INTO country (country_code, country_name) VALUES ('MHL', 'Marshall Islands');
INSERT INTO country (country_code, country_name) VALUES ('MTQ', 'Martinique');
INSERT INTO country (country_code, country_name) VALUES ('MRT', 'Mauritania');
INSERT INTO country (country_code, country_name) VALUES ('MUS', 'Mauritius');
INSERT INTO country (country_code, country_name) VALUES ('MYT', 'Mayotte');
INSERT INTO country (country_code, country_name) VALUES ('MEX', 'Mexico');
INSERT INTO country (country_code, country_name) VALUES ('FSM', 'Micronesia (Federated States of)');
INSERT INTO country (country_code, country_name) VALUES ('MDA', 'Moldova, Republic of');
INSERT INTO country (country_code, country_name) VALUES ('MCO', 'Monaco');
INSERT INTO country (country_code, country_name) VALUES ('MNG', 'Mongolia');
INSERT INTO country (country_code, country_name) VALUES ('MNE', 'Montenegro');
INSERT INTO country (country_code, country_name) VALUES ('MSR', 'Montserrat');
INSERT INTO country (country_code, country_name) VALUES ('MAR', 'Morocco');
INSERT INTO country (country_code, country_name) VALUES ('MOZ', 'Mozambique');
INSERT INTO country (country_code, country_name) VALUES ('MMR', 'Myanmar');
INSERT INTO country (country_code, country_name) VALUES ('NAM', 'Namibia');
INSERT INTO country (country_code, country_name) VALUES ('NRU', 'Nauru');
INSERT INTO country (country_code, country_name) VALUES ('NPL', 'Nepal');
INSERT INTO country (country_code, country_name) VALUES ('NLD', 'Netherlands');
INSERT INTO country (country_code, country_name) VALUES ('NCL', 'New Caledonia');
INSERT INTO country (country_code, country_name) VALUES ('NZL', 'New Zealand');
INSERT INTO country (country_code, country_name) VALUES ('NIC', 'Nicaragua');
INSERT INTO country (country_code, country_name) VALUES ('NER', 'Niger');
INSERT INTO country (country_code, country_name) VALUES ('NGA', 'Nigeria');
INSERT INTO country (country_code, country_name) VALUES ('NIU', 'Niue');
INSERT INTO country (country_code, country_name) VALUES ('NFK', 'Norfolk Island');
INSERT INTO country (country_code, country_name) VALUES ('MNP', 'Northern Mariana Islands');
INSERT INTO country (country_code, country_name) VALUES ('NOR', 'Norway');
INSERT INTO country (country_code, country_name) VALUES ('OMN', 'Oman');
INSERT INTO country (country_code, country_name) VALUES ('PAK', 'Pakistan');
INSERT INTO country (country_code, country_name) VALUES ('PLW', 'Palau');
INSERT INTO country (country_code, country_name) VALUES ('PSE', 'Palestine, State of');
INSERT INTO country (country_code, country_name) VALUES ('PAN', 'Panama');
INSERT INTO country (country_code, country_name) VALUES ('PNG', 'Papua New Guinea');
INSERT INTO country (country_code, country_name) VALUES ('PRY', 'Paraguay');
INSERT INTO country (country_code, country_name) VALUES ('PER', 'Peru');
INSERT INTO country (country_code, country_name) VALUES ('PHL', 'Philippines');
INSERT INTO country (country_code, country_name) VALUES ('PCN', 'Pitcairn');
INSERT INTO country (country_code, country_name) VALUES ('POL', 'Poland');
INSERT INTO country (country_code, country_name) VALUES ('PRT', 'Portugal');
INSERT INTO country (country_code, country_name) VALUES ('PRI', 'Puerto Rico');
INSERT INTO country (country_code, country_name) VALUES ('QAT', 'Qatar');
INSERT INTO country (country_code, country_name) VALUES ('MKD', 'Republic of North Macedonia');
INSERT INTO country (country_code, country_name) VALUES ('ROU', 'Romania');
INSERT INTO country (country_code, country_name) VALUES ('RUS', 'Russian Federation');
INSERT INTO country (country_code, country_name) VALUES ('RWA', 'Rwanda');
INSERT INTO country (country_code, country_name) VALUES ('REU', 'Réunion');
INSERT INTO country (country_code, country_name) VALUES ('BLM', 'Saint Barthélemy');
INSERT INTO country (country_code, country_name) VALUES ('SHN', 'Saint Helena, Ascension and Tristan da Cunha');
INSERT INTO country (country_code, country_name) VALUES ('KNA', 'Saint Kitts and Nevis');
INSERT INTO country (country_code, country_name) VALUES ('LCA', 'Saint Lucia');
INSERT INTO country (country_code, country_name) VALUES ('MAF', 'Saint Martin (French part)');
INSERT INTO country (country_code, country_name) VALUES ('SPM', 'Saint Pierre and Miquelon');
INSERT INTO country (country_code, country_name) VALUES ('VCT', 'Saint Vincent and the Grenadines');
INSERT INTO country (country_code, country_name) VALUES ('WSM', 'Samoa');
INSERT INTO country (country_code, country_name) VALUES ('SMR', 'San Marino');
INSERT INTO country (country_code, country_name) VALUES ('STP', 'Sao Tome and Principe');
INSERT INTO country (country_code, country_name) VALUES ('SAU', 'Saudi Arabia');
INSERT INTO country (country_code, country_name) VALUES ('SEN', 'Senegal');
INSERT INTO country (country_code, country_name) VALUES ('SRB', 'Serbia');
INSERT INTO country (country_code, country_name) VALUES ('SYC', 'Seychelles');
INSERT INTO country (country_code, country_name) VALUES ('SLE', 'Sierra Leone');
INSERT INTO country (country_code, country_name) VALUES ('SGP', 'Singapore');
INSERT INTO country (country_code, country_name) VALUES ('SXM', 'Sint Maarten (Dutch part)');
INSERT INTO country (country_code, country_name) VALUES ('SVK', 'Slovakia');
INSERT INTO country (country_code, country_name) VALUES ('SVN', 'Slovenia');
INSERT INTO country (country_code, country_name) VALUES ('SLB', 'Solomon Islands');
INSERT INTO country (country_code, country_name) VALUES ('SOM', 'Somalia');
INSERT INTO country (country_code, country_name) VALUES ('ZAF', 'South Africa');
INSERT INTO country (country_code, country_name) VALUES ('SGS', 'South Georgia and the South Sandwich Islands');
INSERT INTO country (country_code, country_name) VALUES ('SSD', 'South Sudan');
INSERT INTO country (country_code, country_name) VALUES ('ESP', 'Spain');
INSERT INTO country (country_code, country_name) VALUES ('LKA', 'Sri Lanka');
INSERT INTO country (country_code, country_name) VALUES ('SDN', 'Sudan');
INSERT INTO country (country_code, country_name) VALUES ('SUR', 'Suriname');
INSERT INTO country (country_code, country_name) VALUES ('SJM', 'Svalbard and Jan Mayen');
INSERT INTO country (country_code, country_name) VALUES ('SWE', 'Sweden');
INSERT INTO country (country_code, country_name) VALUES ('CHE', 'Switzerland');
INSERT INTO country (country_code, country_name) VALUES ('SYR', 'Syrian Arab Republic');
INSERT INTO country (country_code, country_name) VALUES ('TWN', 'Taiwan, Province of China');
INSERT INTO country (country_code, country_name) VALUES ('TJK', 'Tajikistan');
INSERT INTO country (country_code, country_name) VALUES ('TZA', 'Tanzania, United Republic of');
INSERT INTO country (country_code, country_name) VALUES ('THA', 'Thailand');
INSERT INTO country (country_code, country_name) VALUES ('TLS', 'Timor-Leste');
INSERT INTO country (country_code, country_name) VALUES ('TGO', 'Togo');
INSERT INTO country (country_code, country_name) VALUES ('TKL', 'Tokelau');
INSERT INTO country (country_code, country_name) VALUES ('TON', 'Tonga');
INSERT INTO country (country_code, country_name) VALUES ('TTO', 'Trinidad and Tobago');
INSERT INTO country (country_code, country_name) VALUES ('TUN', 'Tunisia');
INSERT INTO country (country_code, country_name) VALUES ('TUR', 'Turkey');
INSERT INTO country (country_code, country_name) VALUES ('TKM', 'Turkmenistan');
INSERT INTO country (country_code, country_name) VALUES ('TCA', 'Turks and Caicos Islands');
INSERT INTO country (country_code, country_name) VALUES ('TUV', 'Tuvalu');
INSERT INTO country (country_code, country_name) VALUES ('UGA', 'Uganda');
INSERT INTO country (country_code, country_name) VALUES ('UKR', 'Ukraine');
INSERT INTO country (country_code, country_name) VALUES ('ARE', 'United Arab Emirates');
INSERT INTO country (country_code, country_name) VALUES ('GBR', 'United Kingdom of Great Britain and Northern Ireland');
INSERT INTO country (country_code, country_name) VALUES ('USA', 'United States of America');
INSERT INTO country (country_code, country_name) VALUES ('UMI', 'United States Minor Outlying Islands');
INSERT INTO country (country_code, country_name) VALUES ('URY', 'Uruguay');
INSERT INTO country (country_code, country_name) VALUES ('UZB', 'Uzbekistan');
INSERT INTO country (country_code, country_name) VALUES ('VUT', 'Vanuatu');
INSERT INTO country (country_code, country_name) VALUES ('VEN', 'Venezuela (Bolivarian Republic of)');
INSERT INTO country (country_code, country_name) VALUES ('VNM', 'Viet Nam');
INSERT INTO country (country_code, country_name) VALUES ('VGB', 'Virgin Islands (British)');
INSERT INTO country (country_code, country_name) VALUES ('VIR', 'Virgin Islands (U.S.)');
INSERT INTO country (country_code, country_name) VALUES ('WLF', 'Wallis and Futuna');
INSERT INTO country (country_code, country_name) VALUES ('ESH', 'Western Sahara');
INSERT INTO country (country_code, country_name) VALUES ('YEM', 'Yemen');
INSERT INTO country (country_code, country_name) VALUES ('ZMB', 'Zambia');
INSERT INTO country (country_code, country_name) VALUES ('ZWE', 'Zimbabwe');

-- INSERTING into OPERATOR
INSERT INTO operator (
    oper_id,
    oper_comp_name,
    oper_ceo_gname,
    oper_ceo_fname
) VALUES ( 1,
           'Princess',
           'Haydn', 
           'Millar' );

INSERT INTO operator (
    oper_id,
    oper_comp_name,
    oper_ceo_gname,
    oper_ceo_fname
) VALUES ( 2,
           'Carnival',
           'Jayden-Lee',
           'Garrison' );

INSERT INTO operator (
    oper_id,
    oper_comp_name,
    oper_ceo_gname,
    oper_ceo_fname
) VALUES ( 3,
           'Cunard',
           null,
           'Frost' );
 
-- INSERTING into SHIP
INSERT INTO ship (
    ship_code,
    ship_name,
    ship_date_commiss,
    ship_tonnage,
    ship_guest_capacity,
    oper_id,
    country_code
) VALUES ( 101,
           'Coral Princess',
           TO_DATE('23-May-2022','dd-Mon-yyyy'),
           153012,
           1860,
           1,
           'AUS' );

INSERT INTO ship (
    ship_code,
    ship_name,
    ship_date_commiss,
    ship_tonnage,
    ship_guest_capacity,
    oper_id,
    country_code
) VALUES ( 102,
           'Majestic Princess',
           TO_DATE('22-Sep-2019','dd-Mon-yyyy'),
           172191,
           2240,
           1,
           'AUS' );

INSERT INTO ship (
    ship_code,
    ship_name,
    ship_date_commiss,
    ship_tonnage,
    ship_guest_capacity,
    oper_id,
    country_code
) VALUES ( 103,
           'Carnival Luminosa',
           TO_DATE('17-Jun-2022','dd-Mon-yyyy'),
           121713,
           1240,
           2,
           'ESP' );

INSERT INTO ship (
    ship_code,
    ship_name,
    ship_date_commiss,
    ship_tonnage,
    ship_guest_capacity,
    oper_id,
    country_code
) VALUES ( 104,
           'Carnival Splendor',
           TO_DATE('09-Jun-2021','dd-Mon-yyyy'),
           135762,
           1864,
           2,
           'NZL' );

INSERT INTO ship (
    ship_code,
    ship_name,
    ship_date_commiss,
    ship_tonnage,
    ship_guest_capacity,
    oper_id,
    country_code
) VALUES ( 105,
           'Queen Mary 2',
           TO_DATE('19-Aug-2018','dd-Mon-yyyy'),
           201425,
           4328,
           3,
           'PAN' );

-- INSERTING into CRUISE
INSERT INTO cruise (
    cruise_id,
    cruise_name,
    cruise_description,
    cruise_depart_dt,
    cruise_arrive_dt,
    cruise_cost_pp,
    ship_code
) VALUES ( 1,
           'Australian Circumnavigation',
           '28 Night Australian Circumnavigation Cruise. Starts from Sydney. Stops at Brisbane, Cairns, Darwin, Booome, Fremantle, Albany, Adelaide, Melbourne, Hobart. Ends at Sydney.',
           TO_DATE('02-Jun-2025 10:00','dd-Mon-yyyy hh24:mi'),
           TO_DATE('30-Jun-2025 14:00','dd-Mon-yyyy hh24:mi'),
           11499,
           101 );

INSERT INTO cruise (
    cruise_id,
    cruise_name,
    cruise_description,
    cruise_depart_dt,
    cruise_arrive_dt,
    cruise_cost_pp,
    ship_code
) VALUES ( 2,
           'Melbourne to Sydney',
           '2 nights at sea from Melbourne to Sydney.',
           TO_DATE('16-Jun-2025 9:00','dd-Mon-yyyy hh24:mi'),
           TO_DATE('18-Jun-2025 16:00','dd-Mon-yyyy hh24:mi'),
           899,
           102 );

INSERT INTO cruise (
    cruise_id,
    cruise_name,
    cruise_description,
    cruise_depart_dt,
    cruise_arrive_dt,
    cruise_cost_pp,
    ship_code
) VALUES ( 3,
           'New Zealand Delight',
           'Starts from Melbourne. Cruising in Fiordland National Park. Stops at Dunedin, Lyttelton (Christchurch), Wellington, Tauranga (Rotorua), Auckland. Ends at Melbourne.',
           TO_DATE('16-Jun-2025 9:00','dd-Mon-yyyy hh24:mi'),
           TO_DATE('23-Jun-2025 13:00','dd-Mon-yyyy hh24:mi'),
           4599,
           103 );

INSERT INTO cruise (
    cruise_id,
    cruise_name,
    cruise_description,
    cruise_depart_dt,
    cruise_arrive_dt,
    cruise_cost_pp,
    ship_code
) VALUES ( 4,
           'Queensland Islands',
           '7 Night Queensland Islands Cruise. Start from Brisbane. Stops at Airlie Beach, Port Douglas, Cairns, Willis Island. Ends at Brisbane.',
           TO_DATE('07-Jul-2025 14:00','dd-Mon-yyyy hh24:mi'),
           TO_DATE('14-Jul-2025 10:00','dd-Mon-yyyy hh24:mi'),
           2299,
           101 );

INSERT INTO cruise (
    cruise_id,
    cruise_name,
    cruise_description,
    cruise_depart_dt,
    cruise_arrive_dt,
    cruise_cost_pp,
    ship_code
) VALUES ( 5,
           'Brisbane to Hobart',
           '7 nights at sea from Brisbane to Hobart.',
           TO_DATE('08-Jul-2025 10:30','dd-Mon-yyyy hh24:mi'),
           TO_DATE('15-Jul-2025 10:30','dd-Mon-yyyy hh24:mi'),
           3399,
           102 );

INSERT INTO cruise (
    cruise_id,
    cruise_name,
    cruise_description,
    cruise_depart_dt,
    cruise_arrive_dt,
    cruise_cost_pp,
    ship_code
) VALUES ( 6,
           'Australian Circumnavigation',
           '28 Night Australian Circumnavigation Cruise. Starts from Sydney. Stops at Brisbane, Cairns, Darwin, Booome, Fremantle, Albany, Adelaide, Melbourne, Hobart. Ends at Sydney.',
           TO_DATE('18-Sep-2025 16:00','dd-Mon-yyyy hh24:mi'),
           TO_DATE('16-Oct-2025 11:00','dd-Mon-yyyy hh24:mi'),
           11199,
           101 );

INSERT INTO cruise (
    cruise_id,
    cruise_name,
    cruise_description,
    cruise_depart_dt,
    cruise_arrive_dt,
    cruise_cost_pp,
    ship_code
) VALUES ( 7,
           'Melbourne to Auckland',
           'Starts from Melbourne. Cruising in Fiordland National Park. Stops at Dunedin, Lyttelton (Christchurch), and Wellington. Ends at Auckland.',
           TO_DATE('23-Oct-2025 15:00','dd-Mon-yyyy hh24:mi'),
           TO_DATE('05-Nov-2025 11:00','dd-Mon-yyyy hh24:mi'),
           5699,
           103 );

INSERT INTO cruise (
    cruise_id,
    cruise_name,
    cruise_description,
    cruise_depart_dt,
    cruise_arrive_dt,
    cruise_cost_pp,
    ship_code
) VALUES ( 8,
           'Melbourne to Singapore',
           'Starts from Melbourne. Stops at Adelaide, Albany, Fremantle, Bali and Jakarta. Ends at Singapore.',
           TO_DATE('30-Nov-2025 9:30','dd-Mon-yyyy hh24:mi'),
           TO_DATE('10-Dec-2025 10:00','dd-Mon-yyyy hh24:mi'),
           9799,
           105 );

INSERT INTO cruise (
    cruise_id,
    cruise_name,
    cruise_description,
    cruise_depart_dt,
    cruise_arrive_dt,
    cruise_cost_pp,
    ship_code
) VALUES ( 9,
           'Queensland Islands',
           '7 Night Queensland Islands Cruise in Summer. Start from Brisbane. Stops at Airlie Beach, Port Douglas, Cairns, Willis Island. Ends at Brisbane.',
           TO_DATE('06-Dec-2025 14:00','dd-Mon-yyyy hh24:mi'),
           TO_DATE('13-Dec-2025 10:00','dd-Mon-yyyy hh24:mi'),
           2699,
           101 );

INSERT INTO cruise (
    cruise_id,
    cruise_name,
    cruise_description,
    cruise_depart_dt,
    cruise_arrive_dt,
    cruise_cost_pp,
    ship_code
) VALUES ( 10,
           'New Zealand Christmas Sail',
           'Starts from Brisbane. Cruising in Fiordland National Park. Stops at Dunedin, Lyttelton (Christchurch), Wellington, Tauranga (Rotorua), Auckland. Ends at Brisbane.',
           TO_DATE('20-Dec-2025 9:00','dd-Mon-yyyy hh24:mi'),
           TO_DATE('02-Jan-2026 16:00','dd-Mon-yyyy hh24:mi'),
           8599,
           102 );

-- INSERTING into CABIN
INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 101,
           '1001',
           4,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 101,
           '1002',
           4,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 101,
           '1003',
           4,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 101,
           '1004',
           4,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 101,
           '1011',
           2,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 101,
           '1012',
           2,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 101,
           '1013',
           2,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 101,
           '2001',
           3,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 101,
           '2002',
           3,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 101,
           '2003',
           3,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 101,
           '2022',
           2,
           'B' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 101,
           '2023',
           2,
           'B' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 101,
           '3001',
           4,
           'S' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 101,
           '3002',
           4,
           'S' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 102,
           '2001',
           4,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 102,
           '2002',
           3,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 102,
           '2003',
           4,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 102,
           '2004',
           3,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 102,
           '2011',
           4,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 102,
           '2012',
           3,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 102,
           '2013',
           4,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 102,
           '2014',
           3,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 102,
           '4002',
           2,
           'S' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 102,
           '4004',
           2,
           'S' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 102,
           '4006',
           2,
           'S' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 102,
           '4031',
           2,
           'B' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 102,
           '4033',
           3,
           'B' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 102,
           '4034',
           3,
           'B' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 103,
           '110',
           2,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 103,
           '111',
           2,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 103,
           '112',
           2,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 103,
           '113',
           2,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 103,
           '114',
           2,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 103,
           '210',
           4,
           'B' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 103,
           '211',
           4,
           'B' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 103,
           '213',
           4,
           'B' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 104,
           '141',
           4,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 104,
           '142',
           4,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 104,
           '143',
           4,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 104,
           '144',
           4,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 104,
           '145',
           4,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 104,
           '146',
           4,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 104,
           '211',
           4,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 104,
           '212',
           4,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 104,
           '213',
           4,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 104,
           '214',
           4,
           'I' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '8031',
           3,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '8032',
           3,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '8033',
           3,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '8034',
           3,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '8035',
           3,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '8036',
           4,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '8037',
           4,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '8038',
           4,
           'O' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '9012',
           2,
           'B' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '9013',
           2,
           'B' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '9014',
           2,
           'B' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '9015',
           2,
           'B' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '10101',
           6,
           'S' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '10102',
           4,
           'S' );

INSERT INTO cabin (
    ship_code,
    cabin_no,
    cabin_capacity,
    cabin_class
) VALUES ( 105,
           '10103',
           4,
           'S' );

COMMIT;
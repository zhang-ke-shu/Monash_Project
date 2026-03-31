--****PLEASE ENTER YOUR DETAILS BELOW****
--T4-oo-mods.sql

--Student ID:36436763
--Student Name:Keshu Zhang


--(a)

DROP TABLE maintenance CASCADE CONSTRAINTS PURGE;

CREATE TABLE maintenance (
    mainten_id              NUMBER(6) NOT NULL,
    mainten_type            VARCHAR2(30) NOT NULL,
    mainten_scheduled_start DATE NOT NULL,
    mainten_scheduled_end   DATE NOT NULL,
    mainten_actual_start    DATE,
    mainten_actual_end      DATE,
    ship_code               NUMBER(4) NOT NULL
);

COMMENT ON COLUMN maintenance.mainten_id IS
    'Identifier for ship maintenance';

COMMENT ON COLUMN maintenance.mainten_type IS
    'Three maintenance type: Preventive Maintenance, Breakdown Maintenance, and Condition-Based Maintenance.';

COMMENT ON COLUMN maintenance.mainten_scheduled_start IS
    'Scheduled maintenance start date';

COMMENT ON COLUMN maintenance.mainten_scheduled_end IS
    'Scheduled maintenance end date';

COMMENT ON COLUMN maintenance.mainten_actual_start IS
    'Actual maintenance start date';

COMMENT ON COLUMN maintenance.mainten_actual_end IS
    'Actual maintenance end date';

COMMENT ON COLUMN maintenance.ship_code IS
    'Identifier for ship';

ALTER TABLE maintenance ADD CONSTRAINT maintenance_pk PRIMARY KEY (mainten_id);

ALTER TABLE maintenance ADD CONSTRAINT mainten_type_chk CHECK ( mainten_type IN ('Preventive Maintenance', 'Breakdown Maintenance', 'Condition-Based Maintenance'));

ALTER TABLE maintenance
    ADD CONSTRAINT ship_maintenance_fk FOREIGN KEY ( ship_code )
        REFERENCES ship ( ship_code );

DESC maintenance;

commit;

--(b)

DROP TABLE need_category CASCADE CONSTRAINTS PURGE;

CREATE TABLE need_category (
    need_category_id        NUMBER(4) NOT NULL,
    need_category_desc      VARCHAR2(20) NOT NULL
);

ALTER TABLE need_category ADD CONSTRAINT need_category_pk PRIMARY KEY (need_category_id);

ALTER TABLE need_category ADD CONSTRAINT need_category_desc_uk UNIQUE (need_category_desc);

COMMENT ON COLUMN need_category.need_category_id IS
    'Identifier for passenger need category';

COMMENT ON COLUMN need_category.need_category_desc IS
    'Description of passenger need category, such as General, Mobility, Hearing, Visual, and others. May expand in the future';

INSERT INTO need_category VALUES (1, 'General');
INSERT INTO need_category VALUES (2, 'Mobility');
INSERT INTO need_category VALUES (3, 'Hearing');
INSERT INTO need_category VALUES (4, 'Visual');
INSERT INTO need_category VALUES (5, 'Others');



DROP TABLE need CASCADE CONSTRAINTS PURGE;

DROP SEQUENCE need_seq;
CREATE SEQUENCE need_SEQ;

CREATE TABLE need (
    need_id                 NUMBER(6) NOT NULL,
    passenger_id            NUMBER(6) NOT NULL,
    need_category_id        NUMBER(4) NOT NULL,
    need_detail             VARCHAR2(50)
);

ALTER TABLE need ADD CONSTRAINT need_pk PRIMARY KEY (need_id);

ALTER TABLE need
    ADD CONSTRAINT passenger_need_fk FOREIGN KEY ( passenger_id )
        REFERENCES passenger ( passenger_id );

ALTER TABLE need
    ADD CONSTRAINT need_category_need_fk FOREIGN KEY ( need_category_id )
        REFERENCES need_category ( need_category_id );

ALTER TABLE need 
    ADD CONSTRAINT need_passenger_category_uk
        UNIQUE (passenger_id, need_category_id);

COMMENT ON COLUMN need.need_id IS
    'Identifier for passenger special need record';

COMMENT ON COLUMN need.passenger_id IS
    'Identifier for the passenger associated with special need';

COMMENT ON COLUMN need.need_category_id IS
    'Identifier for the category of the special need (e.g., General, Mobility, Hearing, Visual, Others)';

COMMENT ON COLUMN need.need_detail IS
    'Detailed description of the passenger special need for the selected category';

INSERT INTO need (need_id, passenger_id, need_category_id, need_detail)
SELECT need_seq.NEXTVAL,
       passenger_id,
       (SELECT need_category_id FROM need_category WHERE UPPER(need_category_desc) = UPPER('General')),
       NULL
FROM passenger
WHERE passenger_specialneed='Y';

commit;

desc need_category;
desc need;
SELECT * from need natural join NEED_CATEGORY;



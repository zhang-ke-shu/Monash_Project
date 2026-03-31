// *****PLEASE ENTER YOUR DETAILS BELOW*****
// T6-oo-mongo.mongodb.js

// Student ID:36436763
// Student Name:Keshu Zhang
// ====================================================================================
// DO NOT modify or relocate any of the comments below (items marked with //)
// You are required to add additional comments as described on page five of this brief.
// ====================================================================================

// Use (connect to) your database - you MUST update xyz001
// with your authcate username

use("kzha0139");

// (b)
// PLEASE PLACE REQUIRED MONGODB COMMAND TO CREATE THE COLLECTION HERE
// YOU MAY PICK ANY COLLECTION NAME
// ENSURE that your statement is formatted and has a semicolon
// (;) at the end of each MongoDB statement

// Drop collection
db.passenger.drop();

// Create collection and insert documents
db.createCollection("passenger")

// List all documents you added
db.passenger.insertMany([

{"_id":1,"passenger_name":"John Smith","passenger_dob":"15-Jun-1985","passenger_contact":"555-1234","guardian_name":"-","address":{"street":"56 Baker St","town":"London","postcode":"NW1","country":"United Kingdom of Great Britain and Northern Ireland"},"no_of_cruises":2,"cruises":[{"cruise_id":3,"cruise_name":"New Zealand Delight","board_datetime":"16-Jun-2025 08:30","cabin_no":"110","cabin_class":"Ocean View"},{"cruise_id":9,"cruise_name":"Queensland Islands","board_datetime":"06-Dec-2025 14:15","cabin_no":"1013","cabin_class":"Interior"}]},
{"_id":2,"passenger_name":"Emily Brown","passenger_dob":"20-Sep-1990","passenger_contact":"555-5678","guardian_name":"-","address":{"street":"101 Market St","town":"San Francisco","postcode":"94103","country":"United States of America"},"no_of_cruises":2,"cruises":[{"cruise_id":3,"cruise_name":"New Zealand Delight","board_datetime":"16-Jun-2025 08:45","cabin_no":"111","cabin_class":"Ocean View"},{"cruise_id":10,"cruise_name":"New Zealand Christmas Sail","board_datetime":"20-Dec-2025 09:15","cabin_no":"4033","cabin_class":"Balcony"}]},
{"_id":3,"passenger_name":"Michael Johnson","passenger_dob":"12-Mar-2008","passenger_contact":"555-8765","guardian_name":"John Smith","address":{"street":"56 Baker St","town":"London","postcode":"NW1","country":"United Kingdom of Great Britain and Northern Ireland"},"no_of_cruises":2,"cruises":[{"cruise_id":1,"cruise_name":"Australian Circumnavigation","board_datetime":"02-Jun-2025 09:50","cabin_no":"1011","cabin_class":"Interior"},{"cruise_id":10,"cruise_name":"New Zealand Christmas Sail","board_datetime":"20-Dec-2025 09:30","cabin_no":"4034","cabin_class":"Balcony"}]},
{"_id":4,"passenger_name":"Sarah Williams","passenger_dob":"25-Jul-2010","passenger_contact":"555-4321","guardian_name":"Emily Brown","address":{"street":"101 Market St","town":"San Francisco","postcode":"94103","country":"United States of America"},"no_of_cruises":2,"cruises":[{"cruise_id":1,"cruise_name":"Australian Circumnavigation","board_datetime":"-","cabin_no":"1012","cabin_class":"Ocean View"},{"cruise_id":7,"cruise_name":"Melbourne to Auckland","board_datetime":"23-Oct-2025 15:15","cabin_no":"211","cabin_class":"Balcony"}]},
{"_id":5,"passenger_name":"David Jones","passenger_dob":"05-Nov-1982","passenger_contact":"555-1111","guardian_name":"-","address":{"street":"78 Queen St","town":"Brisbane","postcode":"4000","country":"Australia"},"no_of_cruises":2,"cruises":[{"cruise_id":1,"cruise_name":"Australian Circumnavigation","board_datetime":"02-Jun-2025 10:00","cabin_no":"1013","cabin_class":"Interior"},{"cruise_id":8,"cruise_name":"Melbourne to Singapore","board_datetime":"30-Nov-2025 10:00","cabin_no":"8033","cabin_class":"Ocean View"}]},
{"_id":6,"passenger_name":"Laura Taylor","passenger_dob":"18-Feb-1978","passenger_contact":"555-2222","guardian_name":"-","address":{"street":"55 Collins Ave","town":"Melbourne","postcode":"3001","country":"Australia"},"no_of_cruises":1,"cruises":[{"cruise_id":9,"cruise_name":"Queensland Islands","board_datetime":"06-Dec-2025 14:30","cabin_no":"2001","cabin_class":"Interior"}]},
{"_id":7,"passenger_name":"Chris Martin","passenger_dob":"30-Dec-2009","passenger_contact":"555-3333","guardian_name":"David Jones","address":{"street":"34 High St","town":"Manchester","postcode":"M1","country":"United Kingdom of Great Britain and Northern Ireland"},"no_of_cruises":2,"cruises":[{"cruise_id":2,"cruise_name":"Melbourne to Sydney","board_datetime":"16-Jun-2025 08:45","cabin_no":"2002","cabin_class":"Ocean View"},{"cruise_id":10,"cruise_name":"New Zealand Christmas Sail","board_datetime":"20-Dec-2025 09:45","cabin_no":"4034","cabin_class":"Balcony"}]},
{"_id":8,"passenger_name":"Anna Lee","passenger_dob":"14-Aug-2012","passenger_contact":"555-4444","guardian_name":"Laura Taylor","address":{"street":"55 Collins Ave","town":"Melbourne","postcode":"3001","country":"Australia"},"no_of_cruises":1,"cruises":[{"cruise_id":2,"cruise_name":"Melbourne to Sydney","board_datetime":"-","cabin_no":"2003","cabin_class":"Ocean View"}]},
{"_id":9,"passenger_name":"Robert Clark","passenger_dob":"09-Apr-1988","passenger_contact":"555-5555","guardian_name":"-","address":{"street":"12 Maple Rd","town":"Toronto","postcode":"M5H","country":"Canada"},"no_of_cruises":1,"cruises":[{"cruise_id":2,"cruise_name":"Melbourne to Sydney","board_datetime":"16-Jun-2025 09:00","cabin_no":"2004","cabin_class":"Ocean View"}]},
{"_id":10,"passenger_name":"Jessica Hall","passenger_dob":"22-Jan-1995","passenger_contact":"555-6666","guardian_name":"-","address":{"street":"123 Main St","town":"New York","postcode":"10001","country":"United States of America"},"no_of_cruises":1,"cruises":[{"cruise_id":2,"cruise_name":"Melbourne to Sydney","board_datetime":"16-Jun-2025 09:15","cabin_no":"2011","cabin_class":"Interior"}]},
{"_id":11,"passenger_name":"Daniel Allen","passenger_dob":"17-May-1980","passenger_contact":"555-7777","guardian_name":"-","address":{"street":"89 Oxford St","town":"London","postcode":"W1D","country":"United Kingdom of Great Britain and Northern Ireland"},"no_of_cruises":1,"cruises":[{"cruise_id":3,"cruise_name":"New Zealand Delight","board_datetime":"16-Jun-2025 09:15","cabin_no":"113","cabin_class":"Ocean View"}]},
{"_id":12,"passenger_name":"Sophia Young","passenger_dob":"03-Oct-1975","passenger_contact":"555-8888","guardian_name":"-","address":{"street":"66 Regent St","town":"London","postcode":"W1B","country":"United Kingdom of Great Britain and Northern Ireland"},"no_of_cruises":1,"cruises":[{"cruise_id":3,"cruise_name":"New Zealand Delight","board_datetime":"-","cabin_no":"114","cabin_class":"Ocean View"}]},
{"_id":13,"passenger_name":"James King","passenger_dob":"11-Jun-2007","passenger_contact":"555-9999","guardian_name":"Daniel Allen","address":{"street":"89 Oxford St","town":"London","postcode":"W1D","country":"United Kingdom of Great Britain and Northern Ireland"},"no_of_cruises":1,"cruises":[{"cruise_id":4,"cruise_name":"Queensland Islands","board_datetime":"07-Jul-2025 13:30","cabin_no":"2001","cabin_class":"Interior"}]},
{"_id":14,"passenger_name":"Olivia Scott","passenger_dob":"29-Sep-2011","passenger_contact":"555-0000","guardian_name":"Sophia Young","address":{"street":"66 Regent St","town":"London","postcode":"W1B","country":"United Kingdom of Great Britain and Northern Ireland"},"no_of_cruises":1,"cruises":[{"cruise_id":4,"cruise_name":"Queensland Islands","board_datetime":"07-Jul-2025 13:45","cabin_no":"2002","cabin_class":"Interior"}]},
{"_id":15,"passenger_name":"Henry Adams","passenger_dob":"08-Mar-1983","passenger_contact":"555-1212","guardian_name":"-","address":{"street":"101 Elm St","town":"Ottawa","postcode":"K1A","country":"Canada"},"no_of_cruises":1,"cruises":[{"cruise_id":4,"cruise_name":"Queensland Islands","board_datetime":"07-Jul-2025 14:15","cabin_no":"2023","cabin_class":"Balcony"}]},
{"_id":16,"passenger_name":"Grace Evans","passenger_dob":"19-Jul-1986","passenger_contact":"555-1313","guardian_name":"-","address":{"street":"34 High St","town":"Manchester","postcode":"M1","country":"United Kingdom of Great Britain and Northern Ireland"},"no_of_cruises":1,"cruises":[{"cruise_id":4,"cruise_name":"Queensland Islands","board_datetime":"07-Jul-2025 14:00","cabin_no":"2003","cabin_class":"Interior"}]},
{"_id":17,"passenger_name":"Ethan Turner","passenger_dob":"02-Dec-1992","passenger_contact":"555-1414","guardian_name":"-","address":{"street":"78 Queen St","town":"Brisbane","postcode":"4000","country":"Australia"},"no_of_cruises":1,"cruises":[{"cruise_id":4,"cruise_name":"Queensland Islands","board_datetime":"07-Jul-2025 14:30","cabin_no":"2022","cabin_class":"Balcony"}]},
{"_id":18,"passenger_name":"Mia Parker","passenger_dob":"23-Aug-1989","passenger_contact":"555-1515","guardian_name":"-","address":{"street":"123 Main St","town":"New York","postcode":"10001","country":"United States of America"},"no_of_cruises":1,"cruises":[{"cruise_id":5,"cruise_name":"Brisbane to Hobart","board_datetime":"08-Jul-2025 10:00","cabin_no":"2012","cabin_class":"Interior"}]},
{"_id":19,"passenger_name":"Lucas Collins","passenger_dob":"30-Apr-1977","passenger_contact":"555-1616","guardian_name":"-","address":{"street":"12 Maple Rd","town":"Toronto","postcode":"M5H","country":"Canada"},"no_of_cruises":1,"cruises":[{"cruise_id":5,"cruise_name":"Brisbane to Hobart","board_datetime":"08-Jul-2025 10:15","cabin_no":"2013","cabin_class":"Interior"}]},
{"_id":20,"passenger_name":"Ella Stewart","passenger_dob":"11-Nov-1998","passenger_contact":"555-1717","guardian_name":"-","address":{"street":"101 Elm St","town":"Ottawa","postcode":"K1A","country":"Canada"},"no_of_cruises":1,"cruises":[{"cruise_id":5,"cruise_name":"Brisbane to Hobart","board_datetime":"08-Jul-2025 10:30","cabin_no":"2014","cabin_class":"Interior"}]},
{"_id":21,"passenger_name":"Jack Morris","passenger_dob":"14-Feb-1984","passenger_contact":"555-1818","guardian_name":"-","address":{"street":"77 Broadway","town":"Chicago","postcode":"60601","country":"United States of America"},"no_of_cruises":1,"cruises":[{"cruise_id":5,"cruise_name":"Brisbane to Hobart","board_datetime":"08-Jul-2025 10:45","cabin_no":"4002","cabin_class":"Suite"}]},
{"_id":22,"passenger_name":"Chloe Rogers","passenger_dob":"06-Jun-1991","passenger_contact":"555-1919","guardian_name":"-","address":{"street":"77 Broadway","town":"Chicago","postcode":"60601","country":"United States of America"},"no_of_cruises":1,"cruises":[{"cruise_id":5,"cruise_name":"Brisbane to Hobart","board_datetime":"08-Jul-2025 11:00","cabin_no":"4004","cabin_class":"Suite"}]},
{"_id":23,"passenger_name":"Ryan Cook","passenger_dob":"09-Sep-1987","passenger_contact":"555-2020","guardian_name":"-","address":{"street":"45 Collins St","town":"Melbourne","postcode":"3000","country":"Australia"},"no_of_cruises":1,"cruises":[{"cruise_id":7,"cruise_name":"Melbourne to Auckland","board_datetime":"23-Oct-2025 15:00","cabin_no":"210","cabin_class":"Balcony"}]},
{"_id":24,"passenger_name":"Zoe Bailey","passenger_dob":"05-May-1993","passenger_contact":"555-2121","guardian_name":"-","address":{"street":"88 Wall St","town":"New York","postcode":"10005","country":"United States of America"},"no_of_cruises":1,"cruises":[{"cruise_id":8,"cruise_name":"Melbourne to Singapore","board_datetime":"30-Nov-2025 09:30","cabin_no":"8031","cabin_class":"Ocean View"}]},
{"_id":25,"passenger_name":"Leo Carter","passenger_dob":"03-Mar-1981","passenger_contact":"555-2223","guardian_name":"-","address":{"street":"123 George St","town":"Sydney","postcode":"2000","country":"Australia"},"no_of_cruises":1,"cruises":[{"cruise_id":9,"cruise_name":"Queensland Islands","board_datetime":"06-Dec-2025 14:00","cabin_no":"3001","cabin_class":"Suite"}]},
{"_id":26,"passenger_name":"Isla Mitchell","passenger_dob":"07-Jul-1996","passenger_contact":"555-2323","guardian_name":"-","address":{"street":"90 King St","town":"Vancouver","postcode":"V6B","country":"Canada"},"no_of_cruises":1,"cruises":[{"cruise_id":10,"cruise_name":"New Zealand Christmas Sail","board_datetime":"20-Dec-2025 09:00","cabin_no":"4031","cabin_class":"Balcony"}]},
{"_id":27,"passenger_name":"Nathan Perez","passenger_dob":"12-Dec-1985","passenger_contact":"555-2424","guardian_name":"-","address":{"street":"45 Collins St","town":"Melbourne","postcode":"3000","country":"Australia"},"no_of_cruises":1,"cruises":[{"cruise_id":8,"cruise_name":"Melbourne to Singapore","board_datetime":"30-Nov-2025 09:45","cabin_no":"8032","cabin_class":"Ocean View"}]},
{"_id":28,"passenger_name":"Ruby Roberts","passenger_dob":"10-Oct-1994","passenger_contact":"555-2525","guardian_name":"-","address":{"street":"56 Baker St","town":"London","postcode":"NW1","country":"United Kingdom of Great Britain and Northern Ireland"},"no_of_cruises":1,"cruises":[{"cruise_id":6,"cruise_name":"Australian Circumnavigation","board_datetime":"18-Sep-2025 16:00","cabin_no":"3002","cabin_class":"Suite"}]},
{"_id":29,"passenger_name":"Oscar Ward","passenger_dob":"01-Jan-1979","passenger_contact":"555-2626","guardian_name":"-","address":{"street":"55 Collins Ave","town":"Melbourne","postcode":"3001","country":"Australia"},"no_of_cruises":1,"cruises":[{"cruise_id":6,"cruise_name":"Australian Circumnavigation","board_datetime":"18-Sep-2025 16:15","cabin_no":"1011","cabin_class":"Interior"}]},
{"_id":30,"passenger_name":"Lily Ward","passenger_dob":"08-Aug-2018","passenger_contact":"555-2727","guardian_name":"Oscar Ward","address":{"street":"55 Collins Ave","town":"Melbourne","postcode":"3001","country":"Australia"},"no_of_cruises":1,"cruises":[{"cruise_id":6,"cruise_name":"Australian Circumnavigation","board_datetime":"18-Sep-2025 16:30","cabin_no":"1012","cabin_class":"Ocean View"}]},
{"_id":31,"passenger_name":"Noah Walker","passenger_dob":"02-Feb-1988","passenger_contact":"555-3030","guardian_name":"-","address":{"street":"123 George St","town":"Sydney","postcode":"2000","country":"Australia"},"no_of_cruises":3,"cruises":[{"cruise_id":1,"cruise_name":"Australian Circumnavigation","board_datetime":"02-Jun-2025 09:30","cabin_no":"1001","cabin_class":"Interior"},{"cruise_id":4,"cruise_name":"Queensland Islands","board_datetime":"07-Jul-2025 14:10","cabin_no":"1002","cabin_class":"Ocean View"},{"cruise_id":9,"cruise_name":"Queensland Islands","board_datetime":"06-Dec-2025 14:20","cabin_no":"1003","cabin_class":"Interior"}]},
{"_id":32,"passenger_name":"Ava Green","passenger_dob":"10-Oct-1992","passenger_contact":"555-4040","guardian_name":"-","address":{"street":"45 Collins St","town":"Melbourne","postcode":"3000","country":"Australia"},"no_of_cruises":3,"cruises":[{"cruise_id":2,"cruise_name":"Melbourne to Sydney","board_datetime":"16-Jun-2025 09:05","cabin_no":"4002","cabin_class":"Suite"},{"cruise_id":6,"cruise_name":"Australian Circumnavigation","board_datetime":"18-Sep-2025 16:10","cabin_no":"2001","cabin_class":"Interior"},{"cruise_id":8,"cruise_name":"Melbourne to Singapore","board_datetime":"30-Nov-2025 09:50","cabin_no":"8033","cabin_class":"Ocean View"}]},
{"_id":33,"passenger_name":"Liam Bennett","passenger_dob":"15-May-1985","passenger_contact":"555-5050","guardian_name":"-","address":{"street":"10 Queen St","town":"Auckland","postcode":"1010","country":"New Zealand"},"no_of_cruises":3,"cruises":[{"cruise_id":3,"cruise_name":"New Zealand Delight","board_datetime":"16-Jun-2025 09:25","cabin_no":"113","cabin_class":"Ocean View"},{"cruise_id":7,"cruise_name":"Melbourne to Auckland","board_datetime":"23-Oct-2025 15:10","cabin_no":"210","cabin_class":"Balcony"},{"cruise_id":10,"cruise_name":"New Zealand Christmas Sail","board_datetime":"20-Dec-2025 09:10","cabin_no":"2014","cabin_class":"Interior"}]},
{"_id":500,"passenger_name":"Dominik Kohl","passenger_dob":"12-Oct-1985","passenger_contact":"+61493336312","guardian_name":"-","address":{"street":"23 Banksia Avenue","town":"Melbourne","postcode":"3000","country":"Australia"},"no_of_cruises":0,"cruises":null},
{"_id":505,"passenger_name":"Stella Kohl","passenger_dob":"26-Jun-2012","passenger_contact":"-","guardian_name":"Dominik Kohl","address":{"street":"23 Banksia Avenue","town":"Melbourne","postcode":"3000","country":"Australia"},"no_of_cruises":0,"cruises":null},
{"_id":510,"passenger_name":"Poppy Kohl","passenger_dob":"09-Dec-2015","passenger_contact":"-","guardian_name":"Dominik Kohl","address":{"street":"23 Banksia Avenue","town":"Melbourne","postcode":"3000","country":"Australia"},"no_of_cruises":0,"cruises":null}

]);

db.passenger.find();


// (c)
// PLEASE PLACE REQUIRED MONGODB COMMAND/S FOR THIS PART HERE
// ENSURE that your query is formatted and has a semicolon
// (;) at the end of this answer
db.passenger.find(
    {
        "address.country": { $in: ["Australia", "New Zealand"] },
        "no_of_cruises": { $gt: 2 }
    },
    {
        _id: 1,
        passenger_name: 1,
        passenger_contact: 1,
        address: 1
    }
);


// (d)
// PLEASE PLACE REQUIRED MONGODB COMMAND/S FOR THIS PART HERE
// ENSURE that your statement is formatted and has a semicolon
// (;) at the end of each MongoDB statement


// (i) Add new passenger and first booking
db.passenger.insertMany([
{"_id":1000,"passenger_name":"Kiera Meier","passenger_dob":"7-Jun-2000","passenger_contact":"+61646381936","guardian_name":"-","address":{"street":"23 Woodside Avenue","town":"Melbourne","postcode":"3000","country":"Australia"},"no_of_cruises":1,"cruises":[{"cruise_id":9,"cruise_name":"Queensland Islands","board_datetime":"08-Jul-2025 11:00","cabin_no":"2022","cabin_class":"Balcony"}]}
]);


// Illustrate/confirm changes made
db.passenger.find({ _id: 1000 });

// (ii) Add second booking
db.passenger.deleteOne({ _id: 1000 });

db.passenger.insertMany([
{"_id":1000,"passenger_name":"Kiera Meier","passenger_dob":"7-Jun-2000","passenger_contact":"+61646381936","guardian_name":"-","address":{"street":"23 Woodside Avenue","town":"Melbourne","postcode":"3000","country":"Australia"},"no_of_cruises":2,"cruises":[{"cruise_id":9,"cruise_name":"Queensland Islands","board_datetime":"08-Jul-2025 11:00","cabin_no":"2022","cabin_class":"Balcony"},{"cruise_id":10,"cruise_name":"New Zealand Christmas Sail","board_datetime":"11-Aug-2025 10:00","cabin_no":"4004","cabin_class":"Suite"}]}
]);

// Illustrate/confirm changes made
db.passenger.find({ _id: 1000 });


/* (iii) Write a reflection of the difference
between inserting the passenger and booking data
into the Oracle versus MongoDB.

<<write your reflection here>>
Using Oracle to insert data feels more straightforward and intuitive. 
The syntax is simple—you just list the values in order. 
But in MongoDB, inserting data requires more attention to how the data is structured layer by layer, 
and the syntax rules with braces and brackets are much stricter.
*/
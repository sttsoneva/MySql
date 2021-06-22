#1 Table Design
#The SoftUni Taxi Company (stc) needs to hold information about cars, courses, drivers, clients, addresses and categories.
#Your task is to create a database called stc (SoftUni Taxi Company). Then you will have to create several tables:
#•	cars – contains information about the cars
#o	Each car has a make column, a model column, a year column, a mileage column, a condition  column and a category column
#•	courses – contains information about the courses
#o	Each course has a from_address column, a start column, a car column, a client column and a bill  column
#•	  drivers – contains information about the drivers 
#o	  Each driver has a first and last name columns, an age column and a rating column
#•	clients – contains information about the clients
#o	  Each client has a full name column and a phone number column
#•	addresses – contains information about the addresses
#•	categories – contains information about the categories
#o	  Contains the name of the category
#•	cars_drivers – a many to many mapping tables between the cars and the drivers
#o	Have composite primary key from the car_id column and the driver_id column 

CREATE TABLE addresses(
id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(100) NOT NULL
);

CREATE TABLE categories(
id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(10) NOT NULL
);

CREATE TABLE clients(
id INT PRIMARY KEY AUTO_INCREMENT,
full_name VARCHAR(50) NOT NULL,
phone_number VARCHAR(20) NOT NULL
);

CREATE TABLE drivers(
id INT PRIMARY KEY AUTO_INCREMENT,
first_name VARCHAR(30) NOT NULL,
last_name VARCHAR(30) NOT NULL,
age INT NOT NULL,
rating FLOAT DEFAULT 5.5
);


CREATE TABLE cars(
id INT PRIMARY KEY AUTO_INCREMENT,
make VARCHAR(20) NOT NULL,
model VARCHAR(20),
`year` INT NOT NULL DEFAULT 0,
mileage INT DEFAULT 0,
`condition` CHAR(1) NOT NULL,
category_id INT NOT NULL,
CONSTRAINT fk_cars_categories
FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE courses(
id INT PRIMARY KEY AUTO_INCREMENT,
from_address_id INT NOT NULL,
`start` DATETIME NOT NULL,
bill DECIMAL(10,2) DEFAULT 10,
car_id INT NOT NULL,
client_id INT NOT NULL,
CONSTRAINT fk_courses_cars
FOREIGN KEY (car_id) REFERENCES cars(id),
CONSTRAINT fk_courses_clients
FOREIGN KEY (client_id) REFERENCES clients(id)
);

CREATE TABLE cars_drivers(
car_id INT NOT NULL,
driver_id INT NOT NULL,
CONSTRAINT fk_cars_drivers_cars
FOREIGN KEY (car_id) REFERENCES cars(id),
CONSTRAINT fk_cars_drivers_drivers
FOREIGN KEY (driver_id) REFERENCES drivers(id)
);

ALTER TABLE courses
ADD CONSTRAINT fk_courses_addresses
FOREIGN KEY (from_address_id) REFERENCES addresses(id);

ALTER TABLE `cars_drivers` 
ADD PRIMARY KEY (`car_id`, `driver_id`);
;

#2
#When drivers are not working and need a taxi to transport them, they will also be registered 
#at the database as customers.
#You will have to insert records of data into the clients table, based on the drivers table. 
#For all drivers with an id between 10 and 20 (both inclusive), insert data in the clients table with the following values:
#•	full_name – get first and last name of the driver separated by single space
#•	phone_number – set it to start with (088) 9999 and the driver_id multiplied by 2
#o	 Example – the phone_number of the driver with id = 10 is (088) 999920

INSERT INTO clients (full_name, phone_number)
SELECT CONCAT_WS(' ', first_name, last_name), CONCAT('(088) 9999', id*2) 
FROM drivers AS d
WHERE d.id BETWEEN 10 AND 20;

#3
#After many kilometers and over the years, the condition of cars is expected to deteriorate.
#Update all cars and set the condition to be 'C'. The cars  must have a mileage greater than 800000 (inclusive) or NULL and must be older than 2010(inclusive).
#Skip the cars that contain a make value of Mercedes-Benz. They can work for many more years.

UPDATE cars
SET `condition` = 'C'
WHERE year <= 2010 AND ( mileage >=800000 OR mileage IS NULL ) AND make != 'Mercedes-Benz';

#4
#Some of the clients have not used the services of our company recently, so we need to remove them 
#from the database.	
#Delete all clients from clients table, that do not have any courses and the count of the characters in the full_name is more than 3 characters. 

DELETE FROM clients 
WHERE CHAR_LENGTH(full_name) > 3 AND id NOT IN (SELECT co.client_id FROM courses AS co);

#5
#Extract the info about all the cars. 
#Order the results by car’s id.

SELECT make, model, `condition` FROM cars
ORDER BY id;

#6
#Select all drivers and cars that they drive. Extract the driver’s first and last name from the drivers table and the make, the model and the mileage from the cars table. Order the result by the mileage in descending order, then by the first name alphabetically. 
#Skip all cars that have NULL as a value for the mileage.

SELECT d.first_name, d.last_name, c.make, c.model, c.mileage FROM drivers AS d
LEFT JOIN cars_drivers AS cd
ON d.id = cd.driver_id
LEFT JOIN cars AS c
ON cd.car_id = c.id
WHERE c.mileage IS NOT NULL
ORDER BY c.mileage DESC, d.first_name;

#7
#Extract from the database all the cars and the count of their courses. Also display the average bill of each course by the car, rounded to the second digit.
#Order the results descending by the count of courses, then by the car’s id. 
#Skip the cars with exactly 2 courses.

SELECT c.id AS car_id, c.make AS make, c.mileage AS mileage, COUNT(co.id) AS count_of_courses, ROUND(AVG(co.bill), 2) AS avg_bill
FROM cars AS c
LEFT JOIN courses AS co
ON c.id = co.car_id
GROUP BY c.id
HAVING count_of_courses !=2
ORDER BY count_of_courses DESC, car_id;

#8
#Extract the regular clients, who have ridden in more than one car. The second letter of the customer's full name must be 'a'. Select the full name, the count of cars that he ridden and total sum of all courses.
#Order clients by their full_name.

SELECT cl.full_name AS full_name, COUNT(co.car_id) AS count_of_cars, SUM(co.bill) AS total_sum
FROM clients AS cl
LEFT JOIN courses AS co
ON cl.id = co.client_id
GROUP BY cl.full_name
HAVING count_of_cars > 1 AND SUBSTR(cl.full_name,2,1) = 'a'
ORDER BY full_name;

#9
#The headquarters want us to make a query that shows the complete information about all courses in the database. The information that they need is the address, if the course is made in the Day (between 6 and 20(inclusive both)) or in the Night (between 21 and 5(inclusive both)), the bill of the course, the full name of the client, the car maker, the model and the name of the category.
#Order the results by course id.

SELECT ad.`name` AS `name`,(
	CASE
		WHEN EXTRACT(HOUR FROM co.`start`) BETWEEN 6 AND 20 THEN 'Day'
        ELSE 'Night'
        END
)AS day_time, co.bill AS bill, cl.full_name AS full_name, ca.make AS make, ca.model AS model, cat.`name` AS category_name
FROM courses AS co
LEFT JOIN addresses AS ad
ON ad.id = co.from_address_id
LEFT JOIN clients AS cl
ON cl.id = co.client_id
LEFT JOIN cars AS ca
ON co.car_id = ca.id
LEFT JOIN categories AS cat
ON cat.id = ca.category_id
ORDER BY co.id;

#10
#Create a user defined function with the name udf_courses_by_client (phone_num VARCHAR (20)) that receives a client’s phone number and returns the number of courses that clients have in database.

CREATE FUNCTION udf_courses_by_client (phone_num VARCHAR (20)) 
RETURNS INT
DETERMINISTIC
BEGIN
	RETURN ( 
		SELECT COUNT(cl.id) FROM clients AS cl
        LEFT JOIN courses AS co
        ON co.client_id = cl.id
        WHERE cl.phone_number = phone_num
    );
END

#11
#Create a stored procedure udp_courses_by_address which accepts the following parameters:
#•	address_name (with max length 100)
#
#Extract data about the addresses with the given address_name. The needed data is the name of the address, full name of the client, level of bill (depends of course bill – Low – lower than 20(inclusive), Medium – lower than 30(inclusive), and High), make and condition of the car and the name of the category.
# Order addresses by make, then by client’s full name.

CREATE PROCEDURE udp_courses_by_address (address_name VARCHAR(100))
BEGIN 
	SELECT addr.`name`, cl.full_name AS full_name, (
	CASE
		WHEN co.bill <= 20 THEN 'Low'
        WHEN co.bill BETWEEN 21 AND 30 THEN 'Medium'
        ELSE 'High'
        END
)AS level_of_bill, car.make AS make, car.`condition` AS `condition`, cat.`name` AS cat_name
FROM clients AS cl 
LEFT JOIN courses AS co
ON cl.id = co.client_id
LEFT JOIN addresses AS addr
ON addr.id = co.from_address_id
LEFT JOIN cars AS car
ON car.id = co.car_id
LEFT JOIN categories AS cat
ON cat.id = car.category_id
WHERE address_name = addr.`name`
ORDER BY car.make, cl.full_name;
END
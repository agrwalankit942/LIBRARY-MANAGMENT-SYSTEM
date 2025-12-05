SELECT name 
FROM sys.databases;
USE LibraryDB;
--AUTHORS
CREATE TABLE Authors (
author_id INT IDENTITY(1,1) PRIMARY KEY,
name NVARCHAR(255) NOT NULL,
bio NVARCHAR(MAX),
created_at DATETIME2 DEFAULT SYSUTCDATETIME()
);

INSERT INTO Authors (name, bio) VALUES
('Robert Lafore', 'Writer of Data Structures books'),
('Thomas Cormen', 'Author of CLRS algorithms'),
('Mark Lutz', 'Python expert and author'),
('Eric Freeman', 'Design Patterns author'),
('Paulo Coelho', 'Novelist');


-- PUBLISHERS
CREATE TABLE Publishers (
publisher_id INT IDENTITY(1,1) PRIMARY KEY,
name NVARCHAR(255) NOT NULL,
address NVARCHAR(500),
phone NVARCHAR(50),
created_at DATETIME2 DEFAULT SYSUTCDATETIME()
);

---DATA INSERTION
INSERT INTO Publishers (name, address, phone) VALUES
('Pearson', 'New York', '1111111111'),
('O Reilly Media', 'California', '2222222222'),
('Oxford Press', 'London', '3333333333'),
('McGraw Hill', 'USA', '4444444444'),
('Cambridge Press', 'UK', '5555555555');


---CATEGORIES

CREATE TABLE Categories (
category_id INT IDENTITY(1,1) PRIMARY KEY,
name NVARCHAR(200) NOT NULL,
description NVARCHAR(500)
);

INSERT INTO Categories (name, description) VALUES
('Computer Science', 'Programming and CS'),
('AI', 'Artificial Intelligence'),
('Databases', 'SQL, DBMS'),
('Networking', 'Network fundamentals'),
('Fiction', 'Story books');


-- Books
CREATE TABLE Books (
book_id INT IDENTITY(1,1) PRIMARY KEY,
title NVARCHAR(500) NOT NULL,
subtitle NVARCHAR(500),
isbn NVARCHAR(50),
publisher_id INT NULL,
publication_year SMALLINT,
pages SMALLINT,
language NVARCHAR(100),
category_id INT NULL,
description NVARCHAR(MAX),
created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
CONSTRAINT FK_Books_Publishers FOREIGN KEY (publisher_id) REFERENCES Publishers(publisher_id),
CONSTRAINT FK_Books_Categories FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

INSERT INTO Books (title, isbn, publisher_id, publication_year, pages, language, category_id, description)
VALUES
('Data Structures in C', 'ISBN001', 1, 2002, 500, 'English', 1, 'DS book'),
('Introduction to Algorithms', 'ISBN002', 2, 2009, 1200, 'English', 1, 'Algorithm book'),
('Learning Python', 'ISBN003', 1, 2013, 1600, 'English', 1, 'Python programming'),
('AI Modern Approach', 'ISBN004', 3, 2015, 1000, 'English', 2, 'AI fundamentals'),
('The Alchemist', 'ISBN005', 5, 1993, 200, 'English', 5, 'Fiction novel');




CREATE TABLE BookAuthors (
book_id INT NOT NULL,
author_id INT NOT NULL,
PRIMARY KEY (book_id, author_id),
CONSTRAINT FK_BookAuthors_Books FOREIGN KEY (book_id) REFERENCES Books(book_id),
CONSTRAINT FK_BookAuthors_Authors FOREIGN KEY (author_id) REFERENCES Authors(author_id)
);

INSERT INTO BookAuthors (book_id, author_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 2),
(5, 5);

CREATE TABLE Copies (
copy_id INT IDENTITY(1,1) PRIMARY KEY,
book_id INT NOT NULL,
accession_no NVARCHAR(100) UNIQUE,
location NVARCHAR(200), -- e.g., Shelf-3A
status NVARCHAR(50) DEFAULT 'available', -- available, loaned, reserved, lost, maintenance
price DECIMAL(10,2) NULL,
added_at DATETIME2 DEFAULT SYSUTCDATETIME(),
CONSTRAINT FK_Copies_Books FOREIGN KEY (book_id) REFERENCES Books(book_id)
);

INSERT INTO Copies (book_id, accession_no, location, status, price) VALUES
(1, 'ACC001', 'Shelf A1', 'available', 450.00),
(2, 'ACC002', 'Shelf A2', 'available', 600.00),
(3, 'ACC003', 'Shelf B1', 'available', 550.00),
(4, 'ACC004', 'Shelf B2', 'available', 700.00),
(5, 'ACC005', 'Shelf C1', 'available', 300.00);



CREATE TABLE Members (
member_id INT IDENTITY(1,1) PRIMARY KEY,
full_name NVARCHAR(255) NOT NULL,
email NVARCHAR(255) UNIQUE,
phone NVARCHAR(50),
address NVARCHAR(500),
joined_date DATE DEFAULT CAST(SYSUTCDATETIME() AS DATE),
membership_type NVARCHAR(50) DEFAULT 'standard', -- student, faculty, public, staff
is_active BIT DEFAULT 1
);

INSERT INTO Members (full_name, email, phone, address, membership_type)
VALUES
('Alice Johnson', 'alice@mail.com', '9991111111', 'Delhi', 'student'),
('Ravi Kumar', 'ravi@mail.com', '9992222222', 'Mumbai', 'public'),
('Priya Singh', 'priya@mail.com', '9993333333', 'Kolkata', 'student'),
('John Doe', 'john@mail.com', '9994444444', 'Chennai', 'staff'),
('Meera Shah', 'meera@mail.com', '9995555555', 'Pune', 'faculty');

CREATE TABLE Staff (
staff_id INT IDENTITY(1,1) PRIMARY KEY,
username NVARCHAR(100) UNIQUE NOT NULL,
password_hash NVARCHAR(500) NOT NULL, -- store hashed passwords
full_name NVARCHAR(255),
role NVARCHAR(50) DEFAULT 'librarian', -- admin, librarian
created_at DATETIME2 DEFAULT SYSUTCDATETIME()
);

INSERT INTO Staff (username, password_hash, full_name, role)
VALUES
('admin', 'pass123', 'Admin User', 'admin'),
('lib1', 'pass123', 'Librarian One', 'librarian'),
('lib2', 'pass123', 'Librarian Two', 'librarian'),
('staff1', 'pass123', 'Staff Member 1', 'assistant'),
('staff2', 'pass123', 'Staff Member 2', 'assistant');


CREATE TABLE Loans (
loan_id INT IDENTITY(1,1) PRIMARY KEY,
copy_id INT NOT NULL,
member_id INT NOT NULL,
staff_id INT NULL, -- who issued
issued_date DATE DEFAULT CAST(SYSUTCDATETIME() AS DATE),
due_date DATE NOT NULL,
returned_date DATE NULL,
status NVARCHAR(50) DEFAULT 'issued', -- issued, returned, overdue, lost
fine_amount DECIMAL(10,2) DEFAULT 0,
CONSTRAINT FK_Loans_Copies FOREIGN KEY (copy_id) REFERENCES Copies(copy_id),
CONSTRAINT FK_Loans_Members FOREIGN KEY (member_id) REFERENCES Members(member_id),
CONSTRAINT FK_Loans_Staff FOREIGN KEY (staff_id) REFERENCES Staff(staff_id)
);

INSERT INTO Loans (copy_id, member_id, staff_id, issued_date, due_date, status)
VALUES
(1, 1, 1, '2025-01-01', '2025-01-15', 'issued'),
(2, 2, 2, '2025-01-05', '2025-01-20', 'issued'),
(3, 3, 1, '2025-01-10', '2025-01-25', 'issued'),
(4, 4, 3, '2025-01-08', '2025-01-23', 'issued'),
(5, 5, 2, '2025-01-12', '2025-01-27', 'issued');


CREATE TABLE Reservations (
reservation_id INT IDENTITY(1,1) PRIMARY KEY,
book_id INT NOT NULL,
member_id INT NOT NULL,
reserved_at DATETIME2 DEFAULT SYSUTCDATETIME(),
status NVARCHAR(50) DEFAULT 'active', -- active, cancelled, completed
CONSTRAINT FK_Reservations_Books FOREIGN KEY (book_id) REFERENCES Books(book_id),
CONSTRAINT FK_Reservations_Members FOREIGN KEY (member_id) REFERENCES Members(member_id)
);

INSERT INTO Reservations (book_id, member_id, status)
VALUES
(1, 2, 'active'),
(2, 3, 'active'),
(3, 4, 'active'),
(4, 5, 'active'),
(5, 1, 'active');

CREATE TABLE Payments (
payment_id INT IDENTITY(1,1) PRIMARY KEY,
member_id INT NOT NULL,
loan_id INT NULL,
amount DECIMAL(10,2) NOT NULL,
paid_at DATETIME2 DEFAULT SYSUTCDATETIME(),
payment_method NVARCHAR(50) DEFAULT 'cash',
CONSTRAINT FK_Payments_Members FOREIGN KEY (member_id) REFERENCES Members(member_id),
CONSTRAINT FK_Payments_Loans FOREIGN KEY (loan_id) REFERENCES Loans(loan_id)
);

INSERT INTO Payments (member_id, loan_id, amount, payment_method)
VALUES
(1, 1, 50.00, 'cash'),
(2, 2, 30.00, 'card'),
(3, 3, 20.00, 'cash'),
(4, 4, 15.00, 'cash'),
(5, 5, 10.00, 'card');


CREATE INDEX IDX_Books_ISBN ON Books(isbn);
CREATE INDEX IDX_Copies_Status ON Copies(status);
CREATE INDEX IDX_Loans_Status ON Loans(status);

SELECT * FROM Publishers;
SELECT * FROM Authors;
SELECT * FROM Categories;
SELECT * FROM Books;
SELECT * FROM BookAuthors;
SELECT * FROM Copies;
SELECT * FROM Members;
SELECT * FROM Staff;
SELECT * FROM Loans;
SELECT * FROM Reservations;
SELECT * FROM Payments;


SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Books';

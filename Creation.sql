CREATE TABLE Movies (
    ID NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT by 1) PRIMARY KEY ,
    Title VARCHAR2(255) CHECK (Title IS NOT NULL AND Title <> '') ,
    Genre VARCHAR2(100)  CHECK (Genre IS NOT NULL AND Genre <> ''),
    Director VARCHAR2(100) CHECK (Director IS NOT NULL AND Director <> ''),
    Description CLOB not null,
    Duration NUMBER CHECK (Duration > 0) NOT NULL,
    Poster blob not null,
    Trailer blob not null
);

CREATE TABLE Halls (
    ID NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT by 1) PRIMARY KEY,
    HallName VARCHAR2(50) CHECK (HallName IS NOT NULL AND HallName <> ''),
    RowsCount Number CHECK (RowsCount > 0) NOT NULL,
        SeatsCount NUMBER CHECK (SeatsCount > 0) NOT NULL
);

CREATE TABLE Sessions (
    ID NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT by 1) PRIMARY KEY,
    MovieID NUMBER REFERENCES Movies(ID) on delete cascade,
    HallID NUMBER REFERENCES Halls(ID) on delete cascade,
    StartTime date NOT NULL
);

CREATE TABLE Reservations (
    ID NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT by 1) PRIMARY KEY,
    SessionID NUMBER REFERENCES Sessions(ID) on delete cascade,
    UserID NUMBER REFERENCES Users(ID) on delete cascade,
    RowNumber NUMBER CHECK (RowNumber >0) NOT NULL,
    SeatNumber NUMBER CHECK (SeatNumber >0) NOT NUll,
    Status VARCHAR2(30) NOT NULL CHECK (Status IN ('Забронирован','Куплен'))
);

CREATE TABLE Users (
    ID NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT by 1) PRIMARY KEY,
    Login VARCHAR2(50) CHECK (Login IS NOT NULL AND Login <> '') ,
    Password VARCHAR2(255) CHECK (Password IS NOT NULL AND Password <> '') ,
    Email VARCHAR2(100) CHECK (Email IS NOT NULL AND Email <> '')
);

-- Удаление таблицы "Movies"
DROP TABLE Movies CASCADE CONSTRAINTS;

-- Удаление таблицы "Halls"
DROP TABLE Halls CASCADE CONSTRAINTS;

-- Удаление таблицы "Sessions"
DROP TABLE Sessions CASCADE CONSTRAINTS;

-- Удаление таблицы "Reservations"
DROP TABLE Reservations CASCADE CONSTRAINTS;

-- Удаление таблицы "Users"
DROP TABLE Users CASCADE CONSTRAINTS;

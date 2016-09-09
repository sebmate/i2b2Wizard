-- Generic (Oracle XE):

CREATE USER I2B2DB_USR IDENTIFIED BY I2B2DB_PWD DEFAULT TABLESPACE USERS;
GRANT CONNECT TO I2B2DB_USR;
GRANT RESOURCE TO I2B2DB_USR;
GRANT CREATE TYPE TO I2B2DB_USR;
GRANT CREATE ROLE TO I2B2DB_USR;
GRANT CREATE TABLE TO I2B2DB_USR;
GRANT CREATE VIEW TO I2B2DB_USR;
GRANT CREATE PROCEDURE TO I2B2DB_USR;
GRANT CREATE SEQUENCE TO I2B2DB_USR;
GRANT CREATE TRIGGER TO I2B2DB_USR;

--~ Создание пользователя и прав на psql
ALTER ROLE "user" WITH LOGIN;
ALTER ROLE "user" WITH CREATEDB;
ALTER ROLE "user" WITH REPLICATION;

--~ Создание базы данных, владелец которой user
CREATE DATABASE electro_temperature OWNER "user";

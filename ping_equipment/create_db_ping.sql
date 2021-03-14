CREATE DATABASE ping OWNER "user";


ALTER TABLE IF EXISTS equipment ADD COLUMN  -- Оборудование (устройства)
(
  ip          inet   NOT NULL,              -- IP-адрес устройства
  name        text   NOT NULL,              -- Название устройства
  description text   NOT NULL,              -- Описание устройства
  visio_name  text           ,              -- Название устройства в VISIO
  location    text   NOT NULL,              -- Местонахождение устройства
  PRIMARY KEY ( ip )
);


CREATE UNLOGGED TABLE current_state      -- Значения на текущий момент
(
  ip          inet      NOT NULL,        -- IP-адрес устройства
  time        timestamp NOT NULL,        -- текущее время
  state       boolean   NOT NULL,        -- состояние пинга

  PRIMARY KEY ( ip ),
  FOREIGN KEY ( ip )
    REFERENCES equipment( ip )
    ON DELETE CASCADE
    ON UPDATE CASCADE
);


CREATE TABLE ping_changes                -- Журнал фиксации изменений
(
  ip          inet    NOT NULL,          -- IP-адрес устройства
  time      timestamp NOT NULL,          -- Время
  state       boolean NOT NULL,          -- состояние пинга
  PRIMARY KEY ( ip ),
  FOREIGN KEY ( ip )
    REFERENCES equipment( ip )
    ON DELETE CASCADE
    ON UPDATE CASCADE
);


--~ psql $HOST $DB -U user -t <<EOF
--~ \copy equipment (ip, name, description, visio_name) FROM '/home/user/ping_equipment/config.txt' WITH DELIMITER '|'
--~ EOF

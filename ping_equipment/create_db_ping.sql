/* База данных PostgreSQL для ping_equipment */


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
(                                        -- Записи хранятся 31 день
  ip          inet    NOT NULL,          -- IP-адрес устройства
  time      timestamp NOT NULL,          -- Время
  state       boolean NOT NULL,          -- состояние пинга
  FOREIGN KEY ( ip )
    REFERENCES equipment( ip )
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE INDEX ping_changes_time_idx ON ping_changes("time");
ALTER TABLE ping_changes CLUSTER ON ping_changes_time_idx;


CREATE TABLE ping_changes_archive        -- Журнал-архив фиксации изменений
(
  ip          inet    NOT NULL,          -- IP-адрес устройства
  time      timestamp NOT NULL,          -- Время
  state       boolean NOT NULL,          -- состояние пинга
  FOREIGN KEY ( ip )
    REFERENCES equipment( ip )
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
WITH (autovacuum_freeze_min_age='0');


CREATE FUNCTION public.add_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
/* Функция при изменении значений сохраняет копии в две таблицы:
   1. таблица изменений ping_changes
   2. таблица архива изменений ping_changes_archive
   */
  INSERT INTO ping_changes(    ip,     time,     state)
    VALUES                (NEW.ip, NEW.time, NEW.state);

  INSERT INTO ping_changes_archive(    ip,     time,     state)
    VALUES                        (NEW.ip, NEW.time, NEW.state);

  RETURN NEW;
END;
$$;


CREATE TRIGGER trig_if_changes AFTER UPDATE ON current_state
  FOR EACH ROW WHEN (((old.state IS DISTINCT FROM new.state)
  EXECUTE PROCEDURE add_changes();


CREATE FUNCTION remove_old_inserts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN  -- функция удаляет из таблицы записи старше 31 дня
  DELETE FROM ping_changes WHERE (now() - time) > '31 days';
  RETURN NEW;
END;
$$;


CREATE TRIGGER trig_if_insert AFTER INSERT ON ping_changes
  FOR EACH STATEMENT
  EXECUTE PROCEDURE remove_old_inserts();







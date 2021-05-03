/* База данных temp для приложения take_temp */


CREATE FUNCTION add_not_null_temp() RETURNS trigger
    LANGUAGE plpgsql  -- защита от пустых значений
    AS $$             -- вместо ошибки
BEGIN
  if  NEW.temperature = NULL then
      NEW.temperature = OLD.temperature;
  end if;
  RETURN NEW;
END;
$$;


CREATE FUNCTION add_temp_changes() RETURNS trigger
    LANGUAGE plpgsql    -- Триггерная функция делает запись в таблицы:
    AS $$               -- temp_changes и temp_changes_archive,
DECLARE                 -- если температура изменилась
  temp_plus  integer;   -- дополнительная защита от ложного срабатывания
  temp_minus integer;   -- датчиков температур
BEGIN
  temp_plus  := OLD.temperature + 5;  -- датчики DHT11 иногда могут давать
  temp_minus := OLD.temperature - 5;  -- резко завышенную или заниженную температуру

  if  (NEW.temperature < temp_plus ) AND 
      (NEW.temperature > temp_minus) OR
      (NEW.location    = 'Гисметео') then  -- данные, собираемые с сайта Гисметео
        INSERT INTO temp_changes
                (location,         time,     temperature)
        VALUES  (NEW.location, NEW.time, NEW.temperature);
        INSERT INTO temp_changes_archive
                (location,         time,     temperature)
        VALUES  (NEW.location, NEW.time, NEW.temperature);
    RETURN NEW;
  end if;
    RETURN NULL;
END;
$$;


CREATE FUNCTION remove_old_inserts() RETURNS trigger
    LANGUAGE plpgsql  -- Функция удаляет записи из таблицы
    AS $$             -- temp_changes давностью больше месяца
BEGIN
  DELETE FROM temp_changes WHERE (now() - time) > '31 days';
  RETURN NEW;
END;
$$;


CREATE TRIGGER trig_if_changes AFTER UPDATE ON temp_current
  FOR EACH ROW WHEN ((old.temperature IS DISTINCT FROM new.temperature))
  EXECUTE PROCEDURE add_temp_changes();

CREATE TRIGGER trig_if_insert AFTER INSERT ON temp_changes
  FOR EACH STATEMENT
  EXECUTE PROCEDURE remove_old_inserts();

CREATE TRIGGER trig_if_null BEFORE INSERT OR UPDATE ON temp_current
  FOR EACH ROW WHEN ((new.temperature = NULL::integer))
  EXECUTE PROCEDURE add_not_null_temp();


CREATE TABLE locations (
    ip          inet    NOT NULL,  -- IP-адрес микрокомпьютера "R"
    location    text    NOT NULL,  -- название объекта
    type        integer NOT NULL,  -- тип (модель) датчика
    gpio        integer NOT NULL,  -- GPIO контакта на микрокомпьютере
    blue        integer NOT NULL,  -- порог пониженных температур для объекта
    yellow      integer NOT NULL,  -- порог отклонения от нормы температуры
    red         integer NOT NULL,  -- порог критического превышения
    correction  integer NOT NULL   -- калибровка датчика
);


CREATE UNLOGGED TABLE temp_current ( -- Значения текущего времени
    location    text      NOT NULL,  -- название объекта
    "time"      timestamp NOT NULL,  -- время измерения
    temperature integer   NOT NULL   -- значение
);


CREATE TABLE temp_changes          ( -- Таблица изменений температур
    location    text      NOT NULL,  -- название объекта
    "time"      timestamp NOT NULL,  -- время измерения
    temperature integer   NOT NULL   -- значение
);


CREATE TABLE temp_changes_archive  ( -- Архив значений температур
    location    text      NOT NULL,  -- название объекта
    "time"      timestamp NOT NULL,  -- время измерения
    temperature integer   NOT NULL   -- значение
);


-- Различные ограничения на таблицы
ALTER TABLE ONLY locations
  ADD CONSTRAINT locations_location_key UNIQUE (location);
ALTER TABLE ONLY locations
  ADD CONSTRAINT locations_pkey PRIMARY KEY (location);

ALTER TABLE ONLY temp_current
  ADD CONSTRAINT temp_current_pkey PRIMARY KEY (location);
ALTER TABLE ONLY temp_current
  ADD CONSTRAINT temp_current_location_fkey
  FOREIGN KEY (location) REFERENCES locations(location)
  ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY temp_changes_archive
  ADD CONSTRAINT temp_changes_archive_location_fkey
  FOREIGN KEY (location) REFERENCES locations(location)
  ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY temp_changes
  ADD CONSTRAINT temp_changes_location_fkey
  FOREIGN KEY (location) REFERENCES locations(location)
  ON UPDATE CASCADE ON DELETE CASCADE;

-- индекс для повышения производительности запросов
CREATE INDEX temp_changes_time_idx ON temp_changes USING btree ("time");



/* База данных PostgreSQL для дегидратора */


CREATE FUNCTION add_average_in_operating_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- после вставки значений в таблицу "архив наработки"
  -- подсчитывает и вставляет последнее среднее значение наработки
  UPDATE operating_time_archive
    SET average = (SELECT (average * 100)::smallint FROM operating_time)
      WHERE time = (
        SELECT time FROM operating_time_archive
          ORDER BY time DESC LIMIT 1
      );
  RETURN NEW;
END;
$$;


CREATE FUNCTION add_new_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  if (NEW.c_life <> OLD.c_life) OR   -- если значения изменились
     (NEW.c__low <> OLD.c__low) OR
     (NEW.c_humi <> OLD.c_humi) OR
     (NEW.a_summ <> OLD.a_summ) OR
     (NEW.a_exrt <> OLD.a_exrt) OR
     (NEW.a_high <> OLD.a_high) OR
     (NEW.a__low <> OLD.a__low) OR
     (NEW.a_humi <> OLD.a_humi) OR
     (NEW.a_faul <> OLD.a_faul) then

    INSERT INTO                      -- то делает первую копию значений
      dehydrator_changes(            -- в таблицу dehydrator_changes
                  ip,
                  time,
                  c_life,
                  c_temp,
                  c_high,
                  c__low,
                  c_humi,
                  a_summ,
                  a_exrt,
                  a_high,
                  a__low,
                  a_humi,
                  a_faul
      ) VALUES(
              NEW.ip,
              NEW.time,
              NEW.c_life,
              NEW.c_temp,
              NEW.c_high,
              NEW.c__low,
              NEW.c_humi,
              NEW.a_summ,
              NEW.a_exrt,
              NEW.a_high,
              NEW.a__low,
              NEW.a_humi,
              NEW.a_faul
      );

    INSERT INTO                      -- вторую копию значений
      dehydrator_changes_archive(    -- в таблицу dehydrator_changes_archive
                  ip,
                  time,
                  c_life,
                  c_temp,
                  c_high,
                  c__low,
                  c_humi,
                  a_summ,
                  a_exrt,
                  a_high,
                  a__low,
                  a_humi,
                  a_faul
      ) VALUES(
              NEW.ip,
              NEW.time,
              NEW.c_life,
              NEW.c_temp,
              NEW.c_high,
              NEW.c__low,
              NEW.c_humi,
              NEW.a_summ,
              NEW.a_exrt,
              NEW.a_high,
              NEW.a__low,
              NEW.a_humi,
              NEW.a_faul
      );

  end if;
  RETURN NEW;
END;
$$;


CREATE FUNCTION add_new_operating_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  if (NEW.c_life <> OLD.c_life) then -- если значения наработки изменились

    INSERT INTO                      -- то делает копию значений
      operating_time_archive(        -- в таблицу "архив наработки"
                  c_life,
                  ip,
                  time
      ) VALUES(
              NEW.c_life,
              NEW.ip,
              NEW.time
      );
  end if;
  RETURN NEW;
END;
$$;


CREATE FUNCTION remove_old_inserts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- удаляет из таблицы строки старше 31 дня
  DELETE FROM dehydrator_changes WHERE (now() - time) > '31 days';
  RETURN NEW;
END;
$$;


CREATE TABLE dehydrator_changes (
    c_life smallint,
    c_temp smallint,
    c_high smallint,
    c__low smallint,
    c_humi smallint,
    ip inet NOT NULL,
    "time" timestamp without time zone NOT NULL,
    a_summ boolean DEFAULT false,
    a_exrt boolean DEFAULT false,
    a_high boolean DEFAULT false,
    a__low boolean DEFAULT false,
    a_humi boolean DEFAULT false,
    a_faul boolean DEFAULT false
);


CREATE TABLE dehydrator_changes_archive (
    c_life smallint,
    c_temp smallint,
    c_high smallint,
    c__low smallint,
    c_humi smallint,
    ip inet NOT NULL,
    "time" timestamp without time zone NOT NULL,
    a_summ boolean DEFAULT false,
    a_exrt boolean DEFAULT false,
    a_high boolean DEFAULT false,
    a__low boolean DEFAULT false,
    a_humi boolean DEFAULT false,
    a_faul boolean DEFAULT false
)
WITH (autovacuum_freeze_min_age='0');  -- архив сразу замораживается


CREATE TABLE dehydrator_current (
    c_life smallint,
    c_temp smallint,
    c_high smallint,
    c__low smallint,
    c_humi smallint,
    ip inet NOT NULL,
    "time" timestamp without time zone NOT NULL,
    a_summ boolean DEFAULT false,
    a_exrt boolean DEFAULT false,
    a_high boolean DEFAULT false,
    a__low boolean DEFAULT false,
    a_humi boolean DEFAULT false,
    a_faul boolean DEFAULT false,
    CONSTRAINT dehydrator_current_c_life_check  CHECK ((c_life >  0)),
    CONSTRAINT dehydrator_current_c_life_check1 CHECK ((c_high >= 0)),
    CONSTRAINT dehydrator_current_c_life_check2 CHECK ((c__low >= 0)),
    CONSTRAINT dehydrator_current_c_life_check3 CHECK ((c_humi >= 0))
);



CREATE VIEW operating_time AS
 WITH last_c_life AS (
         SELECT dehydrator_changes.c_life,
            dehydrator_changes."time"
           FROM dehydrator_changes
          WHERE (dehydrator_changes.c_life = ( SELECT dehydrator_current.c_life
                   FROM dehydrator_current))
          ORDER BY dehydrator_changes."time"
         LIMIT 1
        ), last_but_one AS (
         SELECT dehydrator_changes.c_life,
            dehydrator_changes."time"
           FROM dehydrator_changes
          WHERE (dehydrator_changes.c_life = (( SELECT dehydrator_current.c_life
                   FROM dehydrator_current) - 1))
          ORDER BY dehydrator_changes."time"
         LIMIT 1
        )
 SELECT l1.c_life AS last_c_life,
    l1."time" AS last_time,
    l2.c_life AS last_but_one_c_life,
    l2."time" AS last_but_one_time,
    (((1)::double precision / ((date_part('epoch'::text, (l1."time" - l2."time")) / (3600)::double precision) / (24)::double precision)))::numeric(3,2) AS average
   FROM last_c_life l1,
    last_but_one l2;


CREATE VIEW dehydrator_v AS
 SELECT dehydrator_current.c_life,
    dehydrator_current.c_temp,
    dehydrator_current.c_high,
    (((dehydrator_current.c__low)::numeric(4,1) / (10)::numeric))::numeric(4,1) AS c__low,
    (((dehydrator_current.c_humi)::numeric(4,1) / (10)::numeric))::numeric(4,1) AS c_humi,
    date_trunc('sec'::text, dehydrator_current."time") AS c_time,
    dehydrator_current.a_summ,
    dehydrator_current.a_exrt,
    dehydrator_current.a_high,
    dehydrator_current.a__low,
    dehydrator_current.a_humi,
    dehydrator_current.a_faul,
    dehydrator_current.ip,
    operating_time.average
   FROM dehydrator_current,
    operating_time;


CREATE TABLE locations (
    ip inet NOT NULL,
    location text NOT NULL,
    own text NOT NULL
);


CREATE TABLE operating_time_archive (
    average smallint,
    c_life smallint,
    ip inet NOT NULL,
    "time" timestamp without time zone NOT NULL
);


ALTER TABLE ONLY dehydrator_current
    ADD CONSTRAINT dehydrator_current_ip_key UNIQUE (ip);

ALTER TABLE ONLY locations
    ADD CONSTRAINT loc_ip_idx PRIMARY KEY (ip);

ALTER TABLE ONLY locations
    ADD CONSTRAINT locations_location_key UNIQUE (location);


CREATE INDEX dehydrator_changes_time_idx ON dehydrator_changes USING btree ("time");

CREATE TRIGGER trig_if_c_life_changes AFTER UPDATE ON dehydrator_current FOR EACH ROW EXECUTE PROCEDURE add_new_operating_time();
CREATE TRIGGER trig_if_changes AFTER UPDATE ON dehydrator_current FOR EACH ROW EXECUTE PROCEDURE add_new_changes();
CREATE TRIGGER trig_if_insert AFTER INSERT ON dehydrator_changes FOR EACH STATEMENT EXECUTE PROCEDURE remove_old_inserts();
CREATE TRIGGER trig_if_insert_into_operating_time AFTER INSERT ON operating_time_archive FOR EACH ROW EXECUTE PROCEDURE add_average_in_operating_time();

ALTER TABLE ONLY dehydrator_changes_archive
    ADD CONSTRAINT dehydrator_changes_archive_ip_fkey FOREIGN KEY (ip) REFERENCES locations(ip) ON UPDATE CASCADE;

ALTER TABLE ONLY dehydrator_changes
    ADD CONSTRAINT dehydrator_changes_ip_fkey FOREIGN KEY (ip) REFERENCES locations(ip) ON UPDATE CASCADE;

ALTER TABLE ONLY dehydrator_current
    ADD CONSTRAINT dehydrator_current_ip_fkey FOREIGN KEY (ip) REFERENCES locations(ip) ON UPDATE CASCADE;

ALTER TABLE ONLY operating_time_archive
    ADD CONSTRAINT operating_time_archive_ip_fkey FOREIGN KEY (ip) REFERENCES locations(ip) ON UPDATE CASCADE;





CREATE FUNCTION add_temp_changes() RETURNS trigger
  LANGUAGE plpgsql  -- Триггерная функция делает запись в таблицы:
  AS $$             -- temp_changes и temp_changes_archive,
BEGIN               -- если температура системы или АКБ изменилась
  if  (NEW.temp_sys <> OLD.temp_sys) or
      (NEW.temp_akb <> OLD.temp_akb) then
    INSERT INTO temp_changes(
          location,     time,     temp_sys,     temp_akb
    ) VALUES (
      NEW.location, NEW.time, NEW.temp_sys, NEW.temp_akb
    );
    INSERT INTO temp_changes_archive(
          location,     time,     temp_sys,     temp_akb
    ) VALUES (
      NEW.location, NEW.time, NEW.temp_sys, NEW.temp_akb
    );
  end if;
  RETURN NEW;
END;
$$;


CREATE TRIGGER trig_if_changes AFTER UPDATE ON temp_current
  FOR EACH ROW WHEN (((old.temp_akb IS DISTINCT FROM new.temp_akb)
                   OR (old.temp_sys IS DISTINCT FROM new.temp_sys)))
  EXECUTE PROCEDURE add_temp_changes();


CREATE FUNCTION remove_old_inserts() RETURNS trigger
    LANGUAGE plpgsql  -- Функция удаляет записи из таблицы
    AS $$             -- temp_changes давностью больше месяца
BEGIN
  DELETE FROM temp_changes WHERE (now() - time) > '31 days';
  RETURN NEW;
END;
$$;


CREATE TRIGGER trig_if_insert AFTER INSERT ON temp_changes
  FOR EACH STATEMENT
  EXECUTE PROCEDURE remove_old_inserts();


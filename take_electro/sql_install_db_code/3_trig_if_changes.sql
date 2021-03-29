

--~ Триггерная функция add_temp_changes() делает запись в таблицы
--~ temp_changes и temp_changes_archive
--~ если температура системы или АКБ изменилась
CREATE FUNCTION public.add_temp_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
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


CREATE TRIGGER trig_if_changes AFTER UPDATE ON public.temp_current FOR EACH ROW WHEN (((old.temp_akb IS DISTINCT FROM new.temp_akb) OR (old.temp_sys IS DISTINCT FROM new.temp_sys))) EXECUTE PROCEDURE public.add_temp_changes();


--~ удаляет записи давностью больше месяца 
CREATE FUNCTION public.remove_old_inserts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM temp_changes WHERE (now() - time) > '31 days';
  RETURN NEW;
END;
$$;


CREATE TRIGGER trig_if_insert AFTER INSERT ON public.temp_changes FOR EACH STATEMENT EXECUTE PROCEDURE public.remove_old_inserts();

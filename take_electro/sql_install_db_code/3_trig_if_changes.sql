

--~ Триггерная функция add_temp_changes() делает запись в таблицу temp_changes
--~ если температура системы или АКБ изменилась
CREATE TRIGGER trig_if_changes
  AFTER UPDATE ON temp_current
  FOR EACH ROW
  WHEN (OLD.temp_akb IS DISTINCT FROM NEW.temp_akb OR 
        OLD.temp_sys IS DISTINCT FROM NEW.temp_sys)
  EXECUTE PROCEDURE add_temp_changes();

CREATE OR REPLACE FUNCTION add_temp_changes() RETURNS TRIGGER AS $$
BEGIN
  if (NEW.temp_sys <> OLD.temp_sys) OR (NEW.temp_akb <> OLD.temp_akb) then
    INSERT INTO temp_changes(    location, time,     temp_sys,     temp_akb    )
    VALUES                  (NEW.location, NEW.time, NEW.temp_sys, NEW.temp_akb);
  end if;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


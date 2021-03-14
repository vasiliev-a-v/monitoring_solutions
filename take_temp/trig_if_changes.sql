

--~ Триггерная функция add_temp_changes() делает запись в таблицу temp_changes
--~ если температура изменилась
CREATE TRIGGER trig_if_changes
  AFTER UPDATE ON temp_current
  FOR EACH ROW
  WHEN (OLD.temperature IS DISTINCT FROM NEW.temperature)
  EXECUTE PROCEDURE add_temp_changes();

CREATE OR REPLACE FUNCTION add_temp_changes() RETURNS TRIGGER AS $$
DECLARE
  temp_plus  integer;
  temp_minus integer;
BEGIN
  temp_plus  := OLD.temperature + 9;  #~ проверка на случай ложного срабатывания датчика
  temp_minus := OLD.temperature - 9;  #~ проверка на случай ложного срабатывания датчика

  if (NEW.temperature < temp_plus) AND (NEW.temperature > temp_minus) OR (NEW.location = 'Гисметео') then
    INSERT INTO temp_changes(    location,     time,     temperature)
    VALUES                  (NEW.location, NEW.time, NEW.temperature);
    RETURN NEW;
  end if;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;



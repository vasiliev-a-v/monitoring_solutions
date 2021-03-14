--~ Триггерная функция trig_if_null() записывает предыдущее NOT NULL значение
--~ в таблицу temp_current, если новая температура NULL

CREATE TRIGGER trig_if_null
  BEFORE INSERT OR UPDATE ON temp_current
  FOR EACH ROW
  WHEN (NEW.temperature = NULL)
  EXECUTE PROCEDURE add_not_null_temp();

CREATE OR REPLACE FUNCTION add_not_null_temp() RETURNS TRIGGER AS $$
BEGIN
  if  NEW.temperature = NULL then
      NEW.temperature = OLD.temperature;
  end if;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;



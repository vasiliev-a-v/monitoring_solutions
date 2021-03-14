--~ Триггерная функция add_changes() делает запись в таблицу ping_changes
--~ если ping изменился

--~ CREATE TRIGGER trig_if_changes
DROP TRIGGER trig_if_changes ON current_state;
CREATE TRIGGER trig_if_changes
  AFTER UPDATE ON current_state
  FOR EACH ROW
  WHEN (OLD.state IS DISTINCT FROM NEW.state)
  EXECUTE PROCEDURE add_changes();

CREATE OR REPLACE FUNCTION add_changes() RETURNS TRIGGER AS $$
DECLARE
  change_state boolean;
BEGIN
  change_state = 1;
    INSERT INTO ping_changes(    ip,     time,     state)
    VALUES                  (NEW.ip, NEW.time, NEW.state);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


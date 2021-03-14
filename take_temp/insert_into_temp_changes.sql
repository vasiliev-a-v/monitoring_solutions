INSERT INTO temp_changes
  SELECT location, time, temperature
FROM temp_current;


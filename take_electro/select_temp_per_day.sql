

--~ EXPLAIN ANALYZE
SELECT date_trunc('sec', time), temp_akb, temp_sys
  FROM temp_changes
    WHERE location = '[location]' AND
        time BETWEEN (current_date - INTERVAL '1 DAY')
        AND now()
  ORDER BY time -- ;



SELECT date_trunc('sec', time), temperature
  FROM temp_changes
    WHERE location = '[location]' AND
        --~ time >= (current_date - INTERVAL '1 DAY')
        time BETWEEN (current_date - INTERVAL '1 DAY')
        AND now()
        --~ OR time >= 'today'
  ORDER BY time -- ;

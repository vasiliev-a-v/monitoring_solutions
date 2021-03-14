SELECT 
    CASE WHEN state = 't' THEN 'PING_OK'
         WHEN state = 'f' THEN 'PING_NO'
         ELSE 'NULL'
    END AS state
  FROM current_state
  ORDER BY ip;

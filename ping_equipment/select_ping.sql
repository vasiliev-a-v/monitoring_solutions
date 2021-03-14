SELECT e.ip, e.name, e.description,
CASE WHEN c.state = 't' THEN 'PING_OK'
     WHEN c.state = 'f' THEN 'PING_NO'
     ELSE 'NULL'
  END AS state
  FROM equipment e
  JOIN current_state c ON e.ip = c.ip
  ORDER BY e.ip;

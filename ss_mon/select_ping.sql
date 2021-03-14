SELECT e.ip, e.name, e.description,
CASE WHEN c.state = 't' THEN 'PING_OK'
     WHEN c.state = 'f' THEN 'PING_NO'
     ELSE 'NULL'
  END AS state,
CASE WHEN e.visio_name IS NULL THEN 'NULL'
     WHEN e.visio_name = ''   THEN 'NULL'
     ELSE e.visio_name
  END AS visio_name
  FROM equipment e
  JOIN current_state c ON e.ip = c.ip
  ORDER BY e.ip;



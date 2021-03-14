SELECT * FROM (
  SELECT p.ip, e.name, date_trunc('sec', p.time) AS ping_time,
      CASE WHEN p.state = 'f' THEN 'пропал |red_log'
           WHEN p.state = 't' THEN 'восстановился |green_log'
           END
    FROM ping_changes p
    JOIN equipment e ON p.ip = e.ip
    ORDER BY time DESC LIMIT 10
) AS last_ping
ORDER BY last_ping.ping_time ASC;

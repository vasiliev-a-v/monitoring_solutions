SELECT
    l.own "Район", l.location  "Объект",
    s0.temp_sys "t системы 0:00", s0.temp_akb "t АКБ 0:00",
    s3.temp_sys "t системы 3:00", s3.temp_akb "t АКБ 3:00",
    s6.temp_sys "t системы 6:00", s6.temp_akb "t АКБ 6:00"
  FROM
    temp_static s0
    JOIN locations   l  ON s0.location = l.location AND
                           extract( "hour" FROM s0.time ) = 0 AND
                           to_char(s0.time, 'YYYY-mm-dd') = to_char(current_date, 'YYYY-mm-dd')
    JOIN temp_static s3 ON s3.location = l.location AND
                           extract( "hour" FROM s3.time ) = 3 AND
                           to_char(s3.time, 'YYYY-mm-dd') = to_char(current_date, 'YYYY-mm-dd')
    JOIN temp_static s6 ON s6.location = l.location AND
                           extract( "hour" FROM s6.time ) = 6 AND
                           to_char(s6.time, 'YYYY-mm-dd') = to_char(current_date, 'YYYY-mm-dd')
  ORDER BY l.ip;


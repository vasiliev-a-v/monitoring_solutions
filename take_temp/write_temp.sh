#!/bin/bash
#~ читает   из базы данных из таблицы temp_current
#~ сохраняет в базу данных в  таблицу temp_changes


readonly HOST="1.1.1.1"  #~ IP-адрес СУБД


func_main() { #~ основная функция
  psql -р $HOST -d temp -c \
  'INSERT INTO temp_changes (location, time, temperature) select location, time, temperature from temp_current;'
}


func_main #~ отсюда начинает работать программа
exit 0

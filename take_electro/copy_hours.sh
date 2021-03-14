#!/bin/bash


#~ скрипт копирует текущие данные о температуре в 0, 3, 6 часов
#~ из таблицы temp_current в таблицу temp_static
#~ должен запускаться через cron в соответствующее время


source $(dirname $(readlink -e "$0"))/config.sh    #~ подключается файл с общим конфигом


func_main() {             #~ основная функция
  func_copy_temp          #~ новая форма запроса (17.03.20)
}


func_copy_temp() {        #~ копирует текущие температуры в таблицу temp_static
  psql -h $HOST -d $DB -U "$DBROLE" -t <<EOF
  INSERT INTO
    temp_static ( location, time,    temp_sys,   temp_akb )
    SELECT      t.location, now(), t.temp_sys, t.temp_akb
    FROM temp_current AS t;
EOF
}


func_main                 #~ отсюда начинает работать скрипт
exit 0

#!/bin/bash
#~ скрипт собирает статистику последние 24 часа, сохраняет во временной папке
#~ потом формирует SVG-график на GNUPlot


source $(dirname $(readlink -e "$0"))/config.sh    #~ подключается файл с общим конфигом


func_main() {                     #~ основная функция
  func_read_cfg
  func_get_data_from_ip_array
}


func_read_cfg() {                 #~ читает конфиг из SQL-базы в общий массив
  local IFS=$'\n'

  local cfg=$( psql -h $HOST -d $DB -U "$DBROLE" -t <<EOF
  SELECT * FROM locations ORDER BY own DESC;
EOF
)
  _IP=( $( echo "${cfg[@]}" | cut -f1 -d '|' | tr -d " " ) )  #~ первый столбец с IP-адресами
  OBJ=( $( echo "${cfg[@]}" | cut -f2 -d '|' | tr -d " " ) )  #~ второй столбец с Объектами
}


func_select_stat() {  #~ делает выборку статистики за день
  local IFS=$'\n'
  local i=$1          #~ переданный индекс массива

  fl_query="$SCR_DIR"/select_temp_per_day.sql
  query=$(  sed "s/\[location\]/${OBJ[$i]}/g" $fl_query)
  result=$( psql -h $HOST -d $DB -U "$DBROLE" -A -t -q -c "$query" --output=$TMP_DIR/${OBJ[$i]}.csv )
}


func_get_data_from_ip_array() {   #~ обращается по списку IP-адресов (в фоне)
  local i                         #~ собирает статистику и формирует svg-график

  for (( i = 0; i < ${#OBJ[@]}; i++ )); do  #~ собирает статистику за день
    func_select_stat $i &
  done
  wait
  for (( i = 0; i < ${#OBJ[@]}; i++ )); do  #~ формирует svg-график
    $SCR_DIR/gnuplot.sh "${OBJ[$i]}" "$TMP_DIR" &
  done
  wait
  to_find="<title>Gnuplot<\/title>"     #~ имя объекта в заголовке в svg-графике
  for (( i = 0; i < ${#OBJ[@]}; i++ )); do
    to_change="<title>${OBJ[$i]}<\/title>"
    sed -i "s/$to_find/$to_change/" "$TMP_DIR/${OBJ[$i]}.svg"
  done
}


func_main #~ отсюда начинает работать программа
exit 0

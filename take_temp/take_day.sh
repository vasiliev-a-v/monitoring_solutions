#!/bin/bash
#~ скрипт собирает статистику последние 24 часа, сохраняет во временной папке
#~ потом формирует SVG-график на GNUPlot


readonly SLEEP="sleep 0.1"                     #~ пауза между запросами
readonly HOST="1.1.1.1"                        #~ IP-адрес СУБД
readonly DB="temp"                             #~ имя базы данных
readonly DBUSER="user"                         #~ имя роли базы данных
SCRIPT="$(readlink -e "$0")"                   #~ полный путь до файла скрипта
SCR_DIR=$(dirname $SCRIPT)                     #~ каталог в котором лежит скрипт
TMP_DIR="/tmp/$(basename $SCR_DIR )"           #~ каталог для временных файлов
[ ! -d $TMP_DIR  ] && \
mkdir $TMP_DIR && chmod 0777 $TMP_DIR          #~ если каталога нет, то создает
declare -a OBJ=( )                             #~ список Объектов
date_out=$( date +%Y-%m-%d )


func_main() {                     #~ основная функция
  func_read_cfg                   #~ читает конфиг из SQL-базы в общий массив
  func_make_picture               #~ обращается по списку объектов (в фоне)
}


func_read_cfg() {                 #~ читает конфиг из SQL-базы в общий массив
  local IFS=$'\n'

  local command="SELECT * FROM locations ORDER BY id;"
  local cfg=$(psql -h $HOST -d $DB -U "${DBUSER}" --pset="footer=off" -t -A -c "$command")

  OBJ=( $( echo "${cfg[@]}" | cut -f2 -d '|' ) )  #~ столбец Объекты
}


func_select_stat() {  #~ делает запрос к БД за день, сохраняет в CSV-файл
  local IFS=$'\n'
  local i=$1          #~ переданный индекс массива

  fl_query="$SCR_DIR"/select_temp_per_day.sql
  query=$(  sed "s/\[location\]/${OBJ[$i]}/g" $fl_query)
  result=$( psql -h $HOST -d $DB -U "${DBUSER}" -A -t -q -c "$query" --output=$TMP_DIR/${OBJ[$i]}.csv )
}


func_make_picture() {   #~ обращается по списку объектов (в фоне)
  local i

  for (( i = 0; i < ${#OBJ[@]}; i++ )); do
    func_select_stat $i &
  done
  wait
  for (( i = 0; i < ${#OBJ[@]}; i++ )); do
    case ${OBJ[$i]} in    #~ для улицы один график, для серверных - другой
    "Улица_1" | "Улица_2" ) $SCR_DIR/gnuplot_outdoor.sh "${OBJ[$i]}" "$TMP_DIR" &;;
    * ) $SCR_DIR/gnuplot_flat.sh "${OBJ[$i]}" "$TMP_DIR" &;;
    esac
  done
  wait
  to_find="<title>Gnuplot<\/title>"
  for (( i = 0; i < ${#OBJ[@]}; i++ )); do
    to_change="<title>${OBJ[$i]}<\/title>"
    sed -i "s/$to_find/$to_change/" "$TMP_DIR/${OBJ[$i]}.svg"
  done
}


func_main #~ отсюда начинает работать программа
exit 0

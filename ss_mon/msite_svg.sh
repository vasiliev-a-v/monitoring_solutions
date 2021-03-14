#!/bin/bash

#~ Визуальная схема рисуется в файле формата SVG (сохраняется файл VISIO в формат SVG)
#~ ИНИЦИАЛИЗАЦИЯ:
#~ Программа читает построчно файл в массив SVG_ARRAY
#~ Для каждого ID (и IP) из конфига (который читает из базы данных ping)
#~ находит (индекс) свою строчку в массиве,
#~ которую надо будет менять (это пятая строчка в SVG-файле). Записывает число индекса в массив SVG_INDEX
#~ Записывает в массив PING_STATE состояние пингов на основе IP-массива из базы данных
#~ ПЕРЕЗАГРУЗКА (ПЕРЕИНИЦИАЛИЗАЦИЯ):
#~ Для перезагрузки процесса необходимо либо: 
#~ Вариант 1. удалить файл /tmp/ss_mon.svg
#~ Вариант 2. послать SIGHUP этому процессу (msite_svg.sh)

#~ ОСНОВНАЯ РАБОТА:
#~ Периодически опрашивает базу данных на состояние пингов, если новое значение не как в массиве PING_STATE,
#~ то вызывает соответствующую индексу IP-массива строку из массива SVG_INDEX
#~ в строке заменяет значение в конце строки "/>" на "style='background: #F9DEDA;'/>"
#~ после прохождения цикла опроса на пинги - если произошли изменения или файла нет, то
#~ сохраняет весь массив SVG_ARRAY в файл SVG в папке /tmp


SCRIPT="$(readlink -e "$0")"          #~ полный путь до файла скрипта
MY_DIR="$(dirname $SCRIPT)"           #~ каталог в которой работает скрипт
TMP_DIR=/tmp/"take_ping.sh"           #~ каталог для временных файлов
SCHEME="ss_mon.svg"                   #~ имя файла со схемами
TMP_SCHM="/tmp/$SCHEME"               #~ имя копии во временной папке файла со схемами


trap 'echo "EXIT"; sleep 1; exit 0'    2 3 9 15  #~ завершение работы программы по UNIX сигналу (kill)
trap 'echo "EXIT"; sleep 1; "$SCRIPT"' 1         #~ перезапускает эту программу по UNIX сигналу (kill)


IP=( )                                #~ список ip-адресов оборудования
OBJ=( )                               #~ список оборудования
TITLE=( )                             #~ список подробного описания оборудования
ID=( )                                #~ список ID оборудования
SVG_ARRAY=( )                         #~ SVG-файл построчно
SVG_INDEX=( )                         #~ Индекс строк в SVG-файле соответствующих массиву ID
PING_STATE=( )                        #~ массив о состоянии пингов в соответствии с массивом IP-адресов
RED=" style=\"fill: #E57878;\"/>"     #~ фон объекта в SVG-файле при отсутствии пинга
WHITE="/>"                            #~ фон объекта в SVG-файле при наличии пинга
readonly HOST="--host=1.1.1.1"        #~ IP-адрес СУБД
readonly DB="--dbname=ping"           #~ имя базы данных


func_main() {                         #~ главная функция
  local IFS=$'\n'

  cp $MY_DIR/$SCHEME $TMP_SCHM        #~ копирует схему во временную папку
  chmod 0777 $TMP_SCHM                #~ даем права на чтение и запись для любого пользователя
  func_read_cfg $MY_DIR/config.txt    #~ читает конфиг устройств в общий массив
  readarray -t SVG_ARRAY < $TMP_SCHM  #~ читает построчно файл SVG в массив SVG_ARRAY
  func_get_index_by_id                #~ Для каждого ID (и IP) из конфига находит свою строчку в массиве (индекс)
  func_init_first_ping_state          #~ Записывает в массив PING_STATE состояние по-умолчанию (PING_OK)
  while true; do                      #~ программа в бесконечном цикле
    func_check_ping                   #~ проверяет состояние пингов, и сохраняет изменения в SVG-файл
    sleep 10                          #~ пауза на 10 секунд
    func_check_svg_file               #~ проверяет наличие SVG-файла и его новизну
  done
}


func_check_svg_file() {           #~ проверяет наличие SVG-файла и его новизну
  if [[ ! -f $TMP_SCHM ]] || \
     [[ $MY_DIR/$SCHEME -nt $TMP_SCHM ]]; then
    cp $MY_DIR/$SCHEME $TMP_SCHM        #~ копирует схему во временную папку
    chmod 0777 $TMP_SCHM                #~ даем права на чтение и запись для любого пользователя
    echo "$( date +%d.%m.%y" г. "%H:%M:%S ) Перезагружен" >> /tmp/ss_file_reload.txt
    exec $SCRIPT
  fi
}


func_read_cfg() {  #~ читает конфигурацию из БД
  local IFS=$'\n'
  local cfg=$(psql $HOST $DB -U user --pset="footer=off" -t -A -f $MY_DIR/select_ping.sql)
  IP=(    $( echo "${cfg[@]}" | cut -f1 -d '|' ) )  #~ столбец IP-адреса
  ID=(    $( echo "${cfg[@]}" | cut -f5 -d '|' ) )  #~ столбец название в VISIO
}


func_get_new_ping() {  #~ 
  local IFS=$'\n'
  NEW_PING=( $( psql $HOST $DB -U user --pset="footer=off" -t -A -f $MY_DIR/select_new_ping.sql ) )
}


func_get_index_by_id() {  #~ Для каждого ID (и IP) из конфига находит свою строчку в массиве (индекс)
  for (( i = 0; i < ${#ID[@]}; i++ )); do   #~ которую надо будет менять (это пятая строчка в SVG)
    result=$( grep -n "<title>${ID[$i]}</title>" "$TMP_SCHM" | cut -d: -f1 )
    t=$((result - 1))
    SVG_ARRAY[$t]=$(echo ${SVG_ARRAY[$t]} | sed "s!<title>.*</title>!<title>${IP[$i]}</title>!")    #~ вставляет IP
    SVG_INDEX[$i]=$((result + 3))   #~ Записывает число индекса в массив SVG_INDEX
  done
}


func_init_first_ping_state() {  #~ Записывает в массив PING_STATE состояние по-умолчанию (PING_OK)
  for (( i = 0; i < ${#IP[@]}; i++ )); do
    PING_STATE[$i]="PING_OK"
  done
}


func_check_ping() {   #~ проверяет состояние пингов, и сохраняет изменения в SVG-файл
  local i
  local j
  local IFS=$'\n'

  MODIFIED="NO"       #~ переменная с флагом, произошли ли изменения в схеме пингов

  func_get_new_ping

  for (( i = 0; i < ${#IP[@]}; i++ )); do       #~ проверяет состояние пингов
    if [[ ${PING_STATE[$i]} != ${NEW_PING[$i]} ]]; then
      PING_STATE[$i]="${NEW_PING[$i]}"
      MODIFIED="YES"
      local index=${SVG_INDEX[$i]}
      local string="${SVG_ARRAY[$index]}"
      case ${PING_STATE[$i]} in
      PING_OK ) SVG_ARRAY[$index]="${string//$RED/$WHITE}" ;;
      PING_NO ) SVG_ARRAY[$index]="${string//$WHITE/$RED}" ;;
      *       ) continue ;;
      esac
    fi
  done

  if [[ $MODIFIED == "YES" ]]; then             #~ если произошли изменения, то
    echo ${#SVG_ARRAY[@]}
    echo -ne > $TMP_SCHM
    for (( j = 0; j < ${#SVG_ARRAY[@]}; j++ )); do  #~ сохраняет их
      echo -ne "${SVG_ARRAY[$j]}" >> $TMP_SCHM      #~ в SVG-файл
    done
  fi
}


func_main #~ отсюда начинает работать программа
exit 0

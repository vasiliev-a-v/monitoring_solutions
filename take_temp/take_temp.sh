#!/bin/bash
#~ читает из микрокомпьютеров расположенных в сети данные о температуре
#~ сохраняет данные температур в базу данных temp


SCRIPT="$(readlink -e "$0")"          #~ полный путь до файла скрипта
MY_DIR="$(dirname $SCRIPT)"           #~ каталог в которой работает скрипт
readonly HOST="1.1.1.1"               #~ IP-адрес СУБД
readonly DB="temp"                    #~ имя базы данных
readonly DBUSER="user"                #~ имя роли базы данных
browser="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:26.0) Gecko/20100101 Firefox/26.0"
url="https://www.gismeteo.ru/weather-sankt-peterburg-4079/now/"
ssh_user="пользователь"
psswd="пароль"


func_main() { #~ основная функция
    func_read_cfg
    func_gismeteo &
    for (( i = 1; i < ${#IP[@]}; i++ )); do
      func_take_temp $i &
    done
    wait
}


func_read_cfg() {  #~ читает конфигурацию из БД
  local IFS=$'\n'

  local command="SELECT * FROM locations ORDER BY id;"
  local cfg=$(psql -h $HOST -d $DB -U "${DBUSER}" --pset="footer=off" -t -A -c "$command")

  IP=(  $( echo "${cfg[@]}" | cut -f1 -d '|' ) )  #~ столбец IP-адреса
  OBJ=( $( echo "${cfg[@]}" | cut -f2 -d '|' ) )  #~ столбец Объекты
  TYPE=($( echo "${cfg[@]}" | cut -f3 -d '|' ) )  #~ столбец тип датчика
  GPIO=($( echo "${cfg[@]}" | cut -f4 -d '|' ) )  #~ столбец контакт GPIO
  CORR=($( echo "${cfg[@]}" | cut -f8 -d '|' ) )  #~ столбец коррекция температуры
}


func_gismeteo() {  #~ скачивает температуру из интернета с гисметео
  local i=0

  local temp=$( wget -q -O - -T 3 --user-agent=$browser -Q200k $url | \
  grep '{"temperature":{"air":{"C":' | cut -f 4 -d ":" | cut -f 1 -d "," | cut -f 1 -d "." )
  [[ $temp == "" ]] && return

#~ записывает температуру  в базу данных
psql -h $HOST -d $DB -U "${DBUSER}" -t 1>/dev/null <<EOF
INSERT INTO temp_current VALUES
(               '${OBJ[$i]}',
                current_timestamp,
                ${temp}
)
ON CONFLICT (location) DO UPDATE SET
  time        = current_timestamp,
  temperature = ${temp};
EOF
}


func_take_temp() {  #~ забирает температуру с датчиков
  local temp
  local i=$1

  temp=$( sshpass -p "${psswd}" ssh ${ssh_user}@${IP[$i]} -p 22 "echo 1 | sudo -S /home/pi/scripts/dht.py ${TYPE[$i]} ${GPIO[$i]}" )
  temp=$(echo "scale=1; $temp + ${CORR[$i]}" | bc)  #~ scale - количество цифр после запятой

  if [[ ${TYPE[$i]} == "11" ]]; then  #~ калибровка значения для датчика DHT11
    temp="${temp//.0/}"
  fi

#~ записывает температуру  в базу данных
psql -h $HOST -d $DB -U "${DBUSER}" -t 1>/dev/null <<EOF
INSERT INTO temp_current VALUES
(		'${OBJ[$i]}',
		current_timestamp,
		${temp}
)
ON CONFLICT (location) DO UPDATE SET
  time        = current_timestamp,
  temperature = ${temp};
EOF
}


func_main #~ отсюда начинает работать программа
exit 0

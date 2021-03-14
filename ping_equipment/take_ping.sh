#!/bin/bash
#~ скрипт пингует оборудование, сохраняет данные в БД ping


SCRIPT="$(readlink -e "$0")"            #~ полный путь до файла скрипта
readonly HOST="--host=1.1.1.1"          #~ IP-адрес СУБД
readonly DB="--dbname=ping"             #~ имя базы данных
readonly DBUSER="user"                  #~ имя роли (пользователя) в базе данных


func_main() {                           #~ главная функция
  func_read_cfg
  func_get_data_from_ip_array
}


func_read_cfg() {  #~ читает конфигурацию из БД
  local IFS=$'\n'
  local command="SELECT ip FROM equipment ORDER BY ip;"

  IP=( $(psql $HOST $DB -U "$DBUSER" --pset="footer=off" -t -A -c "$command") )  #~ столбец IP-адреса
}


func_do_ping() {       #~ производит пинг по IP-адресу указанному в аргументе $1
  local try=0          #~ количество попыток пинга
  local ip="$1"
  local ping_state

  #~ echo -n "$ip: "
  while (( try++ < 2 )); do  #~ дано две попытки на случай неудачного 1-го пинга
    result="$(ping -c 1 "$ip")"
    if echo "$result" | grep -q "1 received"; then
      ping_state=yes
      try=2   #~ число больше 2 чтобы сразу выйти из цикла while
    else
      ping_state=no
      sleep 1
    fi
    #~ echo -n "$try, $ping_state. "
  done
#~ echo 
#~ записывает состояние пинга в базу данных
psql $HOST $DB $DBUSER -t 1>/dev/null <<EOF
INSERT INTO current_state VALUES
('${ip}', current_timestamp, '${ping_state}')
ON CONFLICT (ip) DO UPDATE SET
  time  = current_timestamp,
  state = '${ping_state}';
EOF
}


func_get_data_from_ip_array() {      #~ обращается по списку IP-адресов (в фоне)
  local i=0

  for (( i = 0; i < ${#IP[@]}; i++ )); do
    func_do_ping "${IP[$i]}" &  #~ запускает проверку пингов в фоне
    sleep 0.1
  done
  wait
}


func_main                            #~ отсюда начинает работать скрипт
exit 0

#!/bin/bash
#~ формирует web-страницу (таблицу) с результатами
#~ пропингованного оборудования


SCRIPT="$(readlink -e "$0")"            #~ полный путь до файла скрипта
MY_DIR="$(dirname $SCRIPT)"             #~ каталог в которой работает скрипт
TMP_DIR=/tmp/"take_ping.sh"             #~ каталог для временных файлов
IP=( )      #~ список ip-адресов оборудования
OBJ=( )     #~ список оборудования
TITLE=( )   #~ список подробного описания оборудования
declare -a RESULT=()
readonly HOST="--host=1.1.1.1"          #~ IP-адрес СУБД
readonly DB="--dbname=ping"             #~ имя базы данных
DBUSER="user"                           #~ пользователь (роль) в базе данных


func_main() {         #~ с неё начинает работать программа
  func_read_cfg
  func_make_html_code
  echo -e "${_SITE//
/\\n}" > /tmp/ping.htm
}


func_read_cfg() {  #~ читает конфигурацию из БД
  local IFS=$'\n'

  local cfg=$(psql $HOST $DB -U "$DBUSER" --pset="footer=off" -t -A -f $MY_DIR/select_ping.sql)

  IP=(    $( echo "${cfg[@]}" | cut -f1 -d '|' ) )  #~ столбец IP-адреса
  OBJ=(   $( echo "${cfg[@]}" | cut -f2 -d '|' ) )  #~ столбец Оборудование
  TITLE=( $( echo "${cfg[@]}" | cut -f3 -d '|' ) )  #~ столбец Описание
  RESULT=($( echo "${cfg[@]}" | cut -f4 -d '|' ) )  #~ столбец Описание

  local cfg=$(psql $HOST $DB -U "$DBUSER" --pset="footer=off" -t -A -f $MY_DIR/select_log.sql)

  ip_log=(   $( echo "${cfg[@]}" | cut -f1 -d '|' ) )  #~ столбец IP-адреса
  obj_log=(  $( echo "${cfg[@]}" | cut -f2 -d '|' ) )  #~ столбец Оборудование
  date_log=( $( echo "${cfg[@]}" | cut -f3 -d '|' ) )  #~ столбец Дата
  state_log=($( echo "${cfg[@]}" | cut -f4 -d '|' ) )  #~ столбец состояние
  color_log=($( echo "${cfg[@]}" | cut -f5 -d '|' ) )  #~ столбец цвет

}


func_make_html_code() { #~ создает HTML-код
  red="F9DEDA"
  yellow="FBFB83"
  green="CEF7A8"

  _SITE="<html>
<head>
  <title>PING EQUIPMENT</title>
  <meta http-equiv='content-type' content='text/html;charset=utf-8'>
  <meta name=generator content='Geany 1.22'>
  <meta http-equiv=refresh content=60>
</head>
<style>
div {font-size: 12;}
.green { width: 100px; height: 50px; border: solid 1px #c0c0c0; padding: 2px; float: left; background: #$green; }
.red   { width: 100px; height: 50px; border: solid 1px #c0c0c0; padding: 2px; float: left; background: #$red; }
.green_log {background: #$green; width:50%}
.red_log   {background: #$red;   width:50%}
</style>
<body>
<font face=Arial>
$( date +%d.%m.%Y" г. "%H:%M:%S )<br>
"

  for (( i = 0; i < ${#IP[@]}; i++ )); do
    case ${RESULT[$i]} in
    PING_OK ) BOX="<div title='${TITLE[$i]}' class=green><a href=http://${IP[$i]}>${IP[$i]}</a><br>${OBJ[$i]}</div>" ;;
    PING_NO ) BOX="<div title='${TITLE[$i]}' class=red><a href=http://${IP[$i]}>${IP[$i]}</a><br>${OBJ[$i]}</div>" ;;
    *       ) continue ;;
    esac
_SITE="$_SITE
$BOX"
  done

LOG=""
  for (( i = 0; i < ${#ip_log[@]}; i++ )); do
    LOG=$LOG"${date_log[$i]} -
    <a href=http://${ip_log[$i]}>${ip_log[$i]}</a> - "${obj_log[$i]}" -
    <b class=${color_log[$i]}>${state_log[$i]}</b><br>"
  done

_SITE="$_SITE<div style=clear:both><br>ЛОГ:<br>
$LOG</div>
</font>
</body>
</html>
"
}


func_main       #~ отсюда начинает работать программа

exit 0

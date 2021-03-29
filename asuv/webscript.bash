#!/bin/bash

#~ модуль программы - веб-интерфейс
#~ получает команды и щелкает GPIO


func_main() {                     #~ с неё начинает работать программа
  MY_DIR="$(dirname $0)"          #~ папка в которой работает скрипт
  CFG_FILE="$MY_DIR"/config.txt   #~ имя файла конфига

  source "$CFG_FILE"          #~ подгружает файл конфиг с переменными

  _LOG=$( tac $MY_DIR/log.txt | head -n 10 )

  func_make_new_gpio 17       #~ создает GPIO на включение  вентиляции
  func_make_new_gpio 18       #~ создает GPIO на выключение вентиляции

  func_make_new_gpio 27       #~ создает GPIO на включение  вентиляции
  func_make_new_gpio 22       #~ создает GPIO на выключение вентиляции

  func_check_GET
  func_check_auto_state
  func_make_site
  echo "Content-type: text/html"
  echo ""
  echo -e ${_SITE//
/\\n}
}


func_make_new_gpio() {  #~ создает новый файл для датчика
  local XX=$1

  if [ ! -e /sys/class/gpio/gpio$XX/value ]; then
    echo $XX   > /sys/class/gpio/export
    echo "out" > /sys/class/gpio/gpio$XX/direction
    echo 1 > /sys/class/gpio/gpio$XX/value
    chown www-data:gpio /sys/class/gpio/gpio$XX/value
    chmod 0777          /sys/class/gpio/gpio$XX/value
    echo "создали новые файлы GPIO"$XX
  fi
}


func_check_auto_state() { #~ проверить автоматическое включение вентиляции (включено либо выключено)
  if [ $(cat $MY_DIR/auto_state.txt) == "ON" ]; then
    auto_state="auto_off"
    auto_value="Выключить автоматику"
    auto_color="90EE90;"
  else
    auto_state="auto_on"
    auto_value="Включить автоматику"
    auto_color="cfcfcf;border-color:000000;"
  fi
}


func_reload_site() {  #~ перезагружает веб-страницу
  if [[ $QUERY_STRING != "" ]]; then
    echo "Content-type: text/html"
    echo ""
    echo "<html><head><meta http-equiv=refresh content=0,url=http://$SERVER_ADDR$SCRIPT_NAME></head></html>"
  fi
}


func_make_site() {  #~ отображает веб-страницу
  if [[ $QUERY_STRING != "" ]]; then  #~ 
    _SITE="<html><head><meta http-equiv=refresh content=0,url=http://$SERVER_ADDR$SCRIPT_NAME></head></html>"
    return 1
  fi

  CPU_TEMP=$(( $(</sys/class/thermal/thermal_zone0/temp) / 1000 ))  #~ температура процессора
  _V1_STATE=$(cat $MY_DIR/v1_state.txt)
  _V5_STATE=$(cat $MY_DIR/v5_state.txt)

  [ $_V1_STATE == "VENTILATION_V1_ON" ] && vent1_color="90EE90" || vent1_color="cfcfcf"
  [ $_V5_STATE == "VENTILATION_V5_ON" ] && vent5_color="90EE90" || vent5_color="cfcfcf"
  temp=$(cat $_FILE_TMP)
  (( _TEMP_OFF >= temp )) && temp_color="90EE90" || temp_color="FBFB83"
  (( _TEMP_ON  <= temp )) && temp_color="red"

_SITE="<html>
  <head>
    <meta http-equiv='content-type' content='text/html;charset=utf-8'>
    <meta http-equiv=Pragma content=no-cache>
    <meta http-equiv=refresh content=60,url=http://$SERVER_ADDR$SCRIPT_NAME>
    <title>АСУ вентиляций В1, В5</title>
  </head>
  <script>
    http_str_orig = location.protocol + '//' + location.host + '/$(basename $0)'
    http_str_real = location.href

    function ConfirmAction(action, url_command){
      isReload = confirm('Вы действительно хотите ' + action + '?');
      if (isReload == true) {
        location.href=http_str_orig + '?' + url_command
      }
    }
  </script>
  <body leftmargin=0 topmargin=0>
<small>
Время: $( date +%d.%m.%Y\ %H:%M:%S )\t|\tТемпература микрокомпьютера: $CPU_TEMP | Уставки: верхняя $_TEMP_ON / нижняя $_TEMP_OFF<br>
Температура серверной: <norm style=background-color:$temp_color>$temp</norm></small><br>
<table cellpadding=0 cellspacing=0 border=0>
  <tr><td>
Состояние автоматики:</td><td><norm style=background-color:${auto_color}>$(cat $MY_DIR/auto_state.txt)</norm>
  </td><td>
<input type=button value=\"$auto_value\" onclick=\"location.href=http_str_orig+'?$auto_state'\">
  </td></tr><tr><td>
Состояние вентиляции В5: </td><td><b style=background-color:$vent5_color>$_V5_STATE</b>
  </td><td>
<input type=button value='ВКЛ V5'  onclick=\"location.href=http_str_orig+'?v5_on'\" > <input type=button value='ВЫКЛ V5' onclick=\"location.href=http_str_orig+'?v5_off'\">
  </td></tr><tr><td>
Состояние вентиляции В1: </td><td><b style=background-color:$vent1_color>$_V1_STATE</b>
  </td><td>
<input type=button value='ВКЛ V1'  onclick=\"location.href=http_str_orig+'?v1_on'\" > <input type=button value='ВЫКЛ V1' onclick=\"location.href=http_str_orig+'?v1_off'\">
  </td></tr>
  </table>
<p>
<input type=button value='Перезапустить веб-скрипт' onclick=\"ConfirmAction('перезапустить веб-скрипт','restart_web')\">
<input type=button value='Перезагрузить контроллер' onclick=\"ConfirmAction('перезагрузить контроллер','reboot')\"><br>
<input type=button value='Выключить контроллер' onclick=\"ConfirmAction('выключить контроллер','poweroff')\">
<input type=button value='Перезапустить автоматику' onclick=\"ConfirmAction('перезапустить автоматику','restart_auto')\">
<p>
  <small>
    ${_LOG//
/<br>\\n}
<center><a href=log.bash>смотреть весь журнал</a></center>
    </small>
  </body>
</html>"
}


func_check_GET() {    #~ запускает функции на основе GET-запроса
  case ${QUERY_STRING} in
    restart_web ) exec "$0";;   #~ перезагружает этот скрипт
    stop_script ) exit 0;;      #~ останавливает этот скрипт
    reboot      ) func_nice_shutdown "-r  now";;              #~ перезагружает операционную систему
    poweroff    ) func_nice_shutdown "-hP now";;              #~ выключает ОС и RaspberryPI
    auto_on     ) echo -n "ON"  > $MY_DIR/auto_state.txt;;    #~ включает автоматику
    auto_off    ) echo -n "OFF" > $MY_DIR/auto_state.txt;;    #~ выключает автоматику
    restart_auto) touch /tmp/restart_automatic_on_off.sh;;    #~ перезагружает скрипт автоматики
    v5_on       ) func_click_gpio 17 $_V1_STATE "VENTILATION_V5_ON"  green;;  #~ щелкает реле 17
    v5_off      ) func_v5_off;;     #~ выключает вентиляцию В5 через отключение вентиляции В1
    v1_on       ) func_click_gpio 27 "VENTILATION_V1_ON"  $_V5_STATE green;;  #~ щелкает реле 27
    v1_off      ) func_click_gpio 22 "VENTILATION_V1_OFF" $_V5_STATE gray ;;  #~ щелкает реле 22
  esac
}


func_nice_shutdown() {  #~ красиво выключает Raspberry Pi
  local attr="$1"   #~ атрибуты для утилиты shutdown (перезагрузка или выключение)
  
  sudo shutdown $attr
}


func_v5_off() { #~ выключает вентиляцию В5 через отключение вентиляции В1
  func_click_gpio 18 $_V1_STATE "VENTILATION_V5_OFF" gray     #~ щелкает реле 18, выключает В5
}


func_get_gpio_value() { #~ считывает состояние реле
  local XX=$1

  value=$(cat /sys/class/gpio/gpio$XX/value)
  echo $value
  SITE_VALUE="GPIO$XX=$value"
}


func_click_gpio() { #~ щелкает релюшкой $1 - номер gpio, $2 - состояние вентиляции
  local XX=$1
  _V1_STATE=$2
  _V5_STATE=$3
  _VENT_ST_CLR=$4
  local _DATE="date +%Y-%m-%d_%H:%M:%S"

  echo 0 > /sys/class/gpio/gpio$XX/value
  sleep $_CLICK_SLEEP
  echo 1 > /sys/class/gpio/gpio$XX/value
  echo -n $_V1_STATE > $MY_DIR/v1_state.txt
  echo -n $_V5_STATE > $MY_DIR/v5_state.txt
  echo "$($_DATE) | $_V1_STATE | $_V5_STATE |/ температура: $(cat $_FILE_TMP) / автоматика: $(cat $MY_DIR/auto_state.txt)" >> $MY_DIR/log.txt
}


func_main #~ отсюда начинает работать программа
exit 0

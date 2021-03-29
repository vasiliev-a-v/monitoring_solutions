#!/bin/bash


#~ Программа запускается на Raspberry Pi
#~ Если автоматика включена, то этот модуль программы:
#~ 1. Проверяет температуру
#~ 2. В зависимости от выставленных уставок
#~    выключает или включает пускатель вентиляции
#~    (щёлкает реле через выводы GPIO)


func_main() {                     #~ с неё начинает работать программа
  MY_DIR="$(dirname $0)"          #~ папка в которой работает скрипт
  CFG_FILE="$MY_DIR"/config.txt   #~ имя файла конфига

  source "$CFG_FILE"          #~ подгружает файл конфиг с переменными

  func_make_new_gpio 17       #~ создает GPIO на включение  вентиляции В5
  func_make_new_gpio 18       #~ создает GPIO на выключение вентиляции В5

  func_make_new_gpio 27       #~ создает GPIO на включение  вентиляции В1
  func_make_new_gpio 22       #~ создает GPIO на выключение вентиляции В1

  while true; do
    auto_state=$(cat $MY_DIR/auto_state.txt)

    if [ -e /tmp/restart_automatic_on_off.sh ]; then
      rm -f /tmp/restart_automatic_on_off.sh
      exec $0
    fi

    if [ "$auto_state" = "ON" ]; then
      #~ echo Автоматика включена
      _V5_STATE=$(cat $MY_DIR/v5_state.txt) #~ считывает состояние вентиляции В5
      func_get_temp
    else
      true
      #~ echo Автоматика отлючена
    fi
    sleep $_TIME
  done
}


func_make_new_gpio() {  #~ создает новый файл для релюшки
  local XX=$1

  if [ ! -e /sys/class/gpio/gpio$XX/value ]; then
    echo $XX   > /sys/class/gpio/export
    echo "out" > /sys/class/gpio/gpio$XX/direction
    echo 1 > /sys/class/gpio/gpio$XX/value
    chown www-data:gpio /sys/class/gpio/gpio$XX/value
    chmod 0777          /sys/class/gpio/gpio$XX/value
  fi
}


func_get_temp() { #~ проверяет температуру
  temp=$(cat $_FILE_TMP)

  if   (( temp > _TEMP_ON  )) && [ "$_V5_STATE" = "VENTILATION_V5_OFF" ]; then
    func_click_gpio 17
    _V5_STATE="VENTILATION_V5_ON"
    echo -n $_V5_STATE > $MY_DIR/v5_state.txt
  elif (( temp < _TEMP_OFF )) && [ "$_V5_STATE" = "VENTILATION_V5_ON" ]; then
    func_click_gpio 18
    _V5_STATE="VENTILATION_V5_OFF"
    echo -n $_V5_STATE > $MY_DIR/v5_state.txt
  fi
}




func_click_gpio() { #~ щелкает релюшкой
  local XX=$1
  local _DATE="date +%Y-%m-%d_%H:%M:%S"

  echo 0 > /sys/class/gpio/gpio$XX/value
  sleep $_CLICK_SLEEP
  echo 1 > /sys/class/gpio/gpio$XX/value

  (( XX == 17 )) && VENT="включена" || VENT="выключена"

  echo "$($_DATE) / $VENT / температура: $(cat $_FILE_TMP) / автоматика: $(cat $MY_DIR/auto_state.txt)" >> $MY_DIR/log.txt
}


func_toggle_gpio() {  #~ переключает реле
  local XX=$1

  value=$(cat /sys/class/gpio/gpio$XX/value)
  case $value in
  [0] )   echo 1 > /sys/class/gpio/gpio$XX/value;;
  [1] )   echo 0 > /sys/class/gpio/gpio$XX/value;;
  esac
  value=$(cat /sys/class/gpio/gpio$XX/value)
  SITE_VALUE="GPIO$XX=$value"
}


func_main #~ отсюда начинает работать программа
exit 0

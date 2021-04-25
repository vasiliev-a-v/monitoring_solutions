#!/bin/bash

#~ модуль программы: take_dehydrator.sh
#~ - подключается к микрокомпьютеру "R" по telnet
#~ - находит номер ttyUSB (номер COM-порта) принадлежащий именно к дегидратору
#~ - к микрокомпьютеру подключены несколько последовательных интерфейсов (COM-портов)
#~ - если порт завис, то переподключает USB-порт на микрокомпьютере "R"
#~ - запускает minicom и подключается по ttyUSB к дегидратору
#~ - запрашивает состояние дегидратора "A"
#~ - заносит показания дегидратора в БД Postgres через UPSERT


source $(dirname $(readlink -e "$0"))/config.sh    #~ подключается файл с общим конфигом


func_main() {                       #~ основная функция
  func_get_tty_from_rpi             #~ находит номер ttyUSB дегидратора
  func_get_measurements             #~ собирает данные с дегидратора
  func_parsing_to_vars              #~ записывает данные в переменные и в БД
}


func_get_tty_from_rpi() {    #~ читает ttyUSB из RPI
  for (( i = 0; i < 2; i++ )); do   #~ две попытки для подключения к USB-порту

    #~ подключается к RPi и получаем массив строк с номером ttyUSB
    result=( $( 
      expect $SCR_DIR/expect_get_tty.sh    \
             $username $password $ip__addr \
             2>/dev/null
    ) )

    #~ выделяет из полученного массива часть с ttyUSB:
    for (( i = 0; i < ${#result[@]}; i++ )); do  #~ читает массив построчно
      com_port=$(echo "${result[$i]}" | grep "ttyUSB" ) #~ ищем номер порта
      [[ $com_port != "" ]] && break        #~ если порт найден, то выходим
    done
    
    if [[ $com_port != "" ]]; then  #~ если порт найден,
      return 0                      #~ то выходит из этой функции
    else                            #~ если порт не найден,
      func_usb_off_and_on           #~ то переподключает USB-порт
    fi
  done
  echo "USB-порт не найден" && exit 1
}


func_usb_off_and_on() {   #~ переподключает USB-порт на микрокомпьютере "R"
  result=$(
    expect $SCR_DIR/expect_usb_off_and_on.sh       \
           $username $password $ip__addr $com_port \
           2>/dev/null
  )
  echo "$result"
}


func_get_measurements() {   #~ собирает данные с дегидратора
  result="$( 
    expect $SCR_DIR/expect_measurements.sh         \
           $username $password $ip__addr $com_port \
           2>/dev/null
  )"
}


func_parsing_to_vars() {    #~ записывает данные с дегидратора в переменные
  #~ заменяет какой-то символ на перевод строки
  result=$( echo "${result}" | sed -e "s//\n/g" )

  #~ парсит в переменные показания дегидратора
  c_life=$( echo "${result}" | grep "life"          | cut -d" " -f5 )
  c_temp=$( echo "${result}" | grep "temp"          | cut -d"=" -f2 | cut -d"C" -f1 )
  c_high=$( echo "${result}" | grep "high pressure" | cut -d"=" -f2 | cut -d" " -f2 )
  c__low=$( echo "${result}" | grep "low pressure"  | cut -d"=" -f2 | cut -d" " -f2 )
  c_humi=$( echo "${result}" | grep "humidity"      | cut -d"=" -f2 | cut -d"%" -f1 )

  #~ парсит в переменные состояние аварийных сигналов
  a_summ=$( echo "${result}" | grep "SUMMARY"       | cut -d"=" -f2 )
  a_exrt=$( echo "${result}" | grep "EXCESSIVE RUN" | cut -d"=" -f2 )
  a_high=$( echo "${result}" | grep "HIGH PRESSURE" | cut -d"=" -f2 )
  a__low=$( echo "${result}" | grep "LOW PRESSURE"  | cut -d"=" -f2 )
  a_humi=$( echo "${result}" | grep "HIGH HUMIDITY" | cut -d"=" -f2 )
  a_faul=$( echo "${result}" | grep "COMPR FAULT"   | cut -d"=" -f2 )

  #~ если OK, то авария = false, если не OK, то авария = true
  echo $a_summ | grep -q "OK" && a_summ="false" || a_summ="true"
  echo $a_exrt | grep -q "OK" && a_exrt="false" || a_exrt="true"
  echo $a_high | grep -q "OK" && a_high="false" || a_high="true"
  echo $a__low | grep -q "OK" && a__low="false" || a__low="true"
  echo $a_humi | grep -q "OK" && a_humi="false" || a_humi="true"
  echo $a_faul | grep -q "OK" && a_faul="false" || a_faul="true"

  if  [[ $c_life == "" ]]; then
    echo $(date)" - получить показания с дегидратора не удалось" > "$SCR_DIR/dehydrator_log.txt" && exit 0
  else
    func_update_to_db       #~ заносит переменные в базу данных
  fi
}


func_update_to_db() {       #~ заносит переменные в базу данных
  echo c_life $c_life
  echo c_temp $c_temp
  echo c_high $c_high
  echo c__low $c__low
  echo c_humi $c_humi
  echo a_summ $a_summ
  echo a_exrt $a_exrt
  echo a_high $a_high
  echo a__low $a__low
  echo a_humi $a_humi
  echo a_faul $a_faul

#~ UPSERT данных дегидратора в базу данных
psql -h $HOST -d $DB -U "$DBROLE" -t 1>/dev/null <<EOF
INSERT INTO dehydrator_current VALUES
(
           $c_life,
           $c_temp,
           $c_high,
           ($c__low * 10)::smallint,
           ($c_humi * 10)::smallint,
           '$ip__addr',
           current_timestamp,
           $a_summ,
           $a_exrt,
           $a_high,
           $a__low,
           $a_humi,
           $a_faul
)
ON CONFLICT (ip) DO UPDATE SET  -- если значение ip уже есть, то UPDATE
  c_life = $c_life,
  c_temp = $c_temp,
  c_high = $c_high,
  c__low = ($c__low * 10)::smallint,
  c_humi = ($c_humi * 10)::smallint,
  ip     = '$ip__addr',
  time   = current_timestamp,
  a_summ = $a_summ,
  a_exrt = $a_exrt,
  a_high = $a_high,
  a__low = $a__low,
  a_humi = $a_humi,
  a_faul = $a_faul;
EOF
}


func_main #~ отсюда начинает работать программа
exit 0


exit 0  #~ Параметры дегидратора (для сведения)

#~ Параметр ALMGET выводит состояние аварийных дискретов
ALMGET
SUMMARY ALARM = OK
EXCESSIVE RUN TIME ALARM = OK
HIGH PRESSURE ALARM = OK
LOW PRESSURE ALARM = OK
HIGH HUMIDITY ALARM = OK
COMPR FAULT ALARM = OK

#~ Параметр ID выводит в конце наработку дегидратора
ID
Current Compressor life: 666 Hours  ( должно быть > 0 )

#~ Параметр MEAS выводит примерно такие измерения
MEAS
temp = 22C
high pressure = 11 psi  ( должно быть >= 0 )
low pressure = 2.2  psi ( должно быть >= 0 )
humidity = 0.0%         ( должно быть >= 0 )

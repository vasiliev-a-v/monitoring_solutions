#!/bin/bash
#~ считывает данные с температурного датчика DHT11, записывает в файл


func_main() {                     #~ главная функция
  MY_DIR="$(dirname $0)"          #~ папка в которой работает скрипт
  CFG_FILE="$MY_DIR"/config.txt   #~ имя файла конфига
  source "$CFG_FILE"

  if [ ! -e /sbin/read_dht ]; then
    cp /home/pi/scripts/read_dht /sbin/read_dht
  fi

  func_read_temp_to_tmp
}


func_read_temp_to_tmp() { #~ считывает температуру с датчика и пишет в файл
  while true; do
    string=$( read_dht 11 4 | grep "Temp" )
    if [[ $string != "" ]]; then
      string=$( echo $string  | awk -F " " '{print $3}' )
      string=$string-1
    else
      sleep 0.2
      continue
    fi
    if [[ $string != "" ]]; then
      string=$(( string ))
      [[ $temp == "" ]] && temp=$string
      false_temp_plus=$((  temp + 10 ))   #~ ложное значение температуры (иногда бывает)
      false_temp_minus=$(( temp - 10 ))   #~ ложное значение температуры (иногда бывает)

      #~ проверка на ложное значение температуры
      if (( string > false_temp_plus )) || (( string < false_temp_minus )); then
        #~ echo "ложняк string=$string false_temp_plus=$false_temp_plus"
        sleep 1
        continue
      fi

      temp=$string
      echo -en $temp > $_FILE_TMP && echo "записал $temp"
      sleep $_TIME
    else
      sleep 0.2
    fi
  done
}


func_main
exit 0

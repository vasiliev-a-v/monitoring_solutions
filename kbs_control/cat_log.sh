#!/bin/bash

SCRIPT="$(readlink -e "$0")"					#~ полный путь до файла скрипта
MY_DIR="$(dirname $SCRIPT)"						#~ каталог в которой работает скрипт
source "$MY_DIR"/common_config.txt				#~ вставляет общий конфиг
source "$MY_DIR/$ks"/config.txt					#~ вставляет локальный конфиг

while true; do
	tput reset
	tput civis
	tput cup 0 0
	tput setaf 3
	tput rev
	echo -ne
	tput sgr 0
	cat $process_log
	sleep 1
done


exit 0

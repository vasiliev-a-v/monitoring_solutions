#!/bin/bash
#~ стартовый процесс. Запускает экземпляры kbs_control.sh из каталогов


func_main() {   #~ главная функция
    SCRIPT="$(readlink -e "$0")"                    #~ полный путь до файла текущего скрипта
    MY_DIR="$(dirname $SCRIPT)"                     #~ каталог в которой работает скрипт
    F_NAME="$(basename $SCRIPT)"                    #~ имя файла текущего скрипта
    for kbs_control in $(ls -d -1 $MY_DIR/*/); do   #~ ищем процессы kbs_control.sh в каталогах
        $(dirname "$kbs_control")/kbs_control.sh $(basename "$kbs_control") &
        #~ echo "$kbs_control"
        #~ "$kbs_control" & #~ запускает найденные подпроцессы в фоне
    done
    wait        #~ ждёт завершения запущенных подпроцессов
}


func_main
exit 0

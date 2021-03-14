#!/bin/bash
#~ Программа проверки состояния базовых станций БС6 и БС7
#~ на контроллере базовых станций (КБС) "Гудвин"
#~ Программа опрашивает КБС раз в минуту:
#~ 1. Скачивает с КБС текущий лог (журнал), проверяет БС на наличие "off",
#~ 2. если есть "off", значит базовая станция отваливалась
#~ 3. проверяет есть ли далее в логе после "off" строка с "on"
#~ 4. если "on" нету, то значит базовая станция зависла,
#~ 5. включает счетчик "терпения" на соответствующую базовую станцию
#~ 6. пишет в свой журнал дату и номер отвалившейся базовой станции,
#~ 7. перезапускает коммутационный процесс g2
#~ 8. сбрасывает счетчики БС и поток E1_АТС
#~ 9. ставится на паузу - в следующий раз начинает проверять не ранее чем через 5 минут
#~ Автор: Васильев Антон


declare -a argv=( $* )
ks="$1"                                 #~ имя каталога для Объекта
SCRIPT="$(readlink -e "$0")"            #~ полный путь до файла скрипта
MY_DIR="$(dirname $SCRIPT)"             #~ каталог в которой работает скрипт
source "$MY_DIR"/common_config.txt      #~ вставляет общий конфиг
source "$MY_DIR/$ks"/config.txt         #~ вставляет локальный конфиг
TMP_DIR=/tmp/"$ks"                      #~ каталог для временных файлов
[ ! -d $TMP_DIR  ] && mkdir $TMP_DIR && chmod 0777 $TMP_DIR   #~ если каталога нет, то создает


func_main() {   #~ главная функция - с неё начинает работать скрипт
  (( ${#argv[@]} < 1 )) && func_help    #~ проверяет аргументы в командной строке
  func_start_initialization             #~ инициализация общих переменных
  func_check_sshpass                    #~ проверяет установлена ли утилита sshpass
  while true; do
    func_check_net                      #~ проверяет доступность КБС Гудвин по сети
    OBJ=(   $(cut -f 1 $MY_DIR/$ks/kbs_config.txt) )  #~ массив с номерами базовых станций
    CHECK=( $(cut -f 2 $MY_DIR/$ks/kbs_config.txt) )  #~ массив с проверяемостью базовых станций

    DATE_YMD="$( date +%y%m%d )"        #~ текущая дата (для скачивания файла лога с КБС)
    sshpass -p ${password} scp ${user_log}@$KBS_IP:/$DATE_YMD.log $TMP_DIR #~ скачивает актуальный лог КБС

    if [ $? -ne 0 ]; then
      func_process_log "Не удается скачать журнал событий. Ждём 1 минуту"
      sleep 60                          #~ ждём 1 минуту
      continue                          #~ начинает цикл while заново
    fi 
    func_read_file $TMP_DIR/$DATE_YMD.log   #~ читает файл лога КБС в массив
    func_reload_script                  #~ перезагружает скрипт, если есть файл
    func_pause_script                   #~ ставит скрипт на паузу
    func_get_Cell_status                #~ читает состояние базовых станций
    func_check_Cell_status              #~ проверяет триггеры БС на off, увеличивает счетчик
    sleep 60                            #~ пауза на 1 минуту
  done
}


func_start_initialization() { #~ функция, инициализирующая общие переменные скрипта
  TRG=( )     #~ массив состояния "off" или "on" базовых станций
  CNT=( )     #~ массив счетчиков терпения для каждой базовой станции
  MAX_CNT=5   #~ максимальное число для счетчика CNT, после которого перезапускает g2 в КБС
  RLD_TRG=0   #~ триггер для перезагрузки КБС. Отрабатывает полная перезагрузка КБС
  LOCKDAY=0   #~ блокирует перезагрузку КБС на день

  func_process_log "Скрипт $(basename "$0") запущен. Инициализируем переменные"
  func_process_log "$KBS_IP $KS $ks"
}


func_help() { #~ выводит хелп как надо стартовать скрипт
  echo Нет аргументов! Должно быть задано имя каталога для объекта. Например: ks46
  exit 0
}


func_read_file() {  #~ читает конфиг устройств в общий массив
  local i; i=0
  local line

  while read line; do
    [[ ${line:0:1} == "#" || ${line:0:2} == "//" ]] && continue #~ удаляет комментарии
    OBJ[$i]=$(    echo $line | awk -F "|" '{print $1}' )  #~ после -F стоит разделитель
    KBS_IP[$i]=$( echo $line | awk -F "|" '{print $2}' )  #~ после -F стоит разделитель
    (( i++ ))
  done < $1
}


func_process_log() {  #~ лог процессов в скрипте (для дебага и прочего)
  echo "$( date +%H:%M:%S ) - $1" | tee -a $process_log
  file=$( cat $process_log )
  echo "$file" | tail -n 20 > $process_log  #~ укорачивает файл лога до 20 строк
}


func_error_log() {    #~ лог ошибок в КБС
  echo $( date +%d.%m.%y" "%H:%M:%S ) - "$1" | tee -a $error_log
}


func_check_net() {  #~ проверяет доступность КБС Гудвин по сети
  local cnt=-1      #~ счетчик нужен, чтобы ошибка записалась в лог только один раз

  while true; do
    ping -c 1 $KBS_IP | grep -q "1 packets transmitted, 1 received, 0% packet loss"
    [[ $? == "0" ]] && break
    (( cnt++ )) && func_process_log "КБС Гудвин недоступна по сети"
    sleep 60        #~ пауза на 1 минуту
  done
  #~ если доступ по сети пропадал, то появляется надпись о восстановлении
  (( cnt > -1 )) && func_process_log "Восстановление сетевого доступа к КБС"
}


func_check_sshpass() {  #~ проверяет установлена ли утилита sshpass
  func_process_log "Проверяем наличие утилиты sshpass"
  if which sshpass 1>/dev/null; then
    return 0
  else
    echo "Необходимо установить утилиту sshpass. Введите пароль"
    sleep 1
    sudo apt-get install sshpass -y
    if [ $? -ne 0 ]; then
      func_error_log "Необходимо установить утилиту sshpass. Ошибка 127"
      exit 127  #~ если не может установить sshpass, то останавливает программу
    fi
    exec  $0 $KBS_IP "$KS" $ks  #~ перезапускает текущий процесс
  fi
}


func_reload_script() {  #~ проверяет наличие файла $(basename $0)_reload для перезапуска нашей программы

  if [ -e $reload_file ]; then    #~ перезапускаем нашу программу
    func_process_log "скрипт $(basename $0) ${KS} перезапущен"
    rm $reload_file
    exec  "$SCRIPT $ks"  #~ перезапускает текущий процесс
  fi
}


func_pause_script() { #~ проверяет наличие файла $(basename $0)_pause для перезапуска нашей программы
  local cnt=-1  #~ счетчик нужен, чтобы ошибка записалась в лог только один раз

  if [ -e $pause_file ]; then   #~ ставим на паузу нашу программу
    (( cnt++ )) && func_process_log "скрипт $(basename $0) ${KS} поставлен на паузу"
    while [ -e $pause_file ]; do
      sleep 1
    done
    func_process_log "скрипт $(basename $0) ${KS} снят с паузы"
  fi
}


func_read_file() {  #~ читает файл построчно в массив $1 - имя файла
  func_process_log "Читает лог КБС в массив FILE"
  local i=0         #~ классический счетчик (для массива FILE)
  local line        #~ строка из прочитываемого файла
  FILE=( )          #~ массив содержащий построчно файл. Перед заполнением - обнуляем

  while read line; do
    FILE[$i]="$line"
    (( i++ ))
  done < $1
}


func_get_Cell_status() {  #~ проверяет статус базовых станций из файла log
  local i; local obj

  for (( i = 0; i < ${#FILE[@]}; i++ )); do
    for (( obj = 0; obj < ${#OBJ[@]}; obj++ )); do
      if [[ ${TRG[$obj]} != "off" ]]; then
        echo "${FILE[$i]}" | grep -q "cell ${OBJ[$obj]}  off"
        [ $? -eq 0 ] && TRG[$obj]="off" #~ && echo -n "cell ${OBJ[$obj]}, ${TRG[$obj]}; "
      else
        echo "${FILE[$i]}" | grep -q "${OBJ[$obj]}  on"
        [ $? -eq 0 ] && TRG[$obj]="on"  #~ && echo -n "cell ${OBJ[$obj]}, ${TRG[$obj]}; "
      fi
    done
  done
}


func_check_Cell_status() {  #~ проверяет триггеры на off, увеличивает счетчик
  local i
  local bs_off=""

  func_process_log "Проверяет триггеры БС на off"
  for (( i = 0; i < ${#OBJ[@]}; i++ )); do      #~ если базовая станция off, то счетчик CNT увеличивается
    [[ ${CHECK[$i]}  == "not" ]] && continue    #~ если CHECK=not, то БС не проверяется
    if [[ ${TRG[$i]} == "off" ]]; then
      (( CNT[$i]++ ))
      bs_off=$bs_off"БС№${OBJ[$i]}=${TRG[$i]}. "
      func_process_log "БС №${OBJ[$i]} ${TRG[$i]}. Счётчик терпения: ${CNT[$i]} из $MAX_CNT"
      if ! [ -e $just_look_file ]; then   #~ если не включен режим не вмешиваться в КБС
        (( CNT[$i] > MAX_CNT )) && func_restart_g2_or_KBS "$i"
      fi
      return 0    #~ стоит для того, чтобы выйти из функции
                  #~ и начать процедуру проверки заново
    fi
  done

  if [[ $LOCKDAY == "0" ]]; then
    func_process_log "НОРМА"
  else
    func_process_log "LOCKDAY=$LOCKDAY. Перезапуск заблокирован на день"
  fi
  #~ до этого места дойдёт, если все БС будут в on
  CNT=( ); TRG=( ); RLD_TRG=0     #~ сбрасывает счетчики и триггеры
}


func_restart_g2_or_KBS() {  #~ производит перезапуск g2 или перезагрузку БС
  local Cell_Num=$1               #~ номер БС
  local current_day=$(date +%d)   #~ текущий день
  action=( "Перезапуск g2" "Перезагрузка КБС" )

  (( LOCKDAY == $current_day )) && return $LOCKDAY  #~ если КБС сегодня уже перезагружалась, то выходим из функции
  (( LOCKDAY >  0            )) && LOCKDAY=0        #~ сбрасывает день блокировки

  if (( RLD_TRG > 0 )); then  #~ значение 1 перезагружает КБС, 0 - g2
    sshpass -p ${password} ssh ${user_log}@$KBS_IP 'mro; reboot'   #~ перезагружает КБС
    func_error_log "Отключилась Cell ${OBJ[$Cell_Num]}; ${action[$RLD_TRG]}"
    RLD_TRG=0             #~ сбрасывает триггер перезагрузки КБС на ноль
    WAIT_TIME=200         #~ ТЕСТ: устанавливает время ожидания после перезагрузки КБС
    #~ WAIT_TIME=300      #~ устанавливает время ожидания после перезагрузки КБС 5 минут
    LOCKDAY=$(date +%d)   #~ устанавливает день блокировки (до следующего дня КБС больше не перезагрузится)
  else
    sshpass -p ${password} ssh ${user_log}@$KBS_IP 'mro; killall /mnt/dom/dect/g2' #~ перезапускает g2
    func_error_log "Отключилась Cell ${OBJ[$Cell_Num]}; ${action[$RLD_TRG]}"
    RLD_TRG=1            #~ триггер перезагрузки КБС ставит в один - в следующий раз перезагрузит КБС
    WAIT_TIME=100        #~ ТЕСТ: устанавливает время ожидания после перезапуска g2 3 минут
    #~ WAIT_TIME=180     #~ устанавливает время ожидания после перезапуска g2
  fi
  CNT=( ); TRG=( )       #~ сбрасывает счетчики и триггеры БС
  func_process_log "Ждём $WAIT_TIME"
  sleep $WAIT_TIME       #~ подождать несколько минут, пока связь с КБС восстановится
}


func_print_Cell_status() {  #~ выводит статус базовых станций
  local i

  for (( i = 0; i < ${#OBJ[@]}; i++ )); do
    echo -n "Cell ${OBJ[$i]} ${TRG[$i]}; "
  done
  echo
}


func_main
exit 0

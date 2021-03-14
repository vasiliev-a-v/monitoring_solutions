#~ файл с общими конфигурационными переменными и т.д.


SLEEP="sleep 0.1"                    #~ пауза между запросами
HOST="1.1.1.1"                       #~ IP-адрес СУБД
DB="electro_temperature"             #~ имя базы данных
DBROLE="user"                        #~ роль (пользователь) в базе данных

if [ "$1" != "" ]; then
  DB="$1"              #~ имя базы данных задано при запуске
  html_file="$1"       #~ имя файла html
else
  html_file="electro"
fi

declare -a OBJ=( )                          #~ список объектов ПРС
declare -a _IP=( )                          #~ список ip-адресов оборудования
SCRIPT="$(readlink -e "$0")"                #~ полный путь до файла скрипта
SCR_DIR=$(dirname $SCRIPT)                  #~ каталог в котором лежит скрипт
daily_reports="$SCR_DIR/daily_reports"      #~ папка с отчётами за сутки
TMP_DIR="/tmp/$(basename $SCR_DIR)"        #~ каталог для временных файлов
[ ! -d $TMP_DIR  ] && \
mkdir $TMP_DIR && chmod 0777 $TMP_DIR       #~ если каталога нет, то создает
date_out=$( date +%Y-%m-%d )


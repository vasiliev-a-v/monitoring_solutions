#~ файл с общими конфигурационными переменными


SLEEP="sleep 0.1"                       #~ пауза между запросами
HOST="10.10.10.10"                      #~ IP-адрес СУБД
DB="dehydrator"                         #~ имя базы данных
DBROLE="user"                           #~ роль (пользователь) в базе данных

SCRIPT="$(readlink -e "$0")"            #~ полный путь до файла скрипта
SCR_DIR=$(dirname $SCRIPT)              #~ каталог в котором лежит скрипт
daily_reports="$SCR_DIR/daily_reports"  #~ папка с отчётами за сутки

date_out=$( date +%Y-%m-%d )            #~ дата в формате поиска в БД
date_rus=$( date +%d.%m.%Y )            #~ текущая дата в Российском формате

username="pi"                           #~ пользователь микрокомпьютера "R"
password=""                             #~ пароль микрокомпьютера "R"
ip__addr="10.10.11.11"                  #~ IP-адрес микрокомпьютера "R"
com_port=""                             #~ имя файла COM-порта ttyUSB
file=/tmp/dehydrator.txt
html_file=/tmp/dehydrator.htm           #~ html-файл визуализации на сервере приложений
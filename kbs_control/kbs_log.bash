#!/bin/bash
#~ отображает журнал, скачанный с КБС Гудвин


SCRIPT="$(readlink -e "$0")"                    #~ полный путь до файла скрипта
MY_DIR="$(dirname $SCRIPT)"                     #~ каталог в которой работает скрипт
ks="${QUERY_STRING}"                            #~ получает через адресную строку имя каталога
[[ $ks == "" ]] && exit 127
source "$MY_DIR"/common_config.txt              #~ вставляет общий конфиг
source "$MY_DIR/$ks"/config.txt                 #~ вставляет локальный конфиг
#~ _LOG=$( tac "$process_log" | head -n 8 ) #~ файл журнала
DATE_YMD="$( date +%y%m%d )"                #~ текущая дата (имя скачанного файла лога с КБС)
_LOG=$( cat /tmp/$ks/$DATE_YMD.log )
_SITE=""


func_main() {   #~ основная функция
    echo "Content-type: text/html; charset=utf-8"
    echo ""
    func_make_site
    echo -e ${_SITE//
/\\n}
}


func_make_site() {  #~ собирает воедино html-код веб-страницы
_SITE="
<html>
<meta http-equiv=refresh content=11,url=http://$SERVER_ADDR$SCRIPT_NAME?$QUERY_STRING>
<title>Журнал процессов фоновой службы контроля за КБС</title>
<body leftmargin=0 rightmargin=0 topmargin=0 bottommargin=0 bgcolor=#4D4D4D text=white>
$( date +%d.%m.%y" "%H:%M:%S ) - [<b> ${KS} </b>]<br>
${_LOG//
/<br>\\n}
</body>
</html>"
}


func_main
exit 0

#!/bin/bash
#~ веб-страница для отображения схемы оборудования


_SITE=""
SCRIPT="$(readlink -e "$0")"          #~ полный путь до файла скрипта
MY_DIR="$(dirname $SCRIPT)"           #~ каталог в которой работает скрипт


func_main() {  #~ основная функция
  func_make_site
  echo "Content-type: text/html; charset=utf-8"
  echo ""
  echo -e ${_SITE//
/\\n}
}


func_make_site() {  #~ создает веб-интерфейс с внедренной схемой
_SITE="
<html><title>Сеть оборудования</title>
<head>
<meta http-equiv=Content-Type content=text/html;charset=utf-8>
<meta http-equiv=refresh content=11,url=http://$SERVER_ADDR$SCRIPT_NAME>
</head>
<body leftmargin=0 rightmargin=0 topmargin=0 bottommargin=0 bgcolor=#FFFFFF text=#000000><div style='position:absolute; text-align:center; left:630px; top:10px'>$( date +%d.%m.%y" г. "%H:%M:%S )</div>$( cat /tmp/ss_mon.svg )</body>
</html>
"
}


func_main   #~ вызов функции запускает скрипт
exit 0

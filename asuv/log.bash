#!/bin/bash

#~ модуль отображает журнал событий


SCRIPT="$(readlink -e "$0")"          #~ полный путь до файла скрипта
MY_DIR="$(dirname $SCRIPT)"           #~ каталог в которой работает скрипт

IFS_OLD=$IFS          #~ Сохранили текущий разделитель полей
IFS=$'\n'             #~ Выставили в качестве разделителя полей символ перевода строки
LOG=( $(tac $MY_DIR/log.txt) )

echo "Content-type: text/html; charset=utf-8"
echo ""

echo -e "<html>
<head>
<meta http-equiv=Content-Type content=text/html;charset=utf-8>
<title>Журнал АСУ Вентиляцией</title>
</head>
<body leftmargin=0 rightmargin=0 topmargin=0 bottommargin=0 bgcolor=#4D4D4D text=white>"

for (( i = 0; i < ${#LOG[@]}; i++ )); do
  echo -e ${LOG[$i]}"<br>\n"
done

echo -e "</body>
</html>"

IFS=$IFS_OLD    #~ Восстановили разделитель полей
exit 0

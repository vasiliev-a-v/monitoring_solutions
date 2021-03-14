#!/bin/bash
#~ ВЕБ-ИНТЕРФЕЙС
#~ отображает температуры на Объектах


_SITE=""

SCRIPT="$(readlink -e "$0")"          #~ полный путь до файла скрипта
SCR_DIR=$(dirname $SCRIPT)            #~ каталог в котором лежит скрипт
TMP_DIR="/tmp/$(basename $SCR_DIR )"  #~ каталог для временных файлов
readonly HOST="1.1.1.1"               #~ IP-адрес СУБД
readonly DB="temp"                    #~ имя базы данных
readonly DBUSER="user"                #~ имя роли базы данных


func_main() { #~ основная функция
  func_read_cfg
  func_get_temp
  func_make_color
  func_make_table
  func_make_site
  echo "Content-type: text/html; charset=utf-8"
  echo ""
  echo -e ${_SITE//
/\\n}
}


func_read_cfg() {  #~ читает конфигурацию из БД
  local IFS=$'\n'

  local command="SELECT * FROM locations ORDER BY id;"
  local cfg=$(psql -h $HOST -d $DB -U "${DBUSER}" --pset="footer=off" -t -A -c "$command")

  IP=(    $( echo "${cfg[@]}" | cut -f1 -d '|' ) )  #~ столбец IP-адреса
  OBJ=(   $( echo "${cfg[@]}" | cut -f2 -d '|' ) )  #~ столбец Объекты
  BLUE=(  $( echo "${cfg[@]}" | cut -f5 -d '|' ) )  #~ столбец низкая температура
  YELLOW=($( echo "${cfg[@]}" | cut -f6 -d '|' ) )  #~ столбец повышенная температура
  RED=(   $( echo "${cfg[@]}" | cut -f7 -d '|' ) )  #~ столбец высокая температура
}


func_get_temp() { #~ собирает температуру в массив
  local IFS=$'\n'

  local command="SELECT temperature FROM temp_current t JOIN locations l ON t.location = l.location ORDER BY l.id;"
  TEMP=( $(psql -h $HOST -d $DB -U "${DBUSER}" --pset="footer=off" -t -A -c "$command") )
}


func_make_color() {  #~ в зависимости от температуры, выставляет цвет ячейки (красный, жёлтый, зелёный)
  for (( i = 0; i < ${#OBJ[@]}; i++ )); do
    color[$i]="#87B987"   #~ по-умолчанию зеленый
    t=${TEMP[$i]}    #~ после -F стоит разделитель
    (( t <= ${BLUE[$i]}   )) && color[$i]="#A2C4D0"    #~ синий   цвет
    (( t >= ${YELLOW[$i]} )) && color[$i]="#F1D678"    #~ жёлтый  цвет
    (( t >= ${RED[$i]}    )) && color[$i]="#DE9586"    #~ красный цвет
  done
}


func_make_table() {  #~ создает таблицу и заполняет её данными
  for (( i = 0; i < ${#OBJ[@]}; i++ )); do
    TABLE_HTML=$TABLE_HTML"
    <tr class=tooltip align=center>
    <td width=75%>
      <a href=#obj$i>${OBJ[$i]}</a>
      <span><img class=img_wh src='/temp/${OBJ[$i]}.svg'></span>
      <div class=lightbox id=obj$i><figure>
        <a href=# class=close></a>
        <img src='/temp/${OBJ[$i]}.svg'>
      </figure></div>
    </td>
    <td bgcolor=${color[$i]} width=25%>"${TEMP[$i]}"</td>
    </tr>"
  done
}


func_make_site() {  #~ собирает воедино html-код веб-страницы
DATE=$(date +%d.%m.%y" г. "%H:%M:%S)
_SITE="
<html><title>Контроль температур на Объектах</title>
  <head>
    <meta name=generator content='Geany 1.22'>
    <meta http-equiv=Pragma content=no-cache>
    <meta http-equiv=refresh content=60>
    <link rel=stylesheet href=/take_temp/take_temp_style.css>
  </head>
<body leftmargin=0 rightmargin=0 topmargin=0 bottommargin=0 bgcolor=#FFFFFF text=black link=black vlink=black>
<font face=Arial size=-1>
<table width=200 cellpadding=3 cellspacing=0 border=1>
$TABLE_HTML
</table><br>
[ $DATE ]<br>
</font>
</body>
</html>"
}


func_main
exit 0

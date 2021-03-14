#!/bin/bash
#~ формирует web-страницу (таблицу) с результатами
#~ Компонует объекты с юга на север по IP-адресу


source $(dirname $(readlink -e "$0"))/config.sh    #~ подключается файл с общим конфигом


red="D2A0AF"                      #~ Цвета клеток в таблице: красный
yellow="F4F4AD"                   #~ Жёлтый
green="B6D1A0"                    #~ Зелёный


func_main() {                     #~ с неё начинает работать программа
  func_read_cfg                   #~ читает конфиг из SQL-базы в общий массив
  func_read_results               #~ читает данные об устройстве в массив
  func_make_html_code             #~ создает HTML-код

  echo -e "${_SITE//
/\\n}" > /tmp/"$html_file.htm"
}


func_read_cfg() {                 #~ читает конфиг из SQL-базы в общий массив
  local IFS=$'\n'

  local cfg=$( psql -h $HOST -d $DB -U "$DBROLE" -t <<EOF
  SELECT * FROM locations ORDER BY ip;
EOF
)
  _IP=( $( echo "${cfg[@]}" | cut -f1 -d '|' | tr -d " " ) )  #~ первый столбец с IP-адресами
  OBJ=( $( echo "${cfg[@]}" | cut -f2 -d '|' | tr -d " " ) )  #~ второй столбец с Объектами
}


func_read_results() {   #~ читает данные об устройстве в массив
  local i
  local result

  for (( i = 0; i < ${#_IP[@]}; i++ )); do
    result=$( psql -h $HOST -d $DB -U $DBROLE -t <<EOF
    SELECT * FROM temp_current WHERE location = '${OBJ[$i]}';
EOF
)

    result=( ${result//"|"/" "} )
    temp_sys[$i]=${result[3]}
    temp_akb[$i]=${result[4]}
    alarm_mains[$i]=${result[5]}
    out_volt[$i]=$(echo  "scale=1; ${result[6]}*0.1"  | bc)
    out_ampr[$i]=$(echo  "scale=1; ${result[7]}*0.1"  | bc)
    out_watt[$i]=$(echo  "scale=1; ${result[8]}*0.1"  | bc)
    if [[ $(echo "scale=2; ${out_watt[$i]} < 1" | bc) != 0 ]]; then
      out_watt[$i]="0${out_watt[$i]}"
    fi
    battery1v[$i]=$(echo "scale=1; ${result[9]}*0.1"  | bc)
    battery2v[$i]=$(echo "scale=1; ${result[10]}*0.1" | bc)
  done
}


func_make_html_code() {     #~ создает HTML-код
  local i

  _SITE="<html>
  <head>
    <title>Electro</title>
    <meta http-equiv='content-type' content='text/html;charset=utf-8'>
    <meta name=generator content='Geany 1.22'>
    <meta http-equiv=Pragma content=no-cache>
    <meta http-equiv=refresh content=60>
    <link rel=stylesheet href=/take_electro_style.css>
    <script>
      ip_plan='http://'+location.hostname
    </script>
  </head>
<body leftmargin=0 topmargin=0>
<font face=Monospace>
$( date +%d.%m.%Y" г. "%H:%M:%S )
<table bordercolor=#0E0E0E cellpadding=2 cellspacing=0 border=1><tr>
<td> Объект   </td>
<td> t АКБ    </td>
<td> t сист   </td>
<td> Вход V   </td>
<td> АБ-1 V   </td>
<td> АБ-2 V   </td>
<td> Выход V  </td>
<td> Выход A  </td>
<td> Выход W  </td>
<td> IP-адрес </td>
</tr>"

  for (( i = 0; i < ${#_IP[@]}; i++ )); do

    func_coloring 15 27 5 35    "${temp_akb[$i]}"
    temp_akb[$i]="<td  bgcolor=$color>${temp_akb[$i]}</td>"
    func_coloring 20 40 15 45   "${temp_sys[$i]}"
    temp_sys[$i]="<td  bgcolor=$color>${temp_sys[$i]}</td>"
    func_coloring 53 55 47 60   "${battery1v[$i]}"
    battery1v[$i]="<td bgcolor=$color>${battery1v[$i]}</td>"
    func_coloring 53 55 47 60   "${battery2v[$i]}"
    battery2v[$i]="<td bgcolor=$color>${battery2v[$i]}</td>"

    case "${alarm_mains[$i]}" in
    0 ) input="<td bgcolor=$green>Есть 380</td>";;
    1 ) input="<td bgcolor=$red  >Нет  380</td>";;
    esac

    _SITE="$_SITE
    <tr>
    <td class=tooltip>
      <a href=#obj$i>
      ${OBJ[$i]}
        <span>
          <img class=img_wh src="$(basename $SCR_DIR)/${OBJ[$i]}.svg">
        </span>
      </a>
<div class=lightbox id=obj$i>
  <figure>
    <a href=# class=close></a>
    <img src="$(basename $SCR_DIR)/${OBJ[$i]}.svg">
  </figure>
</div>
    </td>
    ${temp_akb[$i]}
    ${temp_sys[$i]}
    $input
    ${battery1v[$i]}
    ${battery2v[$i]}
    <td>${out_volt[$i]}</td>
    <td>${out_ampr[$i]}</td>
    <td>${out_watt[$i]}</td>
    <td><a href=http://${_IP[$i]} target=_blank>${_IP[$i]}</a></td>
    </tr>\n"
  done

if [[ $html_file != "electro" ]]; then
  html_bottom=""
else
html_bottom="<small>
Отчёт Electro
[ <a href=/html/take_electro/daily_reports/$( date +%Y-%m-%d ).htm>$( date +%Y-%m-%d )</a> |
  <a href=/html/take_electro/daily_reports/$(date -d "-1 day" +%Y-%m-%d).htm>$(date -d "-1 day" +%Y-%m-%d)</a> |
  <a href=/html/take_electro/daily_reports/$(date -d "-2 day" +%Y-%m-%d).htm>$(date -d "-2 day" +%Y-%m-%d)</a> |
  <a href=/html/take_electro/daily_reports/$(date -d "-3 day" +%Y-%m-%d).htm>$(date -d "-3 day" +%Y-%m-%d)</a> |
  <a href=/html/take_electro/daily_reports/$(date -d "-4 day" +%Y-%m-%d).htm>$(date -d "-4 day" +%Y-%m-%d)</a> |
  <a href=/html/take_electro/daily_reports/$(date -d "-5 day" +%Y-%m-%d).htm>$(date -d "-5 day" +%Y-%m-%d)</a> ]
<br>
Отчёт Truepoint 6500
[ <a href=/html/truepoint/daily_reports/$( date +%Y-%m-%d ).htm>$( date +%Y-%m-%d )</a> |
  <a href=/html/truepoint/daily_reports/$(date -d "-1 day" +%Y-%m-%d).htm>$(date -d "-1 day" +%Y-%m-%d)</a> |
  <a href=/html/truepoint/daily_reports/$(date -d "-2 day" +%Y-%m-%d).htm>$(date -d "-2 day" +%Y-%m-%d)</a> |
  <a href=/html/truepoint/daily_reports/$(date -d "-3 day" +%Y-%m-%d).htm>$(date -d "-3 day" +%Y-%m-%d)</a> |
  <a href=/html/truepoint/daily_reports/$(date -d "-4 day" +%Y-%m-%d).htm>$(date -d "-4 day" +%Y-%m-%d)</a> |
  <a href=/html/truepoint/daily_reports/$(date -d "-5 day" +%Y-%m-%d).htm>$(date -d "-5 day" +%Y-%m-%d)</a> ]
<br>
</small>"
fi  

_SITE="$_SITE
</table>
$html_bottom
</font>
</body>
</html>
"
}


func_coloring() {                       #~ Выставляет цвет для массивов
  color=$green
  local b=$( echo $5 | cut -f1 -d"." )  #~ выделяем целую часть числа (до запятой)
  local y_min=$1; local y_max=$2
  local r_min=$3; local r_max=$4

  (( b < y_min )) || (( b > y_max )) && color=$yellow
  (( b < r_min )) || (( b > r_max )) && color=$red
}


func_main #~ отсюда начинает работать программа

exit 0

#!/bin/bash
#~ формирует web-страницу с результатами


source $(dirname $(readlink -e "$0"))/config.sh    #~ подключается файл с общим конфигом


red="D2A0AF"                      #~ Цвета клеток в таблице: красный
yellow="F4F4AD"                   #~ Жёлтый
green="B6D1A0"                    #~ Зелёный


func_main() {                     #~ с неё начинает работать программа
  func_read_cfg                   #~ читает конфиг из SQL-базы в общий массив
  func_read_results               #~ читает данные об устройстве в массив
  func_make_html_code             #~ создает HTML-код

  echo -e "${_SITE//
/\\n}" > "$html_file"
}


func_read_cfg() {                 #~ читает конфиг из SQL-базы в общий массив
  local IFS=$'\n'

  local cfg=$(
    psql  -h $HOST -d $DB -U "$DBROLE" -tqA 2>/dev/null \
          -c '\timing off' -c 'SELECT * FROM locations ORDER BY ip;'
  )
  _IP=( $( echo "${cfg[@]}" | cut -f1 -d '|' ) )  #~ первый столбец с IP-адресами
  OBJ=( $( echo "${cfg[@]}" | cut -f2 -d '|' ) )  #~ второй столбец с Объектами
}


func_read_results() {   #~ читает данные об устройстве в массив
  local i
  local result

  for (( i = 0; i < ${#_IP[@]}; i++ )); do
    result=$(
      psql  -h $HOST -d $DB -U "$DBROLE" -tqA 2>/dev/null \
            -c '\timing off' \
            -c "SELECT * FROM dehydrator_v WHERE ip = '${_IP[$i]}'"
    )

  c_life=( $( echo "$result" | cut -f1  -d '|' ) )  #~ выделяет столбец
  c_temp=( $( echo "$result" | cut -f2  -d '|' ) )  #~ из таблицы результата
  c_high=( $( echo "$result" | cut -f3  -d '|' ) )
  c__low=( $( echo "$result" | cut -f4  -d '|' ) )
  c_humi=( $( echo "$result" | cut -f5  -d '|' ) )
  c_time=( $( echo "$result" | cut -f6  -d '|' | tr ' ' '_' ) )

  a_summ=( $( echo "$result" | cut -f7  -d '|' ) )  #~ состояние алармов
  a_exrt=( $( echo "$result" | cut -f8  -d '|' ) )
  a_high=( $( echo "$result" | cut -f9  -d '|' ) )
  a__low=( $( echo "$result" | cut -f10 -d '|' ) )
  a_humi=( $( echo "$result" | cut -f11 -d '|' ) )
  a_faul=( $( echo "$result" | cut -f12 -d '|' ) )

  c_avrg=( $( echo "$result" | cut -f14 -d '|' ) )  #~ средняя наработка
  
  done
}


func_make_html_code() {     #~ создает HTML-код
  local i

  _SITE="<html>
  <head>
    <title>Дегидратор Andrew</title>
    <meta http-equiv='content-type' content='text/html;charset=utf-8'>
    <meta http-equiv=Pragma content=no-cache>
    <meta http-equiv=refresh content=60>
    <script>
      ip_plan='http://'+location.hostname
    </script>
  </head>
<body leftmargin=0 topmargin=0>
<font face=Monospace>
Опрос проведён: "${c_time}"
<table bordercolor=#0E0E0E cellpadding=2 cellspacing=0 border=1><tr>
<td> Объект      </td>
<td> Наработка   </td>
<td> Средняя     </td>
<td> t°C         </td>
<td> Высокое     </td>
<td> Низкое      </td>
<td> Влажность   </td>
<td> Э/питание   </td>
<td> Контроллер  </td>
</tr>"

  for (( i = 0; i < ${#_IP[@]}; i++ )); do
    #~ раскрашивание ячеек в таблице
    [ ${a_summ[$i]} == "f" ] && color=$green || color=$red
    OBJ[$i]="<td bgcolor=$color>"${OBJ[$i]}"</td>"

    [ ${a_exrt[$i]} == "f" ] && color=$green || color=$red
    c_life[$i]="<td bgcolor=$color>"${c_life[$i]}"</td>"

    argument=$(echo "scale=2; ${c_avrg[$i]} * 100" | bc)
    func_coloring 14 26 5 45 $argument
    c_avrg[$i]="<td bgcolor=$color>"${c_avrg[$i]}"</td>"

    func_coloring 15 27 5 35        ${c_temp[$i]}
    c_temp[$i]="<td bgcolor=$color>"${c_temp[$i]}"</td>"

    [ ${a_high[$i]} == "f" ] && color=$green || color=$red
    c_high[$i]="<td bgcolor=$color>"${c_high[$i]}"</td>"

    [ ${a__low[$i]} == "f" ] && color=$green || color=$red
    c__low[$i]="<td bgcolor=$color>"${c__low[$i]}"</td>"

    [ ${a_humi[$i]} == "f" ] && color=$green || color=$red
    c_humi[$i]="<td bgcolor=$color>"${c_humi[$i]}"</td>"

    if [ ${a_faul[$i]} == "f" ]; then
      color=$green; a_faul[$i]=OK
    else
      color=$red; a_faul[$i]=NO
    fi
    a_faul[$i]="<td bgcolor=$color>"${a_faul[$i]}"</td>"

    rpi="<td>"${_IP[$i]}"</td>"


    _SITE="$_SITE
    <tr>
    ${OBJ[$i]}
    ${c_life[$i]}
    ${c_avrg[$i]}
    ${c_temp[$i]}
    ${c_high[$i]}
    ${c__low[$i]}
    ${c_humi[$i]}
    ${a_faul[$i]}
    $rpi
    </tr>\n"
  done

_SITE="$_SITE
</table>
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


exit 0
ALMGET

SUMMARY ALARM = OK
EXCESSIVE RUN TIME ALARM = OK
HIGH PRESSURE ALARM = OK
LOW PRESSURE ALARM = OK
HIGH HUMIDITY ALARM = OK
COMPR FAULT ALARM = OK

Current Compressor life:  679 Hours > 0
temp = 22C
high pressure = 11 psi >= 0
low pressure = 2.3  psi >= 0
humidity = 0.0% >= 0

<pre>
+-------------------------------+
| SUMMARY ALARM            = OK |
| EXCESSIVE RUN TIME ALARM = OK |
| HIGH PRESSURE ALARM      = OK |
| LOW PRESSURE ALARM       = OK |
| HIGH HUMIDITY ALARM      = OK |
| COMPR FAULT ALARM        = OK |
+-------------------------------+
</pre>


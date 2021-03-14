#!/bin/bash
#~ формирует web-страницу (таблицу) с отчетом за 0, 3, 6 часов с расцветкой
#~ Компонует объекты с юга на север по IP-адресу


source $(dirname $(readlink -e "$0"))/config.sh    #~ подключается файл с общим конфигом


red="D2A0AF"                      #~ Красный / Цвета клеток в таблице: 
yellow="F4F4AD"                   #~ Жёлтый  / https://colorscheme.ru/#1b62P80sO6q6q
green="B6D1A0"                    #~ Зелёный

#~       Цвета:
#~       Белый  КС-48  ПечЛПУ КС-48  КС-47  КС-46  КС-45
clrarr=( FFFFFF E9E9E9 E8DBB3 E9E9E9 CFEAF3 F9F9F9 F4F4AD )
clrcnt=0


func_main() {                     #~ с неё начинает работать программа
  func_query
  func_make_html_code
  echo -e "${_SITE//
/\\n}" > "$daily_reports"/$date_out.htm
}


func_query() {                    #~ делает запрос
  local IFS=$'\n'
  local i

  fl_query="$SCR_DIR"/select_report_temp.sql
  date_out=$( date +%Y-%m-%d )

  query=$( sed "s/to_char(current_date, 'YYYY-mm-dd')/'$date_out'/g" $fl_query)

  result=$( psql -h $HOST -d $DB -U "$DBUSER" -P footer=off -A -t -q -c "$query" )
  own_ks_ss=( $( echo "${result[*]}" | cut -s -f1 -d '|' ) )
  locations=( $( echo "${result[*]}" | cut -s -f2 -d '|' ) )
  temp_sys0=( $( echo "${result[*]}" | cut -s -f3 -d '|' ) )
  temp_sys3=( $( echo "${result[*]}" | cut -s -f5 -d '|' ) )
  temp_sys6=( $( echo "${result[*]}" | cut -s -f7 -d '|' ) )
  temp_akb0=( $( echo "${result[*]}" | cut -s -f4 -d '|' ) )
  temp_akb3=( $( echo "${result[*]}" | cut -s -f6 -d '|' ) )
  temp_akb6=( $( echo "${result[*]}" | cut -s -f8 -d '|' ) )
}


func_make_html_code() {           #~ создает HTML-код
  local i

  _SITE="<html>
<head>
  <title>Отчет Electro за $( date +%d.%m.%Y" г. ")</title>
  <meta http-equiv='content-type' content='text/html;charset=utf-8'>
</head>
<style>
    body{
    background:#FFFFFF;
    color:#000000;
    }
    a {color:#425E67;}
    td {font-size: 12; color:#000000;}
</style>
<body>
<font face=Monospace>
Отчет Electro за $( date +%d.%m.%Y" г. "%H:%M:%S )
<table bordercolor=#0E0E0E cellpadding=3 cellspacing=0 border=1><tr>
<td> Район      </td>
<td> Объект     </td>
<td> t сист 0:00</td>
<td> t АКБ  0:00</td>
<td> t сист 3:00</td>
<td> t АКБ  3:00</td>
<td> t сист 6:00</td>
<td> t АКБ  6:00</td>
</tr>"

  for (( i = 0; i < ${#locations[@]}; i++ )); do
    if [[ "${own_ks_ss[$i]}" != "${own_ks_ss[$i-1]}" ]]; then
      ((clrcnt++))
    fi
    clrks=${clrarr[$clrcnt]}
    own_ks_ss_td="<td  bgcolor=$clrks>${own_ks_ss[$i]}</td>"
    locations_td="<td  bgcolor=$clrks>${locations[$i]}</td>"

    func_coloring 20 40 15 45   "${temp_sys0[$i]}"
    temp_sys0[$i]="<td  bgcolor=$color>${temp_sys0[$i]}</td>"
    func_coloring 20 40 15 45   "${temp_sys3[$i]}"
    temp_sys3[$i]="<td  bgcolor=$color>${temp_sys3[$i]}</td>"
    func_coloring 20 40 15 45   "${temp_sys6[$i]}"
    temp_sys6[$i]="<td  bgcolor=$color>${temp_sys6[$i]}</td>"

    func_coloring 15 27 5 35    "${temp_akb0[$i]}"
    temp_akb0[$i]="<td  bgcolor=$color>${temp_akb0[$i]}</td>"
    func_coloring 15 27 5 35    "${temp_akb3[$i]}"
    temp_akb3[$i]="<td  bgcolor=$color>${temp_akb3[$i]}</td>"
    func_coloring 15 27 5 35    "${temp_akb6[$i]}"
    temp_akb6[$i]="<td  bgcolor=$color>${temp_akb6[$i]}</td>"

    _SITE="$_SITE
    <tr>
    $own_ks_ss_td
    $locations_td
    ${temp_sys0[$i]}${temp_akb0[$i]}
    ${temp_sys3[$i]}${temp_akb3[$i]}
    ${temp_sys6[$i]}${temp_akb6[$i]}
    </tr>\n"
  done

_SITE="$_SITE</table></font>
</body>
</html>
"
}


func_coloring() {                       #~ Выставляет цвет для массивов
  color=$green
  local b="$5"
  local y_min=$1; local y_max=$2
  local r_min=$3; local r_max=$4

  (( b < y_min )) || (( b > y_max )) && color=$yellow
  (( b < r_min )) || (( b > r_max )) && color=$red
}


func_main #~ отсюда начинает работать программа
exit 0

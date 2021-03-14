#!/bin/bash
#~ скрипт читает Electro по SNMP и записывает в SQL базу DB


source $(dirname $(readlink -e "$0"))/config.sh    #~ подключается файл с общим конфигом


func_main() {                        #~ основная функция
  func_read_cfg
  func_get_data_from_ip_array
}


func_read_cfg() {                    #~ читает конфиг из SQL-базы в общий массив
  local IFS=$'\n'

  local cfg=$( psql -h $HOST -d $DB -U "$DBROLE" -t <<EOF
  SELECT * FROM locations ORDER BY ip;
EOF
)
  _IP=( $( echo "${cfg[@]}" | cut -f1 -d '|' | tr -d " " ) )  #~ первый столбец с IP-адресами
  OBJ=( $( echo "${cfg[@]}" | cut -f2 -d '|' | tr -d " " ) )  #~ второй столбец с Объектами
}


func_snmpget_electro() {           #~ закладывает данные в массив, по IP-адресу
  local ip="$1"                   #~ $1 аргумент - IP-адрес объекта
  local i=$2                      #~ $2 аргумент - индекс массива

  battery1v=$(  snmpget -v 1 -c sgsread $ip 1.3.6.1.4.1.1488.16.1.6.1.2.1.0    )
  $SLEEP
  battery2v=$(  snmpget -v 1 -c sgsread $ip 1.3.6.1.4.1.1488.16.1.6.1.2.2.0    )
  $SLEEP
  temp_akb=$(   snmpget -v 1 -c sgsread $ip 1.3.6.1.4.1.1488.16.1.6.1.7.1.0    )
  $SLEEP
  temp_sys=$(   snmpget -v 1 -c sgsread $ip 1.3.6.1.4.1.1488.16.1.6.1.7.2.0    )
  $SLEEP
  alarm_mains=$(snmpget -v 1 -c sgsread $ip 1.3.6.1.4.1.1488.16.1.6.1.5.3.10.0 )
  $SLEEP
  out_volt=$(   snmpget -v 1 -c sgsread $ip 1.3.6.1.4.1.1488.16.1.6.1.4.1.0    )
  $SLEEP
  out_ampr=$(   snmpget -v 1 -c sgsread $ip 1.3.6.1.4.1.1488.16.1.6.1.4.2.0    )
  $SLEEP
  out_watt=$(   snmpget -v 1 -c sgsread $ip 1.3.6.1.4.1.1488.16.1.6.1.4.3.0    )
  $SLEEP

  battery1v=$(   echo $battery1v   | cut -f4 -d" " )
  battery2v=$(   echo $battery2v   | cut -f4 -d" " )
  temp_akb=$(    echo $temp_akb    | cut -f4 -d" " )
  temp_sys=$(    echo $temp_sys    | cut -f4 -d" " )
  alarm_mains=$( echo $alarm_mains | cut -f4 -d" " )
  out_volt=$(    echo $out_volt    | cut -f4 -d" " )
  out_ampr=$(    echo $out_ampr    | cut -f4 -d" " )
  out_watt=$(    echo $out_watt    | cut -f4 -d" " )


#~ UPSERT данных с SNMP-адаптера Electro в базу данных
psql -h $HOST -d $DB -U "$DBROLE" -t 1>/dev/null <<EOF
INSERT INTO temp_current VALUES
(		'${OBJ[$i]}', 
		current_timestamp, 
		$temp_sys,
  		$temp_akb,
  		$alarm_mains,
 		$out_volt,
  		$out_ampr,
  		$out_watt,
  		$battery1v,
  		$battery2v
)
ON CONFLICT (location) DO UPDATE SET
  time        = current_timestamp,
  temp_sys    = $temp_sys,
  temp_akb    = $temp_akb,
  alarm_mains = $alarm_mains,
  out_volt    = $out_volt,
  out_ampr    = $out_ampr,
  out_watt    = $out_watt,
  battery1v   = $battery1v,
  battery2v   = $battery2v
EOF
}


func_get_data_from_ip_array() {   #~ обращается по списку IP-адресов (в фоне)
  local i=0

  for (( i = 0; i < ${#_IP[@]}; i++ )); do
    func_snmpget_electro "${_IP[$i]}" $i &
    $SLEEP
  done
  wait
}


func_main #~ отсюда начинает работать программа
exit 0

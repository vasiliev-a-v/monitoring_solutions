#!/bin/bash
#~ ВЕБ-ИНТЕРФЕЙС
#~ контролирует управляет КБС Гудвин


_SITE=""

SCRIPT="$(readlink -e "$0")"					#~ полный путь до файла скрипта
MY_DIR="$(dirname $SCRIPT)"						#~ каталог в которой работает скрипт

ks=$(  echo ${QUERY_STRING} | cut -f 1 -d "&" )	#~ получает через адресную строку имя каталога
GET=$( echo ${QUERY_STRING} | cut -f 2 -d "&" )	#~ получает через адресную строку GET-запрос
[[ $ks == "" ]] && exit 127
source "$MY_DIR"/common_config.txt				#~ вставляет общий конфиг
source "$MY_DIR/$ks"/config.txt					#~ вставляет локальный конфиг
kbs_cfg_file="$MY_DIR/$ks"/kbs_config.txt		#~ файл с номерами и проверяемостью базовых станций
OBJ=(   $(cut -f 1 $kbs_cfg_file) )				#~ массив с номерами базовых станций
CHECK=( $(cut -f 2 $kbs_cfg_file) )				#~ массив с проверяемостью базовых станций

func_main() {	#~ основная функция
	#~ если переменные ks и GET равны, значит никаких переменных в GET не передавалось
	[[ $ks == $GET ]] || func_check_GET
	func_make_pause_html
	func_make_just_look_html
	func_make_bs_html
	func_make_site
	echo "Content-type: text/html; charset=utf-8"
	echo ""
	echo -e ${_SITE//
/\\n}
}


func_check_GET() {	#~ запускает функции на основе GET-запроса
	if echo "$GET" | grep -q "bs="; then
		func_change_bs "$GET"
		return 0
	fi

	case "$GET" in
		restart_g2    ) func_restart_g2    ;;	#~ перезапускает программу g2 в КБС
		reboot_KBS    ) func_reboot_KBS    ;;	#~ перезагружает систему в КБС
		reload_script ) func_reload_script ;;	#~ перезагружает программу контроля за КБС на сервере
		pause_on      ) func_pause_on      ;;	#~ ставит проверку КБС на паузу
		pause_off     ) func_pause_off     ;;	#~ снимает проверку КБС с паузы
		just_look_on  ) func_just_look_on  ;;	#~ ставит проверку КБС на невмешательство
		just_look_off ) func_just_look_off ;;	#~ снимает проверку КБС с режима невмешательства
	esac
}


func_change_bs() {	#~ меняет проверяемость БС и записывает обновления в конфиг
	local bs="$1"

	bs=${bs//"bs="/""}							#~ удаляет переменную "bs=" из строки
	bs_number=$( echo $bs | cut -f 1 -d "-" )	#~ определяем номер базы
	bs_check=$(  echo $bs | cut -f 2 -d "-" )	#~ определяем состояние do/not
	[[ $bs_check == "do" ]] && check="ПРОВЕРЯТЬ" || check="НЕ ПРОВЕРЯТЬ"
	for (( i = 0; i < ${#OBJ[@]}; i++ )); do
		[[ $bs_number == ${OBJ[$i]} ]] && CHECK[$i]=$bs_check
	done
	func_process_log "БС №$bs_number изменено на $check"
	echo -ne "" > $kbs_cfg_file		#~ очищает файл
	for (( i = 0; i < ${#OBJ[@]}; i++ )); do
		echo "${OBJ[$i]}	${CHECK[$i]}" >> $kbs_cfg_file
	done
}


func_restart_g2() {	#~ перезапускает программу g2
	sshpass -p ${password} ssh ${user_log}@$KBS_IP -p 22 'mro; killall /mnt/dom/dect/g2'
	func_process_log "С веб-интерфейса перезапущен g2"
}


func_reboot_KBS() {	#~ перезагружает операционную систему в КБС
	#~ true	#~ ТЕСТ: заглушка чтобы реально пока не перезагружать систему
	sshpass -p ${password} ssh ${user_log}@$KBS_IP -p 22 'mro; reboot'
	func_process_log "С веб-интерфейса перезагружен КБС"
}


func_reload_script() {	#~ перезагружает программу контроля за КБС на сервере
	touch $reload_file 		#~ создает файл в каталоге /tmp
}


func_pause_on() {	#~ ставит скрипт проверки КБС на паузу
	touch $pause_file		#~ создает файл в каталоге /tmp
}


func_pause_off() {	#~ снимает скрипт проверки КБС с паузы
	[ -e $pause_file ] && rm $pause_file		#~ удаляет файл из каталога /tmp
}


func_just_look_on() {	#~ ставит скрипт проверки КБС на режим невмешательства в КБС
	touch $just_look_file	#~ создает файл в каталоге /tmp
	func_process_log "Включен режим невмешательства"
}


func_just_look_off() {	#~ снимает скрипт проверки КБС с режима невмешательства
	rm $just_look_file	#~ удаляет файл в каталоге /tmp
	func_process_log "Снят с режима невмешательства"
}


func_process_log() {		#~ лог процессов в скрипте (для дебага и прочего)
	local log="$MY_DIR/process_log.txt"		#~ файл журнала процессов

	echo "$( date +%H:%M:%S ) - $1" >> $process_log
	file=$( cat $process_log )					#~ для укорачивания лога
	echo "$file" | tail -n 20 > $process_log	#~ укорачивает файл лога до 20 строк
}


func_make_bs_html() {	#~ создает кнопки с базовыми станциями
	for (( i = 0; i < ${#OBJ[@]}; i++ )); do
		if [[ ${CHECK[$i]} == "do" ]]; then
			bgcolor="green";   color="#90EE90"; action="отключить"; change_action="not"
		else
			bgcolor="#BFBFBF"; color="#4D4D4D"; action="включить";  change_action="do"
		fi
		BS_HTML=$BS_HTML"<input type=button style=background-color:$bgcolor;color:$color value='${OBJ[$i]}-${CHECK[$i]}' onclick=\"ConfirmAction('$action проверку БС ${OBJ[$i]}','bs=${OBJ[$i]}-$change_action')\">"
	done
}


func_make_pause_html() {	#~ создает кнопки паузы для веб-интерфейса
	if [ -e $pause_file ]; then
		symbol="запустить службу"; action="снять с паузы";          change_action="pause_off"
	else
		symbol="приостановить службу"; action="поставить на паузу"; change_action="pause_on"
	fi
	PAUSE_HTML=$PAUSE_HTML"<input type=button value='$symbol' onclick=\"ConfirmAction('$action', '$change_action')\" >"
}


func_make_just_look_html() {	#~ создает кнопки режима невмешательства для веб-интерфейса
	if [ -e $just_look_file ]; then
		symbol="Реагировать на ошибки КБС";
		action="установить режим вмешательства в КБС при ошибках";
		change_action="just_look_off"
	else
		symbol="Не реагировать на ошибки КБС";
		action="установить режим невмешательства в КБС при ошибках";
		change_action="just_look_on"
	fi
	JUST_LOOKING_HTML=$JUST_LOOKING_HTML"<input type=button value='$symbol' onclick=\"ConfirmAction('$action', '$change_action')\" >"
}


func_make_site() {	#~ собирает воедино html-код веб-страницы
_SITE="
<html><title>Управление КБС Гудвин ${KS}</title>
	<script>
		http_str_orig = location.protocol + '//' + location.host + '${SCRIPT_NAME}'
		http_str_real = location.href
		//document.write( http_str_orig + '<br>' + http_str_real + '<br><br>' )

		function ConfirmAction(action, url_command){
			isReload = confirm('Вы действительно хотите ' + action + '?');
			if (isReload == true) {
				location.href=http_str_orig + '?$ks&' + url_command
			}
		}
	</script>
<body leftmargin=0 rightmargin=0 topmargin=0 bottommargin=0 bgcolor=#4D4D4D text=white link=white vlink=white>
<center>
<b>$KS</b><br>
<table width=100% cellpadding=3 cellspacing=0 border=1><tr align=center>
<td>Управление фоновой службой</td>
<td>Контроль потоков БС</td>
<td>Ручное управление КБС</td>
</tr><tr align=center>
<td>$PAUSE_HTML<br>
<input type=button value='перезапустить службу' onclick=\"ConfirmAction('перезапустить фоновую службу контроля за КБС на сервере', 'reload_script')\">
</td><td>
$BS_HTML<br>
$JUST_LOOKING_HTML
</td><td>
<input type=button value='Перезапустить g2' onclick=\"ConfirmAction('Перезапустить g2','restart_g2')\"><br>
<input type=button value='Перезагрузить КБС' onclick=\"ConfirmAction('Перезагрузить КБС','reboot_KBS')\">
</td></tr></table>

<table width=100% cellpadding=3 cellspacing=0 border=1><tr align=center><td>
[ <a target=_new href=./process_log.bash?$ks>смотреть журнал процесса</a> ]<br>
<iframe src=./process_log.bash?$ks width=100% height=220 frameborder=no seamless></iframe></td><td>
[ <a target=_new href=./error_log.bash?$ks>смотреть журнал ошибок</a> | <a target=_new href=./kbs_log.bash?$ks>журнал КБС</a> ]<br>
<iframe src=./error_log.bash?$ks width=100% height=220 frameborder=no seamless></iframe>
</td></tr></table>
</center></body>
</html>"
}


func_main
exit 0

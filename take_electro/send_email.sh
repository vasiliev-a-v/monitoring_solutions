#!/bin/bash
#~ отправляет отчет по e-mail


source $(dirname $(readlink -e "$0"))/config.sh    #~ подключается файл с общим конфигом


#~ отправка отчета по e-mail утилитой mutt
mutt -s "Отчет за $date_rus" -e "set content_type=text/html" \
dispetcher1@mail.ru -b dispetcher2@mail.ru -b dispetcher3@mail.ru \
< "$daily_reports"/$(date +%Y-%m-%d)".htm"



exit 0

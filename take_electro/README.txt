Программа производит: 
take_electro.sh
- сбор показаний с оборудования Electro по SNMP
- загрузку их в базу данных
msite_electro.sh
- вывод показаний на веб-страницу
take_day.sh и gnuplot.sh
  - отображение графиков суточных трендов в виде картинок SVG
copy_hours.sh
  - сбор статичных данных по часам (здесь: 0, 3 и 6 часов)
report_temp
  - формирование отчёта (на 0, 3 и 6 часов)
send_email
  - отправка отчёта диспетчеру по e-mail
config.sh
  - общий конфигурационный файл для модулей bash-скриптов

- для отправки по e-mail используется агент mutt (при установке необходима его отдельная настройка)
- в коде и конфигах описано несуществующее оборудование Electro. Все данные необходимо установить под своё оборудование


#~ получение данных с Electro по N-скому участку
  * *  *   *   *     sleep 18 && nice -n 19 /home/user/take_elteco/take_day.sh       & #~ запрос температур и формирование графика
  * *  *   *   *     sleep 10 && nice -n 19 /home/user/take_elteco/take_elteco.sh    & #~ запрос данных по SNMP
  * *  *   *   *     sleep 23 && nice -n 19 /home/user/take_elteco/msite_elteco.sh   & #~ формирование веб-интерфейса

#~ Для осуществления параллельного сбора по другим участкам необходимо добавить строки с аргументом в конце
#~ обозначающим название другого участка
#~ Например участок: mskiy_uch_electro.
#~ На сервере Postgresql надо создать копию базы electro_temperature с именем mskiy_uch_electro

#~ получение данных с Electro по М-скому участку
  * *  *   *   *     sleep 38 && nice -n 19 /home/user/take_elteco/take_day.sh     mskiy_uch_electro  &
  * *  *   *   *     sleep 46 && nice -n 19 /home/user/take_elteco/take_elteco.sh  mskiy_uch_electro  &
  * *  *   *   *     sleep 52 && nice -n 19 /home/user/take_elteco/msite_elteco.sh mskiy_uch_electro  &

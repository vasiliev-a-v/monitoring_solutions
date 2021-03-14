#!/bin/bash

TMP_DIR="$2"

width="800"
high="600"
outfile="$TMP_DIR/$1.svg"
format="svg"
title="$1 Electro"
gnuplot << EOP
set terminal ${format} size ${width},${high}

#~ Указываем выходной файл
set output "${outfile}"

#~ set terminal postscript enhanced "DejaVu-Sans" 8
#~ set terminal postscript "DejaVu-Sans" eps enhanced color fontfile "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

#~ Рисуем заголовок
#~ set style fill transparent solid 0.5 noborder
set title "$1"
set key autotitle columnhead
set key outside center bottom
#~ set xlabel "Время"
#~ set ylabel "Температура"

set datafile separator "|"

set xdata time                     #выставляем, что данные по «X» это время
set timefmt "%Y-%m-%d %H:%M:%S"    #формат времени
#~ set timefmt "%H:%M:%S"          #формат времени
#~ set xtics 7200                  #шаг 1 час (60*60*2)
#~ set xtics format "%H:%M"        #на координате отображаем только значение часа (hour)
set format x "%H"

set grid
set yrange [0:*]      #~ диапазон по оси Y

#~ set style line номер-стиля lt тип lc rgb цвет lw толщина-линии

set style line 1 lt 1 lc rgb "#A52A2A" lw 1
set style line 2 lt 1 lc rgb "#1E90FF" lw 1

plot  "$TMP_DIR/$1.csv" using 1:3 title "температура Electro" with line linestyle 1, \
      "$TMP_DIR/$1.csv" using 1:2 title "температура АКБ"    with line linestyle 2       #~ smooth csplines linestyle 1

EOP
exit 0

#~ Рисуем график
gnuplot << EOP
#Указываем формат файла и его размер
set terminal ${format} size ${width},${high}

#Указываем выходной файл
set output ${outfile}


#Рисуем легенды
set key autotitle columnhead
set key outside center bottom
set key horizontal

#Рисуем заголовок
set style fill transparent solid 0.5 noborder
set title "${title}"

#Делаем ось Х в формате отображения дат
#~ set xdata time
#~ set timefmt "%H:%M:%S"
#~ set xrange ["${hour_ago}":"${now}"]
#~ set xtics format "%H:%M"

#Указываем имена осей
set xlabel "Время"
set ylabel "${title}"
set grid
set yrange [0:*]

plot "data.txt" using 1:2 title "First",\
     "data.txt" using 1:3 title "Second"

EOP

exit 0

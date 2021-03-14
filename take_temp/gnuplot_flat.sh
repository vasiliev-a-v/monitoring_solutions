#!/bin/bash


SCRIPT="$(readlink -e "$0")"                    #~ полный путь до файла скрипта
SCR_DIR=$(dirname $SCRIPT)
TMP_DIR="$2"

width="800"
high="600"
outfile="$TMP_DIR/$1.svg"
format="svg"
title="$1"
gnuplot << EOP
set terminal ${format} size ${width},${high}

#~ Указываем выходной файл
set output "${outfile}"

#~ Рисуем заголовок
set title "$1"
set key autotitle columnhead
set key outside center bottom

set datafile separator "|"

set xdata time                     #выставляем, что данные по «X» это время
set timefmt "%Y-%m-%d %H:%M:%S"    #формат времени
set format x "%H"

set grid
set yrange [0:*]      #~ диапазон по оси Y

set style line 1 lt 1 lc rgb "#A52A2A" lw 1
set style line 2 lt 1 lc rgb "#1E90FF" lw 1

plot "$TMP_DIR/$1.csv" using 1:2 title "температура $1" with line linestyle 2 #~ smooth csplines linestyle 1

EOP
exit 0

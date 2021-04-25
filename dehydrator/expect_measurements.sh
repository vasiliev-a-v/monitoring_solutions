#!/usr/bin/expect -f

set username [lindex $argv 0];
set password [lindex $argv 1];
set ip__addr [lindex $argv 2];
set com_port [lindex $argv 3];

spawn telnet -l $username $ip__addr
expect "Password:"  {
        send "$password\r"
}
expect "$username@" {
        send " TERM=xterm\r"
}
expect "$username@" {
        send " minicom $com_port\r"
}
log_user  1
expect "Нажмите CTRL-A Z для получения подсказки по клавишам" {
        sleep 0.1; send "ID\r"
}
expect "Hours*\r" {
        sleep 0.1; send "MEAS\r"
}
expect "humidity = *\r" {
        sleep 0.1; send "ALMGET\r";
}
expect "COMPR FAULT ALARM = *\r" {
        sleep 0.1; close
}
log_user  0

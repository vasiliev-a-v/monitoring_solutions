#!/usr/bin/expect -f

set username [lindex $argv 0];
set password [lindex $argv 1];
set ip__addr [lindex $argv 2];
set com_port [lindex $argv 3];

log_user  0
spawn telnet -l $username $ip__addr
expect "Password:"    {send "$password\r"}
expect "$username@"   {
  send "dmesg | grep 'FTDI USB Serial Device converter now attached'\r"
}
log_user  1
expect "ttyUSB*\r"       {close}
log_user  0

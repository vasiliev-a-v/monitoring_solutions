#!/usr/bin/expect -f

#~ модуль выключает и включает порт USB

set username [lindex $argv 0];
set password [lindex $argv 1];
set ip__addr [lindex $argv 2];
set com_port [lindex $argv 3];

#~ log_user  1
spawn telnet -l $username $ip__addr
expect "Password:"   { send "$password\r" }
expect "$username@"  {
  send "echo '1-1.5' | sudo tee /sys/bus/usb/drivers/usb/unbind\r"
}
expect "$username@"  {
  send "echo '1-1.5' | sudo tee /sys/bus/usb/drivers/usb/bind\r"
}
expect "$username@"  { sleep 0.5; close }
#~ log_user 0
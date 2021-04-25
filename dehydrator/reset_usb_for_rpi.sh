#!/bin/bash
#~ перезагружает USB-порт


for i in /sys/bus/pci/drivers/[uoex]hci_hcd/*:*; do
  echo "${i##*/}" > "${i%/*}/unbind"
  echo "${i##*/}" > "${i%/*}/bind"
done

exit 0
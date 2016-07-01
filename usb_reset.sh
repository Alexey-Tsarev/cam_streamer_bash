#!/bin/bash

USAGE="Usage:
$0 USB_DEVICE_NAME
or
$0 USB_BUS USB_DEV
See the lsusb output"

if [ -n "$1" ]; then
    DEVICE_NAME=$1

    if [ -n "$2" ]; then
        BUS=$1
        DEV=$2
        unset DEVICE_NAME
    fi

    if [ -n "$DEVICE_NAME" ]; then
        USB_LINE=`lsusb | grep "$DEVICE_NAME"`

        if [ -n "$USB_LINE" ]; then
            echo "Device found. USB line:"
            echo "$USB_LINE"

            USB_LINE_AR=(${USB_LINE})

            BUS=${USB_LINE_AR[1]}
            DEV=${USB_LINE_AR[3]}

            DEV=${DEV/:/}
        else
            echo "Device '$DEVICE_NAME' not found"
        fi
    fi

    if [ -n "$BUS" ] && [ -n "$DEV" ]; then
        usbreset /dev/bus/usb/*${BUS}/*${DEV} # Is it correct using * ?
    fi
else
    echo "$USAGE"
    echo
    echo "First parameter - device name - not provided. Exit..."

    exit 1
fi

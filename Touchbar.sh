#!/bin/bash

DRIVER_FROM="apple-ibridge-hid"
DRIVER_TO="apple-ib-touchbar"
VENDOR="05AC"
PRODUCT="8600"

echo "[INFO] searching iBridge HID..."

for dev in /sys/bus/hid/devices/0003:${VENDOR}:${PRODUCT}.*; do
    [ -e "$dev" ] || continue

    DEVICE_ID=$(basename "$dev")

    DRIVER=$(basename "$(readlink -f "$dev/driver")" 2>/dev/null)

    echo "[INFO] Trouvé $DEVICE_ID (driver actuel : $DRIVER)"

    if [ "$DRIVER" = "$DRIVER_TO" ]; then
        echo "    ↳ already binded to $DRIVER_TO"
        continue
    fi

    if [ -n "$DRIVER" ]; then
        echo "    ↳ Unbind of $DRIVER..."
        echo -n "$DEVICE_ID" | sudo tee /sys/bus/hid/drivers/$DRIVER/unbind
    fi

    echo "    ↳ Bind to $DRIVER_TO..."
    echo -n "$DEVICE_ID" | sudo tee /sys/bus/hid/drivers/$DRIVER_TO/bind
done

echo "[INFO] Final state /sys/class/leds/ :"
ls /sys/class/leds/

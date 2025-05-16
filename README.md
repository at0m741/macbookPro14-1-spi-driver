# Apple SPI Driver for MacBookPro14,1 (2017)

This project provides an input driver for the SPI keyboard, trackpad, Touch Bar, and ambient light sensor (ALS) found on 12" MacBooks (2015+) and MacBook Pros (Late 2016–Mid 2018). This document is a concise version tailored specifically for the **MacBookPro14,1 (2017)**.

---

## Kernel Compatibility

* The keyboard and trackpad are supported **natively in the kernel since v5.3** via the `applespi` module.
* For the Touch Bar and ALS, you must **manually load** the following modules:

  * `apple_ibridge`
  * `apple_ib_tb`
  * `apple_ib_als`

---

## Kernel Boot Parameters

Ensure that **you do not** have `noapic` in your kernel parameters.
For the MacBookPro14,1, no additional boot flags are needed.

---

## Required Kernel Modules

The following modules are required:

```
intel_lpss_pci
spi_pxa2xx_platform
applespi
apple_ibridge
apple_ib_tb
apple_ib_als
```

If some modules are missing, rebuild your kernel with:

```text
CONFIG_SPI_PXA2XX=m
CONFIG_MFD_INTEL_LPSS_PCI=m
```

---

## Initramfs Setup (Arch-based systems)

Edit `/etc/mkinitcpio.conf`:

```bash
MODULES=(intel_lpss_pci spi_pxa2xx_platform applespi apple_ibridge apple_ib_tb apple_ib_als)
```

Then regenerate the initramfs:

```bash
sudo mkinitcpio -P
```

---

## Module Loading and Behavior

Loading `apple_ib_tb` will automatically load `apple_ibridge` and `apple_ib_als`.

To load modules manually:

```bash
sudo modprobe intel_lpss_pci
sudo modprobe spi_pxa2xx_platform
sudo modprobe applespi
sudo modprobe apple_ibridge
sudo modprobe apple_ib_tb
sudo modprobe apple_ib_als
```

For best results, ensure all modules are loaded **before login**, especially for disk unlock prompt on encrypted setups.

---

## Touch Bar Binding (post-compilation)

After compiling and inserting the modules, the Touch Bar device may still be attached to the `apple-ibridge-hid` driver. You must unbind it and rebind it to `apple-ib-touchbar` manually.

1. Identify the Touch Bar HID device:

```bash
ls /sys/bus/hid/devices/ | grep 05AC:8600
```

2. Unbind the device from the default driver:

```bash
echo -n "0003:05AC:8600.000X" | sudo tee /sys/bus/hid/drivers/apple-ibridge-hid/unbind
```

3. Bind it to the custom touchbar driver:

```bash
echo -n "0003:05AC:8600.000X" | sudo tee /sys/bus/hid/drivers/apple-ib-touchbar/bind
```

Replace `000X` with the correct identifier seen in step 1.

4. Verify:

```bash
dmesg | grep apple_ib_tb
ls /sys/class/leds/
```

You should now see `apple-touchbar:bar` listed.

---

## Touch Bar Power Behavior

The Touch Bar will dim and then turn off after inactivity:

* Default `dim_timeout`: 270 seconds
* Default `idle_timeout`: 300 seconds

You can change these via sysfs (example path may vary):

```bash
echo 30 | sudo tee /sys/class/input/input9/device/dim_timeout
echo 60 | sudo tee /sys/class/input/input9/device/idle_timeout
```

You can also set parameters at module load time:

```bash
modprobe apple_ib_tb dim_timeout=30 idle_timeout=60
```

---

## Ambient Light Sensor (ALS)

If `iio-sensor-proxy` is installed, ALS should be recognized automatically.

```bash
sudo pacman -S iio-sensor-proxy
```

Then monitor:

```bash
monitor-sensor
```

---

## DKMS (Debian-based systems)

For Debian/Ubuntu systems (not Arch), use:

```bash
sudo apt install dkms
git clone https://github.com/roadrunner2/macbook12-spi-driver.git /usr/src/applespi-0.1
sudo dkms install -m applespi -v 0.1
```

Also add to `/etc/initramfs-tools/modules`:

```
applespi
spi_pxa2xx_platform
intel_lpss_pci
```

Then regenerate initramfs:

```bash
sudo update-initramfs -u
```

---

## Debugging

Enable packet tracing:

```bash
echo 1 | sudo tee /sys/kernel/debug/tracing/events/applespi/applespi_keyboard_data/enable
cat /sys/kernel/debug/tracing/trace
```

Check touchpad dimensions:

```bash
echo 1 | sudo tee /sys/kernel/debug/applespi/enable_tp_dim
watch cat /sys/kernel/debug/applespi/tp_dim
```

---

## Additional Notes

The original monolithic `appletb` module has been split into:

* `apple_ibridge`
* `apple_ib_tb`
* `apple_ib_als`

If you're migrating from `appletb`, remove it via:

```bash
sudo find /lib/modules/ -name appletb.ko | xargs rm
```

### SIMPLE USE

```bash
chmod +x Touchbar.sh && ./Touchbar.sh
```

---

## References

* [https://github.com/roadrunner2/macbook12-spi-driver](https://github.com/roadrunner2/macbook12-spi-driver)
* [https://bugzilla.kernel.org/show\_bug.cgi?id=108331](https://bugzilla.kernel.org/show_bug.cgi?id=108331)
* [https://bugzilla.kernel.org/show\_bug.cgi?id=99891](https://bugzilla.kernel.org/show_bug.cgi?id=99891)

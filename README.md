# rpi5 auto gadget mode
A simple script that automates the Gadget Mode setting on Raspberry Pi 5, Debian Bookworm


## Usage

1. Clone repository
```bash
   sudo apt install git -y
   git clone https://github.com/N0namenull/rpi5-auto-gadget-mode.git
```
2. Launch script
```bash
   cd rpi5-auto-gadget-mode/
   sudo chmod +x setup-usbgadget.sh
   sudo ./setup-usbgadget.sh

```


## Warning
For some reason, Raspberry Pi refuses to work at it's own IP address (10.55.0.1), use instead **``yourrpiname.local``** for example: 
``raspberrypi.local``

Example for ssh:
```bash
   ssh raspberry@raspberrypi.local
```

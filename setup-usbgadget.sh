#!/bin/bash
set -e

echo "[*] Updating config.txt..."
echo "dtoverlay=dwc2" >> /boot/firmware/config.txt

echo "[*] Updating cmdline.txt..."
sed -i 's/$/ modules-load=dwc2/' /boot/firmware/cmdline.txt

echo "[*] Updating /etc/modules..."
echo "libcomposite" >> /etc/modules

echo "[*] Creating usb-gadget.sh..."
cat > /usr/local/sbin/usb-gadget.sh << 'EOF'
#!/bin/bash
cd /sys/kernel/config/usb_gadget/
mkdir -p display-pi
cd display-pi

echo 0x1d6b > idVendor
echo 0x0104 > idProduct
echo 0x0103 > bcdDevice
echo 0x0320 > bcdUSB
echo 2 > bDeviceClass

mkdir -p strings/0x409
echo "fedcba9876543213" > strings/0x409/serialnumber
echo "Ben Hardill" > strings/0x409/manufacturer
echo "Display-Pi USB Device" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "CDC" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower
echo 0x80 > configs/c.1/bmAttributes

# ECM
mkdir -p functions/ecm.usb0
HOST="00:dc:c8:f7:75:15"
SELF="00:dd:dc:eb:6d:a1"
echo $HOST > functions/ecm.usb0/host_addr
echo $SELF > functions/ecm.usb0/dev_addr
ln -s functions/ecm.usb0 configs/c.1/

# RNDIS
mkdir -p configs/c.2
echo 0x80 > configs/c.2/bmAttributes
echo 0x250 > configs/c.2/MaxPower
mkdir -p configs/c.2/strings/0x409
echo "RNDIS" > configs/c.2/strings/0x409/configuration

echo "1" > os_desc/use
echo "0xcd" > os_desc/b_vendor_code
echo "MSFT100" > os_desc/qw_sign

mkdir -p functions/rndis.usb0
HOST_R="00:dc:c8:f7:75:16"
SELF_R="00:dd:dc:eb:6d:a2"
echo $HOST_R > functions/rndis.usb0/dev_addr
echo $SELF_R > functions/rndis.usb0/host_addr
echo "RNDIS" > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
echo "5162001" > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

ln -s functions/rndis.usb0 configs/c.2
ln -s configs/c.2 os_desc

udevadm settle -t 5 || :
ls /sys/class/udc > UDC

sleep 5

nmcli connection up bridge-br0
nmcli connection up bridge-slave-usb0
nmcli connection up bridge-slave-usb1
sleep 5
service dnsmasq restart
EOF

chmod +x /usr/local/sbin/usb-gadget.sh

echo "[*] Creating systemd service..."
cat > /lib/systemd/system/usbgadget.service << 'EOF'
[Unit]
Description=My USB gadget
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/usb-gadget.sh

[Install]
WantedBy=sysinit.target
EOF

systemctl enable usbgadget.service

echo "[*] Creating network bridge..."
nmcli con add type bridge ifname br0
nmcli con add type bridge-slave ifname usb0 master br0
nmcli con add type bridge-slave ifname usb1 master br0
nmcli connection modify bridge-br0 ipv4.method manual ipv4.addresses 10.55.0.1/24

echo "[*] Installing dnsmasq..."
apt update
apt install -y dnsmasq

echo "[*] Configuring dnsmasq..."
mkdir -p /etc/dnsmasq.d
cat > /etc/dnsmasq.d/br0 << 'EOF'
dhcp-authoritative
dhcp-rapid-commit
no-ping
interface=br0
dhcp-range=10.55.0.2,10.55.0.6,255.255.255.248,1h
dhcp-option=3
leasefile-ro
EOF

echo "[✓] Setup complete. Reboot your system."

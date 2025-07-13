#!/bin/bash
# author: viliam batka
echo "Setting up DNS for WSL..."
sudo cp /etc/resolv.conf /etc/resolv.conf.bak
echo -e "[network]\ngenerateResolvConf = false" | sudo tee /etc/wsl.conf > /dev/null
sudo rm -f /etc/resolv.conf

# Get DNS servers from --dns or use fallback
if [ "$1" == "--dns" ] && [ -n "$2" ]; then
    dns_servers="$2,8.8.8.8,1.1.1.1"
else
    dns_servers="8.8.8.8,1.1.1.1"
fi

# Write each DNS server to /etc/resolv.conf
for i in $(echo $dns_servers | tr ',' ' '); do
    echo "nameserver $i" | sudo tee -a /etc/resolv.conf
done

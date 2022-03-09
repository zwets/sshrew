

## Server side

sudo adduser --system --shell /bin/sh --home /usr/local/lib/eety --gecos "Eety Server" eety

sudo mkdir /var/lib/eety/.ssh
chmod 0700 /var/lib/eety/.ssh

ssh-genkey -t id25519 ....



## Client (roaming) side

Make sure the client doesn't power down the WiFi.

    # /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf`
    wifi.powersave = 2

Edit the `eety.service` and `ssh.conf` files, replacing

* `{SERVER_HOST}`: the public name of the remote SSH server
* `{SERVER_PORT}`: the port the remote SSH is listening on (normally `22`)
* `{MIRROR_PORT}`: the forwarding port to open on the server (any above 1024)
* `{LOCAL_HOST}`: the local host which will be forwarded (usually `localhost`)
* `{LOCAL_PORT}`: the port on the local host to be forwarded (normally `22`) 

Install the eety files in `/usr/local/lib/eety`

    sudo install -d /usr/local/lib/eety
    sudo install -t /usr/local/lib/eety client/*

Generate the SSH key

    sudo install -m 0750 -d /usr/local/lib/eety/keys
    sudo ssh-keygen -C eety@$(hostname -s) -t ed25519 -f /usr/local/lib/eety/keys/id25519 -N ''


Install the 
sudo install -d /usr/local/lib/systemd/system &&
sudo install -t /usr/local/lib/systemd/system eety.service &&
sudo systemctl daemon-reload

sudo systemctl enable eety.service
sudo systemctl start eety.service

mkdir /usr/local/lib/eety
chmod 0750 /usr/local/lib/eety

mkdir /var/local/eety
chmod 0750 /var/local/eety


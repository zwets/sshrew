## eety - SSH to roaming machine

The core of `eety` is `ssh -R`, doing a remote forward initiated from 
a roaming client to a remote server.  Once the session runs, the client
can be ssh'd to from the server.


### Server side

Create the eety user and restrict its home

    sudo adduser --system --shell /bin/sh --home /var/lib/eety --gecos "Eety Server" eety
    sudo -u eety chmod 0750 /var/lib/eety

Set up SSH login with the client's public key (see above)

    sudo -u eety mkdir /var/lib/eety/.ssh
    sudo -u eety chmod 0700 /var/lib/eety/.ssh
    sudo -u eety touch /var/lib/eety/.ssh/authorized_keys
    sudo -u eety chmod 0600 /var/lib/eety/.ssh/authorized_keys

### Client (roaming) side

Make sure the client doesn't power down the WiFi.

    # /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf
    wifi.powersave = 2

Edit the `client/ssh.conf` file, replacing

 * `{SERVER_HOST}`: the public name of the remote SSH server
 * `{SERVER_PORT}`: the port the remote SSH is listening on (normally `22`)
 * `{MIRROR_PORT}`: the forwarding port to open on the server (any above 1024)
 * `{LOCAL_HOST}`: the local host which will be forwarded (usually `localhost`)
 * `{LOCAL_PORT}`: the port on the local host to be forwarded (normally `22`) 

Install the eety client files in `/usr/local/lib/eety`

    sudo install -d /usr/local/lib/eety
    sudo install -m 644 -t /usr/local/lib/eety client/eety.service
    sudo install -m 640 -t /usr/local/lib/eety client/ssh.conf

Generate the SSH key for server login

    sudo install -m 0700 -d /usr/local/lib/eety/keys
    sudo ssh-keygen -C eety@$(hostname -s) -t ed25519 -f /usr/local/lib/eety/keys/id_eety -N ''

Echo the public key so you can copy it on the server (see below)

    sudo cat /usr/local/lib/eety/keys/id_eety.pub

### Server side 

Append the public key to the eety user's authorised keys:

    echo "PUT THE KEY HERE" |
    sudo -u eety tee -a /var/lib/eety/.ssh/authorized_keys

### Client side

Once the above is done, we test access from the client.

    sudo ssh -F /usr/local/lib/eety/ssh.conf remotehost

This should give `sh: 1: /var/lib/eety/eety-home.sh: not found`,
which is good.  We now `scp` that script to the server:

    sudo scp -F /usr/local/lib/eety/ssh.conf server/eety-home.sh remotehost:

Now install and enable the service.

    sudo install -d /usr/local/lib/systemd/system
    sudo install -t /usr/local/lib/systemd/system -m 0644 client/eety.service
    sudo systemctl daemon-reload

    sudo systemctl enable eety.service
    sudo systemctl start eety.service

### Server Side

You should now on the server see a file `/var/lib/eety/connect.log`.
It shows the latest connections from the client(s), and the local port
they 'mirroring' on.

To now login to the client, do

    ssh -p {MIRROR_PORT} 127.0.0.1   # it is on the localhost

And this should give you the login on the roaming client.



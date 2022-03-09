# sshrew - Simple reverse SSH

The code in this repository is a simple solution to the problem _how do I
ssh to a roaming machine, without dynamic DNS or port forwarding?_

The core of the solution is to do a remote forward initiated from the
roaming client to a known server (under your control).  Once the session
runs, the client can then be ssh'd from the server.

This works regardless of how the client is connected to the internet,
as long as it can ssh out to your server.

### Server side

Create the sshrew user and restrict its home

    sudo adduser --system --shell /bin/sh --home /var/lib/sshrew --gecos "SSH Reverse Server" sshrew
    sudo -u sshrew chmod 0750 /var/lib/sshrew

Set up SSH login with the client's public key (see above)

    sudo -u sshrew mkdir /var/lib/sshrew/.ssh
    sudo -u sshrew chmod 0700 /var/lib/sshrew/.ssh
    sudo -u sshrew touch /var/lib/sshrew/.ssh/authorized_keys
    sudo -u sshrew chmod 0600 /var/lib/sshrew/.ssh/authorized_keys

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

Install the sshrew client files in `/usr/local/lib/sshrew`

    sudo install -d /usr/local/lib/sshrew
    sudo install -m 644 -t /usr/local/lib/sshrew client/sshrew.service
    sudo install -m 640 -t /usr/local/lib/sshrew client/ssh.conf

Generate the SSH key for server login

    sudo install -m 0700 -d /usr/local/lib/sshrew/keys
    sudo ssh-keygen -C sshrew@$(hostname -s) -t ed25519 -f /usr/local/lib/sshrew/keys/id_sshrew -N ''

Echo the public key so you can copy it on the server (see below)

    sudo cat /usr/local/lib/sshrew/keys/id_sshrew.pub

### Server side 

Append the public key to the sshrew user's authorised keys:

    echo "PUT THE KEY HERE" |
    sudo -u sshrew tee -a /var/lib/sshrew/.ssh/authorized_keys

### Client side

Once the above is done, we test access from the client.

    sudo ssh -F /usr/local/lib/sshrew/ssh.conf remotehost

This should give `sh: 1: /var/lib/sshrew/sshrew-home.sh: not found`,
which is good.  We now `scp` that script to the server:

    sudo scp -F /usr/local/lib/sshrew/ssh.conf server/sshrew-home.sh remotehost:

Now install and enable the service.

    sudo install -d /usr/local/lib/systemd/system
    sudo install -t /usr/local/lib/systemd/system -m 0644 client/sshrew.service
    sudo systemctl daemon-reload

    sudo systemctl enable sshrew.service
    sudo systemctl start sshrew.service

### Server Side

You should now on the server see a file `/var/lib/sshrew/connect.log`.
It shows the latest connections from the client(s), and the local port
they 'mirroring' on.

To now login to the client, do

    ssh -p {MIRROR_PORT} 127.0.0.1   # it is on the localhost

And this should give you the login on the roaming client.



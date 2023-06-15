# sshrew - Simple reverse SSH

The code in this repository is a simple solution to the problem _how do I
ssh to a roaming machine, without dynamic DNS or port forwarding?_

The core of the solution is to do a remote forward initiated from the
roaming client to an SSH server under your control.  Once the session
runs, the client can then be ssh'd from the server.

This works regardless of how the client is connected to the internet,
as long as it can ssh out to your server.

## Steps

### Client (roaming) side

(Optional) make sure the client doesn't power down the WiFi.

    # /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf
    wifi.powersave = 2

Edit the `client/ssh.conf` file, replacing

 * `{SERVER_HOST}`: the public name of the remote SSH server
 * `{SERVER_PORT}`: the public port the remote SSH is listening on (normally `22`)
 * `{MIRROR_PORT}`: the forwarding port to open locally on the server (any free port above 1024)
 * `{LOCAL_HOST}`: the roaming host which will be forwarded to (usually `localhost`)
 * `{LOCAL_PORT}`: the port on `LOCAL_HOST` to be forwarded to (normally `22`) 

Install the sshrew client files in `/usr/local/lib/sshrew`

    sudo install -d /usr/local/lib/sshrew &&
    sudo install -m 0640 -t /usr/local/lib/sshrew client/ssh.conf

Generate the SSH key for server login

    sudo install -m 0700 -d /usr/local/lib/sshrew/keys &&
    sudo ssh-keygen -C sshrew@$(hostname -s) -t ed25519 -f /usr/local/lib/sshrew/keys/id_sshrew -N ''

Echo the public key so you can copy it on the server (see below)

    sudo cat /usr/local/lib/sshrew/keys/id_sshrew.pub

### Server side (one time)

Create the sshrew user and (optionally) restrict its home

    sudo adduser --system --shell /bin/sh --home /var/lib/sshrew --gecos "SSH Reverse Server" sshrew
    # optional: 
    sudo -u sshrew chmod 0750 /var/lib/sshrew

Set up its authorized keys file with appropriate permissions

    sudo install -o sshrew -m 0700 -d /var/lib/sshrew/.ssh
    sudo -u sshrew touch /var/lib/sshrew/.ssh/authorized_keys
    sudo -u sshrew chmod 0600 /var/lib/sshrew/.ssh/authorized_keys

Copy the entrypoint script to its home

    sudo install -m 0755 -t /var/lib/sshrew server/entrypoint.sh

### Server side (for every client)

Authorise the client while restricting it to do only what it is supposed
to do.

    # Replace the {...} placeholders by the values set/obtained above
    M="{MIRROR_PORT}"
    C="{CLIENT_NAME}"
    K="{FULL_PUBLIC_KEY_LINE_FROM_CLIENT}"

    printf 'restrict,port-forwarding,permitlisten="localhost:%d",permitopen="localhost:%d",command="exec /var/lib/sshrew/entrypoint.sh %s %d" %s\n' \
       $M $M "$C" $M "$K" | sudo -u sshrew tee -a /var/lib/sshrew/.ssh/authorized_keys
       
### Client side

Test the connection:

    sudo ssh -TF /usr/local/lib/sshrew/ssh.conf remotehost

This command should not return.  At the server side a _{CLIENT} listening_
line should appear in `/var/lib/sshrew/connection.log`, as well as a file
`{CLIENT}.port` containing the listening port number.

Disconnect the session at the client side by pressing `Ctrl-C`.  Within 30s
a line _{CLIENT} exiting_ should appear in the `connect.log`.

If this did not happen, retrace your steps until this works.

Finally, install and enable the `sshrew` service on the client.  This service
will keep the connection running:

    sudo install -d /usr/local/lib/systemd/system &&
    sudo install -t /usr/local/lib/systemd/system -m 0644 client/sshrew.service &&
    sudo systemctl daemon-reload &&
    sudo systemctl enable sshrew.service &&
    sudo systemctl start sshrew.service

### Server Side

To login to any client, look up its port in `/var/lib/sshrew/{CLIENT}.port`,
and ssh to it:

    ssh -p $(cat {CLIENT}.port) 127.0.0.1

And this should give you a login prompt on the roaming client.

To save yourself from having to pass the `-p ...` option, you could add a
stanza to your `~/.ssh/config` on the server:

    Host {CLIENT_NAME}
        Hostname localhost
        Port {MIRROR_PORT}

With this in place, you can simply `ssh {CLIENT_NAME}`.


# Testing with the test URL

This setup allows to publish the DEV site

## Setup instructions

https://caddyserver.com/
https://github.com/fatedier/frp#enable-https-for-local-http-service

### 1. FRPC configuration file

```bash
cp frpc.ini.sample frpc.ini
```

Fill out the `token` and `server_addr` fields.

### 2. FRPS configuration file

```bash
scp frps.ini.sample you@your-server.io:/somewhere/you/want/frps.ini
```

Fill out the `token` field with the same value as in `frpc.ini`.

Make sure that the ports you expose are open in your firewall. If you are using
`ufw`, it should look something like this:

```bash
sudo ufw allow 7780
```

### 3. Download and run

Download FRP on the [GitHub project], or better using your distribution packages.

[GitHub]: https://github.com/fatedier/frp

Then, simply run:
```bash
# On the server
frps -c ./frps.ini

# On the client
frpc -c ./frpc.ini
```

### 4. Download and run Caddy

Install or download caddy, using your package manager or from the official
website:

```bash
wget 'https://caddyserver.com/api/download?os=linux&arch=amd64' -O caddy
chmod +x caddy
./caddy version

# To allow Caddy to bind to the HTTPS port without running it as root
sudo setcap cap_net_bind_service=ep ./caddy
```

Then, simply run it with the following command (no need for a config file):

```bash
/path/to/caddy reverse-proxy --from dev.pixel-forum.busy.ovh --to localhost:7780
```

# YR Proxy

## Build (local dev)

```bash
go build -o yrproxy
YRPROXY_PORT=8080 YRPROXY_API_KEY=... ./yrproxy
```

## Deploy (roybot.se)

```bash
cd /root/clawd/projects/Undertow/proxy
git pull
systemctl stop yrproxy
go build -o /usr/local/bin/yrproxy .
systemctl start yrproxy
```

Se også: `/var/www/yrproxy.roybot.se/README.md`

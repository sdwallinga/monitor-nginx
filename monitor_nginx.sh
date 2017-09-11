#!/bin/bash

cat << 'EOF' > /etc/zabbix/zabbix_agentd.d/userparameter_nginx.conf
UserParameter=nginx.status[*],/srv/zabbix/libexec/nginx.sh $1
EOF

cat << 'EOF' >> /etc/nginx/conf.d/stats.conf
server {
    listen 10061;
    location /nginx_status {
      stub_status on;
      access_log off;
      allow 127.0.0.1;
      deny all;
    }
}
EOF

mkdir -p /srv/zabbix/libexec
cat << 'EOF' > /srv/zabbix/libexec/nginx.sh
#!/bin/bash
##################################################
# AUTHOR: Neo <netkiller@msn.com>
# WEBSITE: http://www.netkiller.cn
# Description：zabbix 通过 status 模块监控 nginx
# Note：Zabbix 3.2
# DateTime: 2016-11-22
# Modified by Sam Wallinga <sam@5thcolumn.net>
##################################################

HOST="localhost"
PORT="10061"
stub_status=nginx_status

function check() {
    if [ -f /sbin/pidof ]; then
       /sbin/pidof nginx | wc -w
    else
       ps ax | grep "nginx:" | grep -v grep | wc -l
    fi
}

function active() {
    /usr/bin/curl -s "http://$HOST:$PORT/${stub_status}/" 2>/dev/null| grep 'Active' | awk '{print $NF}'
}
function accepts() { 
    /usr/bin/curl -s "http://$HOST:$PORT/${stub_status}/" 2>/dev/null| awk NR==3 | awk '{print $1}'
}
function handled() { 
    /usr/bin/curl -s "http://$HOST:$PORT/${stub_status}/" 2>/dev/null| awk NR==3 | awk '{print $2}'
}
function requests() {
    /usr/bin/curl -s "http://$HOST:$PORT/${stub_status}/" 2>/dev/null| awk NR==3 | awk '{print $3}'
}
function reading() { 
    /usr/bin/curl -s "http://$HOST:$PORT/${stub_status}/" 2>/dev/null| grep 'Reading' | awk '{print $2}'
}
function writing() { 
    /usr/bin/curl -s "http://$HOST:$PORT/${stub_status}/" 2>/dev/null| grep 'Writing' | awk '{print $4}'
}
function waiting() { 
    /usr/bin/curl -s "http://$HOST:$PORT/${stub_status}/" 2>/dev/null| grep 'Waiting' | awk '{print $6}'
}

case "$1" in
    check)
        check
        ;;
    active)
        active
        ;;
    accepts)
        accepts
        ;;
    handled)
        handled
        ;;
    requests)
        requests
        ;;
    reading)
        reading
        ;;
    writing)
        writing
        ;;
    waiting)
        waiting
        ;;

    *)
        echo $"Usage $0 {check|active|accepts|handled|requests|reading|writing|waiting}"
        exit        
esac
EOF

chmod +x /srv/zabbix/libexec/nginx.sh
systemctl restart zabbix-agent

#!/bin/bash
set -eo pipefail
rm -rf /mha4mysql-*
replace_vars() {
  eval "cat <<EOF
  $(<$2)
EOF
  " > $1
}
replace_vars '/etc/keepalived/keepalived.conf' '/etc/keepalived/10_keepalived.conf'
replace_vars '/etc/keepalived/notify.sh' '/etc/keepalived/10_notify.sh'
replace_vars '/etc/keepalived/health.sh' '/etc/keepalived/10_health.sh'
chmod +x /etc/keepalived/notify.sh /etc/keepalived/health.sh

if [ "$ENABLE_LB" = "true" ]; then
{
for i in $REAL_PORTS
do
cat << EOF >> /etc/keepalived/keepalived.conf
  virtual_server $VIRTUAL_IP_LB $i {
  delay_loop 15
  lb_algo $LB_ALGO
  lb_kind $LB_KIND
  persistence_timeout 50
  protocol TCP
  ha_suspend  
EOF

for j in $REAL_IP
do
cat << EOF >> /etc/keepalived/keepalived.conf
  real_server $j $i {
    TCP_CHECK {
      connect_timeout 3
    }
  }
EOF
done
echo "}" >> /etc/keepalived/keepalived.conf
done
}
fi

# Run
sed -i '/Port/ s/22/40022/' /etc/ssh/sshd_config
sed -i "s/192.168.59.150/$VIRTUAL_IP/" /usr/local/mha/master_ip_failover
/etc/init.d/ssh start
/etc/init.d/keepalived start
if [ ! -z "$MYSQL_ROOT_PASSWORD" ];then
   mysqld `bash /entrypoint.sh` &
fi
if [ ! -z "$SERVER1_IP" ];then
   sed -i "19 s/192.168.59.103/$SERVER1_IP/" /etc/mha.conf  
   sed -i "24 s/192.168.59.111/$SERVER2_IP/" /etc/mha.conf  
   sed -i "30 s/192.168.59.111/$SERVER3_IP/" /etc/mha.conf  
fi
if [ ! -z "$SERVER1_SQL_PORT" ];then
   sed -i "20 s/3306/$SERVER1_SQL_PORT/" /etc/mha.conf
fi
if [ ! -z "$SERVER2_SQL_PORT" ];then
   sed -i "26 s/3306/$SERVER2_SQL_PORT/" /etc/mha.conf
fi
if [ ! -z "$SERVER3_SQL_PORT" ];then
   sed -i "31 s/3306/$SERVER3_SQL_PORT/" /etc/mha.conf
fi

tail -f /var/log/mysql/error.log
exec "$@"

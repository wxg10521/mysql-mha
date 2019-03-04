FROM mysql:5.7.15 
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates openssh-server keepalived libdbd-mysql-perl  libconfig-tiny-perl  liblog-dispatch-perl  libparallel-forkmanager-perl make && rm -rf /var/lib/apt/lists/*
ADD mha4mysql-manager-0.57.tar.gz /
ADD mha4mysql-node-0.57.tar.gz /
RUN cd /mha4mysql-manager-0.57 \
    && perl Makefile.PL \
    && make \
    && make install \
    && cd /mha4mysql-node-0.57 \
    && perl Makefile.PL \
    && make \
    && make install
COPY keepalived /etc/keepalived/
COPY master_ip_failover /usr/local/mha/
COPY mha.conf /etc/
COPY .ssh /root/.ssh
COPY start.sh /start.sh
ENTRYPOINT ["/start.sh"]

EXPOSE 3306  
CMD ["mysqld"]

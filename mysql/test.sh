#!/bin/bash
function replace_vars() {
  eval "cat <<EOF
  $(<$2)
EOF
  " > $1
}

replace_vars '/etc/keepalived/keepalived.conf' '/etc/keepalived/10_keepalived.conf'

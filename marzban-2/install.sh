#!/bin/sh
#
# metadata_begin
# recipe: Marzban
# tags: debian12
# revision: 1
# description_ru: Рецепт установки Marzban (данные находятся в /root/marzban.txt)
# description_en: Marzban installation recipe (data can be found in /root/marzban.txt)
# metadata_end
#

RNAME="Marzban"

set -x

LOG_PIPE=/tmp/log.pipe.$$                                                                                                                                                                                                                    
mkfifo ${LOG_PIPE}
LOG_FILE=/root/${RNAME}.log
touch ${LOG_FILE}
chmod 600 ${LOG_FILE}

tee < ${LOG_PIPE} ${LOG_FILE} &

exec > ${LOG_PIPE}
exec 2> ${LOG_PIPE}

killjobs() {
	jops="$(jobs -p)"
	test -n "${jops}" && kill ${jops} || :
}
trap killjobs INT TERM EXIT

echo
echo "=== Recipe ${RNAME} started at $(date) ==="
echo

apt update -y
apt install tmux curl nginx -y

serverip="($IP)"
password="($PASS)"
# *TODO: Reality TLS Scanner*
sni="yandex.ru"

export HOME=/root
cd /root

tmux new -d -s "marzban"
sleep 2
tmux send-keys -t "marzban" 'bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install > /tmp/marzban_log.txt' Enter
while sleep 5; do cat /tmp/marzban_log.txt | grep -q "Press CTRL+C" && echo true && rm -f /tmp/marzban_log.txt && tmux kill-session -t "marzban" && break || echo false; done

tmux new -d -s "marzban2"
sleep 3
tmux send-keys -t "marzban2" "marzban cli admin create --sudo" Enter
sleep 5
tmux send-keys -t "marzban2" "admin" Enter
sleep 3
tmux send-keys -t "marzban2" "$password" Enter
sleep 3
tmux send-keys -t "marzban2" "$password" Enter
sleep 1
tmux send-keys -t "marzban2" Enter
sleep 1
tmux send-keys -t "marzban2" Enter
sleep 3
tmux kill-session -t "marzban2"

wget https://raw.githubusercontent.com/netshield-uk/vm6-repo/refs/heads/main/marzban-2/nginx.conf -O /etc/nginx/nginx.conf
sed -i "s|<(REPLACE_IP_V4)>|$serverip|g" /etc/nginx/nginx.conf
service nginx restart

privatekey=$(docker exec marzban-marzban-1 xray x25519 | grep 'Private key' | awk '{print $3}')
shortids=$(openssl rand -hex 8)

wget https://raw.githubusercontent.com/netshield-uk/vm6-repo/refs/heads/main/marzban-2/xray_config.json -O /var/lib/marzban/xray_config.json

sed -i "s|<(REPLACE_LISTEN_IP)>|$serverip|g" /var/lib/marzban/xray_config.json
sed -i "s|<(REPLACE_SNI)>|$sni|g" /var/lib/marzban/xray_config.json
sed -i "s|<(REPLACE_PRIVATE_KEY)>|$privatekey|g" /var/lib/marzban/xray_config.json
sed -i "s|<(REPLACE_SHORT_IDS)>|$shortids|g" /var/lib/marzban/xray_config.json

tmux new -d -s "marzban3"
sleep 2
tmux send-keys -t "marzban3" 'marzban restart > /tmp/marzban_log.txt' Enter
while sleep 5; do cat /tmp/marzban_log.txt | grep -q "Press CTRL+C" && echo true && rm -f /tmp/marzban_log.txt && tmux kill-session -t "marzban3" && break || echo false; done

echo "Install done!"
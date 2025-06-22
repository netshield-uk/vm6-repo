#!/bin/bash

#
# metadata_begin
# recipe: 3X-UI
# tags: debian11,debian12,ubuntu2204,ubuntu2404
# revision: 1
# description_ru: 3X-UI Рецепт установки (доступы от панели управления находятся в /root/3x-ui.txt)
# description_en: 3X-UI installation recipe (control panel accesses are in /root/3x-ui.txt)
# metadata_end
#

RNAME="3x-ui"

set -x

LOG_PIPE=/tmp/log.pipe.$$                                                                                                                                                                                                                    
mkfifo ${LOG_PIPE}
LOG_FILE=/tmp/${RNAME}_command.log
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
apt install curl -y

tmux new -d -s "3xui_install"

tmux send-keys -t "3xui_install" "bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) | tee -a /tmp/3x-ui_install.log" Enter
sleep 3
tmux send-keys -t "3xui_install" "y" Enter
sleep 1
tmux send-keys -t "3xui_install" "9836" Enter

while ! grep -q "x-ui v2.6.0 installation finished, it is running now..." "/tmp/3x-ui_install.log"; do
  sleep 2
done

tmux kill-session -t "3xui_install"

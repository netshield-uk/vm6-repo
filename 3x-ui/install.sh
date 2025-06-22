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
apt install wget -y

wget https://raw.githubusercontent.com/netshield-uk/vm6-repo/refs/heads/main/3x-ui/main.sh -O /tmp/main.sh
bash /tmp/main.sh
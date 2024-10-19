apt update -y
sudo systemctl daemon-reexec
apt install sudo curl tmux nginx python3 python3-pip -y
pip install marzpy --upgrade --break-system-packages

export HOME=/root

serverip="178.250.191.208"
password="gP8xM6hD8qqC"

cd /root

tmux new -d -s "marzban"
sleep 2
tmux send-keys -t "marzban" 'sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install > /tmp/marzban_log.txt' Enter
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

wget https://raw.githubusercontent.com/netshield-uk/vm6-repo/refs/heads/main/marzban/nginx.conf -O /etc/nginx/nginx.conf
service nginx restart

privatekey=$(docker exec marzban-marzban-1 xray x25519 | grep 'Private key' | awk '{print $3}')
openssl_hex=$(openssl rand -hex 8)

wget https://raw.githubusercontent.com/netshield-uk/vm6-repo/refs/heads/main/marzban/marzban-config.py -O /tmp/marzban-config.py
python3 /tmp/marzban-config.py --password $password --privatekey $privatekey --openssl_hex $openssl_hex
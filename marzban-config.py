from marzpy import Marzban
import asyncio
import argparse

async def main():
    parser = argparse.ArgumentParser(description='My example explanation')
    parser.add_argument(
        '--password',
        type=str,
        default=''
    )
    parser.add_argument(
        '--privatekey',
        type=str,
        default=''
    )
    parser.add_argument(
        '--openssl_hex',
        type=str,
        default=''
    )

    my_namespace = parser.parse_args()

    # Если хотя бы один из аргументов пустой, завершаем выполнение
    if not my_namespace.password or not my_namespace.privatekey or not my_namespace.openssl_hex:
        exit(0)

    print(my_namespace.password)

    panel = Marzban("admin", my_namespace.password, "http://127.0.0.1:8000")
    token = await panel.get_token()
    print(token)

    new_config = {
        "log": {
            "loglevel": "warning"
        },
        "routing": {
            "rules": [
                {
                    "ip": ["geoip:private"],
                    "outboundTag": "BLOCK",
                    "type": "field"
                }
            ]
        },
        "inbounds": [
            {
                "tag": "Shadowsocks TCP",
                "listen": "0.0.0.0",
                "port": 1080,
                "protocol": "shadowsocks",
                "settings": {
                    "clients": [],
                    "network": "tcp,udp"
                }
            },
            {
                "tag": "VLESS TCP REALITY",
                "listen": "0.0.0.0",
                "port": 443,
                "protocol": "vless",
                "settings": {
                    "clients": [],
                    "decryption": "none"
                },
                "streamSettings": {
                    "network": "tcp",
                    "tcpSettings": {},
                    "security": "reality",
                    "realitySettings": {
                        "show": False,
                        "dest": "cloudflare.com:443",
                        "xver": 0,
                        "serverNames": ["cloudflare.com"],
                        "privateKey": my_namespace.privatekey,
                        "shortIds": [my_namespace.openssl_hex]
                    }
                },
                "sniffing": {
                    "enabled": True,
                    "destOverride": ["http", "tls", "quic"]
                }
            },
            {
                "tag": "VMESS + TCP",
                "listen": "0.0.0.0",
                "port": 2053,
                "protocol": "vmess",
                "settings": {
                    "clients": []
                },
                "streamSettings": {
                    "network": "tcp",
                    "tcpSettings": {},
                    "security": "none"
                },
                "sniffing": {
                    "enabled": True,
                    "destOverride": [
                    "http",
                    "tls"
                    ]
                }
            },
            {
                "tag": "TROJAN + TCP",
                "listen": "0.0.0.0",
                "port": 2054,
                "protocol": "trojan",
                "settings": {
                    "clients": []
                },
                "streamSettings": {
                    "network": "tcp",
                    "tcpSettings": {},
                    "security": "none"
                },
                "sniffing": {
                    "enabled": True,
                    "destOverride": [
                    "http",
                    "tls"
                    ]
                }
            }
        ],
        "outbounds": [
            {
                "protocol": "freedom",
                "tag": "DIRECT"
            },
            {
                "protocol": "blackhole",
                "tag": "BLOCK"
            }
        ]
    }

    result = await panel.modify_xray_config(token=token, config=new_config)
    print(result)

asyncio.run(main())

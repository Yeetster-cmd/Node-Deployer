  GNU nano 4.8                                   test.sh                                    Modified
#!/bin/bash
read -p $'Press 0 for Node Deployment or Press 1 for Wings Install&Config\nRun Node Deployment then W>if [ $CHECK = 0 ]
then
read -p "Please enter the domain of the panel: " domain
read -p "Please enter the name of the Node: " name
read -p "Please enter a location ID: " id
read -p "Please enter a FQDN: " fqdn
read -p "Please enter RAM Amount for the Node: " mem
read -p "Pleae enter Disk Size: " disk
read -p "Please enter the directory to the mounted disk: " mnt_disk
read -p "Please enter the Upload Limit to the Node: " us
read -p "Please enter the Port of the SFTP Service: " daemonsftp
read -p "Please enter the Port of the Daemon (Wings): " daemonls
JSONBody="{\
    \"domain\": \"${domain}\",\
    \"name\": \"${name}\",\
    \"location_id\": \"$id\",
    \"fqdn\": \"$fqdn\",
    \"scheme\": \"https\",
    \"memory\": $mem,
    \"memory_overallocate\": 0,
    \"disk\": $disk,
    \"disk_overallocate\": 0,
    \"upload_size\": $us,
    \"daemon_sftp\": $daemonsftp,
    \"daemon_listen\": $daemonls,
    \"daemon_base\":  \"$mnt_disk\"
}"
curl "https://"${domain}"/api/application/nodes" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -H "Authorization: Bearer KQe8z8jgxxRUrgSN7BoZdhJT1Dhu7loWsED6lSdTKUrHDbXx" \
        -X POST \
        -d "$(jq -r . <<< "${JSONBody}")" | json_pp

ufw allow 25565:25590/tcp
ufw allow 25565:25590/udp
ufw allow $daemonsftp
ufw allow $daemonls
echo "Ports: "{$daemonsftp}" , "{$daemonls}" and ports 25565-25590 have been allowed thru the firewall" 
sleep 2
echo "Node Has been Deployed to the Panel, Please run the Wings Install Part of this Script!"
fi
if [ $CHECK = 1 ]
then
echo "Installing Wings"
echo "IF THIS GETS STUCK, GO TO LINE 41 AND PUT A # BEFORE CURL"
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
systemctl enable --now docker
mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
echo "Max is gay ;)"
chmod u+x /usr/local/bin/wings
echo '[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service
[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s
[Install]
WantedBy=multi-user.target' >  /etc/systemd/system/wings.service
cd /etc/pterodactyl
FILE=/etc/pterodactyl/config.yml
if [ -f "$FILE" ]; then
    rm config.yml
    echo "Config File already exists, deleting file"
fi
read -p "Please Enter Node ID, which can be found on the admin panel by clicking on the node and looking at the URL: " node_id
curl "https://panel.crewcraft.cc/api/application/nodes/"${node_id}"/configuration" \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer KQe8z8jgxxRUrgSN7BoZdhJT1Dhu7loWsED6lSdTKUrHDbXx' \
  -X GET  | json_pp >> config.yml
systemctl enable --now wings
systemctl restart wings
echo "Wings have been installed and configured"
cd /
fi

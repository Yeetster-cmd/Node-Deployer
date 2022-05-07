#!/bin/bash
read -p $'Press 0 for Node Deployment or Press 1 for Wings Install&Config\nRun Node Deployment then Wings Installation if you are using this to easily boot up servers\n' CHECK
if [ $CHECK = 0 ]
then
read -p "Please enter the domain of the panel: " domain
read -p "Please enter the name of the Node: " name
read -p "Please enter an API Key: " key
read -p "Please enter a location ID: " id
read -p "Please enter a FQDN: " fqdn
read -p "Please enter RAM Amount for the Node: " mem
read -p "Pleae enter Disk Size: " disk
read -p "Please enter the directory to the mounted disk: " mnt_disk
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
    \"upload_size\": 100,
    \"daemon_sftp\": 2022,
    \"daemon_listen\": 8080,
    \"daemon_base\":  \"$mnt_disk\"
}"
curl "https://"${domain}"/api/application/nodes" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $key" \
        -X POST \
        -d "$(jq -r . <<< "${JSONBody}")"


fi
if [ $CHECK = 1 ]
then
echo "Installing Wings"
echo "IF THIS GETS STUCK, GO TO LINE 41 AND PUT A # BEFORE CURL"
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
systemctl enable --now docker
mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
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
systemctl enable --now wings
echo "Wings have been installed, please auto-deploy the node with the command given with Pterodactyl!"
fi

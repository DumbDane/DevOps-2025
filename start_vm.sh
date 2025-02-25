#!/usr/bin/env bash

sudo apt-get update
# Wait again for any potential lock from the previous install
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for apt-get lock to be released..."
    sleep 1
done

sudo apt-get install -y docker.io docker-compose-v2
sudo systemctl status docker
# sudo usermod -aG docker ${USER}

echo -e "\nVerifying that docker works ...\n"
docker run --rm hello-world
docker rmi hello-world

echo -e "\nOpening port for minitwit ...\n"
ufw allow 5000 && \
ufw allow 22/tcp

echo ". $HOME/.bashrc" >> $HOME/.bash_profile

echo -e "\nConfiguring credentials as environment variables...\n"

source $HOME/.bash_profile

echo -e "\nSelecting Minitwit Folder as default folder when you ssh into the server...\n"
echo "cd /minitwit" >> ~/.bash_profile

chmod +x /minitwit/deploy.sh

echo "\nInstalling jq for json parsing ...\n"
sudo apt-get install -y jq
wait -n
echo "\nInstalled jq for json parsing  ...\n"
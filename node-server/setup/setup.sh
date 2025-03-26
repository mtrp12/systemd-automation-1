#!/bin/bash
exec > >(tee /var/log/setup.log) 2>&1

# Update system and install dependencies
apt-get update
apt-get upgrade -y
apt-get install -y netcat-openbsd mysql-client git

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

useradd -m nodejs
echo "nodejs user added"

git clone https://github.com/mtrp12/systemd-automation-1.git /home/nodejs/app
echo "Repository cloned"

cp /home/nodejs/app/node-server/setup/mysql-check.sh /usr/local/bin/mysql-check.sh
chmod +x /usr/local/bin/mysql-check.sh
cp /home/nodejs/app/node-server/setup/node.service /etc/system/system/
cp /home/nodejs/app/node-server/setup/mysql-check.service /etc/system/system/

chown -R nodejs:nodejs /home/nodejs/app
echo "file ownership set to nodejs:nodejs"

systemctl daemon-reload
systemctl enable mysql-check
systemctl enable node

# Wait for environment variable to be set
max_attempts=30 
attempt=0

while [ -z "$DB_PRIVATE_IP" ]; do
    if [ $attempt -ge $max_attempts ]; then
        echo "Timeout waiting for DB_PRIVATE_IP to be set"
        exit 1
    fi
    echo "Waiting for DB_PRIVATE_IP environment variable..."
    attempt=$((attempt + 1))
    sleep 10
    # Source the environment file only once per iteration
    source /etc/environment
done

max_retries=12
count=0
while ! nc -zv "$DB_PRIVATE_IP" 3306 && [ "$count" -lt "$max_retries" ]; do
  ((count++))
  sleep 10
done

systemctl start mysql-check
systemctl start node



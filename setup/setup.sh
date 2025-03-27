#!/bin/bash
exec > >(tee /var/log/setup.log) 2>&1

# Update system and install dependencies
apt-get update
apt-get upgrade -y
apt-get install -y netcat-openbsd mysql-client git mysql-server

# Configure MySQL to allow remote connections
sed -i 's/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# Create database and user
mysql -e "CREATE DATABASE IF NOT EXISTS practice_app;"
mysql -e "CREATE USER 'api_user'@'%' IDENTIFIED BY 'secure_password_123';"
mysql -e "GRANT SELECT, INSERT, UPDATE, DELETE ON practice_app.* TO 'api_user'@'%';"
mysql -e "FLUSH PRIVILEGES;"
mysql -e "USE practice_app;CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  phone VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  INDEX idx_email (email),
  INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;"
mysql -e "USE practice_app;INSERT INTO users (first_name, last_name, email, phone, is_active) VALUES
('John', 'Doe', 'john.doe@example.com', '+1234567890', TRUE),
('Jane', 'Smith', 'jane.smith@example.com', '+1987654321', TRUE),
('Robert', 'Johnson', 'robert.j@example.com', '+1122334455', TRUE),
('Emily', 'Williams', 'emily.w@example.com', '+1567890123', TRUE),
('Michael', 'Brown', 'michael.b@example.com', '+1456789012', TRUE),
('Sarah', 'Davis', 'sarah.d@example.com', '+1345678901', TRUE),
('David', 'Miller', 'david.m@example.com', '+1678901234', TRUE),
('Jessica', 'Wilson', 'jessica.w@example.com', '+1789012345', TRUE),
('Thomas', 'Moore', 'thomas.m@example.com', '+1890123456', TRUE),
('Jennifer', 'Taylor', 'jennifer.t@example.com', '+1901234567', TRUE),
('James', 'Anderson', 'james.a@example.com', '+1012345678', TRUE),
('Lisa', 'Thomas', 'lisa.t@example.com', '+1123456789', TRUE),
('Daniel', 'Jackson', 'daniel.j@example.com', '+1234567890', TRUE),
('Nancy', 'White', 'nancy.w@example.com', '+1345678901', TRUE),
('Paul', 'Harris', 'paul.h@example.com', '+1456789012', TRUE),
('Emma', 'Martin', 'emma.m@example.com', '+1567890123', FALSE),
('Christopher', 'Garcia', 'chris.g@example.com', '+1678901234', TRUE),
('Amanda', 'Martinez', 'amanda.m@example.com', '+1789012345', FALSE),
('Kevin', 'Robinson', 'kevin.r@example.com', '+1890123456', TRUE),
('Laura', 'Clark', 'laura.c@example.com', '+1901234567', TRUE),
('Mark', 'Rodriguez', 'mark.r@example.com', '+1012345678', TRUE),
('Stephanie', 'Lewis', 'stephanie.l@example.com', '+1123456789', TRUE),
('Ryan', 'Lee', 'ryan.l@example.com', '+1234567890', TRUE),
('Nicole', 'Walker', 'nicole.w@example.com', '+1345678901', FALSE),
('Andrew', 'Hall', 'andrew.h@example.com', '+1456789012', TRUE),
('Rachel', 'Allen', 'rachel.a@example.com', '+1567890123', TRUE),
('Joshua', 'Young', 'joshua.y@example.com', '+1678901234', TRUE),
('Megan', 'Hernandez', 'megan.h@example.com', '+1789012345', TRUE),
('Brandon', 'King', 'brandon.k@example.com', '+1890123456', TRUE),
('Heather', 'Wright', 'heather.w@example.com', '+1901234567', TRUE),
('Justin', 'Lopez', 'justin.l@example.com', '+1012345678', TRUE),
('Melissa', 'Scott', 'melissa.s@example.com', '+1123456789', FALSE),
('Matthew', 'Green', 'matthew.g@example.com', '+1234567890', TRUE),
('Rebecca', 'Adams', 'rebecca.a@example.com', '+1345678901', TRUE),
('Patrick', 'Baker', 'patrick.b@example.com', '+1456789012', TRUE),
('Amber', 'Gonzalez', 'amber.g@example.com', '+1567890123', TRUE),
('Gregory', 'Nelson', 'gregory.n@example.com', '+1678901234', TRUE),
('Danielle', 'Carter', 'danielle.c@example.com', '+1789012345', TRUE),
('Timothy', 'Mitchell', 'timothy.m@example.com', '+1890123456', TRUE),
('Christina', 'Perez', 'christina.p@example.com', '+1901234567', TRUE),
('Kyle', 'Roberts', 'kyle.r@example.com', '+1012345678', TRUE),
('Lauren', 'Turner', 'lauren.t@example.com', '+1123456789', TRUE),
('Eric', 'Phillips', 'eric.p@example.com', '+1234567890', FALSE),
('Kayla', 'Campbell', 'kayla.c@example.com', '+1345678901', TRUE),
('Brian', 'Parker', 'brian.p@example.com', '+1456789012', TRUE),
('Allison', 'Evans', 'allison.e@example.com', '+1567890123', TRUE),
('Zachary', 'Edwards', 'zachary.e@example.com', '+1678901234', TRUE),
('Victoria', 'Collins', 'victoria.c@example.com', '+1789012345', TRUE),
('Nathan', 'Stewart', 'nathan.s@example.com', '+1890123456', TRUE),
('Samantha', 'Sanchez', 'samantha.s@example.com', '+1901234567', TRUE),
('Dustin', 'Morris', 'dustin.m@example.com', '+1012345678', TRUE),
('Tiffany', 'Rogers', 'tiffany.r@example.com', '+1123456789', TRUE),
('Scott', 'Reed', 'scott.r@example.com', '+1234567890', TRUE),
('Olivia', 'Cook', 'olivia.c@example.com', '+1345678901', TRUE),
('Travis', 'Morgan', 'travis.m@example.com', '+1456789012', TRUE),
('Maria', 'Bell', 'maria.b@example.com', '+1567890123', TRUE),
('Peter', 'Murphy', 'peter.m@example.com', '+1678901234', TRUE),
('Kristen', 'Bailey', 'kristen.b@example.com', '+1789012345', TRUE),
('Jeffrey', 'Rivera', 'jeffrey.r@example.com', '+1890123456', TRUE),
('Hannah', 'Cooper', 'hannah.c@example.com', '+1901234567', TRUE);"

# Restart MySQL
systemctl enable mysql
systemctl restart mysql


# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

useradd -m nodejs
echo "nodejs user added"

git clone -b master --depth 1 https://github.com/mtrp12/systemd-automation-1.git /home/nodejs/app
echo "Repository cloned"

cp /home/nodejs/app/setup/mysql-check.sh /usr/local/bin/mysql-check.sh
chmod +x /usr/local/bin/mysql-check.sh
cp /home/nodejs/app/setup/node.service /etc/systemd/system/
cp /home/nodejs/app/setup/mysql-check.service /etc/systemd/system/

chown -R nodejs:nodejs /home/nodejs/app
echo "file ownership set to nodejs:nodejs"

systemctl daemon-reload
systemctl enable mysql-check
systemctl enable node

max_retries=12
count=0
while ! nc -zv localhost 3306 && [ "$count" -lt "$max_retries" ]; do
  ((count++))
  sleep 10
done

systemctl start mysql-check
systemctl start node



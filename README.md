



# Systemd Automation of Mysql Backed NodeJS API Server

This repository provides scripts and configurations to automate the setup, testing, and teardown of a Node.js application managed by systemd. It streamlines the deployment and management of the application as a systemd service.

# Repository Structure

- **node-server/**: Contains the Node.js application code.
- **setup/**: Holds the systemd service unit file for the Node.js application and associated scripts.
- **setup.sh**: Automates the setup process, including installing dependencies and configuring the systemd service.
- **teardown.sh**: Removes the systemd service and cleans up resources.
- **test.sh**: Provides a mechanism to test the running Node.js application.

# How to Run
## 1. Initial Setup
Run the installation script to set up the environment:
```bash
curl https://raw.githubusercontent.com/mtrp12/systemd-automation-1/refs/heads/master/setup.sh | bash -
```
The installation script will:
- Update system packages
- Install required dependencies (Node.js, MySQL, Git)
- Configure MySQL for remote access
- Clone the application repository
- Set up systemd services
- Configure proper permissions

## 2. Verify Installation
Test the installed services and configuration:
```bash
curl https://raw.githubusercontent.com/mtrp12/systemd-automation-1/refs/heads/master/test.sh | bash -
```
The verification script will:
- Check MySQL connectivity
- Validate service status
- Test API endpoints
- Display system resource usage

## 3. Clean Up (When Needed)
Remove all installed components. This will allow one to rerun setup process again.

```bash
curl https://raw.githubusercontent.com/mtrp12/systemd-automation-1/refs/heads/master/teardown.sh | bash -
```
The cleanup script will:
- Stop and disable all services
- Remove application files
- Uninstall dependencies (optional)
- Clean up system configurations

## 4. Logging and Monitoring
To check log use the following commands:
### Node Server Logs
```bash
journalctl -u node
```
This command shows the systemd logs for the node application server.

### Mysql Logs
```bash
journalctl -u mysql
```
This command shows the systemd logs for the mysql database.

### Mysql Health Check Logs
```bash
journalctl -u mysql-check
```
This command shows the systemd logs for mysql health check logs.

# NodeJS Application API Specification

## Base URL
`http://localhost:3000`

## Endpoints

### 1. Health Check
**Endpoint**: `/health`  
**Method**: GET  
**Description**: Checks application and database connectivity  
**Response**:

```json
{
  "status": "healthy",
  "database": "connected"
}
```

### 2. Get Users
**Endpoint**: `/users`  
**Method**: GET  
**Description**: Retrieves paginated list of users with filtering capabilities. `The API only takes one query parameter at the moment`

**Query Parameters**:
| Parameter | Type   | Description                          | Default |
|-----------|--------|--------------------------------------|---------|
| `id`      | number | Filter by specific user ID           | -       |
| `email`   | string | Filter by email (partial match)      | -       |
| `name`    | string | Filter by name (partial match)       | -       |
| `page`    | number | Page number for pagination           | 1       |

**Successful Response**:
```json
{
  "data": [
    {
      "id": number,
      "name": string,
      "email": string,
      "phone": string,
      "created_at": "ISO8601",
      "updated_at": "ISO8601",
      "is_active": boolean
    }
  ],
  "pagination": {
    "page": number,
    "pageSize": number,
    "totalItems": number,
    "totalPages": number
  }
}
```

**Examples**:
1. Get user by ID:  
   `GET /users?id=5`

2. Search by name:  
   `GET /users?name=Scott`

3. Paginated results:  
   `GET /users?page=2`

## Response Codes
- `200 OK`: Successful request
- `500 Internal Server Error`: Server error (check error message)

# Mysql Database Configuration
Creates a MySQL database, user, table structure, and populates with sample user data for a practice application.

## Mysql Installation
Prepares an Ubuntu/Debian system with MySQL server and necessary dependencies for application deployment.

### 1. System Update and Package Installation
```bash
apt-get update
apt-get upgrade -y
apt-get install -y netcat-openbsd mysql-client git mysql-server
```
- **`apt-get update`**: Updates package lists
- **`apt-get upgrade -y`**: Upgrades all installed packages (auto-confirms)
- **Package Installation**:
  - `netcat-openbsd`: Network utility for connection testing
  - `mysql-client`: MySQL command-line tools
  - `git`: Version control system
  - `mysql-server`: MySQL database server

### 2. MySQL Remote Access Configuration
```bash
sed -i 's/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
```
- Modifies MySQL configuration to:
  - Change `bind-address` from `127.0.0.1` to `0.0.0.0`
  - Allows remote connections from any network interface
  - **Security Note**: Should be restricted to specific IPs in production

### 3. MySQL Service Management
```bash
systemctl start mysql
```
- Starts MySQL database service
- Ensures service is running before proceeding

### 4. MySQL Availability Check (wait_for_mysql)
This is a function that checks for mysql service at `localhost:3306` using `nc` utility. We wait until the service is up before proceeding with database creation.

## Database Initialization
The following steps provide explanation of how the database was initialized with sample table and data for nodejs application server.

### 1. Database Creation
```bash
mysql -e "CREATE DATABASE IF NOT EXISTS practice_app;"
```
- Creates new database named `practice_app` if it doesn't exist

### 2. User Creation
```bash
mysql -e "CREATE USER 'api_user'@'%' IDENTIFIED BY 'secure_password_123';"
```
- Creates MySQL user `api_user` with password
- `'%'` allows connection from any host (adjust for production)

### 3. Permission Assignment
```bash
mysql -e "GRANT SELECT, INSERT, UPDATE, DELETE ON practice_app.* TO 'api_user'@'%';"
mysql -e "FLUSH PRIVILEGES;"
```
- Grants CRUD permissions on all tables in `practice_app`
- Flushes privileges to apply changes

### 4. Table Creation
```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  INDEX idx_email (email),
  INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```
- Creates `users` table with:
  - Auto-incrementing primary key
  - Required name and email (unique)
  - Optional phone number
  - Automatic timestamps
  - Active/inactive flag
  - Optimized indexes

### 5. Data Population
```sql
INSERT INTO users (name, email, phone, is_active) VALUES
('John Doe', 'john.doe@example.com', '+1234567890', TRUE),
...
('Hannah Cooper', 'hannah.c@example.com', '+1901234567', TRUE);
```
- Inserts 60 sample user records
- Provides `name`, `email`, `phone`
- `id` is autogenerated


## Mysql Service Activation
```bash
systemctl enable mysql
systemctl restart mysql
```
- Enables the mysql service
- Restarts the mysql service so that it picks up the configuration changes


# Node Application Server Setup
Installs Node.js runtime and creates a dedicated system user for running Node applications.


## 1. node.js Installation
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
```
- **Repository Setup**:
  - Downloads and executes NodeSource setup script for Node.js 18.x
  - Adds official Node.js repository to package sources
- **Installation**:
  - Installs Node.js and npm (Node Package Manager)
  - `-y` flag automatically confirms installation

## 2. System User Creation
```bash
useradd -m nodejs
```
- Creates a dedicated system user account:
  - `-m` flag creates home directory at `/home/nodejs`
  - User will run Node.js applications with limited privileges
  - Follows security best practice of not running apps as root

## 3. Application Directory Setup
```bash
git clone -b master --depth 1 https://github.com/mtrp12/systemd-automation-1.git /home/nodejs/app
```
- Clones repository:
  - `-b master`: Uses main branch
  - `--depth 1`: Shallow clone (faster, no history)
  - Targets `/home/nodejs/app` directory

## 4. Systemd Service Configuration
```bash
cp /home/nodejs/app/setup/mysql-check.sh /usr/local/bin/mysql-check.sh
chmod +x /usr/local/bin/mysql-check.sh
cp /home/nodejs/app/setup/node.service /etc/systemd/system/
cp /home/nodejs/app/setup/mysql-check.service /etc/systemd/system/
```
- Deploys:
  - MySQL health check script to `/usr/local/bin`
  - Makes script executable
  - Systemd service files for:
    - Node application (`node.service`)
    - MySQL checker (`mysql-check.service`)

## 5. Nodejs Dependency Installation
```bash
cd /home/nodejs/app/node-server
npm install
```
- Installs Node.js dependencies:
  - Reads `package.json`
  - Creates `node_modules` directory
  - Installs production and dev dependencies

## 6. Permission Management
```bash
chown -R nodejs:nodejs /home/nodejs/app
```
- Recursively sets ownership:
  - User: `nodejs`
  - Group: `nodejs`
  - Ensures proper file access

## 7. Service Registration
```bash
systemctl daemon-reload
systemctl enable mysql-check
systemctl enable node
```
- `daemon-reload`: Refreshes systemd configuration
- Enables services to:
  - Start on boot (`enable`)
  - MySQL health check runs first
  - Node application starts after
Here's the structured breakdown of the service activation and cleanup script:


## 8. Service Activation
```bash
wait_for_mysql
systemctl start mysql-check
systemctl start node
```
- **Execution Order**:
  1. Waits for MySQL to become available (`wait_for_mysql`)
  2. Starts MySQL health check service
  3. Launches Node.js application

## 9. Service Verification
```bash
systemctl status mysql
systemctl status mysql-check
systemctl status node
```
- Validates operational state of:
  - MySQL database service
  - Custom MySQL check service
  - Node.js application service
- Outputs current status to logs

# Cleanup Phase
In this phase setup files and development related files

```bash
rm -rf /home/nodejs/app/setup
rm /home/nodejs/app/.gitattributes
rm /home/nodejs/app/.gitignore
rm /home/nodejs/app/README.md
rm -rf /home/nodejs/app/.git
rm /home/nodejs/app/setup.sh
rm /home/nodejs/app/teardown.sh
rm /home/nodejs/app/test.sh
```
- **Files Removed**:
  - Version control files (`.git*`)
  - Documentation (`README.md`)
  - Setup/teardown scripts
  - Temporary configuration directory
- **Security Benefit**:
  - Reduces attack surface
  - Removes unnecessary execute permissions

# Service Configuration Files

## MySQL Connection Check Script (setup/mysql-check.sh)
Verifies MySQL database availability before application startup, with retry logic for containerized environments.

### 1. Configuration Setup
```bash
DB_HOST=localhost
DB_PORT=3306
MAX_RETRIES=30
RETRY_INTERVAL=10
```
- **Environment Configuration**:
  - `DB_HOST`: Database host (default: localhost)
  - `DB_PORT`: MySQL port (default: 3306)
  - `MAX_RETRIES`: Maximum connection attempts (30)
  - `RETRY_INTERVAL`: Delay between attempts in seconds (10)

### 2. Connection Check Function
```bash
check_mysql() {
    nc -z "$DB_HOST" "$DB_PORT"
    return $?
}
```
- Uses `netcat` (`nc`) to test TCP connectivity:
  - `-z` flag scans without sending data
  - Returns exit code:
    - `0` = success (MySQL accepting connections)
    - `1` = failure (connection refused/timeout)

### 3. Retry Loop
```bash
while [ $retry_count -lt $MAX_RETRIES ]; do
    if check_mysql; then
        echo "Successfully connected to MySQL at $DB_HOST:$DB_PORT"
        exit 0
    fi
    echo "Attempt $((retry_count + 1))/$MAX_RETRIES: Cannot connect to MySQL at $DB_HOST:$DB_PORT. Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
    retry_count=$((retry_count + 1))
done
```
- **Behavior**:
  - Attempts connection immediately
  - On failure:
    - Logs attempt count (1/30, 2/30, etc.)
    - Waits specified interval
    - Increments retry counter
  - On success:
    - Prints confirmation
    - Exits with code `0` (success)

### 4. Failure Handling
```bash
echo "Failed to connect to MySQL after $MAX_RETRIES attempts"
exit 1
```
- **Final Failure**:
  - After all retries exhausted
  - Logs failure message
  - Exits with code `1` (error)


## MySQL Check Service Specification (setup/mysql-check.service)
Here's the detailed breakdown of the `mysql-check.service` systemd unit file:
### 1. Unit Configuration
```ini
[Unit]
Description=MySQL Connectivity Check Service
After=network.target
Wants=network.target
```
- **Description**: Human-readable service name
- **Dependencies**:
  - `After=network.target`: Ensures network is available before starting
  - `Wants=network.target`: Soft dependency on network (will start if possible)

### 2. Service Definition
```ini
[Service]
Type=simple
EnvironmentFile=/etc/environment
ExecStart=/usr/local/bin/mysql-check.sh
Restart=on-failure
RestartSec=30
StandardOutput=append:/var/log/mysql-check.log
StandardError=append:/var/log/mysql-check.log
```
- **Service Type**: `simple` (default for scripts running in foreground)
- **Configuration**:
  - `EnvironmentFile`: Loads environment variables from `/etc/environment`
  - `ExecStart`: Absolute path to the check script
- **Failure Handling**:
  - `Restart=on-failure`: Auto-restarts if script exits non-zero
  - `RestartSec=30`: Waits 30 seconds before restarting
- **Logging**:
  - Appends both stdout and stderr to `/var/log/mysql-check.log`
  - Creates file if nonexistent

### 3. Installation Directive
```ini
[Install]
WantedBy=multi-user.target
```
- **Startup Behavior**:
  - Activates when system reaches multi-user runlevel (normal boot)
  - Enables with: `systemctl enable mysql-check`

Here's the concise breakdown of the Node.js systemd service file:

## Node Application Service Specification (setup/node.service)
### 1. Service Unit Definition
```ini
[Unit]
Description=Start Node.js App
After=network.target
```
- **Description**: Identifies the service purpose
- **Dependencies**:
  - Starts only after network is available (`network.target`)

### 2. Service Configuration
```ini
[Service]
User=nodejs
Group=nodejs
ExecStart=/usr/bin/node /home/nodejs/app/node-server/server.js
KillMode=control-group
WorkingDirectory=/home/nodejs/app/node-server/
Restart=on-failure
```
- **Security Context**:
  - Runs as dedicated `nodejs` user/group
- **Process Management**:
  - `ExecStart`: Launches Node.js application
  - `KillMode=control-group`: Terminates entire process group
- **Operational Settings**:
  - `WorkingDirectory`: Sets execution context
  - `Restart=on-failure`: Auto-recovery for crashes

### 3. Startup Configuration
```ini
[Install]
WantedBy=multi-user.target
```
- **Activation**:
  - Starts at normal system boot (multi-user target)
  - Enable with: `systemctl enable node-app`

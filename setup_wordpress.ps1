#ps1

# Allow HTTP and HTTPS in Windows Firewall
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Allow HTTPS" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow

# Download and Install XAMPP (non-interactive)
$xamppUrl = "https://www.apachefriends.org/xampp-files/8.2.4/xampp-windows-x64-8.2.4-0-VS16-installer.exe"
$xamppInstaller = "$env:TEMP\xampp-installer.exe"
Invoke-WebRequest -Uri $xamppUrl -OutFile $xamppInstaller

Start-Process -FilePath $xamppInstaller -ArgumentList "/SILENT" -Wait

# Wait for XAMPP to be installed
Start-Sleep -Seconds 30

# Generate secure MySQL root password
$securePassword = -join ((65..90) + (97..122) + (48..57) + (35..38) | Get-Random -Count 16 | % {[char]$_})

# Start Apache and MySQL services
Start-Process "C:\xampp\xampp-control.exe" -ArgumentList "startapache" -NoNewWindow
Start-Process "C:\xampp\xampp-control.exe" -ArgumentList "startmysql" -NoNewWindow

# Download and extract WordPress
$wordpressUrl = "https://wordpress.org/latest.zip"
$wordpressZip = "$env:TEMP\wordpress.zip"
Invoke-WebRequest -Uri $wordpressUrl -OutFile $wordpressZip

# Create wordpress directory if it doesn't exist
New-Item -ItemType Directory -Force -Path "C:\xampp\htdocs\wordpress"

# Extract WordPress
Expand-Archive -Path $wordpressZip -DestinationPath "C:\xampp\htdocs\wordpress" -Force

# Set up MySQL database and secure it
$mysql = "C:\xampp\mysql\bin\mysql.exe"
$dbName = "wordpress"
$dbUser = "wp_user"
$dbUserPass = -join ((65..90) + (97..122) + (48..57) + (35..38) | Get-Random -Count 16 | % {[char]$_})

$sql = @"
CREATE DATABASE IF NOT EXISTS $dbName;
CREATE USER '$dbUser'@'localhost' IDENTIFIED BY '$dbUserPass';
GRANT ALL PRIVILEGES ON $dbName.* TO '$dbUser'@'localhost';
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '$securePassword';
"@

# Save credentials to a secure file
$credentials = @"
WordPress Database Credentials
----------------------------
Database Name: $dbName
Database User: $dbUser
Database Password: $dbUserPass
MySQL Root Password: $securePassword
"@

$credentials | Out-File -FilePath "C:\xampp\wordpress_credentials.txt" -Force

# Execute SQL
$sql | & $mysql -u root

# Create wp-config.php
$wpConfig = Get-Content "C:\xampp\htdocs\wordpress\wordpress\wp-config-sample.php"
$wpConfig = $wpConfig.Replace("database_name_here", $dbName)
$wpConfig = $wpConfig.Replace("username_here", $dbUser)
$wpConfig = $wpConfig.Replace("password_here", $dbUserPass)

# Add security keys
$salts = (Invoke-WebRequest -Uri "https://api.wordpress.org/secret-key/1.1/salt/").Content
$wpConfig = $wpConfig -replace "/'AUTH_KEY',\s*'put your unique phrase here'.*?define\('NONCE_SALT',\s*'put your unique phrase here'\s*\);/s", $salts

$wpConfig | Out-File -FilePath "C:\xampp\htdocs\wordpress\wordpress\wp-config.php" -Force

Write-Host @"
Installation completed!
----------------------
1. WordPress files are in C:\xampp\htdocs\wordpress
2. Database credentials are saved in C:\xampp\wordpress_credentials.txt
3. Access your WordPress site at http://<your-ec2-public-ip>/wordpress
4. Complete the installation through the web interface

IMPORTANT:
- Save the credentials file securely and then move it from the server
- Configure your EC2 security group to allow ports 80 and 443
- Consider setting up SSL certificate for HTTPS
"@

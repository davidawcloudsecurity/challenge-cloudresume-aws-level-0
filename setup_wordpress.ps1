# Download and Install XAMPP (non-interactive)
$xamppUrl = "https://www.apachefriends.org/xampp-files/8.2.4/xampp-windows-x64-8.2.4-0-VS16-installer.exe"
$xamppInstaller = "$env:TEMP\xampp-installer.exe"
Invoke-WebRequest -Uri $xamppUrl -OutFile $xamppInstaller

Start-Process -FilePath $xamppInstaller -ArgumentList "/SILENT" -Wait

# Wait for XAMPP to be installed
Start-Sleep -Seconds 30

# Start Apache and MySQL services
& "C:\xampp\xampp-control.exe" startapache
& "C:\xampp\xampp-control.exe" startmysql

# Download and extract WordPress
$wordpressUrl = "https://wordpress.org/latest.zip"
$wordpressZip = "$env:TEMP\wordpress.zip"
Invoke-WebRequest -Uri $wordpressUrl -OutFile $wordpressZip

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($wordpressZip, "$env:TEMP")

# Move WordPress files to XAMPP htdocs
Copy-Item -Path "$env:TEMP\wordpress\*" -Destination "C:\xampp\htdocs\wordpress" -Recurse

# Set up MySQL database for WordPress
$mysql = "C:\xampp\mysql\bin\mysql.exe"
$dbName = "wordpress"
$dbUser = "root"
$dbPassword = "" # Default XAMPP root password is blank

$sql = @"
CREATE DATABASE IF NOT EXISTS $dbName;
"@

# Execute SQL to create database
& $mysql -u $dbUser -e $sql

Write-Host "WordPress files copied to C:\xampp\htdocs\wordpress"
Write-Host "MySQL database 'wordpress' created."
Write-Host "Open your browser and go to http://<your-ec2-public-ip>/wordpress to complete WordPress setup."

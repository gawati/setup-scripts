Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
$Env:PATH="$Env:PATH;$Env:ALLUSERSPROFILE\chocolatey\bin"

choco install kitty 7zip virtualbox -y

$Reply = Read-Host "Do you want to install developer tools (Y/[N])?"

if ($Reply -eq "y" -or $Reply -eq "Y") {
  choco install git jdk8 ant visualstudiocode -y
  }

#TODO edit hosts file: 192.168.56.101  my.gawati.local

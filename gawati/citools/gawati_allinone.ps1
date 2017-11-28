#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$CSV = (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/gawati/setup-scripts/master/gawati/citools/scripts.csv')
$Files = $CSV | ConvertFrom-Csv -Delim ','

$Files | ForEach {
  $URL = $_.URL
  $File = $PSScriptRoot + '\' + $_.Filename
  Invoke-WebRequest -Uri "$URL" -OutFile "$File"
  }

Start-Process "$psHome\powershell.exe" -wait -verb runas -ArgumentList "-noprofile -file ""$PSScriptRoot\gawati_preinstall_admin.ps1"""
Start-Process "$psHome\powershell.exe" -wait -ArgumentList "-noprofile -file ""$PSScriptRoot\gawati_preinstall.ps1"""
Start-Process "$psHome\powershell.exe" -wait -ArgumentList "-noprofile -file ""$PSScriptRoot\gawati_devsetup.ps1"""

#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$CSV = (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/gawati/setup-scripts/master/gawati/citools/scripts.csv')
$Files = $CSV | ConvertFrom-Csv -Delim ','

$DLRoot = $PSScriptRoot + '\scripts\'
New-Item -ItemType Directory -Force -Path $DLRoot

$Files | ForEach {
  $URL = $_.URL
  $File = $DLRoot + $_.Filename
  Invoke-WebRequest -Uri "$URL" -OutFile "$File"
  }

$Tasks = "gawati_preinstall_admin.ps1"
$Tasks | ForEach {
  $Script = $DLRoot + $_
  Start-Process "$psHome\powershell.exe" -wait -verb runas -ArgumentList "-noprofile -file ""$Script"""
  }

$Tasks = "gawati_preinstall.ps1", "gawati_devsetup.ps1"
$Tasks | ForEach {
  $Script = $DLRoot + $_
  Start-Process "$psHome\powershell.exe" -wait -ArgumentList "-noprofile -file ""$Script"""
  }

pause

#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$CSV = (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/gawati/setup-scripts/master/gawati/citools/scripts.csv')
$Files = $CSV | ConvertFrom-Csv -Delim ','

$ScriptRoot = $PSScriptRoot + '\scripts\'
New-Item -ItemType Directory -Force -Path $ScriptRoot

$Files | ForEach {
  $URL = $_.URL
  $File = $PSScriptRoot + '\' + $_.Filename
  Invoke-WebRequest -Uri "$URL" -OutFile "$File"
  }

$Tasks = "setup_tools.ps1"
$Tasks | ForEach {
  $Script = $ScriptRoot + $_
  Start-Process "$psHome\powershell.exe" -wait -verb runas -ArgumentList "-noprofile -file ""$Script"""
  }

$Tasks = "deploy_gawati_os.ps1", "gawati_devsetup.ps1"
$Tasks | ForEach {
  $Script = $ScriptRoot + $_
  Start-Process "$psHome\powershell.exe" -wait -ArgumentList "-noprofile -file ""$Script"""
  }

pause

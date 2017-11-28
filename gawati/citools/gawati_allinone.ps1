Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$Files = (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/gawati/setup-scripts/master/gawati/citools/scripts.csv') | ConvertFrom-Csv -Delim ','

$Files | ForEach {
  Invoke-WebRequest -Uri "$_.URL" -OutFile "$PSScriptRoot\$_.Filename"
  }

Start-Process "$psHome\powershell.exe" -wait -verb runas -ArgumentList "-noprofile -file '$PSScriptRoot\gawati_preinstall_admin.ps1'"
Start-Process "$psHome\powershell.exe" -wait -ArgumentList "-noprofile -file '$PSScriptRoot\gawati_preinstall.ps1'"
Start-Process "$psHome\powershell.exe" -wait -ArgumentList "-noprofile -file '$PSScriptRoot\gawati_devsetup.ps1'"

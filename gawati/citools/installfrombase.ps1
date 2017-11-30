$ScriptRoot = $PSScriptRoot + '\scripts\'

$Tasks = "gawati_devsetup.ps1"
$Tasks | ForEach {
  $Script = $ScriptRoot + $_
  Start-Process "$psHome\powershell.exe" -wait -ArgumentList "-noprofile -file ""$Script"""
  }

pause

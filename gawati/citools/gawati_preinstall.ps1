$GawatiOSURL = "https://gawati.org/GawatiVM.7z"

$ZIPFile = "$Env:USERPROFILE\Downloads\GawatiVM.7z"
if ( -not (Test-Path $ZIPFile)) {
  Write-Host "Downloading Gawati Virtual Machine Image. This may take a while..."
  (New-Object System.Net.WebClient).DownloadFile($GawatiOSURL,$ZIPFile)
  }

$VMFolder = "$Env:USERPROFILE\VirtualBox VMs"
if ( -not (Test-Path "$VMFolder\Gawati")) {
  Write-Host "Deploying Gawati Virtual Machine Image into Virtualbox. This may take a while..."
  Start-Process "$Env:ProgramFiles\7-Zip\7z.exe" -Wait -ArgumentList "x -o""$Env:USERPROFILE\VirtualBox VMs"" ""$ZIPFile"""
  VBoxManage registervm "$Env:USERPROFILE\VirtualBox VMs\Gawati\Gawati.vbox"
  }

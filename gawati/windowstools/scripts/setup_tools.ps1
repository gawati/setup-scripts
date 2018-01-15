Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force


function setHostEntries([hashtable] $entries) {
  $hostsFile = "$env:windir\System32\drivers\etc\hosts"
  $newLines = @()

  $c = Get-Content -Path $hostsFile

  foreach ($line in $c) {
    $bits = [regex]::Split($line, "\s+")
    if ($bits.count -eq 2) {
      $match = $NULL
      ForEach($entry in $entries.GetEnumerator()) {
        if($bits[1] -eq $entry.Key) {
          $newLines += ($entry.Value + '     ' + $entry.Key)
          Write-Host Replacing HOSTS entry for $entry.Key
          $match = $entry.Key
          break
          }
        }
      if($match -eq $NULL) {
        $newLines += $line
        } else {
        $entries.Remove($match)
        }
      } else {
      $newLines += $line
      }
    }

  foreach($entry in $entries.GetEnumerator()) {
    Write-Host Adding HOSTS entry for $entry.Key
    $newLines += $entry.Value + '     ' + $entry.Key
    }

  Write-Host Saving $hostsFile
  Clear-Content $hostsFile
  foreach ($line in $newLines) {
    $line | Out-File -encoding ASCII -append $hostsFile
    }
  }

$entries = @{
  'my.gawati.local' = "192.168.56.101"
  };

setHostEntries($entries)

#Install-Module -Force Posh-SSH

Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
$Env:PATH="$Env:PATH;$Env:ALLUSERSPROFILE\chocolatey\bin"

choco upgrade kitty 7zip virtualbox -y

$Reply = Read-Host "Do you want to install developer tools (Y/[N])?"

if ($Reply -eq "y" -or $Reply -eq "Y") {
  choco upgrade git jdk8 ant visualstudiocode -y
  }

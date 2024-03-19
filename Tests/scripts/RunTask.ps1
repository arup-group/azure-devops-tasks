param(
  [Parameter(Mandatory=$true)]
  [string]$taskDirectory,
  [Parameter(Mandatory=$true)]
  [string]$taskName,
  [string]$dotEnv,
  [switch]$disableInteractive=$false)

If (!$taskName.EndsWith(".ps1")) {
  $taskName = "$taskName.ps1"
}

$env:SYSTEM_CULTURE='en-UK'

Push-Location
try {
  Set-Location $taskDirectory
  Import-Module .\ps_modules\VstsTaskSdk

  If ($dotEnv -ne "") {
    Write-Host "`nSetting the following env variables:`n"
    Get-Content $dotEnv | ForEach-Object {
        $name, $value = $_.split('=')
        Write-Host $name=$value
        Set-Content env:\$name $value
    }
  }

  Write-Host "`nRunning $taskDirectory\$taskName...`n"
  Invoke-VstsTaskScript -ScriptBlock { . .\$taskName } 
} finally {
  Pop-Location
}
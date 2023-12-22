[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
  [string]$sourcesDirectory = Get-VstsTaskVariable -Name "Build.SourcesDirectory"
  [string]$projectParentDirectory = Get-VstsInput -Name projectParentDirectory

  If($projectParentDirectory -NotMatch $sourcesDirectory) {
    $projectParentDirectory = [string]$sourcesDirectory/$projectParentDirectory
  }

  [string]$projectDisplayName = Get-VstsInput -Name projectDisplayName
  [string]$buildHelp = Get-VstsInput -Name buildHelp
  [string]$includePdf = Get-VstsInput -Name includePdf
  [string]$clientId = Get-VstsInput -Name clientId
  [string]$clientSecret = Get-VstsInput -Name clientSecret

  $project = [string]$projectDisplayName.ToLower()
  $versionInfo = $(Get-Item $projectParentDirectory\programs64\$project.exe).VersionInfo
  $fullVersion = [array]$versionInfo.FileVersion.split('.')
  $productVersion = [array]$versionInfo.ProductVersion.split('.')
  $majorNumber = [string]$fullVersion[0]
  $minorNumber = [string]$fullVersion[1]
  $spNumber    = [string]$fullVersion[2]
  $buildNumber = [string]$fullVersion[3]

  [string]$installerProjectName = Get-VstsInput -Name installerProjectName -Default $projectDisplayName
  [string]$installerDirectoryName = Get-VstsInput -Name installerDirectoryName -Default $project
  [string]$installerBuilderDirectory = "$sourcesDirectory\installer-builder\"

  $linuxInstallerBuilderDirectory=[string]$installerBuilderDirectory -replace [regex]::Escape("C:\"), "/c/"
  $linuxInstallerBuilderDirectory=[string]$linuxInstallerBuilderDirectory -replace [regex]::Escape("\"), "/"

  $appInstallerDirectory = "$installerBuilderDirectory\$installerDirectoryName-$majorNumber.$minorNumber"
  $targetDirectory = "$appInstallerDirectory\TARGETDIR\Program Files\Oasys\$installerProjectName $majorNumber.$minorNumber"

  If($fullVersion.Length -ne 4 -or $productVersion.Length -ne 2) {
    Write-Error "FileVersion should be 4 digits and product version should be 2 digits long in $product.exe"
  }

  Write-Output "Delete old installer directory if it exists"
  Set-Location -Path $sourcesDirectory
  If (Test-Path -Path $installerBuilderDirectory -PathType Container) {
    Get-ChildItem -Path $installerBuilderDirectory -Recurse | Remove-Item -force -recurse
    Remove-Item $installerBuilderDirectory -Force 
  }

  Write-Output "Copying Installer"
  Copy-Item -Path oasys-windows-installer -Destination $installerBuilderDirectory -recurse -Force 

  If ($buildHelp -eq "yes") {
    [string]$helpDirectory = "$projectParentDirectory\$project\help"
    [string]$helpFileOverride = Get-VstsInput -Name helpFileOverride -Default "$project.hmxp"

    # Help and Manual Settings
    Set-Variable -Name helpAndManualPath -Value "$sourcesDirectory\HelpAndManualMinimal"

    # Project Paths
    Set-Variable -Name skinPath -Value "$sourcesDirectory\oasys-helpandmanual-skin"
    Set-Variable -Name outputPath -Value "$outputPath"

    # Project Settings
    Set-Variable -Name helpProject -Value $helpFileOverride
    Set-Variable -Name skinFile -Value Oasys.hmskin
    Set-Variable -Name logFile -Value "$project.log"
    Set-Variable -Name projectVariables -Value project_variables.txt

    # CHM Settings
    Set-Variable -Name chmFileName -Value "$projectDisplayName.chm"
    Set-Variable -Name chmOptions -Value "PRODUCT_${project.toUpper()}"

    # PDF Settings
    Set-Variable -Name pdfFileName -Value "${installerProjectName}${majorNumber}.${minorNumber}_Manual.pdf"
    Set-Variable -Name pdfTemplate -Value "oasys_$project.mnl"

    # HnM Executable
    Set-Variable -Name hnmexe -Value HELPMAN.EXE

    Set-Content -Path "$helpDirectory\project_variables.txt" `
      -Value "VERSION=$majorNumber.$minorNumber`r`nPROGRAM=$projectDisplayName"

    # Working directory
    Write-Output "Building Help files"
    $p=Start-Process "${helpAndManualPath}\${hnmexe}" -ArgumentList "$helpDirectory\$helpProject `
      /stdout /CHM=${outputPath}\${chmFileName} /O=${skinPath}\${skinFile} /I=CHM,${chmOptions} `
      /V=${helpDirectory}\${projectVariables} /PDF=${outputPath}\${pdfFileName} `
      /TEMPLATE=${helpDirectory}\${pdfTemplate} /V=${helpDirectory}\${projectVariables} `
      /L=${outputPath}\${logFile}" -Wait -PassThru
    $p.WaitForExit()

    Get-ChildItem -Filter *.chm -Path "$outputPath" -Recurse -Force | Copy-Item -Destination $targetDirectory
    If ($includePdf -eq "yes") {
      Get-ChildItem -Filter *.pdf -Path "$outputPath" -Recurse -Force | Copy-Item -Destination "$targetDirectory\Docs"
    }
  }

  Write-Output "Copying DLLs"
  Get-Content $projectParentDirectory\$project\build\programs64.txt | `
    ForEach-Object {Copy-Item -Recurse -Path "$projectParentDirectory\programs64\$_" -Destination $targetDirectory}

  Write-Output "Running Installer"
  c:\tools\msys64\usr\bin\env MSYSTEM=MINGW64 /bin/bash -l -c `
    "cd $linuxInstallerBuilderDirectory `
    && ./update_release_version.sh `
    -product $installerDirectoryName `
    -major $majorNumber -minor $minorNumber `
    -build $buildNumber -sp $spNumber"
  c:\tools\msys64\usr\bin\env MSYSTEM=MINGW64 /bin/bash -l -c `
    "cd $linuxInstallerBuilderDirectory/$installerDirectoryName-$majorNumber.$minorNumber `
    && make clean all CLIENTID=$clientId CLIENTSECRET=$clientSecret 2>errors.log `
    && if grep -iq 'error' errors.log; then cat errors.log && exit 1; fi"
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}
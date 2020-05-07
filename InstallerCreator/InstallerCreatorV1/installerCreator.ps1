[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
   [string]$sourceBranch = Get-VstsInput -Name sourceBranch
   [string]$sourcesDirectory = Get-VstsInput -Name sourcesDirectory
   [string]$projectDisplayName = Get-VstsInput -Name projectDisplayName
   [string]$buildHelp = Get-VstsInput -Name buildHelp
   $linuxDir=[string]$sourcesDirectory -replace [regex]::Escape("C:\"), "/c/"
   $linuxDir=[string]$linuxDir -replace [regex]::Escape("\"), "/"
   $project = [string]$projectDisplayName.ToLower()
   $majorNumber = [string]$sourceBranch.split("_")[1]
   $minorNumber = [string]$sourceBranch.split("_")[2]
   $buildNumber = [string]$sourceBranch.split("_")[3]
   [string]$installerProjectName = Get-VstsInput -Name installerProjectName -Default $projectDisplayName
   [string]$installerDirectoryName = Get-VstsInput -Name installerDirectoryName -Default $project

   $targetDirectory = "$sourcesDirectory\oasys-combined\gsa-assembler\$installerDirectoryName-$majorNumber.$minorNumber\TARGETDIR\Program Files\Oasys\$installerProjectName $majorNumber.$minorNumber"
   $installerDirectory = "$sourcesDirectory\oasys-combined\gsa-assembler\$installerDirectoryName-$majorNumber.$minorNumber"

   Write-Output "Delete old installer directory if it exists"
   Set-Location -Path $sourcesDirectory
   If (Test-Path -Path "oasys-combined\gsa-assembler" -PathType Container) {
    Get-ChildItem -Path oasys-combined\gsa-assembler -Recurse | Remove-Item -force -recurse
    Remove-Item oasys-combined\gsa-assembler -Force 
   }

   Write-Output "Copying Installer"
   Copy-Item -Path oasys-windows-installer -Destination oasys-combined\gsa-assembler -recurse -Force 


   If ($buildHelp -eq "yes") {
    Set-Variable  -Name WORKING_DIRECTORY -Value ${pwd}
    
    # Help and Manual Settings
    Set-Variable -Name helpAndManualPath -Value "$WORKING_DIRECTORY\HelpAndManualMinimal"
    
    # Project Paths
    Set-Variable -Name sourcePath -Value "$WORKING_DIRECTORY\oasys-combined\$project\help"
    Set-Variable -Name skinPath -Value "$WORKING_DIRECTORY\oasys-helpandmanual-skin"
    Set-Variable -Name outputPath -Value "$sourcePath\output"
    
    # Project Settings
    [string]$helpFileOverride = Get-VstsInput -Name helpFileOverride -Default "$project.hmxp"
    Set-Variable -Name helpProject -Value $helpFileOverride
    Set-Variable -Name skinFile -Value Oasys.hmskin
    Set-Variable -Name logFile -Value "$project.log"
    Set-Variable -Name projectVariables -Value project_variables.txt
    
    # CHM Settings
    Set-Variable -Name chmFileName -Value "$projectDisplayName.chm"
    Set-Variable -Name chmOptions -Value "PRODUCT_${project.toUpper()}"
    
    # PDF Settings
    Set-Variable -Name pdfFileName -Value "${projectDisplayName}_Manual.pdf"
    Set-Variable -Name pdfTemplate -Value "oasys_$project.mnl"
    
    # HnM Executable
    Set-Variable -Name hnmexe -Value HELPMAN.EXE


    Set-Content -Path "oasys-combined\$project\help\project_variables.txt" -Value "VERSION=$majorNumber.$minorNumber`r`nPROGRAM=$projectDisplayName"
    # Working directory
    Write-Output "Building Help files"
    $p=Start-Process "${helpAndManualPath}\${hnmexe}" -ArgumentList "$sourcePath\$helpProject /stdout /CHM=${outputPath}\${chmFileName} /O=${skinPath}\${skinFile} /I=CHM,${chmOptions} /V=${sourcePath}\${projectVariables} /PDF=${outputPath}\${pdfFileName} /TEMPLATE=${sourcePath}\${pdfTemplate} /V=${sourcePath}\${projectVariables} /L=${outputPath}\${logFile}" -Wait -PassThru
    $p.WaitForExit()

    Get-ChildItem -Filter *.chm -Path "oasys-combined\$project\help\output" -Recurse -Force | Copy-Item -Destination $targetDirectory
    Get-ChildItem -Filter *.pdf -Path "oasys-combined\$project\help\output" -Recurse -Force | Copy-Item -Destination "$targetDirectory\Docs"
   }

   Write-Output "Copying DLLs"
   Get-Content $installerDirectory\batchfiles\programs64.txt |  ForEach-Object {Copy-Item -Path "$sourcesDirectory\oasys-combined\$project\programs64\$_" -Destination $targetDirectory}

   Write-Output "Running Installer"
   c:\tools\msys64\usr\bin\env MSYSTEM=MINGW64 /bin/bash -l -c "cd $linuxDir/oasys-combined/gsa-assembler && ./update_release_version.sh -product $installerDirectoryName -major $majorNumber -minor $minorNumber -build $buildNumber"
   c:\tools\msys64\usr\bin\env MSYSTEM=MINGW64 /bin/bash -l -c "cd $linuxDir/oasys-combined/gsa-assembler/$installerDirectoryName-$majorNumber.$minorNumber && make clean all 2>errors.log && if grep -iq 'error' errors.log; then cat errors.log && exit 1; fi"
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}
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


   Copy-Item -Path oasys-windows-installer -Destination oasys-combined\gsa-assembler -recurse -Force 

   $project = [string]$sourceBranch.split("_")[0].ToLower()
   $majorNumber = [string]$sourceBranch.split("_")[1]
   $minorNumber = [string]$sourceBranch.split("_")[2]
   $buildNumber = [string]$sourceBranch.split("_")[3]

   If ($buildHelp -eq "Yes") {
    Set-Content -Path "oasys-combined\$project\help\project_variables.txt" -Value "VERSION=$majorNumber.$minorNumber`r`nPROGRAM=$projectDisplayName"
    & .\oasys-combined\xdisp\help\buildhelp-xdisp.ps1
   }

   Copy-Item -Filter *.chm -Path oasys-combined\$project\help\output -Destination oasys-combined\gsa-assembler\$project-$majorNumber.$minorNumber\TARGETDIR\Program Files\Oasys\$projectDisplayName] $majorNumber.$minorNumber -recurse -Force 

   Get-Content $sourcesDirectory\oasys-combined\gsa-assembler\xdisp-$majorNumber.$minorNumber\batchfiles\programs64.txt |  ForEach-Object {Copy-Item -Path "$sourcesDirectory\oasys-combined\$project\programs64\$_" -Destination "$sourcesDirectory\oasys-combined\gsa-assembler\$project-$majorNumber.$minorNumber\TARGETDIR\Program Files\Oasys\$projectDisplayName $majorNumber.$minorNumber"}

   c:\tools\msys64\usr\bin\env MSYSTEM=MINGW64 /bin/bash -l -c "cd $linuxDir/oasys-combined/gsa-assembler && ./update_release_version.sh -product $project -major $majorNumber -minor $minorNumber -build $buildNumber"

   c:\tools\msys64\usr\bin\env MSYSTEM=MINGW64 /bin/bash -l -c "cd $linuxDir/oasys-combined/gsa-assembler/$project-$majorNumber.$minorNumber && make clean all"
} catch {

}
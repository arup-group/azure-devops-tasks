
function ReadTaskArguments {

    $taskArgs = "" | Select-Object -Property `
        SourcesDirectory, RepoName, RepoPath, `
        ProjectParentPath, ProjectName

    $taskArgs.SourcesDirectory = Get-VstsTaskVariable -Name "Build.SourcesDirectory"
    $taskArgs.ProjectParentPath = Get-VstsInput -Name projectParentPath
    $taskArgs.RepoName = Get-VstsInput -Name repoName
    $taskArgs.ProjectName = Get-VstsInput -Name projectName

    $taskArgs.RepoPath = $taskArgs.SourcesDirectory + "\" + $taskArgs.RepoName

    If(!$taskArgs.ProjectParentPath.StartsWith($taskArgs.RepoPath) `
        -And !$taskArgs.ProjectParentPath.StartsWith("C:")) {
        $taskArgs.ProjectParentPath = "$($taskArgs.RepoPath)\$($taskArgs.ProjectParentPath)"
    }

    return $taskArgs
}

function ReadVersion {
    param ([Parameter()]$_)

    $fullVersion = Get-VstsInput -Name fullVersion

    If ($fullVersion -NotMatch '^\d.\d.\d.\d$') {
        Write-Error "The version requires four numbers, e.g. 1.2.3.4"
    }

    $splitVersion = $fullVersion.split('.')

    $version = "" | Select-Object -Property `
        Major, Minor, Patch, Build

    $version.Major = $splitVersion[0]
    $version.Minor = $splitVersion[1]
    $version.Patch = $splitVersion[2]
    $version.Build = $splitVersion[3]

    return $version
}

function GetInstallerInfo {
    param (
        [Parameter(Mandatory=$true)]
        [Object]$taskArgs,
        [Parameter(Mandatory=$true)]
        [Object]$version
    )

    $installerInfo = "" | Select-Object -Property `
        BuilderDirectory, TargetDirectory

    $installerInfo.BuilderDirectory = "$($taskArgs.RepoPath)\installer-builder"

    $appDirectory = "$($installerInfo.BuilderDirectory)\$($taskArgs.ProjectName.ToLower())" `
                    + "-$($version.Major).$($version.Minor)"

    $installerInfo.TargetDirectory = `
        "$($appDirectory)\TARGETDIR\Program Files\Oasys\$($taskArgs.ProjectName) $($version.Major).$($version.Minor)"

    return $installerInfo
}

function ClearInstallerDirectory {
    param (
        [Parameter(Mandatory=$true)]
        [string]$repoPath,
        [Parameter(Mandatory=$true)]
        [string]$installerDirectory
    )

    Push-Location
    try {
        Set-Location -Path $repoPath
        If (Test-Path -Path $installerDirectory -PathType Container) {
            Write-Host "Cleaning $installerDirectory"
            Get-ChildItem -Path $installerDirectory -Recurse | Remove-Item -force -recurse
            Remove-Item $installerDirectory -Force 
        }
    } finally {
        Pop-Location
    }
}

function CopyWindowsInstaller {
    param(
        [Parameter(Mandatory=$true)]
        [string]$sourcesDirectory,
        [Parameter(Mandatory=$true)]
        [string]$installerDirectory
    )

    Write-Host "Copying Installer"
    Copy-Item -Path $sourcesDirectory\oasys-windows-installer -Destination $installerDirectory -Recurse -Force
}

function BuildHelp {
    # param (
    #     [Parameter(Mandatory=$true)]
    #     [string]$sourcesDirectory,
    #     [Parameter(Mandatory=$true)]
    #     [string]$projectParentDirectory,
    #     [Parameter(Mandatory=$true)]
    #     [string]$projectName
    # )

    # $buildHelp = Get-VstsInput -Name buildHelp
    # $includePdf = Get-VstsInput -Name includePdf

    # $project = $projectName.ToLower()

    # $helpDirectory = "$projectParentDirectory\$project\help"
    # $helpFileOverride = Get-VstsInput -Name helpFileOverride -Default "$project.hmxp"

    # # Help and Manual Settings
    # $helpAndManualPath = "$sourcesDirectory\HelpAndManualMinimal"

    # # Project Paths
    # $skinPath = "$sourcesDirectory\oasys-helpandmanual-skin"
    # $outputPath = "$sourcesDirectory\output"

    # # Project Settings
    # $helpProject = $helpFileOverride
    # $skinFile = "Oasys.hmskin"
    # $logFile = "$project.log"
    # $projectVariables = "project_variables.txt"

    # # # CHM Settings
    # $chmFileName = "$projectName.chm"
    # $chmOptions = "PRODUCT_${project.toUpper()}"

    # # PDF Settings
    # $pdfFileName = "${installerProjectName}${major}.${minor}_Manual.pdf"
    # $pdfTemplate = "oasys_$project.mnl"

    # # HnM Executable
    # $hnmexe = "HELPMAN.EXE"

    # Set-Content -Path "$helpDirectory\project_variables.txt" `
    #     -Value "VERSION=$major.$minor`r`nPROGRAM=$projectName"

    # # Working directory
    # Write-Host "Building Help files"
    # $p=Start-Process "${helpAndManualPath}\${hnmexe}" -ArgumentList "$helpDirectory\$helpProject `
    #     /stdout /CHM=${outputPath}\${chmFileName} /O=${skinPath}\${skinFile} /I=CHM,${chmOptions} `
    #     /V=${helpDirectory}\${projectVariables} /PDF=${outputPath}\${pdfFileName} `
    #     /TEMPLATE=${helpDirectory}\${pdfTemplate} /V=${helpDirectory}\${projectVariables} `
    #     /L=${outputPath}\${logFile}" -Wait -PassThru
    # $p.WaitForExit()

    # Get-ChildItem -Filter *.chm -Path "$outputPath" -Recurse -Force | Copy-Item -Destination $targetDirectory
    # If ($includePdf -eq "yes") {
    #     Get-ChildItem -Filter *.pdf -Path "$outputPath" -Recurse -Force | Copy-Item -Destination "$targetDirectory\Docs"
    # }
}

function CopyDlls {
    param(
        [Parameter(Mandatory=$true)]
        [Object]$taskArgs,
        [Parameter(Mandatory=$true)]
        [string]$targetDirectory
    )

    $project = $taskArgs.ProjectName.ToLower()

    Write-Host "Copying DLLs"
    Get-Content "$($taskArgs.ProjectParentPath)\$project\build\programs64.txt" | `
        ForEach-Object {
            Copy-Item -Recurse -Path "$($taskArgs.ProjectParentPath)\programs64\$_" -Destination $targetDirectory
        }
}

function RunInstaller {
    param(
        [Parameter(Mandatory=$true)]
        [Object]$taskArgs,
        [Parameter(Mandatory=$true)]
        [Object]$version,
        [Parameter(Mandatory=$true)]
        [string]$installerDirectory
    )

    $clientId = Get-VstsInput -Name clientId
    $clientSecret = Get-VstsInput -Name clientSecret
    $project = $taskArgs.ProjectName.ToLower()

    Push-Location
    try {
        Write-Host "Running Installer"

        Set-Location $installerDirectory
        .\update_release_version.sh -product $project `
                                    -major $version.Major -minor $version.Minor `
                                    -sp $version.Patch -build $version.Build
        .\build_installer.sh -product $project `
                             -major $version.Major -minor $version.Minor `
                             -clientId $clientId -clientSecret $clientSecret
    } finally {
        Pop-Location
    }
}
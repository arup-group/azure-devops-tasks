[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
  [string]$projectDirectory = Get-VstsInput -Name projectDirectory
  [string]$exeName = Get-VstsInput -Name exeName
  $versionInfo = $(Get-Item $sourcesDirectory\oasys-combined\$projectDirectory\programs64\$exeName).VersionInfo
  $fullVersion = [array]$versionInfo.FileVersion.split('.')
  $currentTime = $(Get-Date -Format "dddd MM/dd/yyyy HH:mm")
  $majorVersion = [string]$fullVersion[0]
  $minorVersion = [string]$fullVersion[1]
  $spVersion = [string]$fullVersion[2]
  $buildNumber = [string]$fullVersion[3]
  $uppercase = $exeName.ToUpper()

  $tag = [array]@($uppercase,$majorVersion,$minorVersion,$spVersion,$buildNumber)
  $dotSeparatedTag = [system.String]::Join(".", $tag)
  $underscoreSeparatedTag = [system.String]::Join("_", $tag)

  Write-VstsSetVariable -Name CI_MAJOR_NUMBER -Value $majorVersion
  Write-VstsSetVariable -Name CI_MINOR_NUMBER -Value $minorVersion
  Write-VstsSetVariable -Name CI_SP_NUMBER -Value $spVersion
  Write-VstsSetVariable -Name CI_BUILD_NUMBER -Value $buildNumber
  Write-VstsSetVariable -Name CURRENT_DATE -Value $currentTime
  Write-VstsSetVariable -Name DOT_SEPARATED_TAG -Value $dotSeparatedTag
  Write-VstsSetVariable -Name UNDERSCORE_SEPARATED_TAG -Value $underscoreSeparatedTag
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}

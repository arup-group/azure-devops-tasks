[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
  [string]$projectName = Get-VstsInput -Name projectName
  [string]$tagExists = Get-VstsTaskVariable -Name TAG_EXISTS
  [string]$tagNumbersOnlyDot = Get-VstsTaskVariable -Name TAG_NUMBERS_ONLY_DOT
  [string]$underscoreSeparatedTag = Get-VstsTaskVariable -Name UNDERSCORE_SEPARATED_TAG
  [string]$buildId = Get-VstsTaskVariable -Name "Build.BuildId"
  [string]$webhook = Get-VstsInput -Name webhook
  $uriSlack = "https://hooks.slack.com/services/$webhook"
  $text = "Installers ready for $projectName version $tagNumbersOnlyDot -> https://github.com/arup-group/oasys-combined/releases"
  if($tagExists -eq "true"){$text = "Tag $underscoreSeparatedTag for $projectName already exists. Update RC files with FileVersion $tagNumbersOnlyDot. Build -> https://dev.azure.com/oasys-software/OASYS%20libraries/_build/results?buildId=$buildId"}
  $body = ConvertTo-Json @{text = $text}
  Invoke-RestMethod -uri $uriSlack -Method Post -body $body -ContentType 'application/json' | Out-Null
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}

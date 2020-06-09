[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
  [string]$projectName = Get-VstsInput -Name projectDirectory
  [string]$tagExists = Get-VstsTaskVariable -Name TAG_EXISTS
  [string]$tagNumbersOnlyDot = Get-VstsTaskVariable -Name TAG_NUMBERS_ONLY_DOT
  [string]$underscoreSeparatedTag = Get-VstsTaskVariable -Name UNDERSCORE_SEPARATED_TAG
  [string]$buildId = Get-VstsTaskVariable -Name Build.BuildId
  $uriSlack = "https://hooks.slack.com/services/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"
  $text = "Installers ready for $projectName version $tagNumbersOnlyDot -> https://github.com/arup-group/oasys-combined/releases"
  if($tagExists -eq "true"){$text = "Tag $underscoreSeparatedTag for slope exists. Update RC files. Build -> https://dev.azure.com/oasys-software/OASYS%20libraries/_build/results?buildId=$buildId"}
  $body = ConvertTo-Json @{text = $text}
  Invoke-RestMethod -uri $uriSlack -Method Post -body $body -ContentType 'application/json' | Out-Null
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}

[CmdletBinding()]
param()

. ./TaskFunctions.ps1

Trace-VstsEnteringInvocation $MyInvocation
try {
  $taskArgs = ReadTaskArguments
  $version = ReadVersion
  $installerInfo = GetInstallerInfo $taskArgs $version

  ClearInstallerDirectory $taskArgs.RepoPath $installerInfo.BuilderDirectory
  CopyWindowsInstaller $taskArgs.SourcesDirectory $installerInfo.BuilderDirectory

  BuildHelp # TODO

  CopyDlls $taskArgs $installerInfo.TargetDirectory
  RunInstaller $taskArgs $version $installerInfo.BuilderDirectory
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}
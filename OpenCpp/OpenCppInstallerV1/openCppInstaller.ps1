[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
  choco install opencppcoverage
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}
#Requires -Version 5.1
<# .SYNOPSIS
Reports the full directional DFSR backlog count from the cmdlet verbose stream.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$GroupName,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$FolderName,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$SourceComputerName,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DestinationComputerName
)
$ErrorActionPreference = 'Stop'
Import-Module DFSR -ErrorAction Stop
# The normal success output contains at most 100 records. Never count those.
$records = @(Get-DfsrBacklog -GroupName $GroupName -FolderName $FolderName -SourceComputerName $SourceComputerName -DestinationComputerName $DestinationComputerName -Verbose 4>&1)
$counts = @($records | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | ForEach-Object {
    if ($_.Message -match 'Count\s*:\s*(\d+)\s*\.?\s*$') { [long]$Matches[1] }
})
if ($counts.Count -ne 1) {
    throw 'No unambiguous backlog count was returned. This parser requires English DFSR verbose output (Count: N). Check the connection and run Get-DfsrBacklog -Verbose directly; do not assume zero.'
}
[pscustomobject]@{
    SourceComputerName = $SourceComputerName
    DestinationComputerName = $DestinationComputerName
    GroupName = $GroupName
    FolderName = $FolderName
    BacklogCount = $counts[0]
    CheckedAt = Get-Date
}

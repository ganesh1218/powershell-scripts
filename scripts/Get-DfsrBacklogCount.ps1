#Requires -Version 5.1
<# .SYNOPSIS
Checks every discovered replicated folder and reports its directional backlog.
.DESCRIPTION
By default discovers folders in all replication groups visible in the current
domain. Use GroupName and FolderName to narrow discovery. Each folder produces
a result, including an Error result when it cannot be checked for the pair.
#>
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()][string[]]$GroupName = @('*'),
    [ValidateNotNullOrEmpty()][string[]]$FolderName = @('*'),
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$SourceComputerName,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DestinationComputerName
)
$ErrorActionPreference = 'Stop'
Import-Module DFSR -ErrorAction Stop
$folders = @(Get-DfsReplicatedFolder -GroupName $GroupName -FolderName $FolderName -ErrorAction Stop |
    Sort-Object -Property GroupName, FolderName -Unique)
if ($folders.Count -eq 0) {
    throw 'No replicated folders matched. Check domain access and the group/folder filters.'
}
foreach ($folder in $folders) {
    $result = [ordered]@{
        SourceComputerName = $SourceComputerName
        DestinationComputerName = $DestinationComputerName
        GroupName = $folder.GroupName
        FolderName = $folder.FolderName
        BacklogCount = $null
        Status = 'Error'
        ErrorMessage = $null
        CheckedAt = Get-Date
    }
    try {
        # Success output lists at most 100 files. Never use its length as the count.
        $records = @(Get-DfsrBacklog -GroupName $folder.GroupName -FolderName $folder.FolderName -SourceComputerName $SourceComputerName -DestinationComputerName $DestinationComputerName -Verbose -ErrorAction Stop 4>&1)
        $counts = @($records | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | ForEach-Object {
            if ($_.Message -match 'Count\s*:\s*(\d+)\s*\.?\s*$') { [long]$Matches[1] }
        })
        if ($counts.Count -ne 1) {
            throw 'No unambiguous Count: N was returned. English DFSR verbose output is required; check Get-DfsrBacklog -Verbose directly. Missing output is not assumed to be zero.'
        }
        $result.BacklogCount = $counts[0]
        $result.Status = 'Success'
    } catch {
        $result.ErrorMessage = $_.Exception.Message
        Write-Warning ("{0}/{1}: {2}" -f $folder.GroupName, $folder.FolderName, $result.ErrorMessage)
    }
    [pscustomobject]$result
}

#Requires -Version 5.1
<# .SYNOPSIS
Reports C: capacity, used space and free space in binary GB/TB units.
#>
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()][string[]]$ComputerName = @('.'),
    [pscredential]$Credential
)
$ErrorActionPreference = 'Stop'
foreach ($computer in $ComputerName) {
    $session = $null
    try {
        $options = @{ ClassName = 'Win32_LogicalDisk'; Filter = "DeviceID='C:'" }
        if ($computer -notin @('.', 'localhost', $env:COMPUTERNAME)) {
            $connection = @{ ComputerName = $computer }
            if ($Credential) { $connection.Credential = $Credential }
            $session = New-CimSession @connection
            $options.CimSession = $session
        } elseif ($Credential) { throw 'Credential is supported only for remote targets.' }
        $disk = Get-CimInstance @options
        if (-not $disk -or $disk.Size -le 0) { throw 'C: was not found or its capacity is unavailable.' }
        [pscustomobject]@{
            ComputerName = $disk.SystemName
            Drive = 'C:'
            TotalGB = [math]::Round($disk.Size / 1GB, 2)
            UsedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
            FreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            TotalTB = [math]::Round($disk.Size / 1TB, 4)
            UsedTB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1TB, 4)
            FreeTB = [math]::Round($disk.FreeSpace / 1TB, 4)
            FreePercent = [math]::Round(100 * $disk.FreeSpace / $disk.Size, 2)
        }
    } catch {
        Write-Error -Message "${computer}: $($_.Exception.Message)" -ErrorAction Continue
    } finally {
        if ($session) { Remove-CimSession -CimSession $session }
    }
}

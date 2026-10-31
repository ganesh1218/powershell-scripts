#Requires -Version 5.1
<# .SYNOPSIS
Sets EnableLUA locally or through PowerShell remoting and optionally reboots.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][ValidateSet(0, 1)][int]$Value,
    [ValidateNotNullOrEmpty()][string]$ComputerName = '.',
    [pscredential]$Credential,
    [switch]$Restart
)
$ErrorActionPreference = 'Stop'
$operation = {
    param([int]$DesiredValue)
    $ErrorActionPreference = 'Stop'
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run from an elevated session with administrator rights on the target server.'
    }
    $path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    $previous = Get-ItemPropertyValue -LiteralPath $path -Name EnableLUA
    New-ItemProperty -LiteralPath $path -Name EnableLUA -PropertyType DWord -Value $DesiredValue -Force | Out-Null
    [pscustomobject]@{ ComputerName = $env:COMPUTERNAME; PreviousValue = $previous; EnableLUA = $DesiredValue; RestartRequired = $true }
}
$action = "Set EnableLUA to $Value (0 disables UAC; 1 enables UAC)"
if ($Restart) { $action += ' and immediately reboot the server' }
if ($PSCmdlet.ShouldProcess($ComputerName, $action)) {
    $local = $ComputerName -in @('.', 'localhost', $env:COMPUTERNAME)
    if ($local) {
        if ($Credential) { throw 'Credential is supported only for remote targets.' }
        & $operation $Value
        if ($Restart) { Restart-Computer -Force -Confirm:$false }
    } else {
        $session = $null
        try {
            $options = @{ ComputerName = $ComputerName }
            if ($Credential) { $options.Credential = $Credential }
            $session = New-PSSession @options
            Invoke-Command -Session $session -ScriptBlock $operation -ArgumentList $Value
            if ($Restart) { Invoke-Command -Session $session -ScriptBlock { Restart-Computer -Force -Confirm:$false } }
        } finally {
            if ($session) { Remove-PSSession -Session $session }
        }
    }
}

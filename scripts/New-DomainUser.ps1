#Requires -Version 5.1
<# .SYNOPSIS
Creates an enabled AD user with a securely supplied password.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Name,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$SamAccountName,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$UserPrincipalName,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path,
    [Parameter(Mandatory)][securestring]$AccountPassword,
    [string]$Server
)
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory -ErrorAction Stop
$options = @{}
if ($Server) { $options.Server = $Server }
if ($PSCmdlet.ShouldProcess("$SamAccountName in $Path", 'Create enabled AD user')) {
    New-ADUser -Name $Name -SamAccountName $SamAccountName -UserPrincipalName $UserPrincipalName -Path $Path -AccountPassword $AccountPassword -Enabled $true -ChangePasswordAtLogon $true -PassThru @options
}

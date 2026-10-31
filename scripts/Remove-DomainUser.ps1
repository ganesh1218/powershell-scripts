#Requires -Version 5.1
<# .SYNOPSIS
Permanently deletes one AD user after resolving its identity.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Identity,
    [string]$Server
)
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory -ErrorAction Stop
$options = @{}
if ($Server) { $options.Server = $Server }
$user = Get-ADUser -Identity $Identity @options
if ($PSCmdlet.ShouldProcess($user.DistinguishedName, 'Permanently delete AD user')) {
    Remove-ADUser -Identity $user.ObjectGUID -Confirm:$false @options
}

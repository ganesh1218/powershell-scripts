#Requires -Version 5.1
<# .SYNOPSIS
Creates an AD security or distribution group in the specified OU.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Name,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$SamAccountName,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path,
    [ValidateSet('Global', 'DomainLocal', 'Universal')][string]$GroupScope = 'Global',
    [ValidateSet('Security', 'Distribution')][string]$GroupCategory = 'Security',
    [string]$Description,
    [string]$Server
)
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory -ErrorAction Stop
$options = @{}
if ($Server) { $options.Server = $Server }
if ($Description) { $options.Description = $Description }
if ($PSCmdlet.ShouldProcess("$Name in $Path", 'Create AD group')) {
    New-ADGroup -Name $Name -SamAccountName $SamAccountName -Path $Path -GroupScope $GroupScope -GroupCategory $GroupCategory -PassThru @options
}

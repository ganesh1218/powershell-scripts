# PowerShell administration scripts

Six standalone scripts for Windows PowerShell 5.1. Run commands below from the repository root. Replace the example domains, OUs and server names with your own values.

## Requirements

- Windows PowerShell 5.1 on Windows. AD and DFSR modules are Windows management components; PowerShell 7 compatibility is not validated.
- AD scripts: RSAT Active Directory PowerShell module, connectivity to a domain controller and delegated rights for the target OU. Use `-Server dc01.contoso.com` to select a domain controller. Existing users/groups cause an error; scripts do not overwrite them.
- DFSR script: DFS Replication management tools (`DFSR` module), domain access for folder discovery, and access to both replication members.
- Remote server scripts: WinRM configured, firewall access and target permissions. EnableLUA requires an administrator session; elevate PowerShell for local changes. Optional `-Credential (Get-Credential)` is supported for remote targets.
- No passwords are stored in the repository. Follow your organization's execution policy and script signing requirements.

## 1. Create an AD user

```powershell
$password = Read-Host 'Temporary password' -AsSecureString
.\scripts\New-DomainUser.ps1 -Name 'Jane Doe' -SamAccountName 'jdoe' -UserPrincipalName 'jdoe@contoso.com' -Path 'OU=Users,DC=contoso,DC=com' -AccountPassword $password -WhatIf
# Remove -WhatIf to create the account.
```

The account is enabled and must change its password at first logon. The password must meet domain policy.

## 2. Delete an AD user

```powershell
.\scripts\Remove-DomainUser.ps1 -Identity 'jdoe' -WhatIf
.\scripts\Remove-DomainUser.ps1 -Identity 'jdoe'
```

Identity accepts a SAM account name, distinguished name, GUID or SID. The script resolves the user and displays its distinguished name in the confirmation. Deletion is permanent unless your AD recovery configuration permits restoration. It does not remove home folders, mailboxes or other external resources.

## 3. Create an AD group

```powershell
.\scripts\New-DomainGroup.ps1 -Name 'Finance Readers' -SamAccountName 'FinanceReaders' -Path 'OU=Groups,DC=contoso,DC=com' -GroupScope Global -GroupCategory Security -WhatIf
```

Remove `-WhatIf` to create it. Scope can be `Global`, `DomainLocal` or `Universal`; category can be `Security` or `Distribution`.

## 4. Check DFSR backlog

```powershell
# All replicated folders across all groups visible in the current domain:
.\scripts\Get-DfsrBacklogCount.ps1 -SourceComputerName 'FS01' -DestinationComputerName 'FS02' | Format-Table GroupName,FolderName,BacklogCount,Status,ErrorMessage -AutoSize
# All folders in one group:
.\scripts\Get-DfsrBacklogCount.ps1 -GroupName 'DataReplication' -SourceComputerName 'FS01' -DestinationComputerName 'FS02'
# Optional folder filter (also supports wildcards):
.\scripts\Get-DfsrBacklogCount.ps1 -GroupName 'DataReplication' -FolderName 'Shared*' -SourceComputerName 'FS01' -DestinationComputerName 'FS02'
```

The script discovers replicated folders with `Get-DfsReplicatedFolder` and checks each separately for the specified server pair. Group and folder filters default to `*`. Discovery covers the current domain's configured groups; folders where this pair is not participating or cannot be queried produce an `Error` row. It does not discover other server pairs or automatically check both directions. Swap source and destination to check the reverse direction.

Each folder returns a row with group, folder, backlog count, status, error message and timestamp. One folder's failure does not stop the remaining checks; discovery failures and no matching folders terminate the script. Always inspect `Status`: an error row has a null count, not zero. Normal `Get-DfsrBacklog` output is limited to 100 entries, so the script extracts the full `Count: N` from English verbose output. Missing, ambiguous, localized or unrecognized zero-backlog messages produce an error row. Run the underlying cmdlet directly to diagnose such cases.

## 5. Update EnableLUA and reboot

```powershell
.\scripts\Set-ServerEnableLUA.ps1 -ComputerName 'SRV01' -Value 1 -Restart -WhatIf
.\scripts\Set-ServerEnableLUA.ps1 -ComputerName 'SRV01' -Value 1 -Restart
# Local server, change now and reboot later:
.\scripts\Set-ServerEnableLUA.ps1 -Value 1
```

`1` enables UAC and `0` disables it. Disabling UAC reduces protection. A restart is required for the policy change to take effect. `-Restart` performs an immediate forced reboot after the write succeeds and can discard unsaved work; schedule it during a maintenance window. Omitting it leaves reboot scheduling to you. The confirmation covers both the write and reboot. Remoting may disconnect as the server restarts; the script does not wait for it to return. Group Policy may reapply the managed setting. Output includes the previous value for rollback; rerun with that value and reboot to restore it.

## 6. Check C: space in GB/TB

```powershell
.\scripts\Get-ServerCDriveSpace.ps1
.\scripts\Get-ServerCDriveSpace.ps1 -ComputerName 'SRV01','SRV02' | Format-Table
.\scripts\Get-ServerCDriveSpace.ps1 -ComputerName 'SRV01','SRV02' | Export-Csv -Path '.\space.csv' -NoTypeInformation
```

Returns total, used and free space in both units plus free percentage. PowerShell `1GB` and `1TB` use binary units (GiB/TiB). Remote failures are written to the error stream while other servers continue; a failed server has no success row, so check errors before treating a report as complete.

## Validation and Git

All scripts are syntax checked with Windows PowerShell 5.1. AD/DFSR operations and registry/reboot changes require validation in a lab with your infrastructure. Creating this repository does not execute administrative changes.

This is a local Git repository on `main`. To publish it later, create an empty remote repository and run:

```powershell
git remote add origin https://github.com/YOUR-ACCOUNT/powershell-admin-scripts.git
git push -u origin main
```

## References

- [Microsoft: Get-DfsrBacklog](https://learn.microsoft.com/en-us/powershell/module/dfsr/get-dfsrbacklog)
- [Microsoft: Get-DfsReplicatedFolder](https://learn.microsoft.com/en-us/powershell/module/dfsr/get-dfsreplicatedfolder)
- [Microsoft: UAC configuration and EnableLUA](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/user-account-control/settings-and-configuration)

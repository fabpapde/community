# Remove Veeam Backup Proxy from All Jobs

## Description

This PowerShell script removes a specified VMware backup proxy from every Veeam Backup & Replication job it is currently assigned to. Useful when decommissioning a proxy or before removing it from the Veeam infrastructure entirely.

## Requirements

- Veeam Backup & Replication PowerShell module (`Veeam.Backup.PowerShell`), typically loaded automatically when run from the Veeam PowerShell console
- Sufficient permissions to read jobs and modify proxy assignments

## Configuration

Set the `$proxyName` variable at the top of the script to the exact name (or IP address) of the proxy to remove:

```powershell
$proxyName = "<proxy-name-or-ip>"
```

## What It Does

1. Looks up the proxy object via `Get-VBRViProxy`
2. Retrieves all backup jobs via `Get-VBRJob`
3. For each job, checks whether the target proxy is assigned
4. If assigned, removes it from the job's proxy list and applies the updated configuration via `Set-VBRJobProxy`
5. Jobs that don't use the proxy are skipped

## Usage

```powershell
.\Remove-VeeamProxyFromJobs.ps1
```

Run from a PowerShell session with the Veeam module loaded (e.g. the Veeam PowerShell Console), on the Veeam Backup Server or a machine with the Veeam Console installed.

## Notes

- This script only removes the proxy from job assignments — it does **not** delete the proxy object itself from the Veeam infrastructure.
- If the proxy is not found, the script stops with an error.
- Output is printed per job, indicating whether the proxy was removed or the job was skipped.

# Name of the proxy to remove
$proxyName = "<The exact name, as well as whether the proxy is integrated with Veeam. This can also be an IP address>"

# Retrieve the proxy object using Get-VBRViProxy (for VMware proxies)
$proxyToRemove = Get-VBRViProxy -Name $proxyName

if (-not $proxyToRemove) {
    Write-Error "Proxy with name '$proxyName' not found."
    return
}

# Retrieve all backup jobs
$jobs = Get-VBRJob

foreach ($job in $jobs) {
    # Get all currently assigned proxies for this job (source proxies)
    $currentProxies = Get-VBRJobProxy -Job $job

    # Filter the proxy list to remove the one we do not want
    $newProxies = $currentProxies | Where-Object { $_.Name -ne $proxyName }

    # If the proxy to remove is not part of this job, skip it
    if ($newProxies.Count -eq $currentProxies.Count) {
        Write-Host "Proxy '$proxyName' is not configured in job '$($job.Name)', skipping."
        continue
    }

    # Apply the new proxy configuration (without the proxy to remove)
    Set-VBRJobProxy -Job $job -Proxy $newProxies

    Write-Host "Proxy '$proxyName' removed from job '$($job.Name)'."
}

<#
.SYNOPSIS
    Get Proxy Settings for use in YDisk functions
.DESCRIPTION
    Get Proxy Settings for use in YDisk functions
.OUTPUTS
    Proxy settings as PSObject
.NOTES
    Author: Max Kozlov
.LINK
    Set-YDiskProxySetting
#>
function Get-YDiskProxySetting {
[CmdletBinding()]
param(
)
    [PSCustomObject]@{
        Proxy = if ($YDiskProxySettings.Proxy) { $YDiskProxySettings.Proxy } else { $null }
        ProxyCredential = if ($YDiskProxySettings.ProxyCredential) { $YDiskProxySettings.ProxyCredential } else { $null }
        ProxyUseDefaultCredentials = if ($YDiskProxySettings.ProxyUseDefaultCredentials) { $YDiskProxySettings.ProxyUseDefaultCredentials } else { $null }
    }
}

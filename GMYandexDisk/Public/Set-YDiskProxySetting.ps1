<#
.SYNOPSIS
    Set Proxy Settings for use in YDisk functions
.DESCRIPTION
    Set Proxy Settings for use in YDisk functions
    Request-YDiskAuthorizationCode does not use this settings because it IE based
.EXAMPLE
    # Set Proxy
    Set-YDiskProxySetting -Proxy http://mycorpproxy.mydomain
.EXAMPLE
    # Remove Proxy
    Set-YDiskProxySetting -Proxy ''
.OUTPUTS
    None
.NOTES
    Author: Max Kozlov
.LINK
    Get-YDiskProxySetting
#>
function Set-YDiskProxySetting {
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(ValueFromPipelineByPropertyName)]
    [Uri]$Proxy,
    [Parameter(ValueFromPipelineByPropertyName)]
    [PSCredential]$ProxyCredential,
    [Parameter(ValueFromPipelineByPropertyName)]
    [switch]$ProxyUseDefaultCredentials
)
    BEGIN {
    }
    PROCESS {
    }
    END {
        if ($PSCmdlet.ShouldProcess("Set New Proxy settings")) {
            if ($Proxy -and $Proxy.IsAbsoluteUri) {
                $YDiskProxySettings.Proxy = $Proxy
            }
            else {
                if ($Proxy.OriginalString) {
                       Write-Error 'Invalid proxy URI, may be you forget http:// prefix ?'
                }
                else {
                    [void]$YDiskProxySettings.Remove('Proxy')
                }
            }
            if ($ProxyCredential) {
                $YDiskProxySettings.ProxyCredential = $ProxyCredential
            }
            else {
                [void]$YDiskProxySettings.Remove('ProxyCredential')
            }
            if ($ProxyUseDefaultCredentials) {
                $YDiskProxySettings.ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials
            }
            else {
                [void]$YDiskProxySettings.Remove('ProxyUseDefaultCredentials')
            }
        }
    }
}

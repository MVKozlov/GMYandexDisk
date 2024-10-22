<#
.SYNOPSIS
    Get Yandex Disk Summary information
.DESCRIPTION
    Get Yandex Disk Summary information
    The API returns general information about the user's Yandex Disk: the available space, system folder paths, and so on.
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Get-YDiskSummary -AccessToken $access_token
.OUTPUTS
    Json with summary metadata as PSObject
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/capacity
#>
function Get-YDiskSummary {
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$AccessToken
)
    $Headers = @{
        "Authorization" = "OAuth $AccessToken"
    }
    $requestParams = @{
        Uri = $YDiskUri
        Headers = $Headers
        ContentType = "application/json; charset=utf-8"
    }
    Write-Verbose "URI: $YDiskUri"
    Invoke-RestMethod @requestParams -Method Get @YDiskProxySettings
}

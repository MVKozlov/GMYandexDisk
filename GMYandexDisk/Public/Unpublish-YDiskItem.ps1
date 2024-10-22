<#
.SYNOPSIS
    Restrict access to published file or folder stored on Yandex Disk
.DESCRIPTION
    Restrict access to published file or folder stored on Yandex Disk
    The resource loses the public_key and public_url attributes, and the public links to it stop working
.PARAMETER Path
    The path to the resource being unpublished
    For example, /bar/photo.png
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Unpublish-YDiskItem -AccessToken $access_token -Path '/file.txt'
.OUTPUTS
    Json with item metadata as PSObject
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/publish#unpublish-q
#>
function Unpublish-YDiskItem {
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position=0)]
    [ValidateLength(1, 32760)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string]$AccessToken
)
    $Headers = @{
        "Authorization" = "OAuth $AccessToken"
    }
    $Uri = '{0}/resources/unpublish?path={1}' -f $YDiskUri, $Path
    Write-Verbose "URI: $Uri"
    $requestParams = @{
        Uri = $Uri
        Headers = $Headers
        ContentType = "application/json; charset=utf-8"
    }
    $res = Invoke-RestMethod @requestParams -Method Put @YDiskProxySettings
    if ($res -and $res.href) {
        Invoke-RestMethod -Uri $res.href -Headers $Headers
    }
    else {
        $res
    }
}

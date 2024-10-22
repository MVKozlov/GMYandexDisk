<#
.SYNOPSIS
    Publish a file or folder stored on Yandex Disk by generating a link that gives other users access to them.
.DESCRIPTION
    Publish a file or folder stored on Yandex Disk by generating a link that gives other users access to them.
    Access to previously published resources can be revoked.
    A published resource gets two new attributes:
        public_key — The key of the published resource. Other apps can use this key to get the published resource's meta information.
        public_url — The public link to the resource in the format https://yadi.sk/.... With the link, users can open the published folder or download the file.
    When the owner restricts access to the resource, these attributes are removed.
.PARAMETER Path
    The path to the resource being published
    For example, /bar/photo.png
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Publish-YDiskItem -AccessToken $access_token -Path '/file.txt'
.OUTPUTS
    Json with item metadata as PSObject
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/publish
#>
function Publish-YDiskItem {
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
    $Uri = '{0}/resources/publish?path={1}' -f $YDiskUri, $Path
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

<#
.SYNOPSIS
    Download a resource published on Yandex Disk.
.DESCRIPTION
    Download a resource published on Yandex Disk.
    You can also use this operation to download individual files from public folders.
.PARAMETER Public_Key
    The key of a published resource or a public link to a resource.
.PARAMETER Path
    Relative path to the resource in the public folder started with "/"
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Get-YDiskPublishedItem -AccessToken $access_token -Public_Url 'https://yadi.sk/i/file123456'
.EXAMPLE
    Get-YDiskPublishedItem -AccessToken $access_token -Public_Url 'https://yadi.sk/i/dir123456' -Path /filename -Outfile d:\111
.OUTPUTS
    File content or nothing if output saved to file
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/public#download
#>
function Get-YDiskPublishedItem {
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position=0)]
    [Alias('Public_Url')]
    [string]$Public_Key,

    [Parameter(Position=1)]
    [ValidateLength(1, 32760)]
    [string]$Path,

    [string]$OutFile
)
    $Uri = '{0}/public/resources/download?public_key={1}' -f $YDiskUri, [uri]::EscapeDataString($Public_Key)
    if ($Path) {
        $Uri += '&path={0}' -f $Path
    }
    $requestParams = @{
        Uri = $Uri
        ContentType = "application/json; charset=utf-8"
    }
    Write-Verbose "URI: $Uri"
    $res = Invoke-RestMethod @requestParams -Method Get @YDiskProxySettings
    if ($res -and $res.href) {
        if ($OutFile) {
            Invoke-WebRequest -Uri $res.href -Method Get @YDiskProxySettings -OutFile $OutFile
        }
        else {
            Invoke-WebRequest -Uri $res.href -Method Get @YDiskProxySettings | Select-Object -ExpandProperty Content
        }
    }
}

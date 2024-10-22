<#
.SYNOPSIS
    Get meta information of Yandex Disk resource (the file properties or the folder properties).
.DESCRIPTION
    Get meta information of Yandex Disk resource (the file properties or the folder properties).
.PARAMETER Public_Key
    The key of a published resource or a public link to a resource.
.PARAMETER Path
    Relative path to the resource in the public folder stared with "/"
.PARAMETER Property
    Properties to return
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    # Get info about file in published file/folder
    Get-YDiskPublishedItemProperty -AccessToken $access_token -Public_Url 'https://yadi.sk/i/test123456' -Property type, name, created
.EXAMPLE
    # Get info about file in published folder
    Get-YDiskPublishedItemProperty -AccessToken $access_token -Public_Url 'https://yadi.sk/i/test123456' -Path /filename
.OUTPUTS
    Json with item metadata as PSObject
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/public#meta
#>
function Get-YDiskPublishedItemProperty {
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position=0)]
    [Alias('Public_Url')]
    [string]$Public_Key,

    [Parameter(Position=1)]
    [ValidateLength(1, 32760)]
    [string]$Path,

    [ValidateSet(
        '*',
        'antivirus_status',
        'public_key',
        'public_url',
        'views_count',
        'exif',
        'created',
        'modified',
        'type',
        'resource_id',
        'size',
        'custom_properties',
        'comment_ids',
        'comment_ids.private_resource',
        'comment_ids.public_resource',
        'mime_type',
        'file',
        'path',
        'origin_path',
        'owner',
        'owner.login',
        'owner.display_name',
        'owner.uid',
        'media_type',
        'sha256',
        'revision',
        'md5',
        'name'
    )]
    [Parameter(Position=2)]
    [Alias('Metadata')]
    [string[]]$Property = @()
)
    $Uri = '{0}/public/resources?public_key={1}' -f $YDiskUri, [uri]::EscapeDataString($Public_Key)
    if ($Path) {
        $Uri += '&path={0}' -f $Path
    }
    if ($Property -contains "*") {
        $Property = "*"
    }
    if ($Property) {
        $Uri += '&fields={0}' -f ($Property -join ',')
    }
    Write-Verbose "URI: $Uri"
    $requestParams = @{
        Uri = $Uri
        ContentType = "application/json; charset=utf-8"
    }
    Invoke-RestMethod @requestParams -Method Get @YDiskProxySettings
}

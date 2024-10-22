<#
.SYNOPSIS
    Get Yandex Disk published folder content
.DESCRIPTION
    Get Yandex Disk published folder content
.PARAMETER Property
    List of JSON properties to include in the response.
    Keys not specified in this list are omitted when generating a response.
    If the parameter isn't specified, the response is returned in full without omitting anything.
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Get-YDiskPublishedChildItem -AccessToken $access_token -Property path, created
.OUTPUTS
    Json with item list metadata as PSObject
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/public#meta
#>
function Get-YDiskPublishedChildItem {
[CmdletBinding()]
param(
    [Alias('Public_Url')]
    [string]$Public_Key,

    <#
    type (file|dir)
    name
    path
    created
    modified
    resource_id
    comment_ids
        private_resource
        public_resource
    share
        is_root
        is_owned
        rights
    exif
    revision

    (file:)
    antivirus_status
    size
    mime_type
    file # download url https://downloader.disk.yandex.ru/disk/....
    media_type # https://yandex.ru/dev/disk-api/doc/ru/reference/all-files
    sha256
    md5
    preview # "https://downloader.disk.yandex.ru/preview/..."

    (dir:)
    _embedded
        sort
        limit
        offset
        path
        total
        items[]
    #>
    [ValidateSet(
        '*',
        'type',
        'name',
        'path',
        'created',
        'modified',
        'resource_id',
        'custom_properties',
        'comment_ids',
        'comment_ids.private_resource',
        'comment_ids.public_resource',
        'share',
        'share.is_root',
        'share.is_owned',
        'share.rights',
        'exif',
        'revision',
        'public_key',
        'public_url',
        'antivirus_status',
        'size',
        'mime_type',
        'file',
        'media_type',
        'sha256',
        'md5',
        'preview'
    )]
    [Parameter(Position=1)]
    [Alias('Metadata')]
    [string[]]$Property = @()
)
    $offset = 0
    $total = 0
    $files = New-Object System.Collections.ArrayList
    do {
        $Uri = '{0}/public/resources?public_key={1}' -f $YDiskUri, $Public_Key
        if ($Property -contains "*") {
            $Property = "*"
        }
        if ($Property) {
            $Uri += '&fields=_embedded.offset,_embedded.limit,_embedded.items.{0}' -f ($Property -join ',_embedded.items.')
        }
        Write-Verbose "URI: $Uri"
        $requestParams = @{
            Uri = $Uri
            ContentType = "application/json; charset=utf-8"
        }
        $result = Invoke-RestMethod @requestParams -Method Get @YDiskProxySettings
        if (-not $result -or -not $result._embedded) {
            break;
        }
        if ($result._embedded.items) {
            $files.AddRange($result._embedded.items)
        }
        $offset += $result._embedded.limit
        $total = $result._embedded.total
    } while ($offset -lt $total )
    $files
}

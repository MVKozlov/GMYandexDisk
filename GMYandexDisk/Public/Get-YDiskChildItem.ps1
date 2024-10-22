<#
.SYNOPSIS
    Get Yandex Disk folder content
.DESCRIPTION
    Get Yandex Disk folder content
.PARAMETER Path
    The path to the resource relative to the Yandex Disk root directory
.PARAMETER Property
    List of JSON properties to include in the response.
    Keys not specified in this list are omitted when generating a response.
    If the parameter isn't specified, the response is returned in full without omitting anything.
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Get-YDiskChildItem -AccessToken $access_token -Path '/foldername' -Property path, created
.OUTPUTS
    Json with item list metadata as PSObject
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/meta
#>
function Get-YDiskChildItem {
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position=0)]
    [ValidateLength(1, 32760)]
    [string]$Path,

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
    [string[]]$Property = @(),

    [Parameter(Mandatory)]
    [string]$AccessToken
)
    $Headers = @{
        "Authorization" = "OAuth $AccessToken"
    }
    if ($Property -contains "*") {
        $Property = "*"
    }
    $offset = 0
    $total = 0
    $files = New-Object System.Collections.ArrayList
    do {
        $Uri = '{0}/resources?path={1}&limit=100&offset={2}' -f $YDiskUri, $Path, $offset
        if ($Property) {
            $Uri += '&fields=_embedded.offset,_embedded.limit,_embedded.items.{0}' -f ($Property -join ',_embedded.items.')
        }
        Write-Verbose "URI: $Uri"
        $requestParams = @{
            Uri = $Uri
            Headers = $Headers
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

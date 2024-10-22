<#
.SYNOPSIS
    Get a list of resources published on the user's Yandex Disk. Resources in the list are sorted in order of publishing, from latest to earliest.
.DESCRIPTION
    Get a list of resources published on the user's Yandex Disk. Resources in the list are sorted in order of publishing, from latest to earliest.
    The list can be filtered by resource type to get only files or folders.
.PARAMETER ResourceType
    Resource type,
    file or folder
.PARAMETER Property
    List of JSON properties to include in the response.
    Keys not specified in this list are omitted when generating a response.
    If the parameter isn't specified, the response is returned in full without omitting anything.
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Get-YDiskPublishedItemList -AccessToken $access_token -ResourceType dir
.EXAMPLE
    Get-YDiskPublishedItemList -AccessToken $access_token -Property name, public_key, public_url
.OUTPUTS
    Json with item list metadata as PSObject
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/recent-public
#>
function Get-YDiskPublishedItemList {
[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet('dir', 'file')]
    [string]$ResourceType,

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
        $Uri = '{0}/resources/public?type={1}&limit=100&offset={2}' -f $YDiskUri, $ResourceType, $offset
        if ($Property) {
            $Uri += '&fields=offset,limit,items.{0}' -f ($Property -join ',items.')
        }
        Write-Verbose "URI: $Uri"
        $requestParams = @{
            Uri = $Uri
            Headers = $Headers
            ContentType = "application/json; charset=utf-8"
        }
        $result = Invoke-RestMethod @requestParams -Method Get @YDiskProxySettings
        if (-not $result -or -not $result.items) {
            break;
        }
        $files.AddRange($result.items)
        $offset += $result.limit
        $total = $result.total
    } while ($offset -lt $total )
    $files
}

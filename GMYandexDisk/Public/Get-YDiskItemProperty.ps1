<#
.SYNOPSIS
    Get Yandex Disk file and folder meta information
.DESCRIPTION
    Get Yandex Disk file and folder meta information (properties)
.PARAMETER Path
    The path to the resource relative to the Yandex Disk root directory
.PARAMETER Property
    List of JSON properties to include in the response.
    Keys not specified in this list are omitted when generating a response.
    If the parameter isn't specified, the response is returned in full without omitting anything.
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Get-YDiskItemProperty -AccessToken $access_token -Path '/' -Property path, created
.OUTPUTS
    Json with item metadata as PSObject
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/meta
#>
function Get-YDiskItemProperty {
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
    $Uri = '{0}/resources?path={1}&limit=0' -f $YDiskUri, $Path
    if ($Property -contains "*") {
        $Property = "*"
    }
    if ($Property) {
        $Uri += '&fields={0}' -f ($Property -join ',')
    }
    Write-Verbose "URI: $Uri"
    $requestParams = @{
        Uri = $Uri
        Headers = $Headers
        ContentType = "application/json; charset=utf-8"
    }
    Invoke-RestMethod @requestParams -Method Get @YDiskProxySettings
}

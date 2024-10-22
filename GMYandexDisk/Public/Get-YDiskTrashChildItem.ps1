<#
.SYNOPSIS
    Get Yandex Disk trash folder content
.DESCRIPTION
    Get Yandex Disk trash folder content
.PARAMETER Path
    The path to the resource relative to the Yandex Disk trash root directory
    Shows root content if empty
.PARAMETER Property
    List of JSON properties to include in the response.
    Keys not specified in this list are omitted when generating a response.
    If the parameter isn't specified, the response is returned in full without omitting anything.
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Get-YDiskTrashChildItem -AccessToken $access_token -Path '/foldername' -Property path, deleted
.OUTPUTS
    Json with item list metadata as PSObject
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/meta
#>
function Get-YDiskTrashChildItem {
[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Path,
    [ValidateSet(
        '*',
        'type',
        'name',
        'path',
        'created',
        'modified',
        'deleted',
        'origin_path',
        'resource_id',
        'custom_properties',
        'comment_ids',
        'comment_ids.private_resource',
        'comment_ids.public_resource',
        'exif',
        'revision',
        'antivirus_status',
        'size',
        'mime_type',
        'file',
        'media_type',
        'sha256',
        'md5'
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
        $Uri = '{0}/trash/resources?path={1}&limit=100&offset={2}' -f $YDiskUri, $Path, $offset
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

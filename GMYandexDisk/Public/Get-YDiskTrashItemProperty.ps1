<#
.SYNOPSIS
    Get Yandex Disk trashed file and folder meta information
.DESCRIPTION
    Get Yandex Disk trashed file and folder meta information (properties)
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
function Get-YDiskTrashItemProperty {
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position=0)]
    [ValidateLength(1, 32760)]
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
    $Uri = '{0}/trash/resources?path={1}&limit=0' -f $YDiskUri, $Path
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

<#
.SYNOPSIS
    Create new folder on Yandex Disk
.DESCRIPTION
    Create new folder on Yandex Disk
.PARAMETER Path
    The path to the folder being created
    For example, to create a Music folder in the Yandex Disk root directory, set the parameter value to /Music
    The maximum folder name length is 255 characters
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    New-YDiskFolder -Path '/foldername' -AccessToken $access_token
.OUTPUTS
    Json with href and operation status
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/create-folder
#>
function New-YDiskFolder {
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
    $Uri = '{0}/resources?path={1}' -f $YDiskUri, $Path
    $requestParams = @{
        Uri = $Uri
        Headers = $Headers
        ContentType = "application/json; charset=utf-8"
    }
    Write-Verbose "URI: $Uri"
    Invoke-RestMethod @requestParams -Method Put @YDiskProxySettings
}

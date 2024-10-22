<#
.SYNOPSIS
    Download a file from Yandex Disk as file or raw content
.DESCRIPTION
    Download a file from Yandex Disk as file or raw content
.PARAMETER Path
    The path to the file being downloaded
    For example, /bar/photo.png
.PARAMETER OutFile
    Path to the file to which the contents should be written
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Get-YDiskItem -AccessToken $access_token -Path '/filename'
.EXAMPLE
    Get-YDiskItem -AccessToken $access_token -Path '/filename' -OutFile "C:\temp\filename"
.OUTPUTS
    File content or nothing if output saved to file
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/content
#>
function Get-YDiskItem {
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position=0)]
    [ValidateLength(1, 32760)]
    [string]$Path,
    [string]$OutFile,
    [Parameter(Mandatory)]
    [string]$AccessToken
)
    $Headers = @{
        "Authorization" = "OAuth $AccessToken"
    }
    $Uri = '{0}/resources/download?path={1}' -f $YDiskUri, $Path
    $requestParams = @{
        Uri = $Uri
        Headers = $Headers
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

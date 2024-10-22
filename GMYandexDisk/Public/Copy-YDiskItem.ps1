<#
.SYNOPSIS
    Copy a file or folder on Yandex Disk
.DESCRIPTION
    Copy a file or folder on Yandex Disk
.PARAMETER Path
    The path to the resource being copied
    For example, /foo/photo.png
.PARAMETER TargetPath
    The path to the resource copy being created
    For example, /bar/photo.png
.PARAMETER Overwrite
    File overwrite flag. Used if the file is uploaded to a folder that already contains a file with the same name.
.PARAMETER Async
    Do not wait for the process to complete
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Copy-YDiskItem -AccessToken $access_token -Path '/file1.txt' -TargetPath '/file2.txt'
.EXAMPLE
    Copy-YDiskItem -AccessToken $access_token -Path '/folder' -TargetPath '/folder2' -Overwrite
.OUTPUTS
    Json with href and operation status
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/copy
#>
function Copy-YDiskItem {
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position=0)]
    [ValidateLength(1, 32760)]
    [Alias('SourcePath')]
    [string]$Path,

    [Parameter(Mandatory, Position=1)]
    [ValidateLength(1, 32760)]
    [string]$TargetPath,

    [switch]$Overwrite,
    [switch]$Async,

    [Parameter(Mandatory)]
    [string]$AccessToken
)
    $Headers = @{
        "Authorization" = "OAuth $AccessToken"
    }
    $Uri = '{0}/resources/copy?from={1}&path={2}&overwrite={3}' -f $YDiskUri, $Path, $TargetPath, $Overwrite.ToString().ToLower()
    $requestParams = @{
        Uri = $Uri
        Headers = $Headers
        ContentType = "application/json; charset=utf-8"
    }
    Write-Verbose "URI: $Uri"
    try {
        $res = Invoke-WebRequest @requestParams -Method Post @YDiskProxySettings -ErrorAction Stop
        if ($res.StatusCode -eq 202 -and -Not $Async) {
            $json = $res.Content | ConvertFrom-Json
            $status = Wait-YDiskOperation -AccessToken $AccessToken -OperationUri $json.href
            $json | Add-Member -MemberType NoteProperty -Name status -Value $status -PassThru
        }
        else {
            $res.Content | ConvertFrom-Json
        }
    }
    catch {
        throw
    }
}

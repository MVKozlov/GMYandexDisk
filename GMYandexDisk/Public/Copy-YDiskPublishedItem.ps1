<#
.SYNOPSIS
    Copy A file published on Yandex Disk to the Dowloads folder on the user's Yandex Disk.
.DESCRIPTION
    Copy A file published on Yandex Disk to the Dowloads folder on the user's Yandex Disk.
    To do this, you need to know the key or public link to the file.
    If you know the public folder key, you can also copy individual files from it.
    If a file with this name already exists on Yandex Disk, the file is renamed to "name (1).ext"
.PARAMETER Public_Key
    The key of a published resource or a public link to a resource.
.PARAMETER Path
    Relative path to the resource in the public folder stared with "/"
.PARAMETER TargetName
    The name for saving the file in the Downloads folder
.PARAMETER Async
    Do not wait for the process to complete
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Copy-YDiskPublishedItem -AccessToken $access_token -Public_Url 'https://yadi.sk/i/file123456'
.EXAMPLE
    Copy-YDiskPublishedItem -AccessToken $access_token -Public_Url 'https://yadi.sk/i/dir123456' -Path /folder -Name newfilename
.OUTPUTS
    Json with item metadata as PSObject
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/public#save
#>
function Copy-YDiskPublishedItem {
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position=0)]
    [Alias('Public_Url')]
    [string]$Public_Key,

    [Parameter(Position=1)]
    [ValidateLength(1, 32760)]
    [string]$Path,

    [string]$TargetName,

    [switch]$Async,

    [Parameter(Mandatory)]
    [string]$AccessToken
)
    $Headers = @{
        "Authorization" = "OAuth $AccessToken"
    }
    $Uri = '{0}/public/resources/save-to-disk?public_key={1}&path={2}&name={3}' -f $YDiskUri, [uri]::EscapeDataString($Public_Key), $Path, $TargetName
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

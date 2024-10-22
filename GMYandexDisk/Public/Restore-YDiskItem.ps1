<#
.SYNOPSIS
    Restore a file or folder from Trash on Yandex Disk
.DESCRIPTION
    Restore a file or folder from Trash on Yandex Disk
.PARAMETER Path
    File/Folder Path to restore (not equal to original filename !)
.PARAMETER TargetName
    The new name of the resource being restored
.PARAMETER Overwrite
    File overwrite flag. Used if the file is restored to a folder that already contains a file with the same name.
.PARAMETER Async
    Do not wait for the process to complete
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Restore-YDiskItem -AccessToken $access_token -Path 'trash://removed_252345425325'
.OUTPUTS
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/trash-restore
#>
function Restore-YDiskItem {
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position=0)]
    [ValidateLength(1, 32760)]
    [string]$Path,
    [ValidateLength(1, 255)]
    [string]$TargetName,
    [switch]$Overwrite,
    [switch]$Async,
    [Parameter(Mandatory)]
    [string]$AccessToken
)
    $Headers = @{
        "Authorization" = "OAuth $AccessToken"
    }
    $Path = $Path -replace '^trash:' -replace '^/'
    $Uri = '{0}/trash/resources/restore?path=trash:/{1}&overwrite={2}' -f $YDiskUri, $Path, $Overwrite.ToString().ToLower()
    if ($TargetName) {
        $Uri += '&name={0}' -f $TargetName
    }
    $requestParams = @{
        Uri = $Uri
        Headers = $Headers
        ContentType = "application/json; charset=utf-8"
    }
    Write-Verbose "URI: $Uri"
    try {
        $res = Invoke-WebRequest @requestParams -Method Put @YDiskProxySettings -ErrorAction Stop
        if ($res.StatusCode -eq 202) {
            $res = $res.Content | ConvertFrom-Json
            if ($Async) {
                $res
            }
            else {
                $status = Wait-YDiskOperation -AccessToken $AccessToken -OperationUri $res.href
                if ($status -ne 'success') {
                    throw "Restore failed"
                }
            }
        }
    }
    catch {
        throw
    }
}

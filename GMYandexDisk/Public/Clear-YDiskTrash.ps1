<#
.SYNOPSIS
    Clear Yandex Disk Trash
.DESCRIPTION
    Clear Yandex Disk Trash
    Files that were moved to Trash permanently deleted.
.PARAMETER Path
    The path to the resource being deleted relative to the Trash root directory.
    If this parameter isn't specified, Trash is emptied.
.PARAMETER Async
    No wait for full cleaning, Return immediately
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Clear-YDiskTrash -AccessToken $access_token -Async
.EXAMPLE
    Clear-YDiskTrash -AccessToken $access_token -Path /folder/file.txt
.OUTPUTS
    Json with operation status
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/trash-delete
#>
function Clear-YDiskTrash {
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Position=0)]
    [ValidateLength(1, 32760)]
    [string]$Path,
    [switch]$Async,
    [Parameter(Mandatory)]
    [string]$AccessToken
)
    $Headers = @{
        "Authorization" = "OAuth $AccessToken"
    }
    $Uri = '{0}/trash/resources?' -f $YDiskUri
    if ($Path) {
        $Path = $Path -replace '^trash:' -replace '^/'
        $Uri += 'path=trash:/{0}' -f $Path
    }
    $requestParams = @{
        Uri = $Uri
        Headers = $Headers
        ContentType = "application/json; charset=utf-8"
    }
    Write-Verbose "URI: $Uri"
    if ($PSCmdlet.ShouldProcess("Trash $Path", "Clear")) {
        try {
            $res = Invoke-WebRequest @requestParams -Method Delete @YDiskProxySettings -ErrorAction Stop
            if ($res.StatusCode -eq 202) {
                $res = $res.Content | ConvertFrom-Json
                if ($Async) {
                    $res
                }
                else {
                    $status = Wait-YDiskOperation -AccessToken $AccessToken -OperationUri $res.href
                    if ($status -ne 'success') {
                        throw "Trash clear failed"
                    }
                }
            }
        }
        catch {
            throw
        }
    }
}

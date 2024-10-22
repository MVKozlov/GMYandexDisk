<#
.SYNOPSIS
    Delete a file or folder on Yandex Disk
.DESCRIPTION
    Delete a file or folder on Yandex Disk
.PARAMETER Path
    The path to the resource being deleted
    For example, /foo/photo.png
.PARAMETER Permanently
    Permanently remove item. If not set, item moved to trash
.PARAMETER Async
    Do not wait for the process to complete
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Remove-YDiskItem -AccessToken $access_token -Path '/filename'
.EXAMPLE
    Remove-YDiskItem -AccessToken $access_token -Path '/folder' -Permanently
.OUTPUTS
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/delete
#>
function Remove-YDiskItem {
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory, Position=0)]
    [string]$Path,
    [switch]$Permanently,
    [switch]$Async,
    [Parameter(Mandatory)]
    [string]$AccessToken
)
    $Headers = @{
        "Authorization" = "OAuth $AccessToken"
    }
    $Uri = '{0}/resources?&path={1}&permanently={2}' -f $YDiskUri, $Path, $Permanently.ToString().ToLower()
    $requestParams = @{
        Uri = $Uri
        Headers = $Headers
        ContentType = "application/json; charset=utf-8"
    }
    Write-Verbose "URI: $Uri"
    $perm = if ($Permanently) { 'permanently' } else { 'to trash' }
    if ($PSCmdlet.ShouldProcess($Path, "Remove $perm")) {
        try {
            $res = Invoke-WebRequest @requestParams -Method Delete @YDiskProxySettings -ErrorAction Stop
            if ($res.StatusCode -eq 202 -and -Not $Async) {
                $json = $res.Content | ConvertFrom-Json
                $status = Wait-YDiskOperation -AccessToken $AccessToken -OperationUri $json.href
                if ($status -ne 'success') {
                    throw "Remove failed"
                }
            }
        }
        catch {
            throw
        }
    }
}

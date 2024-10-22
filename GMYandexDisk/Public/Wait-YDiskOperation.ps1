<#
.SYNOPSIS
    Wait for Yandex Disk pending operation
.DESCRIPTION
    Wait for Yandex Disk pending operation
.PARAMETER OperationUri
    Operation Uri
.PARAMETER Delay
    Operation check pause in seconds
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Remove-YDiskItem -AccessToken $access_token -Path '/SomeBigFolder' -Async | Wait-YDiskOperation
.OUTPUTS
    status code string
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/operations
#>
function Wait-YDiskOperation {
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position=0, ValueFromPipelineByPropertyName)]
    [Alias('href')]
    [string]$OperationUri,
    [int]$Delay = 1,
    [Parameter(Mandatory)]
    [string]$AccessToken
)
BEGIN {
    $Headers = @{
        "Authorization" = "OAuth $AccessToken"
    }
}
PROCESS {
    do {
        Write-Verbose "Await operation on $OperationUri for $Delay sec"
        Start-Sleep -Seconds $Delay
        $res = Invoke-RestMethod -Uri $OperationUri -Headers $Headers -Method Get @YDiskProxySettings
    }
    while ($res -and $res.status -eq 'in-progress') # 'failed', 'success'
    $res.status
}
}
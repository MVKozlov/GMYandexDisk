<#
.SYNOPSIS
    Set additional custom attributes for any writable file or folder on Yandex Disk.
.DESCRIPTION
    Set additional custom attributes for any writable file or folder on Yandex Disk.
    These attributes will be returned in response to all requests for resource meta information (list of all files, recently uploaded files, and others)
.PARAMETER Path
    The path to the resource relative to the Yandex Disk root directory
.PARAMETER CustomProperty
    Hashtable of CustomProperties to set
    If the custom_properties object doesn't exist in the resource meta information, the API simply adds the passed object to it.
    If this object already exists the API updates the keys with the same names and adds the new ones.
    To delete an attribute, pass it with the $null value.
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Set-YDiskCustomItemProperty -AccessToken $access_token -Path 'file.txt' -Property @{ foo = 'bar'; baz = 'foo' }
.OUTPUTS
    Json with item metadata as PSObject
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/meta-add
#>
function Set-YDiskCustomItemProperty {
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position=0)]
    [ValidateLength(1, 32760)]
    [string]$Path,
    [Parameter(Mandatory, Position=1)]
    [ValidateScript({
        try {
            # PSv5 do no show warning and allow Depth from 1 only
            if ($PSVersionTable.PSVersion.Major -gt 5) {
                $r = $_ | ConvertTo-Json -Depth 0 -Compress -WarningAction Stop 3>$null
            }
            else {
                $r = $_ | ConvertTo-Json -Depth 1 -Compress
                if ($r -match '{.+[^\\]":{') {
                    throw
                }
            }
        }
        catch {
            throw 'The custom_properties object deepness must be limited to one level'
        }
        ($r.Length -lt 1024) -or
        ( & { throw 'The length of the custom_properties object (the names and values of embedded keys along with syntactic symbols) is limited to 1024 characters.' } )
})]
    [hashtable]$CustomProperty,

    [Parameter(Mandatory)]
    [string]$AccessToken
)
    $Headers = @{
        "Authorization" = "OAuth $AccessToken"
    }
    $Uri = '{0}/resources?path={1}' -f $YDiskUri, $Path
    Write-Verbose "URI: $Uri"
    $requestParams = @{
        Uri = $Uri
        Headers = $Headers
        ContentType = "application/json; charset=utf-8"
        Body = @{ custom_properties = $CustomProperty } | ConvertTo-Json -Compress
    }
    Invoke-RestMethod @requestParams -Method Patch @YDiskProxySettings
}

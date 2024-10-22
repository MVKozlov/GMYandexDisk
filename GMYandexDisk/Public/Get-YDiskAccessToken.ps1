<#
.SYNOPSIS
    Get or renew Access Token to work with Yandex Disk
.DESCRIPTION
    Get or renew Access Token to work with Yandex Disk
.PARAMETER ClientID
    OAuth2 Client ID
.PARAMETER ClientSecret
    OAuth2 Client Secret
.PARAMETER RefreshToken
    OAuth2 RefreshToken
.PARAMETER Code
    OAuth2 AuthorizationCode
.EXAMPLE
    Get-YDiskAccessToken -ClientId 12345678 -ClientSecret 87654321 -Code 12345
.EXAMPLE
    Get-YDiskAccessToken -ClientId 12345678 -ClientSecret 87654321 -RefreshToken 'RefreSHT0ken'
.OUTPUTS
    Json with Access/Refresh Codes and its lifetime as PSObject
.NOTES
    Author: Max Kozlov
.LINK
    Request-YDiskAuthorizationCode
    https://yandex.ru/dev/disk-api/doc/ru/concepts/quickstart#quickstart__oauth
    https://yandex.ru/dev/id/doc/ru/codes/code-url
#>
function Get-YDiskAccessToken {
[CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0, ValueFromPipelineByPropertyName)]
        [string]$ClientID,

        [Parameter(Mandatory, Position=1, ValueFromPipelineByPropertyName)]
        [string]$ClientSecret,

        [Parameter(Mandatory, Position=2, ValueFromPipelineByPropertyName, ParameterSetName='refresh')]
        [string]$RefreshToken,

        [Parameter(Mandatory, Position=2, ValueFromPipelineByPropertyName, ParameterSetName='code')]
        [string]$Code
    )
    BEGIN {
        $Uri = '{0}/token' -f $YDiskAuthUri
    }
    PROCESS {
        $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ClientID}:${ClientSecret}"))
        $requestParams = @{
            Uri = $Uri
            MaximumRedirection = 0
            ContentType = 'application/x-www-form-urlencoded'
            Headers = @{ Authorization = "Basic $auth" }
        }
        if ($PSCmdlet.ParameterSetName -eq 'code') {
            $requestParams.Body = @{ grant_type='authorization_code'; code=$Code; }
        }
        else {
            $requestParams.Body = @{ grant_type='refresh_token'; refresh_token=$RefreshToken; }
        }
        Invoke-RestMethod @requestParams -Method Post @YDiskProxySettings
    }
}

<#
.SYNOPSIS
    Get Authorization code for Yandex Disk
.DESCRIPTION
    Get Authorization code for Yandex Disk
    Try to open browser to get code
.PARAMETER ClientID
    OAuth2 Client ID
.PARAMETER TryAuto
    Try to automate code search in opened browser window
.EXAMPLE
    $code = Request-YDiskAuthorizationCode -ClientID 1234567890
.OUTPUTS
    Authorization url or Authorization Code or nothing
.NOTES
    Author: Max Kozlov
.LINK
    Get-YDiskAccessToken
    https://yandex.ru/dev/id/doc/ru/codes/code-url
#>
function Request-YDiskAuthorizationCode {
[CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0, ValueFromPipelineByPropertyName)]
        [string]$ClientID,
        [switch]$TryAuto
    )
    BEGIN {
        $Uri = '{0}/authorize?response_type=code&client_id={1}' -f $YDiskAuthUri, $ClientID
        # &redirect_uri=https://oauth.yandex.ru/verification_code
    }
    PROCESS {
        Write-Verbose $Uri
        if ($TryAuto) {
            $ie = $null
            try {
                $ie = New-Object -ComObject InternetExplorer.Application
            }
            catch {
                Write-Error "Unsupported. Can't load InternetExplorer COM Application: ($_.Exception)" -ErrorAction Continue
            }
            if ($ie) {
                try {
                    $ie.Navigate($Uri)
                    $ie.Visible = $true
                    $codeFound = $False
                    do {
                        do {
                            Start-Sleep -Milliseconds 50
                        } while ($null -ne $ie.Busy -and ($ie.Busy -eq $true -or $ie.ReadyState -ne 4))
                        if ($ie.LocationURL.startsWith('https://oauth.yandex.ru/verification_code') -and $ie.LocationURL -match 'code=(\d+)' ) {
                            Write-Verbose "Search code by urlmatch"
                            $Code = $matches[1]
                            $codeFound = $true
                        }
                        if ($ie.LocationURL -eq 'https://oauth.yandex.ru/') {
                            Write-Verbose "Search code on page"
                            $h1 = $ie.Document.querySelector('h1')
                            $Code = $h1.innerText
                            $codeFound = $true
                        }
                    } until ($codeFound -or $null -eq $ie.Busy)
                }
                finally {
                    if ($null -ne $ie.Busy) {
                        $ie.Quit()
                    }
                    $ie = $null
                    [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); [System.GC]::Collect()
                }
                if ($Code) {
                    $Code
                    return
                }
                Write-Error "Code can not be found automatically, look it yourself at $Uri"
            }
        }
        $params = @{
            Uri = $Uri
            MaximumRedirection = 0 
            ErrorAction = 'SilentlyContinue'
        }
        if ($PSVersionTable.PSVersion.Major -gt 5) {
            $params.ErrorAction = 'Stop'
        }
        try {
            $res = Invoke-WebRequest @params @YDiskProxySettings
            if ($res.StatusCode -eq 302) {
                Write-Verbose "Found location header"
                $res.Headers.Location
            }
            else {
                throw "Can not get location url"
            }
        }
        catch {
            if ($_.Exception.Response.Headers.Location.AbsoluteUri) {
                $_.Exception.Response.Headers.Location.AbsoluteUri
            }
            else {
                throw
            }
        }
    }
}

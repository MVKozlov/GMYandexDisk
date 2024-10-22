<#
.SYNOPSIS
    Upload a file to Yandex Disk
.DESCRIPTION
    Upload a file to Yandex Disk from local system or url
.PARAMETER Path
    The path the file should be uploaded to
    For example, /bar/photo.png
    The maximum file name length is 255 characters
.PARAMETER StringContent
    Content to upload as string
.PARAMETER Encoding
    Enconding used for string
.PARAMETER RawContent
    Content to upload as raw byte[] array
.PARAMETER InFile
    Content to upload as path to file
.PARAMETER Overwrite
    File overwrite flag. Used if the file is uploaded to a folder that already contains a file with the same name.
.PARAMETER SourceURL
    The link to the file to download. For example, http://example.com/photo.png
    The maximum file name length is 255 characters
    If a file with this name already exists on Yandex Disk, the file is renamed to "name (1).ext"
.PARAMETER DisableRedirects
    This parameter disables redirects for the address specified in the SourceURL parameter.
.PARAMETER Async
    Do not wait for the process to complete
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    # File based item upload
    Add-YDiskItem -AccessToken $access_token -Path '/filename' -InFile D:\SomeDocument.doc
.EXAMPLE
    # String based item upload
    Add-YDiskItem -AccessToken $access_token -Path '/filename' -StringContent 'test file'
.EXAMPLE
    # Byte[] based item upload
    Add-YDiskItem -AccessToken $access_token -Path '/filename' -RawContent 1,2,3,4,5
.OUTPUTS
    Json with href and operation status
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/upload
    https://yandex.ru/dev/disk-api/doc/ru/reference/upload-ext
#>
function Add-YDiskItem {
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position=0)]
    [ValidateLength(1, 32760)]
    [string]$Path,
    [Parameter(Mandatory, ParameterSetName='string')]

    [string]$StringContent,
    [Parameter(ParameterSetName='string')]
    [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8,

    [Parameter(Mandatory, ParameterSetName='raw')]
    [byte[]]$RawContent,

    [Parameter(Mandatory, ParameterSetName='file')]
    [string]$InFile,

    [Parameter(ParameterSetName='string')]
    [Parameter(ParameterSetName='raw')]
    [Parameter(ParameterSetName='file')]
    [switch]$Overwrite = $false,

    [Parameter(Mandatory, ParameterSetName='url')]
    [ValidateLength(1, 32760)]
    [string]$SourceURL,
    
    [Parameter(ParameterSetName='url')]
    [switch]$DisableRedirects = $false,
    [Parameter(ParameterSetName='url')]
    [switch]$Async,

    [Parameter(Mandatory)]
    [string]$AccessToken
)
    $Headers = @{
        "Authorization" = "OAuth $AccessToken"
    }
    $Uri = '{0}/resources/upload?path={1}' -f $YDiskUri, $Path
    $requestParams = @{
        Uri = $Uri
        Headers = $Headers
    }
    if ($PSCmdlet.ParameterSetName -eq 'url') {
        $requestParams.Uri += "&overwrite=$Overwrite&disable_redirects=$DisableRedirects".ToLower() + "&url=$SourceURL"
        Write-Verbose "URI: $($requestParams.Uri)"
        $res = Invoke-RestMethod @requestParams -Method Post @YDiskProxySettings
        if ($Async) {
            $res
        }
        else {
            $status = Wait-YDiskOperation -AccessToken $AccessToken -OperationUri $res.href
            $res | Add-Member -MemberType NoteProperty -Name status -Value $status -PassThru
        }
    }
    else {
        $requestParams.Uri += "&overwrite=$Overwrite".ToLower()
        Write-Verbose "URI: $($requestParams.Uri)"
        try {
            $res = Invoke-RestMethod @requestParams -Method Get @YDiskProxySettings
            if ($res -and $res.href) {
                if ($PSCmdlet.ParameterSetName -eq 'string') {
                    [byte[]]$RawContent = $Encoding.GetBytes($StringContent)
                }
                $requestParams = @{
                    Uri = $res.href
                    ContentType = 'application/octet-stream'
                }
                Write-Verbose "URI: $($requestParams.Uri)"
                if ($PSCmdlet.ParameterSetName -eq 'file') {
                    Invoke-WebRequest @requestParams -Method Put -InFile $InFile @YDiskProxySettings | Out-Null
                }
                else {
                    Invoke-WebRequest @requestParams -Method Put -Body $RawContent @YDiskProxySettings | Out-Null
                }
                $res | Add-Member -MemberType NoteProperty -Name status -Value 'success' -PassThru
            }
            else {
                throw "Invalid response while prepare upload: $res"
            }
        }
        catch {
            throw
        }
    }
}

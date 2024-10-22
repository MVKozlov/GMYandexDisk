$YDiskUri = "https://cloud-api.yandex.net/v1/disk"
$YDiskAuthUri = "https://oauth.yandex.ru"

$YDiskProxySettings = @{}

#region Load Private Functions
Try {
    Get-ChildItem "$PSScriptRoot\Private\*.ps1" -Exclude *.tests.ps1, *profile.ps1 | ForEach-Object {
        #$Function = $_.Name
        . $_.FullName
    }
} Catch {
    Write-Warning ("{0}: {1}" -f $Function,$_.Exception.Message)
    Continue
}
#endregion Load Private Functions

#region Load Public Functions
Try {
    Get-ChildItem "$PSScriptRoot\Public\*.ps1" -Exclude *.tests.ps1, *profile.ps1 -Recurse | ForEach-Object {
        #$Function = $_.Name
        . $_.FullName
    }
} Catch {
    Write-Warning ("{0}: {1}" -f $Function,$_.Exception.Message)
    Continue
}
#endregion Load Public Functions

<#
$pesterConfig = New-PesterConfiguration
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.Run.SkipRemainingOnFailure = 'Container'
Invoke-Pester -Configuration $pesterConfig

Invoke-Pester -TagFilter 'Token', 'Published' -Output Detailed
#>

<#
Request-YDiskAuthorizationCode

Get-YDiskError
#>

BeforeAll {
    Set-StrictMode -Version latest
    Import-Module $PSScriptRoot\..\GMYandexDisk -Verbose -Force -ErrorAction Stop
    $ErrorActionPreference = 'Stop'
    $global:tmpfile = [IO.Path]::GetTempFileName()

    $global:oauth_json | Should -Not -BeNullOrEmpty
    $oauth_json.client_id | Should -Not -BeNullOrEmpty
    $oauth_json.client_secret | Should -Not -BeNullOrEmpty
    $global:refresh    | Should -Not -BeNullOrEmpty
    $refresh.refresh_token  | Should -Not -BeNullOrEmpty

    $script:path = '/_yd_PesterTestFolder'
    $script:image_url = 'https://www.w3.org/assets/logos/w3c/w3c-no-bars.svg'
}

Describe "YDiskProxySetting" -Tag "Proxy" {
    Context "Add Proxy" {
        It "should set proxy" {
            { Set-YDiskProxySetting -Proxy 'http://ya.ru:800/' } | Should -Not -Throw
        }
        It "should get proxy" {
            { $script:proxy = Get-YDiskProxySetting } | Should -Not -Throw
            $proxy | Should -Not -BeNullOrEmpty
            $proxy.Proxy -is [Uri] | Should -Be $true
            $proxy.Proxy.AbsoluteUri | Should -Be 'http://ya.ru:800/'
        }
    }
    Context "Remove Proxy" {
        It "should remove proxy" {
            { Set-YDiskProxySetting -Proxy $null } | Should -Not -Throw
        }
        It "should get empty proxy" {
            { $script:proxy = Get-YDiskProxySetting } | Should -Not -Throw
            $proxy | Should -Not -BeNullOrEmpty
            $proxy.Proxy | Should -BeNullOrEmpty
        }
    }
}

Describe "Get-YDiskAccessToken" -Tag "Token" {
    It "Should Request Access Token" {
        { 
            $params = @{
                ClientID = $oauth_json.client_id
                ClientSecret = $oauth_json.client_secret
                RefreshToken = $refresh.refresh_token
            }
            $script:access = Get-YDiskAccessToken @params
        } | Should -Not -Throw
        $access | Should -Not -BeNullOrEmpty
        $access.access_token | Should -Not -BeNullOrEmpty
        $script:params = @{
            AccessToken = $access.access_token
        }
        $global:refresh = $script:access # save new refresh token
    }
}

Describe "Get-YDiskSummary" -Tag "Summary" {
    It "should return drive summary" {
        { $script:summary = Get-YDiskSummary -AccessToken $access.access_token } | Should -Not -Throw
        $summary | Should -Not -BeNullOrEmpty
        $summary.total_space | Should -Not -BeNullOrEmpty
    }
}

Describe "New-YDiskFolder" -Tag "Item" {
    It "should create first new folder" {
        { $script:folder = New-YDiskFolder -Path $path -AccessToken $access.access_token } | Should -Not -Throw
        $folder | Should -Not -BeNullOrEmpty
        $folder.href | Should -Not -BeNullOrEmpty
    }
    It "should create 2nd new folder" {
        { $script:folder = New-YDiskFolder -Path "$path/2nd" -AccessToken $access.access_token } | Should -Not -Throw
        $folder | Should -Not -BeNullOrEmpty
        $folder.href | Should -Not -BeNullOrEmpty
    }
}

Describe "Add-YDiskItem" -Tag "Item" {
    Context "string" {
        It "should create file from string" {
            { $script:file1 = Add-YDiskItem @params -Path "$path/PesterTestFile1"  -StringContent 'test file1' } | Should -Not -Throw
            $file1.operation_id | Should -Not -BeNullOrEmpty
            $file1.href | Should -Not -BeNullOrEmpty
            $file1.status | Should -Be "success"
        }
    }
    Context "byte[]" {
        It "should create file from byte[]" {
            { $script:file2 = Add-YDiskItem @params -Path "$path/PesterTestFile2" -RawContent ([Text.Encoding]::Utf8.GetBytes('test file2')) } | Should -Not -Throw
            $file2.operation_id | Should -Not -BeNullOrEmpty
            $file2.href | Should -Not -BeNullOrEmpty
            $file2.status | Should -Be "success"
        }
    }
    Context "file" {
        BeforeAll {
            'test file3' | Set-Content -Path $global:tmpfile -Encoding ASCII
        }
        It "should create file from file" {
            { $script:file3 = Add-YDiskItem @params -Path "$path/PesterTestFile3" -InFile $global:tmpfile } | Should -Not -Throw
            $file3.operation_id | Should -Not -BeNullOrEmpty
            $file3.href | Should -Not -BeNullOrEmpty
            $file3.status | Should -Be "success"
        }
    }
    Context "url" {
        It "should create file from source url" {
            { $script:file4 = Add-YDiskItem @params -Path "$path/PesterTestFile4" -SourceUrl $image_url } | Should -Not -Throw
            $file4.href | Should -Not -BeNullOrEmpty
            $file4.status | Should -Be "success"
        }
    }
    Context "overwrite" {
        It "should throw while upload existing file" {
            { $script:file1 = Add-YDiskItem @params -Path "$path/PesterTestFile1"  -StringContent 'test file1' } | Should -Throw
        }
        It "should not throw while upload existing file with overwrite" {
            { $script:file1 = Add-YDiskItem @params -Path "$path/PesterTestFile1"  -StringContent 'test file1' -Overwrite } | Should -Not -Throw
            $file1.operation_id | Should -Not -BeNullOrEmpty
            $file1.href | Should -Not -BeNullOrEmpty
            $file1.status | Should -Be "success"
        }
    }
}

Describe "Set-YDiskCustomItemProperty" -Tag "Item" {
    It "should throw on invalid custom property" {
        { Set-YDiskCustomItemProperty @params -Path "$path/PesterTestFile1" -CustomProperty @{ a=@{b=@{c='d'}} } } | Should -Throw
    }
    It "should set custom property" {
        { $script:file1 = Set-YDiskCustomItemProperty @params -Path "$path/PesterTestFile1" -CustomProperty @{foo='bar'} } | Should -Not -Throw
        $file1.name | Should -Be "PesterTestFile1"
        $file1.type | Should -Be "file"
        $file1.media_type | Should -Be "text"
        $file1.mime_type | Should -Be "text/plain"
        $file1.sha256 | Should -Be "4e829e799e1fa5134ed0601beeea8f136fe66c8b737a2eb712e40073359ed436"
        $file1.custom_properties | Should -Not -BeNullOrEmpty
        $file1.custom_properties.foo | Should -Be 'bar'
    }
}

Describe "Get-YDiskItemProperty" -Tag "Item" {
    Context "folder" {
        It "should get folder properties" {
            { $script:folder1 = Get-YDiskItemProperty @params -Path "$path" } | Should -Not -Throw
            $folder1.name | Should -Be "_yd_PesterTestFolder"
            $folder1.type | Should -Be "dir"
            $folder1._embedded | Should -Not -BeNullOrEmpty
            $folder1._embedded.total | Should -Be 5
        }
    }
    Context "file" {
        It "should get text file properties" {
            { $script:file1 = Get-YDiskItemProperty @params -Path "$path/PesterTestFile1" } | Should -Not -Throw
            $file1.name | Should -Be "PesterTestFile1"
            $file1.type | Should -Be "file"
            $file1.media_type | Should -Be "text"
            $file1.mime_type | Should -Be "text/plain"
            $file1.sha256 | Should -Be "4e829e799e1fa5134ed0601beeea8f136fe66c8b737a2eb712e40073359ed436"
        }
        It "should get image file properties" {
            { $script:file4 = Get-YDiskItemProperty @params -Path "$path/PesterTestFile4" } | Should -Not -Throw
            $file4.name | Should -Be "PesterTestFile4"
            $file4.type | Should -Be "file"
            $file4.media_type | Should -Be "image"
            $file4.mime_type | Should -Be "image/svg+xml"
        }
    }
}
Describe "Get-YDiskItem" -Tag "Item" {
    It "should get file content" {
        { $script:file1_content = Get-YDiskItem @params -Path "$path/PesterTestFile1" } | Should -Not -Throw
        $file1_content | Should -Be "test file1"
    }
    It "should save file content to file" {
        { Get-YDiskItem @params -Path "$path/PesterTestFile1" -OutFile $global:tmpfile } | Should -Not -Throw
        $global:tmpfile | Should -FileContentMatchExactly "test file1"
    }
}

Describe "Copy-YDiskItem" -Tag "Item" {
    It "should copy file" {
        { Copy-YDiskItem @params -Path "$path/PesterTestFile1" -TargetPath "$path/2nd/PesterTestFile1" } | Should -Not -Throw
    }
    It "should throw while copy file" {
        { Copy-YDiskItem @params -Path "$path/PesterTestFile1" -TargetPath "$path/PesterTestFile2" } | Should -Throw
    }
    It "should not throw while copy file with overwrite" {
        { Copy-YDiskItem @params -Path "$path/PesterTestFile1" -TargetPath "$path/PesterTestFile2" -Overwrite } | Should -Not -Throw
    }
}

Describe "Move-YDiskItem" -Tag "Item" {
    It "should throw while move file" {
        { Move-YDiskItem @params -Path "$path/PesterTestFile2" -TargetPath "$path/PesterTestFile3" } | Should -Throw
    }
    It "should not throw while move file with overwrite" {
        { Move-YDiskItem @params -Path "$path/PesterTestFile2" -TargetPath "$path/PesterTestFile3" -Overwrite } | Should -Not -Throw
    }
}

Describe "Get-YDiskChildItem" -Tag "Item" {
    It "should get file list" {
        { $script:folder1_items = Get-YDiskChildItem @params -Path $path } | Should -Not -Throw
        $folder1_items | Should -HaveCount 4
        $folder1_items | Where-Object { $_.name -eq 'PesterTestFile1' } | Should -Not -BeNullOrEmpty
    }
}

Describe "Find-YDiskItemByType" -Tag "Item" {
    It "should get image file list" {
        { $script:image_items = Find-YDiskItemByType @params -Type 'image' } | Should -Not -Throw
        $image_items.Count | Should -BeGreaterThan 0
        $image_items | Where-Object { $_.path -eq "disk:$path/PesterTestFile4" } | Should -Not -BeNullOrEmpty
    }
}

Describe "Publish-YDiskItem" -Tag "Publish" {
    It "should publish file" {
        { $script:published = Publish-YDiskItem @params -Path "disk:$path/PesterTestFile4" } | Should -Not -Throw
        $published.name | Should -Be "PesterTestFile4"
        $published.public_key | Should -Not -BeNullOrEmpty
        $published.public_url | Should -Not -BeNullOrEmpty
    }
    It "should publish folder" {
        { $script:published = Publish-YDiskItem @params -Path "disk:$path/2nd" } | Should -Not -Throw
        $published.name | Should -Be "2nd"
        $published.public_key | Should -Not -BeNullOrEmpty
        $published.public_url | Should -Not -BeNullOrEmpty
    }
}

Describe "Get-YDiskPublishedItemList" -Tag "Publish" {
    It "should return published item list" {
        { $script:all_published = Get-YDiskPublishedItemList @params } | Should -Not -Throw
        $all_published.Count | Should -BeGreaterThan 0
        $all_published | Where-Object { $_.path -eq "disk:$path/PesterTestFile4" } | Should -Not -BeNullOrEmpty
    }
    It "should return published dir" {
        { $script:dir_published = Get-YDiskPublishedItemList @params -ResourceType dir } | Should -Not -Throw
        $dir_published.Count | Should -BeGreaterThan 0
        $dir_published | Where-Object { $_.path -eq "disk:$path/2nd" } | Should -Not -BeNullOrEmpty
    }
}

Describe "Get-YDiskPublishedItemProperty" -Tag "Publish" {
    It "should return published item property" {
        $tf = $all_published | Where-Object { $_.path -eq "disk:$path/PesterTestFile4" }
        { $script:published = Get-YDiskPublishedItemProperty -Public_Url $tf.public_url } | Should -Not -Throw
        $published.name | Should -Be 'PesterTestFile4'
    }
    It "should return published dir" {
        $td = $all_published | Where-Object { $_.path -eq "disk:$path/2nd" }
        { $script:published = Get-YDiskPublishedItemProperty -Public_Key $td.public_key } | Should -Not -Throw
        $published.name | Should -Be '2nd'
    }
    It "should return published file in dir" {
        $td = $all_published | Where-Object { $_.path -eq "disk:$path/2nd" }
        { $script:published = Get-YDiskPublishedItemProperty -Public_Key $td.public_key -Path '/PesterTestFile1' } | Should -Not -Throw
        $published.name | Should -Be 'PesterTestFile1'
    }
}

Describe "Get-YDiskPublishedItem" -Tag "Item" {
    It "should get file content" {
        $td = $all_published | Where-Object { $_.path -eq "disk:$path/2nd" }
        { $script:file1_content = Get-YDiskPublishedItem -Public_Key $td.public_key -Path '/PesterTestFile1' } | Should -Not -Throw
        $file1_content | Should -Be "test file1"
    }
    It "should save file content to file" {
        $td = $all_published | Where-Object { $_.path -eq "disk:$path/2nd" }
        { $script:file1_content = Get-YDiskPublishedItem -Public_Key $td.public_key -Path '/PesterTestFile1' -OutFile $global:tmpfile } | Should -Not -Throw
        $global:tmpfile | Should -FileContentMatchExactly "test file1"
    }
}

Describe "Copy-YDiskPublishedItem" -Tag "Item" {
    It "should copy file to downloads" {
        $td = $all_published | Where-Object { $_.path -eq "disk:$path/2nd" }
        { $script:res = Copy-YDiskPublishedItem @params -Public_Key $td.public_key -Path '/PesterTestFile1' -TargetName 'PesterTestFile2' } | Should -Not -Throw
        $res.href | Should -Not -BeNullOrEmpty
    }
    It "should copy folder to downloads" {
        $td = $all_published | Where-Object { $_.path -eq "disk:$path/2nd" }
        { $script:res = Copy-YDiskPublishedItem @params -Public_Key $td.public_key } | Should -Not -Throw
        $res.href | Should -Not -BeNullOrEmpty
    }
}

Describe "Unpublish-YDiskItem" -Tag "Publish" {
    It "should unpublish file" {
        { $script:published = Unpublish-YDiskItem @params -Path "$path/PesterTestFile4" } | Should -Not -Throw
        $published.name | Should -Be "PesterTestFile4"
        { $published.public_key } | Should -Throw
        { $published.public_url } | Should -Throw
    }
    It "should unpublish folder" {
        { $script:published = Unpublish-YDiskItem @params -Path "$path/2nd" } | Should -Not -Throw
        $published.name | Should -Be "2nd"
        { $published.public_key } | Should -Throw
        { $published.public_url } | Should -Throw
    }
}

Describe "Remove-YDiskItem" -Tag "Item" {
    It "should remove file" {
        { Remove-YDiskItem @params -Path "$path/PesterTestFile3" -Confirm:$false } | Should -Not -Throw
    }
    It "should remove file permanently" {
        { Remove-YDiskItem @params -Path "$path/PesterTestFile4" -Permanently -Confirm:$false } | Should -Not -Throw
    }
    It "should remove folder" {
        { Remove-YDiskItem @params -Path "$path/2nd" -Confirm:$false } | Should -Not -Throw
    }
}

Describe "Get-YDiskTrashChildItem" -Tag "Trash" {
    It "should get trash file list" {
        { $script:trash_items = Get-YDiskTrashChildItem @params } | Should -Not -Throw
        $trash_items | Where-Object { $_.name -eq 'PesterTestFile3' } | Should -Not -BeNullOrEmpty
        $trash_items | Where-Object { $_.name -eq '2nd' } | Should -Not -BeNullOrEmpty
    }
    It "should get trash file list from folder" {
        $td = $trash_items | Where-Object { $_.name -eq '2nd' }
        { $script:trash_items2 = Get-YDiskTrashChildItem @params -Path $td.path } | Should -Not -Throw
        $trash_items2 | Where-Object { $_.name -eq 'PesterTestFile1' } | Should -Not -BeNullOrEmpty
    }
}

Describe "Get-YDiskTrashItemProperty" -Tag "Trash" {
    It "should get trash folder info" {
        $td = $trash_items | Where-Object { $_.name -eq '2nd' }
        { $script:trash_info = Get-YDiskTrashItemProperty @params -Path $td.path } | Should -Not -Throw
        $trash_info | Should -Not -BeNullOrEmpty
        $trash_info.name | Should -Be '2nd'
    }
    It "should get trash file info" {
        $tf = $trash_items | Where-Object { $_.name -eq 'PestertestFile3' }
        { $script:trash_info = Get-YDiskTrashItemProperty @params -Path $tf.path } | Should -Not -Throw
        $trash_info | Should -Not -BeNullOrEmpty
        $trash_info.name | Should -Be 'PestertestFile3'
    }
}

Describe "Restore-YDiskItem" -Tag "Trash" {
    It "should restore file" {
        $tf = $trash_items | Where-Object { $_.name -eq 'PestertestFile3' }
        { Restore-YDiskItem @params -Path $tf.path -TargetName 'PesterTestFile3a' } | Should -Not -Throw
    }
    It "should restore folder" {
        $td = $trash_items | Where-Object { $_.name -eq '2nd' }
        { Restore-YDiskItem @params -Path $td.path -TargetName '2nda' } | Should -Not -Throw
    }
}

Describe "Clear-YDiskTrash" -Tag "Trash" {
    It "should clear trash" {
        { Clear-YDiskTrash @params -Confirm:$false } | Should -Not -Throw
    }
}

Describe "Cleanup" -Tag "Cleanup" {
    It "should remove test folder permanently" {
        { Remove-YDiskItem @params -Path $path -Permanently -Confirm:$false } | Should -Not -Throw
    }
}

AfterAll {
    Remove-Item -Path $global:tmpfile
}

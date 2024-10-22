<#
.SYNOPSIS
    Get flat list of all files on Yandex Disk in alphabetical order.
.DESCRIPTION
    Get flat list of all files on Yandex Disk in alphabetical order.
    The flat list doesn't reflect the folder structure and can be used for searching for files of a specific type in different folders
.PARAMETER Type
    File types to include in the list.
    Yandex Disk identifies the type of each uploaded file.
.PARAMETER Property
    List of JSON properties to include in the response.
    Keys not specified in this list are omitted when generating a response.
    If the parameter isn't specified, the response is returned in full without omitting anything.
.PARAMETER AccessToken
    Access Token for request
.EXAMPLE
    Find-YDiskItemByType -AccessToken $access_token -Type 'image' -Property path, created
.OUTPUTS
    Json with item list metadata as PSObject
.NOTES
    Author: Max Kozlov
.LINK
    https://yandex.ru/dev/disk-api/doc/ru/reference/all-files
#>
function Find-YDiskItemByType {
[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet(
        'audio', # — аудио-файлы.
        'backup', # — файлы резервных и временных копий.
        'book', # — электронные книги.
        'compressed', # — сжатые и архивированные файлы.
        'data', # — файлы с базами данных.
        'development', # — файлы с кодом (C++, Java, XML и т. п.), а также служебные файлы IDE.
        'diskimage', # — образы носителей информации и сопутствующие файлы (например, ISO и CUE).
        'document', # — документы офисных форматов (Word, OpenOffice и т. п.).
        'encoded', # — зашифрованные файлы.
        'executable', # — исполняемые файлы.
        'flash', # — файлы с флэш-видео или анимацией.
        'font', # — файлы шрифтов.
        'image', # — изображения.
        'settings', # — файлы настроек для различных программ.
        'spreadsheet', # — файлы офисных таблиц (Excel, Numbers, Lotus).
        'text', # — текстовые файлы.
        'unknown', # — неизвестный тип.
        'video', # — видео-файлы.
        'web' # — различные файлы, используемые браузерами и сайтами (CSS, сертификаты, файлы закладок).
    )]
    [string[]]$Type,
    [ValidateSet(
        '*',
        'type',
        'name',
        'path',
        'created',
        'modified',
        'resource_id',
        'custom_properties',
        'comment_ids',
        'comment_ids.private_resource',
        'comment_ids.public_resource',
        'exif',
        'revision',
        'public_key',
        'public_url',
        'antivirus_status',
        'size',
        'mime_type',
        'file',
        'media_type',
        'sha256',
        'md5',
        'preview'
    )]
    [Parameter(Position=1)]
    [Alias('Metadata')]
    [string[]]$Property = @(),

    [Parameter(Mandatory)]
    [string]$AccessToken
)
    $Headers = @{
        "Authorization" = "OAuth $AccessToken"
    }
    if ($Property -contains "*") {
        $Property = "*"
    }
    $offset = 0
    $files = New-Object System.Collections.ArrayList
    do {
        $Uri = '{0}/resources/files?media_type={1}&limit=100&offset={2}' -f $YDiskUri, ($Type -join ','), $offset
        if ($Property) {
            $Uri += '&fields=offset,limit,items.{0}' -f ($Property -join ',items.')
        }
        Write-Verbose "URI: $Uri"
        $requestParams = @{
            Uri = $Uri
            Headers = $Headers
            ContentType = "application/json; charset=utf-8"
        }
        $result = Invoke-RestMethod @requestParams -Method Get @YDiskProxySettings
        if (-not $result -or -not $result.items) {
            break;
        }
        $files.AddRange($result.items)
        $offset += $result.limit
    } while ($true)
    $files
}

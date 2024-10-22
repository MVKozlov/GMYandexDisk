# Yandex Disk rest api

Яндекс Диск позволяет управлять ресурсами Диска (файлами и папками) посредством HTTP-запросов REST API.

API Диска предназначен для приложений, которые работают с файлами пользователей Яндекс Диска или хранят на Диске собственные файлы и настройки.

## Получение OAuth-токенов

[Оригинальная документация](https://yandex.ru/dev/disk-api/doc/ru/concepts/quickstart#quickstart__oauth)

Яндекс Диск авторизует приложения с помощью OAuth-токенов. Каждый токен предоставляет определенному приложению доступ к данным определенного пользователя.

Чтобы использовать протокол OAuth при работе с Яндекс Диском:

1. Зарегистрируйте свое OAuth-приложение.

    1. Войдите в аккаунт на Яндексе.
    2. Откройте страницу создания приложения.
        [https://oauth.yandex.ru/client/new/](https://oauth.yandex.ru/client/new/)  
        Обратите внимание, на странице [https://oauth.yandex.ru/](https://oauth.yandex.ru/) кнопка "Создать приложение" ведёт _не туда_, там лишний **/id/** в url и она не позволяет указать доступы
    3. Укажите название вашего сервиса и при необходимости прикрепите иконку.
    4. Выберите платформу **Веб-сервисы** и в поле **Redirect URI** подставьте значение по умолчанию, которое появится в подсказке _Подставить URL для отладки_: [https://oauth.yandex.ru/verification_code](https://oauth.yandex.ru/verification_code).

    5. В разделе **Доступ к данным** укажите необходимые права доступа (помимо доступа к файлам пользователя можно пользоваться папкой приложения):
        - Запись в любом месте на Диске — **cloud_api:disk.write**;
        - Чтение всего Диска — **cloud_api:disk.read**;
        - Доступ к папке приложения на Диске — **cloud_api:disk.app_folder**;
        - Доступ к информации о Диске — **cloud_api:disk.info**.
    6. Укажите электронную почту для связи.

    7. Внизу страницы нажмите **Создать приложение**. На экране появятся его описание.

    8. Скопируйте идентификатор приложения из поля **ClientID** — он потребуется для получения OAuth-токена. В дальнейшем открыть страницу со всеми вашими приложениями вы сможете по ссылке [oauth.yandex.ru](https://oauth.yandex.ru).

2. Получите OAuth-токены для доступа к данным пользователей [любым подходящим способом](https://yandex.ru/dev/id/doc/ru/access).

    [Запрос OAuth-токена при помощи кода подтверждения](https://yandex.ru/dev/id/doc/ru/codes/code-and-token)

    [Отладочный токен](https://yandex.ru/dev/id/doc/ru/tokens/debug-token) необходимо получить вручную:

    1. Перейдите по ссылке `https://oauth.yandex.ru/authorize?response_type=token&client_id=<ClientID>`

        Вместо "ClientID" подставьте значение из пункта 1.8.

    2. Если токен вашему приложению выдается впервые, откроется экран авторизации. После входа Яндекс OAuth перенаправит вас на страницу с токеном.

        На самом деле оно открывается всегда, так что код надо брать из браузера

    3. Можно воспользоваться `Request-YDiskAuthorizationCode -ClientID <clientid> -TryAuto`. Эта команда откроет "за вас" нужную страницу и попробует дождаться кода. Или просто выдаст ссылку на эту страницу без _-TryAuto_

3. Для авторизации в модуле надо получить токены с помощью

    `$token = Get-YDiskAccessToken -Code 123456 -ClientID $client_id -ClientSecret $client_secret`

   Потом безопасно сохранить ClientID, ClientSecret, refresh_token

   И обновлять _access_token_ через

   `$token = Get-YDiskAccessToken -RefreshToken $token.refresh_token -ClientID $client_id -ClientSecret $client_secret`

   Кстати, одновременно с _access_token_ мы получаем и новый _refresh_token_, но старый продолжает действовать

## Хранение ClientID, ClientSecret и Refresh_Token

ClientID, ClientSecret и Refresh_Token надо сохранить где-то в безопасном месте, напрямую в код их класть не надо

Для этого можно использовать модуль [SecretManagement](https://www.powershellgallery.com/packages/Microsoft.PowerShell.SecretManagement/) и его дополнения или хотя бы самописные функции типа

``` powershell
function Protect-String {
<#
.SYNOPSIS
    Convert String to textual form of SecureString
.PARAMETER String
    String to convert
.OUTPUTS
    String
.NOTES
    Author: MVKozlov
#>
param(
  [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
  [string]$String
)
PROCESS {
    $String | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
}
}

function Unprotect-String {
<#
.SYNOPSIS
    Convert SecureString to string
.PARAMETER String
    String to convert (textual form of SecureString)
.PARAMETER SecureString
    SecureString to convert
.OUTPUTS
    String
.NOTES
    Author: MVKozlov
#>
[CmdletBinding(DefaultParameterSetName='s')]
param(
  [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0, ParameterSetName='s')]
  [string]$String,
  [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0, ParameterSetName='ss')]
  [SecureString]$SecureString
)
PROCESS {
  if ($String) {
      $SecureString = $String | ConvertTo-SecureString
  }
  if ($SecureString) {
      (New-Object System.Net.NetworkCredential '', ($SecureString)).Password
  }
}
}
```

## Использование

``` powershell
Get-YDiskSummary -AccessToken $token.access_token
Add-YDiskItem -AccessToken $token.access_token -Path '/myfile.txt' -InFile D:\MyFile.txt
Publish-YDiskItem  -AccessToken $token.access_token -Path '/myfile.txt'
```

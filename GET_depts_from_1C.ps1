# обрезаем пробелы по краям, убираем спецсимволы и заменяем пробелы на нижнее подчёркивание
function NormalizeAdName {
    Param(
        [Parameter (Mandatory = $true)]
        [string]$NormalizeAdName_text
    )
    # обрезаем пробелы по краям, удаляем всё кроме буквоцифр, нижнего подчёркивания, пробела и дефиса, после чего заменяет пробел на нижнее подчёркивание
    $NormalizeAdName_text = $NormalizeAdName_text.Trim() -replace '[^\w\s\-]', '' -replace '\s', '_' 

    return $NormalizeAdName_text
}
# путь к файлу лога
$target_log = "C:\Scripts\Logs\GET_depts_from_1C.txt"

# получатель уведомления, отправитель, адрес почтового сервера
$Email_to_notification = 'Терехов Степан Владимирович <terekhov@spgr.ru>'
$Email_from_notification = '!ИТ поддержка <hd@spgr.ru>'
$Email_server = 'post.spgr.ru'
# массив для ошибок
$errMSG = @()

# отправка письма с employeeid пользователей, которые не найдены в AD
function Send_Email_users {
    # тема письма
    $Subject = 'Ошибка скрипта создания групп департаментов'
    # не изменяемый текст, `n - перенос на следующую строку
    $BodyTxt1 = "Добрый день!"
    $BodyTxt2 = "!`n`nНеобходимо проверить пользователей - не были добавлены в группу `n"
    $BodyTxt3 = "`n`nС уважением,`nТехническая поддержка`nГруппы компаний Спектрум"
    # формируем еткст из нужных переменных и неизменяемой части
    $EmailBody = $BodyTxt1 + $BodyTxt2 + $User_for_check + $BodyTxt3
    # отправляет от имени -From на ящик -To через сервер -SmtpServer с темой -Subject и текстом письма -Body в кодировке UTF8, иначе проблемы с русским языком на англоязычных системах
    Send-MailMessage -To $Email_to_notification  -From $Email_from_notification -SmtpServer $Email_server -Subject $Subject -Body $EmailBody -encoding UTF8
}

# отправка письма с текстом ошибок работы скрипта
function Send_Email_error {
    # тема письма
    $Subject = 'Ошибка скрипта создания групп департаментов'
    # не изменяемый текст, `n - перенос на следующую строку
    $BodyTxt1 = "Добрый день!"
    $BodyTxt2 = "!`n`nНеобходимо проверить работу скрипта - в процессе выполнения возникли ошибки. `n"
    $BodyTxt3 = "`n`nС уважением,`nТехническая поддержка`nГруппы компаний Спектрум"
    # формируем еткст из нужных переменных и неизменяемой части
    $EmailBody = $BodyTxt1 + $BodyTxt2 + $errMSG + $BodyTxt3
    # отправляет от имени -From на ящик -To через сервер -SmtpServer с темой -Subject и текстом письма -Body в кодировке UTF8, иначе проблемы с русским языком на англоязычных системах
    Send-MailMessage -To $Email_to_notification  -From $Email_from_notification -SmtpServer $Email_server -Subject $Subject -Body $EmailBody -encoding UTF8
}

Start-Transcript -Path $target_log
# создаём таблицу для упрощения работы и добавления родителей
$Datatable_dept = New-Object System.Data.DataTable
$Datatable_dept.Columns.Add("ItemId") 
$Datatable_dept.Columns.Add("ItemName")
$Datatable_dept.Columns.Add("ParentId")
$Datatable_dept.Columns.Add("ParentName")
$Datatable_dept.Columns.Add("DeleteMark")

# текущая дата
$date = Get-Date -Format dd_MM_yyyy
# коммент для удалённой в 1С группы в AD
$dept_deletemark_description = 'ОБЪЕКТ УДАЛЁН'
# префикс в названии группы
$GroupPrefix = '$DPT-'
# OU в AD где находятся группы
[ADSI]$DeptsGroupPath = "LDAP://OU=Security-Depts,OU=Groups,DC=spectrum,DC=repm"
# тип группы в AD - универсальная, безопасности
$Dept_Groups_Type = "0x80000008"
# id группы архива подразделений
$dept_archive_1c = '0xB84600155D00230511EA80AE0B0801F3'


###____________________________________________________________________________________________________________________________###


# блок подключения к msql
$server = "MDMSQL"
$database = "MDM"
# если нет подключения - не выполнять скрипт
try {
    # получаем список dept из 1С, сразу в запросе конвертируем данные
    $sql_dept = "SELECT CONVERT(nvarchar(100), Item.[Id], 2) as ItemId, CONVERT(nvarchar(100), Item.[ParentId], 2) as ParentId, Item.[Name] as ItemName,  CONVERT(nvarchar(100), Item.[DeleteMark], 1) as DeleteMark, Parent.[Name] as ParentName FROM [v1CZUP_CompanyStructure] Item LEFT JOIN [v1CZUP_CompanyStructure] Parent ON Item.ParentId = Parent.Id where Item.[ParentId] != $dept_archive_1c Order by Item.[Name] asc"
    $SqlConnection_dept = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection_dept.ConnectionString = "Server=$server;Database=$database;Integrated Security=True"
    $SqlCmd_dept = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd_dept.CommandText = $sql_dept
    $SqlCmd_dept.Connection = $SqlConnection_dept
    $SqlAdapter_dept = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter_dept.SelectCommand = $SqlCmd_dept
    $DataSet_dept = New-Object System.Data.DataSet
    $SqlAdapter_dept.Fill($DataSet_dept)
    $SqlConnection_dept.Close()
}
catch { $Error; break }
# для каждой строки с отделом - создаём/обновляем группу
$row_count_sql = $DataSet_dept.Tables.Rows.Count
for ($i = 0; $i -lt $row_count_sql; $i++) {

    # присваиваем данные столбцов переменным
    $Dept_Id_1C = $DataSet_dept.Tables.Rows[$i].ItemId
    $Dept_Name_1C = $DataSet_dept.Tables.Rows[$i].ItemName
    $Dept_ParentId_1C = $DataSet_dept.Tables.Rows[$i].ParentId
    $Dept_ParentName_1C = $DataSet_dept.Tables.Rows[$i].ParentName
    $Dept_DeleteMark_1C = $DataSet_dept.Tables.Rows[$i].DeleteMark

    # нормализуем название отдела
    $Dept_Name_1C = $GroupPrefix + (NormalizeAdName $Dept_Name_1C)

    # записываем в новую таблицу построчно только нужные данные
    $row = $Datatable_dept.NewRow()
    $row.ItemId = $Dept_Id_1C
    $row.ParentId = $Dept_ParentId_1C
    $row.DeleteMark = $Dept_DeleteMark_1C
    $Datatable_dept.Rows.Add($Row)

    # проверяем есть ли в AD dept с таким id
    $dept_searcher = [adsisearcher]"(departmentNumber=$Dept_Id_1C)"
    $dept_result = $dept_searcher.Findone()
        
    switch ($dept_result) {
        # если группа не найдена
        { $null -eq $dept_result } {
            # проверяем уникальность имени отдела
            $dept_searcher_test = [adsisearcher]"(name=$Dept_Name_1C)"
            $dept_result_test = $dept_searcher_test.Findone()
            # если группа с таким именем уже есть - добавляем дату
            if ($null -ne $dept_result_test) {
                $Dept_Name_1C = $Dept_Name_1C + '_' + $date
            }

            # если имя больше 64-х символов - обрезаем, полное пишем в коммент
            if ($Dept_Name_1C.Length -gt '64') {
                $Dept_Name_1C_64 = $Dept_Name_1C.Remove(64)
            }
            else {
                $Dept_Name_1C_64 = $Dept_Name_1C
            }
            
            write-host "Создание новой группы $Dept_Name_1C c именем $Dept_Name_1C_64"
            # создаём новую группу
            $new_dept_AD = $DeptsGroupPath.Create("group", "CN=" + $Dept_Name_1C_64)
            $new_dept_AD.put("departmentNumber", "$Dept_Id_1C")
            $new_dept_AD.put("description", $Dept_Name_1C)
            $new_dept_AD.put('grouptype', 0x80000008)
            $new_dept_AD.put("info", "$Dept_Id_1C")
            $new_dept_AD.put('name', $Dept_Name_1C)
            $new_dept_AD.put('samaccountname', $Dept_Name_1C_64)
            $new_dept_AD.SetInfo()	
        }

        # если группа существует
        { $null -ne $dept_result } {
            write-host "Проверка имени $Dept_Name_1C"
            # заменяем имя у группы на имя из AD
            $from = [ADSI]$dept_result.Path
            $to = [ADSI]$DeptsGroupPath
            $from.PSBase.MoveTo($to, "cn=" + $Dept_Name_1C)
        }
    }
}


###____________________________________________________________________________________________________________________________###


# для каждой строки с отделом - добавляем в родительскую группу и заполняем пользователями
$row_count_depts = $Datatable_dept.Rows.Count
for ($i = 0; $i -lt $row_count_depts; $i++) {

    # присваиваем данные столбцов переменным
    $Dept_Id_1C_datatable = $Datatable_dept.Rows[$i].ItemId
    $Dept_ParentId_1C_datatable = $Datatable_dept.Rows[$i].ParentId
    $Dept_DeleteMark_1C_datatable = $Datatable_dept.Rows[$i].DeleteMark
    
    # находим dept в ad
    $dept_search_item = [adsisearcher]"(departmentNumber=$Dept_Id_1C_datatable)"
    $dept_result_item = $dept_search_item.Findone()
    [ADSI]$dept_item = $dept_result_item.Path
    $dept_item_name = $dept_item.name
    #$dept_item_users = $dept_item.Member
    write-host "группа"
    $dept_item_name
    
    # если у dept нет родителя - пропускаем блок. Если есть - добавляем в родителский dept
    if ($Dept_ParentId_1C_datatable -ne '00000000000000000000000000000000') {
        # находим родительскую группу
        $dept_search_parent = [adsisearcher]"(departmentNumber=$Dept_ParentId_1C_datatable)"
        $dept_result_parent = $dept_search_parent.Findone()
        [ADSI]$dept_parent = $dept_result_parent.Path
        # проверяем, что группа уже не добавлена
        if ($dept_parent.member -notcontains $dept_item.distinguishedName) {
            # добавляем dept в родителя, если группа ещё не включена
            $dept_parent.Add($dept_item.ADSPath)
        }
    }

    # если dept в 1с имеет признак удалён - добавляем это в описание группы
    if ($Dept_DeleteMark_1C_datatable -eq '0x01') {
        $dept_item.Put("description", $dept_deletemark_description)
        $dept_item.SetInfo()
    }
    # конвертируем ID dept для поиска пользователей в sql
    $Dept_Id_1C_datatable_binary = '0x' + $Dept_Id_1C_datatable
    # находим всех пользователей отдела
    # если нет подключения - не выполнять скрипт, иначе группы будут пустыми
    try {
        $sql_user = "SELECT EmployeeId, Department 
        FROM [v1CZUP_EmployeeClassifier_Actual] 
        where DepartmentId = $Dept_Id_1C_datatable_binary" 
        $SqlConnection_user = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection_user.ConnectionString = "Server=$server;Database=$database;Integrated Security=True"
        $SqlCmd_user = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd_user.CommandText = $sql_user
        $SqlCmd_user.Connection = $SqlConnection_user
        $SqlAdapter_user = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter_user.SelectCommand = $SqlCmd_user
        $DataSet_user = New-Object System.Data.DataSet
        $SqlAdapter_user.Fill($DataSet_user)
        $SqlConnection_user.Close()
    }
    catch { $Error; break }
    # записываем EmployeeId в переменную
    $dept_1C_members = $DataSet_user.Tables.Rows.EmployeeId
    write-host "пользователи из 1С"
    $dept_1C_members

    # получаем список участников группы в AD в виде списка employeeID
    $dept_ad_members = @()
    $dept_item.Member | ForEach-Object {
        $Searcher_users = [adsisearcher]"(distinguishedname=$_)"
        $result_users = $Searcher_users.FindOne()
        if ($result_users.Properties.objectclass -contains 'user') {
            $dept_ad_members += $result_users.Properties.employeeid
        }
    }
    write-host "участники группы"
    $dept_ad_members

    # сравниваем список в массиве и список участников, получаем список тех, кого надо добавить
    $new_users = ''
    $new_users = $dept_1C_members | Where-Object { $dept_ad_members -notcontains $_ }
    write-host "кого добавить"
    $new_users
    $new_users.count

    # сравниваем список участников с массивом и получаем список, кто больше не в группе
    $old_users = ''
    $old_users = $dept_ad_members | Where-Object { $dept_1C_members -notcontains $_ }
    write-host "кого удалить"
    $old_users
    $old_users.Count

    # если есть кого надо добавлять - находим учётки из массива по employeeid и добавляем в группу
    switch ($new_users.count) {
        { $new_users.count -ge 1 } {
                write-host "число пользователей вне группы $dept_item_name 1 или больше"
                $group_user_new = $new_users | ForEach-Object {
                    $Search_new_user = [adsisearcher]"(&(employeeid=$_)(!userAccountControl:1.2.840.113556.1.4.803:=2))"
                    $Search_new_user.FindOne().Properties.adspath
                }
                $group_user_new | ForEach-Object { Write-Host "добавить $_" } { $dept_item.Add($_) }
        }
        # если новых сотрудников в массиве не было - ничего не делаем и переходим к следующему пункту
        { $new_users.count -eq 0 } {
            write-host "число пользователей вне группы $dept_item_name 0"
        }
    }
    # если есть кого надо удалить из группы - находим учётки из массива по employeeid и удаляем из группы    
    switch ($old_users.count) {
        { $old_users.count -ge 1 } {
            write-host "число лишних пользователей в группе dept_item_name 1 или больше"
            $group_user_old = $old_users | ForEach-Object {
                $Search_old_user = [adsisearcher]"(employeeid=$_)"
                $Search_old_user.FindOne().Properties.adspath
            }
            $group_user_old | ForEach-Object { $dept_item.Remove($_) }
        }
        # если ненужных сотрудников в массиве не было - ничего не делаем 
        { $old_users.count -eq 0 } {
            write-host "число лишних пользователей в группе $dept_item_name 0"
        }
    }
}

# если есть ненайденные пользователи - отправляем почтовое уведомление
if ($User_for_check.count -gt 0) {
    Send_Email_users
}


# проверяем наличие ошибок при выполнении, если есть - пишем в переменную и отправляем письмом
if ($Error.Count -gt 0) {
    for ($i = 0; $i -le ($Error.Items.Count + 1); $i++) {
        $errMSG += "$Error"
    }
}
if ($errMSG.count -gt 0) {
    Send_Email_error
}

# очищаем переменную и список ошибок на случай выполнения других скриптов
$errMSG = ""
$Error.clear()

Stop-Transcript
# SIG # Begin signature block
# MIIIcwYJKoZIhvcNAQcCoIIIZDCCCGACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjWMKfCgoDmLyzo1wHVYZPEkK
# 34igggXbMIIF1zCCBL+gAwIBAgITbwAAC5UOUq3XSWP25wACAAALlTANBgkqhkiG
# 9w0BAQsFADBKMRQwEgYKCZImiZPyLGQBGRYEcmVwbTEYMBYGCgmSJomT8ixkARkW
# CHNwZWN0cnVtMRgwFgYDVQQDEw9TcGVjdHJ1bS1Sb290Q0EwHhcNMjMwODE1MDg1
# MjMwWhcNMjQwODE0MDg1MjMwWjAaMRgwFgYDVQQDEw9zdmMtc2lnbmF0dXJlUFMw
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC3+t+Kvon33cUPs4S+DxXC
# UXii0IeKu4WdSd+uiJhBIcFuqLXs30QOWy356ty2jL9nStrksJIkKYxTIRmY9pct
# xHfveKYimNQt2B1gex7aNapLrPAgdRypdy1RvHEyGw6ZkTuTPpzK+Ub+g3RywWbX
# ZME9C+DuqqeSBYy7gRH9TS+XElqCei0TN/NrJIcnyqzsqatcQV0hJR4rSeh0lO+y
# n++BeeCDa5j7TqydQd3fV7hGq0t4AQG0tYWdq25qSn4FpQjDQSOjFIpjLL9yZsV3
# 0px15Z92+lUTP4W/2WoKuX1sXcyFuJHHRnf2/rb2VZjkl3RGyEYG3J9n/hjymKGt
# AgMBAAGjggLkMIIC4DA+BgkrBgEEAYI3FQcEMTAvBicrBgEEAYI3FQiHrNhsg8CP
# HYXxlzuFp8xoh8HPLYFGhYfsO4erzAUCAWQCAQkwEwYDVR0lBAwwCgYIKwYBBQUH
# AwMwCwYDVR0PBAQDAgeAMBsGCSsGAQQBgjcVCgQOMAwwCgYIKwYBBQUHAwMwHQYD
# VR0OBBYEFKr32uSgKQRQI1kgfYbHGcqdqu7mMB8GA1UdIwQYMBaAFLU1C/9Pnp9q
# TcI7EEyqiI1aFFmYMIHPBgNVHR8EgccwgcQwgcGggb6ggbuGgbhsZGFwOi8vL0NO
# PVNwZWN0cnVtLVJvb3RDQSxDTj1tQVVUSC0yLENOPUNEUCxDTj1QdWJsaWMlMjBL
# ZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPXNw
# ZWN0cnVtLERDPXJlcG0/Y2VydGlmaWNhdGVSZXZvY2F0aW9uTGlzdD9iYXNlP29i
# amVjdENsYXNzPWNSTERpc3RyaWJ1dGlvblBvaW50MIHDBggrBgEFBQcBAQSBtjCB
# szCBsAYIKwYBBQUHMAKGgaNsZGFwOi8vL0NOPVNwZWN0cnVtLVJvb3RDQSxDTj1B
# SUEsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29u
# ZmlndXJhdGlvbixEQz1zcGVjdHJ1bSxEQz1yZXBtP2NBQ2VydGlmaWNhdGU/YmFz
# ZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MDgGA1UdEQQxMC+g
# LQYKKwYBBAGCNxQCA6AfDB1zdmMtc2lnbmF0dXJlUFNAc3BlY3RydW0ucmVwbTBN
# BgkrBgEEAYI3GQIEQDA+oDwGCisGAQQBgjcZAgGgLgQsUy0xLTUtMjEtNDM2Mzc0
# MDY5LTMwODIzNjgyNS03MjUzNDU1NDMtMzg2MDcwDQYJKoZIhvcNAQELBQADggEB
# AEvs8Uu3lcdbaTZaNY+V34s7HSSTXK0MJ+UxY0U8k0AFpcqMjdkNOtOyKPaDPMal
# G3gkQ7WohbMojCesp2ZzO8RoBHmyhCzHaHBL5FRIlWqZkN4LMkHflqgrPQydAvJY
# m8G2sUBHKXsG+1ALWtPPolIma2LvTqWbKHu1kHjw0pzHTb1XevKou+7GvYt4u2Uo
# U5ea0uivY8KcCq7bEc5uf1+pMfsauNiepbdQPue8G1UdKWegdEML5yEiIzGu18B4
# UDV1HE11Qdi020xauYm6zMS8qBzqAzEFxZJBrswN8rWKliSKbxhNO3KZLl0F6kOz
# AY68EXImRBgMTRhXyvQC/NIxggICMIIB/gIBATBhMEoxFDASBgoJkiaJk/IsZAEZ
# FgRyZXBtMRgwFgYKCZImiZPyLGQBGRYIc3BlY3RydW0xGDAWBgNVBAMTD1NwZWN0
# cnVtLVJvb3RDQQITbwAAC5UOUq3XSWP25wACAAALlTAJBgUrDgMCGgUAoHgwGAYK
# KwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIB
# BDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU
# NYD1FgSu0oJVgE80xoPnEHTB4mAwDQYJKoZIhvcNAQEBBQAEggEAAzL2AB+HJhVT
# WhDJHSEeRSiQkK05c6JXEmkaqiH75vl5b3p1RZi88do7Izn5L7yUtzudCZvVqrKm
# nTNpLxXbig6lst6SqLBc1dIA/IvNQOVy36WVSYd6kLe5cd+K2QH5sjNvgD3x0Rp5
# YAzVOktDBli9HU9rksuLX7b37H/qW4dT3SMaVkRCbehgNhm7QU43IzE0qVHHu22t
# CN1jBl2mQE02lfO/GjOJZWejblWRplhcDILL65nWa/JFUsWrfLFNM4AUO7wZ7mwd
# 86XGbuaWTSZDlW6OXVbnB7xpQgGdtpH5qDnWI5cUfwu3iNlm2hp4XDpF3MyYWJlo
# qMgGOZNjcA==
# SIG # End signature block

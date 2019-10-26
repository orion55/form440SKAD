#Программа для автоматизации отправки банковской отчетности по форме 440p SKAD Signature
#(c) Гребенёв О.Е. 26.10.2019

Param(
    [switch]$autoget = $false
)

[boolean]$debug = $true
[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
[string]$lib = "$curDir\lib"

. $curDir/variables.ps1
. $lib/PSMultiLog.ps1
. $lib/libs.ps1
. $lib/libsSKAD.ps1

$global:incoming_files_arj = $null
Import-Module PSSQLite

Set-Location $curDir

#ClearUI
Clear-Host

Start-HostLog -LogLevel Information

$curDate = Get-Date -Format "ddMMyyyy"
[string]$logName440 = (Get-Item $PSCommandPath ).DirectoryName + "\log\" + $curDate + "_f440.log"
[string]$logSpki = (Get-Item $PSCommandPath ).DirectoryName + "\log\" + $curDate + "_spki.log"

Start-FileLog -LogLevel Information -FilePath $logName440 -Append
if ($debug) {
    Write-Log -EntryType Information -Message "Режим отладки"
    Copy-Item -Path "$tmp\work1\*.*" -Destination $comita_in
    $nobegin = $false
    $form = "440out"
}
elseif (!$autoget) {
    #меню для ввода с клавиатуры
    $title = "Отправка отчетности по форме 440п SKAD Signatura"
    $message = "Выберите вариант для отправки отчетности:"
    $440in = New-Object System.Management.Automation.Host.ChoiceDescription "440п принять - &0", "440in"
    $440out = New-Object System.Management.Automation.Host.ChoiceDescription "440п отправить - &1", "440out"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($440in, $440out)
    try {
        $choice = $host.ui.PromptForChoice($title, $message, $options, 0)
        switch ($choice) {
            0 { $form = "440in" }
            1 { $form = "440out" }
        }
    }
    catch [Management.Automation.Host.PromptingException] {
        Write-Log -EntryType Warning -Message "Выход!"
        exit
    }

    $title = "Автоматизация копирования"
    $message = "Файлы отчетности скопированы в папку $work ?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "Да - &0", "Да"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "Нет - &1", "Нет"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    try {
        $choice = $host.ui.PromptForChoice($title, $message, $options, 1)
        switch ($choice) {
            0 { $nobegin = $true }
            1 { $nobegin = $false }
        }
    }
    catch [Management.Automation.Host.PromptingException] {
        Write-Log -EntryType Warning -Message "Выход!"
        exit
    }

    Write-Log -EntryType Information -Message "Обработка отчетности - $form"

    if ($nobegin) {
        Write-Log -EntryType Warning -Message "Автоматическое копирование в папку $work произведено не было!"
    }
}
else {
    #автоматический режим
    Write-Log -EntryType Information -Message "Автоматический режим работы 440П SKAD Signature"
    $files2 = Get-ChildItem -Path $incoming_out $incoming_files
    if ($files2.count -eq 0) {
        Write-Log -EntryType Information -Message "Файлы отчетности не найдены в каталоге $incoming_out"
        exit
    }
    $files3 = Get-ChildItem -Path $work -File *.*
    if ($files3.count -gt 0) {
        Write-Log -EntryType Information -Message "Найдены файлы в каталоге $work"
        exit
    }

    $encoding = [System.Text.Encoding]::UTF8
    $date = Get-Date -UFormat "%d.%m.%Y %H:%M:%S"
    $title = "Автоматический приём по форме 440П SKAD Signature"
    $body = "Начат автоматический приём по форме 440П SKAD Signature $date"
    Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
    Write-Log -EntryType Information -Message $body
    $nobegin = $false
    $form = "440in"
}

#проверяем существуют ли нужные пути и файлы
$dir_arr = @($work, $incoming_out, $comita_in, $440p_arhive, $440p_ack, $440p_err, $vdkeys)
Test_dir($dir_arr)

$files_arr = @($spki, $arj32, $recList)
Test_files($files_arr)

#копируем файлы отчетности в каталог $work
if (!($nobegin)) {
    switch ($form) {
        '440in' {
            Remove-Item -Path "$work\*.*"

            $global:incoming_files_arj = Get-ChildItem -Path $incoming_out $incoming_files
            if ($global:incoming_files_arj.count -eq 0) {
                exit
            }

            Check-FilesLock -in_files $global:incoming_files_arj

            foreach ($f2 in $global:incoming_files_arj) {
                Copy-Item -Path "$incoming_out\$f2" -Destination $work
                Write-Log -EntryType Information -Message "Копируем файл $f2"
            }
        }
        '440out' {
            Remove-Item -Path "$work\*.*"
            $files2 = Get-ChildItem -Path $comita_in "*.xml"
            if ($files2.count -eq 0) {
                exit
            }
            $msg = Move-Item -Path "$comita_in\*.xml" -Destination $work -Verbose -Force *>&1
            Write-Log -EntryType Information -Message ($msg | Out-String)
        }
        default { exit }
    }
}
else {
    $files2 = Get-ChildItem -Path $work "*.xml"
    if ($files2.count -eq 0) {
        Write-Log -EntryType Error -Message "Файлы xml в каталоге $work не найдены!"
        exit
    }
}

#проверяем есть ли диск А
$disks = (Get-PSDrive -PSProvider FileSystem).Name
if ($disks -notcontains "a") {
    Write-Log -EntryType Error -Message "Диск А не найден!"
    exit
}

#сохраняем текущею ключевую дискету
Write-Log -EntryType Information -Message "Сохраняем текущею ключевую дискету"
$tmp_keys = "$curDir\tmp_keys"
if (!(Test-Path $tmp_keys)) {
    New-Item -ItemType directory -Path $tmp_keys | out-Null
}
Copy_dirs -from 'a:' -to $tmp_keys
Remove-Item 'a:' -Recurse -ErrorAction "SilentlyContinue"

switch ($form) {
    '440in' {
        440_in
        kwtfcbCheck
        documentsCheck

        foreach ($f2 in $global:incoming_files_arj) {
            Remove-Item -Path "$incoming_out\$f2"
            Write-Log -EntryType Information -Message "Удаляем файл $incoming_out\$f2"
        }
    }
    '440out' {
        440_out
    }
    default { exit }
}

Write-Log -EntryType Information -Message "Загружаем исходную ключевую дискету"
Remove-Item 'a:' -Recurse -ErrorAction "SilentlyContinue"
Copy_dirs -from $tmp_keys -to 'a:'
Remove-Item $tmp_keys -Recurse

Write-Log -EntryType Information -Message "Конец работы скрипта!"

Stop-FileLog
Stop-HostLog
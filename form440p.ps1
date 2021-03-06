#Программа для автоматизации отправки банковской отчетности по форме 440p SKAD Signature
#(c) Гребенёв О.Е. 26.10.2019

Param(
    [switch]$autoget = $false
)

[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
[string]$lib = "$curDir\lib"

. $curDir/variables.ps1
. $lib/PSMultiLog.ps1
. $lib/libs.ps1
. $lib/libsSKAD.ps1

$incoming_files_arj = $null

Set-Location $curDir

#ClearUI
Clear-Host

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName440 -Append

if ($debug) {
    Write-Log -EntryType Information -Message "Режим отладки"
    $nobegin = $false

    <#Copy-Item -Path "$tmp\work1\*.*" -Destination $comita_out
    $form = "440out"#>

    Copy-Item -Path "$tmp\work1\*.*" -Destination $incoming_out
    $form = "440in"
}
elseif (!$autoget) {
    #меню для ввода с клавиатуры
    $title = "Отправка отчетности по форме 440п SKAD Signatura"
    $message = "Выберите вариант для отправки отчетности:"
    $440in = New-Object System.Management.Automation.Host.ChoiceDescription "440п принять - &0", "440in"
    $440out = New-Object System.Management.Automation.Host.ChoiceDescription "440п отправить - &1", "440out"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($440in, $440out)
    try {
        $choice = $host.ui.PromptForChoice($title, $message, $options, 1)
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

    if (Test-Connection $mail_server -Quiet -Count 2) {
        $encoding = [System.Text.Encoding]::UTF8
        $date = Get-Date -UFormat "%d.%m.%Y %H:%M:%S"
        $title = "Автоматический приём по форме 440П SKAD Signature"
        $body = "Начат автоматический приём по форме 440П SKAD Signature $date"
        Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
        Write-Log -EntryType Information -Message $body
    }
    else {
        Write-Log -EntryType Error -Message "Не удалось соединиться с почтовым сервером $mail_server"
    }

    $nobegin = $false
    $form = "440in"
}

#проверяем существуют ли нужные пути и файлы
$dir_arr = @($work, $incoming_out, $comita_in, $comita_out, $comita_cscp_in, $440p_arhive, $440p_ack, $440p_err, $vdkeys)
Test_dir($dir_arr)

$files_arr = @($spki, $archiver, $recList)
Test_files($files_arr)

#копируем файлы отчетности в каталог $work
if (!($nobegin)) {
    switch ($form) {
        '440in' {
            Remove-Item -Path "$work\*.*"

            $incoming_files_arj = Get-ChildItem -Path $incoming_out $incoming_files
            if ($incoming_files_arj.count -eq 0) {
                Write-Log -EntryType Information -Message "Файлы в $incoming_out не найдены!"
                exit
            }
            $msg = $incoming_files_arj | Copy-Item  -Destination $work -Verbose -Force *>&1
            Write-Log -EntryType Information -Message ($msg | Out-String)
        }
        '440out' {
            Remove-Item -Path "$work\*.*"
            $files2 = Get-ChildItem -Path $comita_out "*.xml"
            if ($files2.count -eq 0) {
                Write-Log -EntryType Information -Message "Файлы в $comita_out не найдены!"
                exit
            }
            $msg = Move-Item -Path "$comita_out\*.xml" -Destination $work -Verbose -Force *>&1
            Write-Log -EntryType Information -Message ($msg | Out-String)

            copyArchive
        }
        default { exit }
    }
    if (!$debug -and !$autoget) {
        $title = "Проверка копирования"
        $message = "Файлы корректно скопированы в папку $work ?"
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "Да - &0", "Да"
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "Нет - &1", "Нет"
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        try {
            $choice = $host.ui.PromptForChoice($title, $message, $options, 0)
            switch ($choice) {
                0 { $check = $true }
                1 { $check = $false }
            }
        }
        catch [Management.Automation.Host.PromptingException] {
            Write-Log -EntryType Warning -Message "Выход!"
            exit
        }
        if (!$check) {
            Write-Log -EntryType Information -Message "Завершение работы программы!"
            exit
        }
    }
}
else {
    switch ($form) {
        '440in' {
            $files2 = Get-ChildItem -Path $work "*.arj"
            if ($files2.count -eq 0) {
                Write-Log -EntryType Error -Message "Файлы arj в каталоге $work не найдены!"
                exit
            }
        }
        '440out' {
            $files2 = Get-ChildItem -Path $work "*.xml"
            if ($files2.count -eq 0) {
                Write-Log -EntryType Error -Message "Файлы xml в каталоге $work не найдены!"
                exit
            }
            copyArchive
        }
        default { exit }
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

        #удаляем архивы, если файлы были вручную скопированы в work
        $incoming_files_arj = Get-ChildItem -Path $work $incoming_files
        if ($incoming_files_arj.count -gt 0) {
            $msg = $incoming_files_arj | Remove-Item -Verbose -Force *>&1
            Write-Log -EntryType Information -Message ($msg | Out-String)
        }
        #Удаляем архивы, если программа в автоматическом режиме
        if (!($nobegin)) {
            $incoming_files_arj = Get-ChildItem -Path $incoming_out $incoming_files
            if ($incoming_files_arj.count -gt 0) {
                $msg = $incoming_files_arj | Remove-Item -Verbose -Force *>&1
                Write-Log -EntryType Information -Message ($msg | Out-String)
            }
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
Remove-Item $tmp_keys -Recurse -Force

Write-Log -EntryType Information -Message "Конец работы скрипта!"

Stop-FileLog
Stop-HostLog
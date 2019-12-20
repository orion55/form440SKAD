[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#рабочий каталог, где будут подписываться и шифроваться файлы
[string]$tmp = "$curDir\temp"
[string]$work = "$tmp\work"
[boolean]$debug = $true

[string]$arj32 = "$curDir\util\arj32.exe"
[string]$archiver = "$curDir\util\gzip.exe"
[string]$extArchiver = "arj"

#настройка почты
#[string]$mail_addr = "tmn-f365@tmn.apkbank.apk"
[string]$mail_addr = "tmn-goe@tmn.apkbank.ru"
[string]$mail_server = "191.168.6.50"
[string]$mail_from = "atm_support@tmn.apkbank.apk"

#входящие - настройки
[string]$incoming_out = "$tmp\OUT"
[string]$incoming_files = "AFN_MIFNS00_7102803_*_000??.$extArchiver"
[string]$outcoming_post = "$tmp\Post"

#архив
[string]$440p_arhive = "$tmp\440p\Arhive"
[string]$440p_ack = "$tmp\440p\ack"
[string]$440p_err = "$tmp\440p\error"
[string]$arm440 = "$tmp\ARM_440"

#комита
[string]$comita_in = "$tmp\BANK"

#Параметры СКАД-Сигнатуры
[string]$spki = "C:\Program Files\MDPREI\spki\spki1utl.exe"
[string]$vdkeys = "d:\SKAD\Floppy\foiv"
[string]$profile = "r2880_2"
[string]$recList = "$curDir\util\Reclist.conf"

#имя лог-файлов
$curDate = Get-Date -Format "ddMMyyyy"
[string]$logName440 = (Get-Item $PSCommandPath ).DirectoryName + "\log\" + $curDate + "_f440.log"
[string]$logSpki = (Get-Item $PSCommandPath ).DirectoryName + "\log\" + $curDate + "_spki.log"
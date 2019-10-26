[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#рабочий каталог, где будут подписываться и шифроваться файлы
[string]$tmp = "$curDir\temp"
[string]$work = "$tmp\work"

[string]$arj32 = "$curDir\util\arj32.exe"

#настройка почты
[string]$mail_addr = "tmn-f365@tmn.apkbank.apk"
#[string]$mail_addr = "tmn-goe@tmn.apkbank.ru"
[string]$mail_server = "191.168.6.50"
[string]$mail_from = "atm_support@tmn.apkbank.apk"

#входящие - настройки
[string]$incoming_out = "$tmp\OUT"
[string]$incoming_files = "AFN_MIFNS00_7102803_*_000??.ARJ"
[string]$outcoming_post = "$tmp\Post"

#архив
[string]$440p_arhive = "$tmp\440p\Arhive"
[string]$440p_ack = "$tmp\440p\ack"
[string]$440p_err = "$tmp\440p\error"

#комита
[string]$comita_in = "$tmp\BANK"

#имя лог-файла
[string]$logName = $curDir + "\log\form440p.log"

[string]$spki = "C:\Program Files\MDPREI\spki\spki1utl.exe"
[string]$vdkeys = "d:\SKAD\Floppy\DISKET2019-skad-test\test1"
[string]$profile = "OT_TestFOIV"



#скрипты для подписи и шифрования
[string]$scripts = "$curDir\scripts"
[string]$script_unsig = "$scripts\440UnSign.scr"
[string]$script_uncrypt = "$scripts\440UnCript.scr"
[string]$script_sig = "$scripts\send440Sign.scr"
[string]$script_crypt = "$scripts\send440Cript.scr"

#дискеты для подписи и шифрования
[string]$disk_sig = "C:\DISKET2019\disk\disk22"
[string]$disk_crypt = "c:\DISKET2019\Disk\DISK21"
[string]$disk_sig_send = "c:\DISKET2018-1\Disk\DISK2"

#путь до программы шифрования и архиватор
[string]$verba = "c:\Program Files\MDPREI\РМП Верба-OW\FColseOW.exe"

#Каталог XSD-схем
[string]$schemaCatalog = "$curDir\xsd-schemas"

#каталог на московском сервере, с отчетами для налоговой
[string]$arm440 = "$tmp\ARM_440"
[string]$arm440_ul = "$arm440\ANSWER_UL"
[string]$arm440_fl = "$arm440\ANSWER_FL"

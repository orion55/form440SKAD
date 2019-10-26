[string]$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent

#рабочий каталог, где будут подписываться и шифроваться файлы
[string]$work = "c:\work"

#скрипты для подписи и шифрования
[string]$scripts = "$dir1\scripts"
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
[string]$arj32 = "$dir1\util\arj32.exe"

#каталог на московском сервере, с отчетами для налоговой
[string]$arm440 = "\\191.168.6.12\quorum\TMN\ARM_440"
[string]$arm440_ul = "$arm440\ANSWER_UL"
[string]$arm440_fl = "$arm440\ANSWER_FL"

#настройка почты
[string]$mail_addr = "tmn-f365@tmn.apkbank.apk"
#[string]$mail_addr = "tmn-goe@tmn.apkbank.ru"
[string]$mail_server = "191.168.6.50"
[string]$mail_from = "atm_support@tmn.apkbank.apk"

#входящие - настройки
[string]$incoming_out = "l:\PTK PSD\Post\ELO\OUT"
[string]$incoming_files = "AFN_MIFNS00_7102803_*_000??.ARJ"
[string]$outcoming_post = "l:\PTK PSD\Post\Post"

#архив
[string]$440p_arhive = "\\tmn-ts-01\440p\Arhive"
[string]$440p_ack = "\\tmn-ts-01\440p\ack"
[string]$440p_err = "\\tmn-ts-01\440p\error"

#комита
[string]$comita_in = "\\TMN-EMPTY-01\Arm_365\Files\CSCP\GCI\BANK"

#имя лог-файла
[string]$logName = (Get-Item $PSCommandPath ).DirectoryName + "\log\form440p.log"

#Каталог XSD-схем
[string]$schemaCatalog = "$dir1\xsd-schemas"
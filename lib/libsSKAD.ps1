#копируем каталоги рекурсивно на "волшебный" диск А: - туда и обратно
function Copy_dirs {
	Param(
		[string]$from,
		[string]$to)

	Get-ChildItem -Path $from -Recurse |
	Copy-Item -Destination {
		if ($_.PSIsContainer) {
			Join-Path $to $_.Parent.FullName.Substring($from.length)
		}
		else {
			Join-Path $to $_.FullName.Substring($from.length)
		}
	} -Force
}

function kwtfcbCheck {
	$kwtFiles = Get-ChildItem "$work\KWTFCB_*.xml"
	if ($kwtFiles.count -eq 0) {
		return
	}
	$errorArr = @()
	$successArr = @()
	$flag = $true
	foreach ($kwt in $kwtFiles) {
		[xml]$xml = Get-Content $kwt
		$result = $xml.Файл.КВТНОПРИНТ.Результат
		if (!$result) {
			$result = $xml.Файл.КВТНОПРИНТ
			if (!$result) {
				$flag = $false
			}
		}
		elseif ($result.КодРезПроверки -ne "01") {
			$flag = $false
		}

		if ($flag) {
			$successArr += $kwt.Name
		}
		else {
			$errorArr += $kwt.Name
		}
		$flag = $true
	}

	$curDate = Get-Date -Format "ddMMyyyy"
	$body = ""
	$title = ""

	if ($successArr.Count -ne 0) {
		$succPath = $440p_ack + '\' + $curDate
		if (!(Test-Path $succPath)) {
			New-Item -ItemType directory -Path $succPath | out-Null
		}
		Write-Log -EntryType Information -Message "Пришли подтверждения"
		foreach ($file in $successArr) {
			$msg = Copy-Item -Path "$work\$file" -Destination $succPath -ErrorAction "SilentlyContinue" -Verbose -Force *>&1
			Write-Log -EntryType Information -Message ($msg | Out-String)
		}
		$count = $successArr.Count
		$body += "Пришли успешные подтверждения - $count шт.`n"
		$body += "Потверждения находятся в каталоге $succPath`n"
		$body += "`n"
		$title = "Пришли подтверждения по 440П"
	}

	if ($errorArr.Count -ne 0) {
		$errPath = $440p_err + '\' + $curDate
		if (!(Test-Path $errPath)) {
			New-Item -ItemType directory -Path $errPath | out-Null
		}
		Write-Log -EntryType Error -Message "Пришли подтверждения с ошибками!"
		foreach ($file in $errorArr) {
			$msg = Copy-Item -Path "$work\$file" -Destination $errPath -ErrorAction "SilentlyContinue" -Verbose -Force *>&1
			Write-Log -EntryType Information -Message ($msg | Out-String)
		}
		$count = $errorArr.Count
		$body += "Пришли подтверждения с ошибками - $count шт.`n"
		$body += $errorArr -join "`n"
		$body += "`n"
		$body += "Потверждения находятся в каталоге $errPath`n"
		$title = "Пришли подтверждения с ошибками по 440П"
	}
	if (Test-Connection $mail_server -Quiet -Count 2) {
		$encoding = [System.Text.Encoding]::UTF8
		Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
	}
	else {
		Write-Log -EntryType Error -Message "Не удалось соединиться с почтовым сервером $mail_server"
	}
	Write-Log -EntryType Information -Message $body

	$msg = Copy-Item -Path "$work\KWTFCB_*.xml" -Destination $arm440 -ErrorAction "SilentlyContinue"  -Verbose -Force *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)
	$msg = Copy-Item -Path "$work\KWTFCB_*.xml" -Destination $comita_in -ErrorAction "SilentlyContinue"  -Verbose -Force *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)
	$msg = Remove-Item -Path "$work\KWTFCB_*.xml" -Verbose -Force *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)
}

function documentsCheck {
	$docFiles = Get-ChildItem "$work\*.xml"
	if ($docFiles.count -eq 0) {
		return
	}
	$typeDocs = @{resolution = 0; charge = 0; request = 0; demand = 0; other = 0 }
	$resolution = 'RPO', 'ROO', 'APN', 'APO', 'APZ'
	$charge = 'PNO', 'PPD', 'PKO'
	$request = 'ZSN', 'ZSO', 'ZSV'
	$demand = 'TRB', 'TRG'

	foreach ($file in $docFiles) {
		$firstChars = $file.BaseName.Substring(0, 3)
		if ($resolution -contains $firstChars) {
			$typeDocs.resolution++
		}
		elseif ($charge -contains $firstChars) {
			$typeDocs.charge++
		}
		elseif ($request -contains $firstChars) {
			$typeDocs.request++
		}
		elseif ($demand -contains $firstChars) {
			$typeDocs.demand++
		}
		else {
			$typeDocs.other++
		}
	}

	$title = "Пришли сообщения по 440П"
	$count = $docFiles.count
	$body = "Пришло всего $count сообщений`n"
	$body += "Из них:`n"

	if ($typeDocs.resolution -gt 0) {
		$body += "Решения: " + $typeDocs.resolution + "`n"
	}
	if ($typeDocs.charge -gt 0) {
		$body += "Поручения: " + $typeDocs.charge + "`n"
	}
	if ($typeDocs.request -gt 0) {
		$body += "Запросы: " + $typeDocs.request + "`n"
	}
	if ($typeDocs.demand -gt 0) {
		$body += "Требования: " + $typeDocs.demand + "`n"
	}
	if ($typeDocs.other -gt 0) {
		$body += "Прочие документы: " + $typeDocs.other + "`n"
	}

	if (Test-Connection $mail_server -Quiet -Count 2) {
		$encoding = [System.Text.Encoding]::UTF8
		Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
		Write-Log -EntryType Information -Message $body
	}
	else {
		Write-Log -EntryType Error -Message "Не удалось соединиться с почтовым сервером $mail_server"
	}

	$curDate = Get-Date -Format "ddMMyyyy"
	$arhivePath = $440p_arhive + '\' + $curDate
	if (!(Test-Path $arhivePath)) {
		New-Item -ItemType directory -Path $arhivePath | out-Null
	}
	$msg = Copy-Item -Path "$work\*.xml" -Destination $arhivePath -ErrorAction "SilentlyContinue" -Verbose -Force *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)
	$msg = Copy-Item -Path "$work\*.xml" -Destination $arm440 -ErrorAction "SilentlyContinue" -Verbose -Force *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)
	$msg = Copy-Item -Path "$work\*.xml" -Destination $comita_in -ErrorAction "SilentlyContinue" -Verbose -Force *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)
	$msg = Remove-Item -Path "$work\*.xml" -Verbose -Force *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)
}

function Test-FileLock {
	param (
		[parameter(Mandatory = $true)][string]$Path
	)

	$oFile = New-Object System.IO.FileInfo $Path

	if ((Test-Path -Path $Path) -eq $false) {
		return $false
	}

	try {
		$oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)

		if ($oStream) {
			$oStream.Close()
		}
		$false
	}
 catch {
		# file is locked by a process.
		return $true
	}
}

function Check-FilesLock {
	param (
		[parameter(Mandatory = $true)][array]$in_files
	)

	$lock_files = @()
	foreach ($in_file in $in_files) {
		if (Test-FileLock -Path $in_file.FullName) {
			$lock_files += $in_file.FullName;
		}
	}

	if ($lock_files.count -gt 0) {
		$encoding = [System.Text.Encoding]::UTF8
		$title = "Автоматический приём по форме 440П - прекращён!"
		$body = "Приём прекращён. Файлы заблокированы. Проведите разблокировку`n"
		$body += ($lock_files | Out-String)
		Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
		Write-Log -EntryType Error -Message $body
		exit
	}
}

function 440_in {
	$curDate = Get-Date -Format "ddMMyyyy"
	$arhivePath = $440p_arhive + '\' + $curDate
	if (!(Test-Path $arhivePath)) {
		New-Item -ItemType directory -Path $arhivePath | out-Null
	}

	Write-Log -EntryType Information -Message "Загружаем ключевую дискету $vdkeys"
	Copy_dirs -from $vdkeys -to 'a:'

	$arj_files = Get-ChildItem "$work\*.$extArchiver"
	if ($arj_files.count -eq 0) {
		Write-Log -EntryType Error -Message "Файлы отчетности не найдены в каталоге $work"
		exit
	}
	#Проверяем блокировку файлов
	Check-FilesLock -in_files $arj_files

	#переносим файлы в архив
	Write-Log -EntryType Information -Message "Копирование файлов в архив $arhivePath"
	$msg = Copy-Item -Path "$work\*.$extArchiver" -Destination $arhivePath -Verbose -Force *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)

	#снимаем подпись с отчетов
	Write-Log -EntryType Information -Message "Снимаем подпись с $extArchiver-архивов"
	SKAD_Decrypt -decrypt $false -maskFiles "*.$extArchiver"
	arj_unpack

	Set-Location $work

	#снимаем подпись с xml-файлов
	$xmlFiles = Get-ChildItem "$work\*.xml"
	if (($xmlFiles | Measure-Object).count -gt 0) {
		Write-Log -EntryType Information -Message "Снимаем подпись с xml-файлов"
		SKAD_Decrypt -decrypt $false -maskFiles "*.xml"
	}

	$vrbFiles = Get-ChildItem "$work\*.vrb"
	if (($vrbFiles | Measure-Object).count -gt 0) {
		#расшифровываем файлы
		Write-Log -EntryType Information -Message "Расшифровываем vrb-файлы"
		SKAD_Decrypt -decrypt $true -maskFiles "*.VRB"

		Write-Log -EntryType Information -Message "Переименовываем файлы в xml"
		$msg = Get-ChildItem '*.vrb' | Rename-Item -NewName { $_.Name -replace '.vrb$', '.xml' } -Verbose -Force *>&1
		Write-Log -EntryType Information -Message ($msg | Out-String)
	}

	Write-Log -EntryType Information -Message "Форматируем xml-файлы"
	$files_xml = Get-ChildItem -Path "*.xml"
	foreach ($file_xml in $files_xml) {
		[xml]$xml = Get-Content $file_xml
		$xml.Save($file_xml)
	}
}
function arj_unpack {
	Write-Log -EntryType Information -Message "Начинаем разархивацию..."
	$tmp_arj = "$curDir\tmp_arj"
	if (!(Test-Path $tmp_arj)) {
		New-Item -ItemType directory -Path $tmp_arj | out-Null
	}

	Set-Location $tmp_arj

	$err_files = @()
	foreach ($arj_file in $arj_files) {
		Write-Log -EntryType Information -Message "Разархивация файла $arj_file"

		if ($extArchiver -eq 'arj'){
			$arg_list = "e -y $arj_file"
		}
		if ($extArchiver -eq 'zip'){
			$arg_list = "e $arj_file -o""$tmp_arj"""
		}

		$arjProc = Start-Process -FilePath $archiver -ArgumentList $arg_list -Wait -NoNewWindow

		if ($arjProc -eq $null) {
			Copy-Item "$tmp_arj\*.*" -Destination $work -Force -Exclude "*.$extArchiver"
			Remove-Item "$tmp_arj\*.*"
		}
		else {
			$err_files += $arj_file.FullName;
		}
	}

	if ($err_files.count -gt 0) {
		if (Test-Connection $mail_server -Quiet -Count 2) {
			$encoding = [System.Text.Encoding]::UTF8
			$title = "Автоматический приём по форме 440П - прекращён!"
			$body = "Приём прекращён. Архивы повреждены`n"
			$body += ($err_files | Out-String)
			Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
		}
		else {
			Write-Log -EntryType Error -Message "Не удалось соединиться с почтовым сервером $mail_server"
		}
		Write-Log -EntryType Error -Message $body
		exit
	}

	Remove-Item $tmp_arj -Force -ErrorAction SilentlyContinue -Recurse

	Remove-Item -Path "$work\*.$extArchiver"

	Set-Location $curDir
}

function documentsCheckSend {
	$docFiles = Get-ChildItem "$work\*.xml"
	if ($docFiles.count -eq 0) {
		return
	}
	$typeDocs = @{message = 0; ref = 0; notice = 0; info = 0; extract = 0; query = 0; confirmation = 0; other = 0 }
	[string]$message = 'BNP'
	$ref = 'BNS', 'BOS'
	[string]$notice = 'BUV'
	[string]$info = 'BVD'
	[string]$extract = 'BVS'
	[string]$query = 'BZ1'
	[string]$confirmation = 'PB'

	foreach ($file in $docFiles) {
		$firstChars = $file.BaseName.Substring(0, 3)
		$firstChars2 = $file.BaseName.Substring(0, 2)
		if ($message -contains $firstChars) {
			$typeDocs.message++
		}
		elseif ($ref -contains $firstChars) {
			$typeDocs.ref++
		}
		elseif ($notice -contains $firstChars) {
			$typeDocs.notice++
		}
		elseif ($info -contains $firstChars) {
			$typeDocs.info++
		}
		elseif ($extract -contains $firstChars) {
			$typeDocs.extract++
		}
		elseif ($query -contains $firstChars) {
			$typeDocs.query++
		}
		elseif ($confirmation -contains $firstChars2) {
			$typeDocs.confirmation++
		}
		else {
			$typeDocs.other++
		}
	}

	$count = $docFiles.count
	$body = "Отправленно всего $count сообщений`n"
	$body += "Из них:`n"

	if ($typeDocs.message -gt 0) {
		$body += "Сообщения: " + $typeDocs.message + "`n"
	}
	if ($typeDocs.ref -gt 0) {
		$body += "Справка: " + $typeDocs.ref + "`n"
	}
	if ($typeDocs.notice -gt 0) {
		$body += "Уведомления: " + $typeDocs.notice + "`n"
	}
	if ($typeDocs.info -gt 0) {
		$body += "Сведения: " + $typeDocs.info + "`n"
	}
	if ($typeDocs.extract -gt 0) {
		$body += "Выписка: " + $typeDocs.extract + "`n"
	}
	if ($typeDocs.query -gt 0) {
		$body += "Запрос: " + $typeDocs.query + "`n"
	}
	if ($typeDocs.confirmation -gt 0) {
		$body += "Потверждения: " + $typeDocs.confirmation + "`n"
	}
	if ($typeDocs.other -gt 0) {
		$body += "Прочие документы: " + $typeDocs.other + "`n"
	}

	return $body
}

Function 440_out {
	#проверяем типы сообщений для отправки
	[string]$body = documentsCheckSend

	$curDate = Get-Date -Format "ddMMyyyy"
	$arhivePath = $440p_arhive + '\' + $curDate
	if (!(Test-Path $arhivePath)) {
		New-Item -ItemType directory -Path $arhivePath | out-Null
	}

	Stop-HostLog
	$msg = Copy-Item -Path "$work\*.xml" -Destination $arhivePath -Verbose -Force *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)
	Start-HostLog -LogLevel Information
	Write-Log -EntryType Information -Message "Копирование файлов в архив $arhivePath"

	Write-Log -EntryType Information -Message "Переименовываем файлы *.xml -> *.vrb"
	Get-ChildItem "$work\b*.xml" -Exclude "$work\bz1*.xml" | rename-item -newname { $_.name -replace '\.xml', '.vrb' }

	#подписываем все файлы
	Write-Log -EntryType Information -Message "Загружаем ключевую дискету $vdkeys"
	Copy_dirs -from $vdkeys -to 'a:'

	$vrbFiles = Get-ChildItem "$work\*.vrb"
	if ($vrbFiles.count -gt 0) {
		#зашифровываем и подписываем файлы
		Write-Log -EntryType Information -Message "Зашифровываем и подписываем vrb-файлы"
		SKAD_Encrypt -encrypt $true -maskFiles "*.vrb"
	}

	$someFiles = Get-ChildItem "$work\*.xml"
	if ($someFiles.count -gt 0) {
		#подписываем файлы
		Write-Log -EntryType Information -Message "Подписываем оставшиеся файлы файлы"
		SKAD_Encrypt -encrypt $false -maskFiles "*.xml"
	}

	if ($debug) {
		$afnFiles = Get-ChildItem "$arhivePath\AFN_7102803_MIFNS00_*.$extArchiver.tst"
	}
	else {
		$afnFiles = Get-ChildItem "$arhivePath\AFN_7102803_MIFNS00_*.$extArchiver"
	}
	$afnCount = ($afnFiles | Measure-Object).count
	$afnCount++
	$afnCountStr = $afnCount.ToString("00000")

	$curDateAfn = Get-Date -Format "yyyyMMdd"

	$afnFileName = "AFN_7102803_MIFNS00_" + $curDateAfn + "_" + $afnCountStr + "." + $extArchiver

	Write-Log -EntryType Information -Message "Начинаем архивацию..."
	if ($debug) {
		if ($extArchiver -eq 'arj') {
			$AllArgs = @('a', '-e', "$work\$afnFileName", "$work\*.xml.tst", "$work\*.vrb.tst")
		}
		if ($extArchiver -eq 'zip') {
			$AllArgs = @('a', '-tzip', '-ssw', "$work\$afnFileName", "$work\*.xml.tst", "$work\*.vrb.tst")
		}

	}
	else {
		if ($extArchiver -eq 'arj') {
			$AllArgs = @('a', '-e', "$work\$afnFileName", "$work\*.xml", "$work\*.vrb")
		}
		if ($extArchiver -eq 'zip') {
			$AllArgs = @('a', '-tzip', '-ssw', "$work\$afnFileName", "$work\*.xml", "$work\*.vrb")
		}
	}
	&$archiver	$AllArgs

	$msg = Remove-Item "$work\*.*" -Exclude "AFN_7102803_MIFNS00_*.$extArchiver" -Verbose *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)

	#подписываем все файлы
	Write-Log -EntryType Information -Message "Подписываем файл архива $work\$afnFileName"
	SKAD_Encrypt -encrypt $false -maskFiles "*.$extArchiver"

	if ($debug) {
		$afnFileName = $afnFileName + ".tst"
	}

	Write-Log -EntryType Information -Message "Копируем файл архива $afnFileName в $arhivePath"
	Copy-Item "$work\$afnFileName" -Destination $arhivePath -Force
	Write-Log -EntryType Information -Message "Копируем файл архива $afnFileName в $outcoming_post"
	Copy-Item "$work\$afnFileName" -Destination $outcoming_post -Force

	$msg = Remove-Item "$work\$afnFileName" -Verbose *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)

	Write-Log -EntryType Information -Message "Отправка почтового сообщения"
	if (Test-Connection $mail_server -Quiet -Count 2) {
		$title = "Отправлены сообщения по 440П SKAD Signatura"
		$encoding = [System.Text.Encoding]::UTF8
		Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
	}
	else {
		Write-Log -EntryType Error -Message "Не удалось соединиться с почтовым сервером $mail_server"
	}
	Write-Log -EntryType Information -Message $body
}

function SKAD_Encrypt {
	Param(
		$encrypt = $false,
		[string]$maskFiles = "*.*")

	<#$Database = "$tmp\Names.SQLite"
	if (Test-Path -Path $Database) {
		Remove-Item $Database
	}#>
	$Database = ":MEMORY:"
	$memoryConn = New-SQLiteConnection -DataSource $Database

	[int]$amount = 0
	[string]$tmp = "$curDir\tmp"

	do {
		$query = "CREATE TABLE FiLES (
	    namefile VARCHAR (100) NOT NULL UNIQUE,
	    lengthfile INTEGER NOT NULL,
	    PRIMARY KEY(namefile)
        );
        CREATE TABLE NEWFiLES (
	    namefile VARCHAR (100) NOT NULL UNIQUE,
	    lengthfile INTEGER NOT NULL,
	    PRIMARY KEY(namefile)
        );"

		Invoke-SqliteQuery -Query $query -SQLiteConnection $memoryConn

		$mask = Get-ChildItem -path $work $maskFiles
		$DataTable = $mask | % {
			[pscustomobject]@{
				namefile   = $_.Name
				lengthfile = $_.Length
			}
		} | Out-DataTable

		if (($DataTable | Measure-Object).count -eq 0) {
			$amount = 1
			break
		}

		Invoke-SQLiteBulkCopy -DataTable $DataTable -Table FiLES -Force -SQLiteConnection $memoryConn

		Write-Log -EntryType Information -Message "Начинаем преобразование..."

		foreach ($file in $mask) {
			$tmpFile = $file.FullName + '.test'

			$arguments = ''
			if ($encrypt) {
				$arguments = "-sign -encrypt -profile $profile -registry -algorithm 1.2.643.7.1.1.2.2 -in $($file.FullName) -out $tmpFile -reclist $recList -silent $logSpki"
			}
			else {
				$arguments = "-sign -profile $profile -registry -algorithm 1.2.643.7.1.1.2.2 -data $($file.FullName) -out $tmpFile -reclist $recList -silent $logSpki"
			}

			Write-Log -EntryType Information -Message "Обрабатываем файл $($file.Name)"
			Start-Process $spki $arguments -NoNewWindow -Wait
		}
		$testFiles = Get-ChildItem "$work\*.test"
		if (($testFiles | Measure-Object).count -gt 0) {
			$msg = $mask | Remove-Item -Verbose -Force *>&1
			Write-Log -EntryType Information -Message ($msg | Out-String)
			if ($debug) {
				$msg = Get-ChildItem -path $work '*.test' | Rename-Item -NewName { $_.Name -replace '.test$', '.tst' } -Verbose *>&1
			}
			else {
				$msg = Get-ChildItem -path $work '*.test' | Rename-Item -NewName { $_.Name -replace '.test$', '' } -Verbose *>&1
			}

			Write-Log -EntryType Information -Message ($msg | Out-String)
		}
		else {
			Write-Log -EntryType Error -Message "Ошибка при работе программы $spki"
			exit
		}

		#проверяем действительно или все файлы подписаны\расшифрованы
		Write-Log -EntryType Information -Message "Сравниваем до и после преобразования..."

		$DataTable = Get-ChildItem -path $work $maskFiles | % {
			[pscustomobject]@{
				namefile   = $_.Name
				lengthfile = $_.Length
			}
		} | Out-DataTable

		if (($DataTable | Measure-Object).count -eq 0) {
			$amount = 1
			break
		}
		Invoke-SQLiteBulkCopy -DataTable $DataTable -Table NEWFiLES -Force -SQLiteConnection $memoryConn

		#сравниваем старую и новую длину файлов, и показываем те файлы у которых длина не изменилась (т.е. преобразование не было осуществлено)
		$query = "select FiLES.namefile from FiLES join NEWFiLES on FiLES.namefile = NEWFiLES.namefile where FiLES.lengthfile = NEWFiLES.lengthfile"
		$namefiles = Invoke-SqliteQuery -Query $query -SQLiteConnection $memoryConn

		#если не все преобразованы, повторяем процесс
		$count = ($namefiles | Measure-Object).Count
		if ($count -ne 0) {

			Write-Log -EntryType Error -Message "Часть файлов не были преобразованы!"

			if (!(Test-Path $tmp)) {
				New-Item -ItemType directory -Path $tmp | out-Null
			}
			$excludeArray = @()
			$namefiles.namefile | % { $excludeArray += $_ }

			$files1 = Get-ChildItem "$work\$mask" -Exclude $excludeArray
			foreach ($ff2 in $files1) {
				Move-Item -Path $ff2 -Destination $tmp
			}

			$query = "drop table FiLES;
				drop table NEWFiLES;"

			Invoke-SqliteQuery -Query $query -SQLiteConnection $memoryConn
		}
		$amount--
	} until ($count -eq 0 -or $amount -eq 0)

	if (Test-Path $tmp) {
		Move-Item -Path "$tmp\*.*" -Destination $work
		Remove-Item -Recurse $tmp
	}

	if ($amount -eq 0) {
		Write-Log -EntryType Error -Message "Ошибка при работе со SKAD Signatura"
		exit
	}

	$memoryConn.Close()

}
function SKAD_Decrypt {
	Param(
		$decrypt = $false,
		[string]$maskFiles = "*.*")

	Write-Log -EntryType Information -Message "Начинаем преобразование..."
	$mask = Get-ChildItem -path $work $maskFiles

	foreach ($file in $mask) {
		$tmpFile = $file.FullName + '.test'

		$arguments = ''
		if ($decrypt) {
			$arguments = "-decrypt -verify -delete -1 -profile $profile -registry -in $($file.FullName) -out $tmpFile -silent $logSpki"
		}
		else {
			$arguments = "-verify -delete -1 -profile $profile -registry -in $($file.FullName) -out $tmpFile -silent $logSpki"
		}

		Write-Log -EntryType Information -Message "Обрабатываем файл $($file.Name)"
		Start-Process $spki $arguments -NoNewWindow -Wait
	}

	$testFiles = Get-ChildItem "$work\*.test"
	if (($testFiles | Measure-Object).count -gt 0) {
		$msg = $mask | Remove-Item -Verbose -Force *>&1
		Write-Log -EntryType Information -Message ($msg | Out-String)
		$msg = Get-ChildItem -path $work '*.test' | Rename-Item -NewName { $_.Name -replace '.test$', '' } -Verbose *>&1
		Write-Log -EntryType Information -Message ($msg | Out-String)
	}
	else {
		Write-Log -EntryType Error -Message "Ошибка при работе программы $spki"
		exit
	}

}

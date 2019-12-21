#�������� �������� ���������� �� "���������" ���� �: - ���� � �������
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
		$result = $xml.����.����������.���������
		if (!$result) {
			$result = $xml.����.����������
			if (!$result) {
				$flag = $false
			}
		}
		elseif ($result.�������������� -ne "01") {
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
		Write-Log -EntryType Information -Message "������ �������������"
		foreach ($file in $successArr) {
			$msg = Copy-Item -Path "$work\$file" -Destination $succPath -ErrorAction "SilentlyContinue" -Verbose -Force *>&1
			Write-Log -EntryType Information -Message ($msg | Out-String)
		}
		$count = $successArr.Count
		$body += "������ �������� ������������� - $count ��.`n"
		$body += "������������ ��������� � �������� $succPath`n"
		$body += "`n"
		$title = "������ ������������� �� 440�"
	}

	if ($errorArr.Count -ne 0) {
		$errPath = $440p_err + '\' + $curDate
		if (!(Test-Path $errPath)) {
			New-Item -ItemType directory -Path $errPath | out-Null
		}
		Write-Log -EntryType Error -Message "������ ������������� � ��������!"
		foreach ($file in $errorArr) {
			$msg = Copy-Item -Path "$work\$file" -Destination $errPath -ErrorAction "SilentlyContinue" -Verbose -Force *>&1
			Write-Log -EntryType Information -Message ($msg | Out-String)
		}
		$count = $errorArr.Count
		$body += "������ ������������� � �������� - $count ��.`n"
		$body += $errorArr -join "`n"
		$body += "`n"
		$body += "������������ ��������� � �������� $errPath`n"
		$title = "������ ������������� � �������� �� 440�"
	}
	if (Test-Connection $mail_server -Quiet -Count 2) {
		$encoding = [System.Text.Encoding]::UTF8
		Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
	}
	else {
		Write-Log -EntryType Error -Message "�� ������� ����������� � �������� �������� $mail_server"
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

	$title = "������ ��������� �� 440�"
	$count = $docFiles.count
	$body = "������ ����� $count ���������`n"
	$body += "�� ���:`n"

	if ($typeDocs.resolution -gt 0) {
		$body += "�������: " + $typeDocs.resolution + "`n"
	}
	if ($typeDocs.charge -gt 0) {
		$body += "���������: " + $typeDocs.charge + "`n"
	}
	if ($typeDocs.request -gt 0) {
		$body += "�������: " + $typeDocs.request + "`n"
	}
	if ($typeDocs.demand -gt 0) {
		$body += "����������: " + $typeDocs.demand + "`n"
	}
	if ($typeDocs.other -gt 0) {
		$body += "������ ���������: " + $typeDocs.other + "`n"
	}

	if (Test-Connection $mail_server -Quiet -Count 2) {
		$encoding = [System.Text.Encoding]::UTF8
		Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
	}
	else {
		Write-Log -EntryType Error -Message "�� ������� ����������� � �������� �������� $mail_server"
	}
	Write-Log -EntryType Information -Message $body

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
		$title = "�������������� ���� �� ����� 440� - ���������!"
		$body = "���� ���������. ����� �������������. ��������� �������������`n"
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

	Write-Log -EntryType Information -Message "��������� �������� ������� $vdkeys"
	Copy_dirs -from $vdkeys -to 'a:'

	$arj_files = Get-ChildItem "$work\*.$extArchiver"
	if ($arj_files.count -eq 0) {
		Write-Log -EntryType Error -Message "����� ���������� �� ������� � �������� $work"
		exit
	}
	#��������� ���������� ������
	#Check-FilesLock -in_files $arj_files

	#��������� ����� � �����
	Write-Log -EntryType Information -Message "����������� ������ � ����� $arhivePath"
	$msg = Copy-Item -Path "$work\*.$extArchiver" -Destination $arhivePath -Verbose -Force *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)

	#������� ������� � �������
	Write-Log -EntryType Information -Message "������� ������� � $extArchiver-�������"
	SKAD_Decrypt -decrypt $false -maskFiles "*.$extArchiver"
	arj_unpack

	Set-Location $work

	$vrbFiles = Get-ChildItem "$work\*.vrb"
	if (($vrbFiles | Measure-Object).count -gt 0) {
		Write-Log -EntryType Information -Message "�������������� vrb-�����"
		SKAD_Decrypt -decrypt $true -maskFiles "*.vrb"

		Write-Log -EntryType Information -Message "������������� vrb-�����"
		$msg = Get-ChildItem '*.vrb' | Rename-Item -NewName { $_.Name -replace '.vrb$', '.vrb.gz' } -Verbose -Force *>&1
		Write-Log -EntryType Information -Message ($msg | Out-String)
		SKAD_Decompress -maskFiles "*.gz"

		Write-Log -EntryType Information -Message "��������������� ����� � xml"
		$msg = Get-ChildItem '*.vrb' | Rename-Item -NewName { $_.Name -replace '.vrb$', '.xml' } -Verbose -Force *>&1
		Write-Log -EntryType Information -Message ($msg | Out-String)
	}

	#������� ������� �� ���� ������
	$xmlFiles = Get-ChildItem "$work\*.*"
	if (($xmlFiles | Measure-Object).count -gt 0) {
		Write-Log -EntryType Information -Message "������� ������� �� ���� ������"
		SKAD_Decrypt -decrypt $false -maskFiles "*.*"
	}

	Write-Log -EntryType Information -Message "����������� xml-�����"
	$files_xml = Get-ChildItem -Path "*.xml"
	foreach ($file_xml in $files_xml) {
		[xml]$xml = Get-Content $file_xml
		$xml.Save($file_xml)
	}
}
function arj_unpack {
	Write-Log -EntryType Information -Message "�������� ������������..."
	$tmp_arj = "$curDir\tmp_arj"
	if (!(Test-Path $tmp_arj)) {
		New-Item -ItemType directory -Path $tmp_arj | out-Null
	}

	Set-Location $tmp_arj

	$err_files = @()
	foreach ($arj_file in $arj_files) {
		Write-Log -EntryType Information -Message "������������ ����� $arj_file"
		$arg_list = "e -y $arj_file"
		Start-Process -FilePath $arj32 -ArgumentList $arg_list -Wait -NoNewWindow

		$miscFiles = Get-ChildItem "$tmp_arj\*.*"
		if (($miscFiles | Measure-Object).count -gt 0) {
			$msg = Copy-Item "$tmp_arj\*.*" -Destination $work -Force -Exclude "*.$extArchiver" -Verbose *>&1
			Write-Log -EntryType Information -Message ($msg | Out-String)
			$msg = Remove-Item "$tmp_arj\*.*" -Verbose *>&1
			Write-Log -EntryType Information -Message ($msg | Out-String)
		}
		else {
			$err_files += $arj_file.FullName;
		}
	}

	if ($err_files.count -gt 0) {
		if (Test-Connection $mail_server -Quiet -Count 2) {
			$encoding = [System.Text.Encoding]::UTF8
			$title = "�������������� ���� �� ����� 440� - ���������!"
			$body = "���� ���������. ������ ����������`n"
			$body += ($err_files | Out-String)
			Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
		}
		else {
			Write-Log -EntryType Error -Message "�� ������� ����������� � �������� �������� $mail_server"
		}
		Write-Log -EntryType Error -Message $body
		exit
	}

	$msg = Remove-Item -Path "$work\*.$extArchiver"  -Verbose *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)

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
	$body = "����������� ����� $count ���������`n"
	$body += "�� ���:`n"

	if ($typeDocs.message -gt 0) {
		$body += "���������: " + $typeDocs.message + "`n"
	}
	if ($typeDocs.ref -gt 0) {
		$body += "�������: " + $typeDocs.ref + "`n"
	}
	if ($typeDocs.notice -gt 0) {
		$body += "�����������: " + $typeDocs.notice + "`n"
	}
	if ($typeDocs.info -gt 0) {
		$body += "��������: " + $typeDocs.info + "`n"
	}
	if ($typeDocs.extract -gt 0) {
		$body += "�������: " + $typeDocs.extract + "`n"
	}
	if ($typeDocs.query -gt 0) {
		$body += "������: " + $typeDocs.query + "`n"
	}
	if ($typeDocs.confirmation -gt 0) {
		$body += "������������: " + $typeDocs.confirmation + "`n"
	}
	if ($typeDocs.other -gt 0) {
		$body += "������ ���������: " + $typeDocs.other + "`n"
	}

	return $body
}

Function 440_out {
	#��������� ���� ��������� ��� ��������
	[string]$body = documentsCheckSend

	$curDate = Get-Date -Format "ddMMyyyy"
	$arhivePath = $440p_arhive + '\' + $curDate
	if (!(Test-Path $arhivePath)) {
		New-Item -ItemType directory -Path $arhivePath | out-Null
	}

	Write-Log -EntryType Information -Message "����������� ������ � ����� $arhivePath"
	$msg = Copy-Item -Path "$work\*.xml" -Destination $arhivePath -Verbose -Force *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)

	Write-Log -EntryType Information -Message "��������� �������� ������� $vdkeys"
	Copy_dirs -from $vdkeys -to 'a:'

	Write-Log -EntryType Information -Message "��������������� ����� *.xml -> *.vrb"
	Get-ChildItem "$work\b*.xml" -Exclude "$work\bz1*.xml" | rename-item -newname { $_.name -replace '\.xml', '.vrb' }

	Write-Log -EntryType Information -Message "����������� ��� �����"
	SKAD_Encrypt -encrypt $false -maskFiles "*.*"

	$vrbFiles = Get-ChildItem "$work\*.vrb"
	if ($vrbFiles.count -gt 0) {
		Write-Log -EntryType Information -Message "���������� vrb-�����"
		SKAD_archive -maskFiles "*.vrb"

		#������������� �����
		Write-Log -EntryType Information -Message "������������� vrb-�����"
		SKAD_Encrypt -encrypt $true -maskFiles "*.vrb"
	}

	$afnFiles = Get-ChildItem "$arhivePath\AFN_7102803_MIFNS00_*.$extArchiver"

	$afnCount = ($afnFiles | Measure-Object).count
	$afnCount++
	$afnCountStr = $afnCount.ToString("00000")

	$curDateAfn = Get-Date -Format "yyyyMMdd"

	$afnFileName = "AFN_7102803_MIFNS00_" + $curDateAfn + "_" + $afnCountStr + "." + $extArchiver

	Write-Log -EntryType Information -Message "�������� ���������..."
	$AllArgs = @('a', '-e', "$work\$afnFileName", "$work\*.xml", "$work\*.vrb")
	&$arj32	$AllArgs

	$msg = Remove-Item "$work\*.*" -Exclude "AFN_7102803_MIFNS00_*.$extArchiver" -Verbose *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)

	#����������� ��� �����
	Write-Log -EntryType Information -Message "����������� ���� ������ $work\$afnFileName"
	SKAD_Encrypt -encrypt $false -maskFiles "*.$extArchiver"

	Write-Log -EntryType Information -Message "�������� ���� ������ $afnFileName � $arhivePath"
	Copy-Item "$work\$afnFileName" -Destination $arhivePath -Force
	Write-Log -EntryType Information -Message "�������� ���� ������ $afnFileName � $outcoming_post"
	Copy-Item "$work\$afnFileName" -Destination $outcoming_post -Force

	$msg = Remove-Item "$work\$afnFileName" -Verbose *>&1
	Write-Log -EntryType Information -Message ($msg | Out-String)

	Write-Log -EntryType Information -Message "�������� ��������� ���������"
	if (Test-Connection $mail_server -Quiet -Count 2) {
		$title = "���������� ��������� �� 440� SKAD Signatura"
		$encoding = [System.Text.Encoding]::UTF8
		Send-MailMessage -To $mail_addr -Body $body -Encoding $encoding -From $mail_from -Subject $title -SmtpServer $mail_server
	}
	else {
		Write-Log -EntryType Error -Message "�� ������� ����������� � �������� �������� $mail_server"
	}
	Write-Log -EntryType Information -Message $body
}

function SKAD_Encrypt_old {
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

		Write-Log -EntryType Information -Message "�������� ��������������..."

		foreach ($file in $mask) {
			$tmpFile = $file.FullName + '.test'

			$arguments = ''
			if ($encrypt) {
				$arguments = "-sign -encrypt -profile $profile -registry -algorithm 1.2.643.7.1.1.2.2 -in $($file.FullName) -out $tmpFile -reclist $recList -silent $logSpki"
			}
			else {
				$arguments = "-sign -profile $profile -registry -algorithm 1.2.643.7.1.1.2.2 -data $($file.FullName) -out $tmpFile -reclist $recList -silent $logSpki"
			}

			Write-Log -EntryType Information -Message "������������ ���� $($file.Name)"
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
			Write-Log -EntryType Error -Message "������ ��� ������ ��������� $spki"
			exit
		}

		#��������� ������������� ��� ��� ����� ���������\������������
		Write-Log -EntryType Information -Message "���������� �� � ����� ��������������..."

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

		#���������� ������ � ����� ����� ������, � ���������� �� ����� � ������� ����� �� ���������� (�.�. �������������� �� ���� ������������)
		$query = "select FiLES.namefile from FiLES join NEWFiLES on FiLES.namefile = NEWFiLES.namefile where FiLES.lengthfile = NEWFiLES.lengthfile"
		$namefiles = Invoke-SqliteQuery -Query $query -SQLiteConnection $memoryConn

		#���� �� ��� �������������, ��������� �������
		$count = ($namefiles | Measure-Object).Count
		if ($count -ne 0) {

			Write-Log -EntryType Error -Message "����� ������ �� ���� �������������!"

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
		Write-Log -EntryType Error -Message "������ ��� ������ �� SKAD Signatura"
		exit
	}

	$memoryConn.Close()

}
function SKAD_Decrypt {
	Param(
		$decrypt = $false,
		[string]$maskFiles = "*.*")

	Write-Log -EntryType Information -Message "�������� ��������������..."
	$mask = Get-ChildItem -path $work $maskFiles

	foreach ($file in $mask) {
		$tmpFile = $file.FullName + '.test'

		$arguments = ''
		if ($decrypt) {
			$arguments = "-decrypt -profile $profile -registry -in ""$($file.FullName)"" -out ""$tmpFile"" -silent $logSpki"
		}
		else {
			$arguments = "-verify -delete -1 -profile $profile -registry -in ""$($file.FullName)"" -out ""$tmpFile"" -silent $logSpki"
		}

		Write-Log -EntryType Information -Message "������������ ���� $($file.Name)"
		Start-Process $spki $arguments -NoNewWindow -Wait
	}

	$testFiles = Get-ChildItem "$work\*.test"
	if (($testFiles | Measure-Object).count -gt 0) {
		$msg = $testFiles | ForEach-Object { $_.FullName -replace '.test$', '' } | Remove-Item -Verbose -Force *>&1
		Write-Log -EntryType Information -Message ($msg | Out-String)
		$msg = Get-ChildItem -path $work '*.test' | Rename-Item -NewName { $_.Name -replace '.test$', '' } -Verbose *>&1
		Write-Log -EntryType Information -Message ($msg | Out-String)
	}
	else {
		Write-Log -EntryType Error -Message "������ ��� ������ ��������� $spki"
		exit
	}

}

function SKAD_Encrypt {
	Param(
		$encrypt = $false,
		[string]$maskFiles = "*.*")


	$mask = Get-ChildItem -path $work $maskFiles

	foreach ($file in $mask) {
		$tmpFile = $file.FullName + '.test'

		$arguments = ''
		if ($encrypt) {
			$arguments = "-sign -encrypt -profile $profile -registry -algorithm 1.2.643.7.1.1.2.2 -in ""$($file.FullName)"" -out ""$tmpFile"" -reclist $recList -silent $logSpki"
		}
		else {
			$arguments = "-sign -profile $profile -registry -algorithm 1.2.643.7.1.1.2.2 -data ""$($file.FullName)"" -out ""$tmpFile"" -reclist $recList -silent $logSpki"
		}

		Write-Log -EntryType Information -Message "������������ ���� $($file.Name)"
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
		Write-Log -EntryType Error -Message "������ ��� ������ ��������� $spki"
		exit
	}
}
function SKAD_archive {
	Param([string]$maskFiles = "*.*")

	$arguments = "-f -k $work\$maskFiles"
	Start-Process $archiver $arguments -NoNewWindow -Wait

	$gzFiles = Get-ChildItem "$work\*.gz"
	if (($gzFiles | Measure-Object).count -gt 0) {
		$msg = "$work\$maskFiles" | Remove-Item -Verbose -Force -Exclude "$work\*.gz" *>&1
		Write-Log -EntryType Information -Message ($msg | Out-String)
		$msg = Get-ChildItem -path $work '*.gz' | Rename-Item -NewName { $_.Name -replace '.gz$', '' } -Verbose *>&1
		Write-Log -EntryType Information -Message ($msg | Out-String)
	}
	else {
		Write-Log -EntryType Error -Message "������ ��� ������ ��������� $archiver"
		exit
	}
}

function SKAD_Decompress {
	Param([string]$maskFiles = "*.*")

	$arguments = "-d $work\$maskFiles"
	Start-Process $archiver $arguments -NoNewWindow -Wait
}
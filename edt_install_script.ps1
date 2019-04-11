# Проверим, что у пользователя есть право Администратора

If (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
{
   # Проверим что EDT не запущен
   If (Get-Process 1cedt* -ErrorAction SilentlyContinue)
   {
        "---------------------------------------------------"
        "Операция не выполнена! Необходимо закрыть EDT перед запуском установки"
        "---------------------------------------------------"
   } else
   {
	.\1ce-installer-cli.cmd support failures clean
        "Определяем установленные версии EDT"
        .\1ce-installer-cli.cmd query installed >".\uninstall.yml"
        "Удаляем установленные версии EDT"
        .\1ce-installer-cli.cmd uninstall --file ".\uninstall.yml"
         "Устанавливаем новую версию из дистрибутива"
        .\1ce-installer-cli.cmd install all --overwrite --ignore-hardware-checks

        #Определяем новую версию

        .\1ce-installer-cli.cmd query installed >".\install.yml"

        (Get-Content ".\install.yml" -Raw) -match "version:\s*(?'ver'\S*)"
        $EdtVer = $Matches['ver']
        $EdtVer -match "\d*.(?'secver'\d*)."
	$SecondaryVer = [convert]::ToInt32($Matches['secver'])
	$SecondaryVer
	if ($SecondaryVer -lt 10)
	{ $FileName = "C:\Program Files\1C\1CE\components\1c-enterprise-development-tools-" + $EdtVer + "-x86_64\1cedt"}
	else
	{$FileName = "C:\Program Files\1C\1CE\components\1c-edt-" + $EdtVer + "-x86_64\1cedt"}
	$FileName
        
        # Редактируем ini файл согласно рекомендациям для больших конфигураций

        $IniFileName = $FileName + ".ini"
        $BakFileName = $FileName + ".bak"
	$memory = $args[0]
	$tmpdir = $args[1]
	If($memory -eq $null)
	{
		$memory="8g"
	}	

	If($tmpdir -eq $null)
	{
		$tmpdir="C:\jtmp"
	}	
	$MemoryString = "-Xmx"+$memory
        Rename-Item -Path $IniFileName -NewName $BakFileName
        Get-Content $BakFileName | ForEach-Object {$_ -replace "-Xmx4096m", $MemoryString}| Set-Content $IniFileName
        Add-Content -Path $IniFileName -Value ("-Djava.io.tmpdir=" + $tmpdir)

        # Проверим существование временной папки для Java.
        # Создадим в случае отсутствия

        $DirExists= Test-Path $tmpdir
        if($DirExists -eq $false)
        {
            New-Item -Path $tmpdir -ItemType "directory"
        }

        # Удалим временные файлы

        Remove-Item -Path ".\uninstall.yml"
        Remove-Item -Path ".\install.yml"

   }
 
}
ELSE{

    "---------------------------------------------------"
    "Операция не выполнена! Необходимо запустить установку от имени Администратора."
    "---------------------------------------------------"
}
Pause("")


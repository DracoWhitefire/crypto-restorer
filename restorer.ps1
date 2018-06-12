param([switch]$Elevated)

$script:extension = 'srpx'

function Test-Admin {
  $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
	}
	exit
}

function Handle-ShadowCopy-Object {
	param([psobject]$sco)
	$linkName = Mount-As-Symlink($sco)
	$files = Scan-Drive-For-Files($sco, )
}

function Get-Drive-Letter(){
	param([psobject]$sco)
	return (Get-WmiObject Win32_Volume | Where { $_.DeviceID -eq $sco.VolumeName }).Name
}

function Mount-As-Symlink {
	param([psobject]$sco)
	$driveLetter = Get-Drive-Letter($sco)
	$linkName = $driveLetter + "sc_" + $sco.InstallDate.Substring(0,14)
	$sourceLocation = $sco.DeviceObject + '\'
	
	#New-Item -Path $linkName -ItemType SymbolicLink -Value "$sourceLocation"
	cmd /c mklink /d $linkName "$sourceLocation"
	return $linkName
}

Get-WmiObject Win32_ShadowCopy | Sort-Object -Property InstallDate -Descending | ForEach-Object {
	Handle-ShadowCopy-Object($_) 
}



function Delete-Current-Symlink {
	param($drive, $currentSymLinkName)
	(Dir $(drive):\ -Force  -ErrorAction 'silentlycontinue' | Where { $_.Attributes -match "ReparsePoint"} | Where { $_.Name -eq $currentSymLinkName }).Delete()
}

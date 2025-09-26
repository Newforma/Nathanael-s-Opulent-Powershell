Set-PsDebug -Strict
$global:CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()

# path to Mainline PowerShell script
$SCRIPT:NewformaServicesPS1 = "C:\repos\enterprise-suite\Solutions\scripts\NewformaServices.ps1"
$SCRIPT:NewformaServicesPS1Changed = $false

function Prompt
{

	$changed = Test-FileChanged $SCRIPT:NewformaServicesPS1
	if ($changed)
	{
		$SCRIPT:NewformaServicesPS1Changed = $true
	}
	if ($SCRIPT:NewformaServicesPS1Changed)
	{
		Write-Warning ($SCRIPT:NewformaServicesPS1 + ' has changed')
	}
	
	if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
		return "(No git!) NOP> "
	}
	
	$br = git branch --show-current
	$dir = (Get-Item .).FullName
	return  "$dir@$br> "
}

$DotSourceScripts = @(
	$SCRIPT:NewformaServicesPS1
)

foreach ($dotSourceScript in $DotSourceScripts)
{
    . $dotSourceScript
}

Write-Host "Nathanael's Opulent Powershell (NOP) v1.0`n" -ForegroundColor Magenta

if (-not (Get-Command acli -ErrorAction SilentlyContinue)) {
	Write-Host "Atlassian Command Line is missing. Some NOP commands will fail. Get it by following the directions at https://developer.atlassian.com/cloud/acli/guides/install-windows/, or run Install-ACLI.`n" -ForegroundColor DarkYellow
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
	Write-Host "Git Command Line is missing. Some NOP commands will fail. Get it from https://gitforwindows.org/, or run Install-Git.`n" -ForegroundColor DarkYellow
}

function Reboot-ServicesAndApps
{
	Kill-ClientApps
	Stop-NewformaServices
	Start-NewformaServices
}

function Kill-All
{
	Kill-ClientApps
	Stop-NewformaServices
}

function List-Pipes
{
	[System.IO.Directory]::GetFiles("\\.\\pipe\\")
}

function Identify-Command($name)
{
	$cmd = Get-Command $name -ErrorAction SilentlyContinue
	
	if ($null -eq $cmd)
	{
		Write-Host "Not found" -ForegroundColor Red
	}
	else
	{
		Write-Host "$($cmd.Version) $($cmd.Source)" -ForegroundColor Yellow
	}
}

function Install-ACLI
{
	try	{
		mkdir "C:\Program Files\acli"
		Invoke-WebRequest -Uri "https://acli.atlassian.com/windows/latest/acli_windows_amd64/acli.exe" -OutFile "C:\Program Files\acli\acli.exe"
		
		[Environment]::SetEnvironmentVariable(
		"Path",
		[Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";C:\Program Files\acli",
		[EnvironmentVariableTarget]::Machine)
		$env:PATH += ";C:\Program Files\acli"
	} catch {
		Write-Host "ACLI installation failed. Try it yourself using the instructions at https://developer.atlassian.com/cloud/acli/guides/install-windows/."
		return
	}
	
	& acli jira auth login
	
	Write-Host "ACLI successfully installed!" -ForegroundColor Green
}

function Install-Git
{
	try {
		$gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.51.0.windows.1/Git-2.51.0-64-bit.exe"

		$installerPath = "$env:TEMP\Git-64-bit.exe"
	
		Write-Host "Downloading Git..." -ForegroundColor Green
		Invoke-WebRequest -Uri $gitUrl -OutFile $installerPath

		Write-Host "Installing Git, this may take a minute..." -ForegroundColor Green
		Start-Process -FilePath $installerPath -ArgumentList '/VERYSILENT', '/NORESTART', '/NOCANCEL' -Wait -NoNewWindow

		[Environment]::SetEnvironmentVariable(
		"Path",
		[Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";C:\Program Files\Git\bin",
		[EnvironmentVariableTarget]::Machine)
		$env:PATH += ";C:\Program Files\Git\bin"
		
		Remove-Item $installerPath
	} catch {
		Write-Host "Git installation failed. Try it yourself: https://gitforwindows.org/."
		return
	}
	
	Write-Host "Git successfully installed!" -ForegroundColor Green
}

function Edit-Profile 
{
	if (Get-Command code -ErrorAction SilentlyContinue) {
		code $PROFILE
	} else {
		notepad $PROFILE
	}
}

function NK-Logoff()
{
	Get-ChildItem -Path "C:\Users\npage.NEWFORMA\AppData\Local\Newforma\NKTokenCache" -Include *.* -File -Recurse | foreach { $_.Delete()}
}

function Build-CPP()
{
	Build-Newforma $false $false $true $false $false $false $false $false $false
}

function Build-All()
{
	Build-Newforma $true $false $false $false $false $false $false $false $false
}

function Build-CPP-Then-All()
{
	build-cpp
	build-all
}

function Search-Branch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$br
    )

    # Get list of all branches matching the search string
    $branches = git branch --list -a "*$br*" | ForEach-Object { $_.Trim() }

    if (-not $branches -or $branches.Count -eq 0) {
        Write-Host "No matching branches found for '$br'." -ForegroundColor Red
        return $null
    }
	
	# If there is only one match, return it directly
    if ($branches.Count -eq 1) {
        $chosenBranch = $branches[0]
        return $chosenBranch
    }

    Write-Host "Matching branches:"
    for ($i = 0; $i -lt $branches.Count; $i++) {
        Write-Host "[$i] $($branches[$i])"
    }

    $selection = Read-Host "Enter the number of the branch you want to select"

    if ($selection -match '^\d+$' -and [int]$selection -ge 0 -and [int]$selection -lt $branches.Count) {
        $chosenBranch = $branches[$selection]
        Write-Host "You selected: $chosenBranch"
        return $chosenBranch
    }
    else {
        Write-Host "Invalid selection." -ForegroundColor Red
        return $null
    }
}

function Switch-Branch($brn, $bld)
{
	$br = Search-Branch $brn
	if ([string]::IsNullOrEmpty($br))
	{
		return
	}
	
	Kill-ClientApps
	Stop-NewformaServices
	
	git checkout $br
	git pull
	
	if ($bld -ne $false)
	{
		Build-Newforma $true $true $true $true $true $true $true $false $false
	}
	
	Start-NewformaServices
	
	for ($i = 0; $i -lt 50; $i++)
	{
		Write-Host "`n"
	}

	Write-Host "Switched to $br" -ForegroundColor Green
}

function Fork {
    param(
        [Parameter(Mandatory = $true)]
        [string]$base,
		[Parameter(Mandatory = $true)]
		[string]$newName
    )
	Switch-Branch $baseBr $true
	& git checkout -b $newName
}

function Invoke-NIX {
	Start-Process "https://$(hostname)/UserWeb/Projects/MyProjects.aspx"
}

function Jira {
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        $Args
    )
    & acli jira @Args
}

function MyWork {
	& acli jira workitem search --jql "assignee=currentUser() AND status!=Closed"
}

function Todo($spr) {
	if ($spr) {
		Write-Host "Work for Eagle Sprint $spr" -ForegroundColor Green
		& acli jira workitem search --jql "'Scrum Team[Dropdown]'=Eagle AND status='To Do' AND Sprint='Eagle Sprint $spr'"
	} else {
		Write-Host "Work for all Eagle Sprints" -ForegroundColor Green
		& acli jira workitem search --jql "'Scrum Team[Dropdown]'=Eagle AND status='To Do'"
	}
}

function Grab {
    param(
        [Parameter(Mandatory = $true)]
        [string]$tckt
    )
	
	& acli jira workitem assign --key "NPC-$tckt" --assignee "@me"
	& acli jira workitem transition --key "NPC-$tckt" --status "In Progress"
}

function About {
    param(
        [Parameter(Mandatory = $true)]
        [string]$tckt
    )
	
	& acli jira workitem view "NPC-$tckt"
}

function ShowMe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$tckt
    )
	
	& acli jira workitem view "NPC-$tckt" --web
}

function Jira-Dashboard {
	Start-Process "https://newforma.atlassian.net/jira/software/c/projects/NPC/boards/443?useStoredSettings=true"
}

function Backlog {
	Start-Process "https://newforma.atlassian.net/jira/software/c/projects/NPC/boards/443/backlog"
}

function Search-Registry { 
<# 
.SYNOPSIS 
Searches registry key names, value names, and value data (limited). 

.DESCRIPTION 
This function can search registry key names, value names, and value data (in a limited fashion). It outputs custom objects that contain the key and the first match type (KeyName, ValueName, or ValueData). 

.EXAMPLE 
Search-Registry -Path HKLM:\SYSTEM\CurrentControlSet\Services\* -SearchRegex "svchost" -ValueData 

.EXAMPLE 
Search-Registry -Path HKLM:\SOFTWARE\Microsoft -Recurse -ValueNameRegex "ValueName1|ValueName2" -ValueDataRegex "ValueData" -KeyNameRegex "KeyNameToFind1|KeyNameToFind2" 

#> 
    [CmdletBinding()] 
    param( 
        [Parameter(Mandatory, Position=0, ValueFromPipelineByPropertyName)] 
        [Alias("PsPath")] 
        # Registry path to search 
        [string[]] $Path, 
        # Specifies whether or not all subkeys should also be searched 
        [switch] $Recurse, 
        [Parameter(ParameterSetName="SingleSearchString", Mandatory)] 
        # A regular expression that will be checked against key names, value names, and value data (depending on the specified switches) 
        [string] $SearchRegex, 
        [Parameter(ParameterSetName="SingleSearchString")] 
        # When the -SearchRegex parameter is used, this switch means that key names will be tested (if none of the three switches are used, keys will be tested) 
        [switch] $KeyName, 
        [Parameter(ParameterSetName="SingleSearchString")] 
        # When the -SearchRegex parameter is used, this switch means that the value names will be tested (if none of the three switches are used, value names will be tested) 
        [switch] $ValueName, 
        [Parameter(ParameterSetName="SingleSearchString")] 
        # When the -SearchRegex parameter is used, this switch means that the value data will be tested (if none of the three switches are used, value data will be tested) 
        [switch] $ValueData, 
        [Parameter(ParameterSetName="MultipleSearchStrings")] 
        # Specifies a regex that will be checked against key names only 
        [string] $KeyNameRegex, 
        [Parameter(ParameterSetName="MultipleSearchStrings")] 
        # Specifies a regex that will be checked against value names only 
        [string] $ValueNameRegex, 
        [Parameter(ParameterSetName="MultipleSearchStrings")] 
        # Specifies a regex that will be checked against value data only 
        [string] $ValueDataRegex 
    ) 

    begin { 
        switch ($PSCmdlet.ParameterSetName) { 
            SingleSearchString { 
                $NoSwitchesSpecified = -not ($PSBoundParameters.ContainsKey("KeyName") -or $PSBoundParameters.ContainsKey("ValueName") -or $PSBoundParameters.ContainsKey("ValueData")) 
                if ($KeyName -or $NoSwitchesSpecified) { $KeyNameRegex = $SearchRegex } 
                if ($ValueName -or $NoSwitchesSpecified) { $ValueNameRegex = $SearchRegex } 
                if ($ValueData -or $NoSwitchesSpecified) { $ValueDataRegex = $SearchRegex } 
            } 
            MultipleSearchStrings { 
                # No extra work needed 
            } 
        } 
    } 

    process { 
        foreach ($CurrentPath in $Path) { 
            Get-ChildItem $CurrentPath -Recurse:$Recurse |  
                ForEach-Object { 
                    $Key = $_ 

                    if ($KeyNameRegex) {  
                        Write-Verbose ("{0}: Checking KeyNamesRegex" -f $Key.Name)  

                        if ($Key.PSChildName -match $KeyNameRegex) {  
                            Write-Verbose "  -> Match found!" 
                            return [PSCustomObject] @{ 
                                Key = $Key 
                                Reason = "KeyName" 
                            } 
                        }  
                    } 

                    if ($ValueNameRegex) {  
                        Write-Verbose ("{0}: Checking ValueNamesRegex" -f $Key.Name) 

                        if ($Key.GetValueNames() -match $ValueNameRegex) {  
                            Write-Verbose "  -> Match found!" 
                            return [PSCustomObject] @{ 
                                Key = $Key 
                                Reason = "ValueName" 
                            } 
                        }  
                    } 

                    if ($ValueDataRegex) {  
                        Write-Verbose ("{0}: Checking ValueDataRegex" -f $Key.Name) 

                        if (($Key.GetValueNames() | % { $Key.GetValue($_) }) -match $ValueDataRegex) {  
                            Write-Verbose "  -> Match!" 
                            return [PSCustomObject] @{ 
                                Key = $Key 
                                Reason = "ValueData" 
                            } 
                        } 
                    } 
                } 
        } 
    } 
} 

function NHelp($cmd) {
    Write-Host "Help for NOP is not yet implemented. Please slack Nathanael Page with any inquiries or email him at npage@newforma.com."
}

Set-Alias xcl Kill-ClientApps
Set-Alias xc Kill-ClientApps
Set-Alias xsrv Stop-NewformaServices
Set-Alias xs Stop-NewformaServices
Set-Alias ssrv Start-NewformaServices
Set-Alias s Start-NewformaServices
Set-Alias rs Reboot-ServicesAndApps
Set-Alias xx Kill-All
Set-Alias x Kill-All
Set-Alias pipes List-Pipes
Set-Alias lo NK-Logoff
Set-Alias bc Build-CPP
Set-Alias ba Build-All
Set-Alias bca Build-CPP-Then-All
Set-Alias in4 Invoke-n4
Set-Alias npc Invoke-NPC
Set-Alias nix Invoke-NIX
Set-Alias sb Switch-Branch
Set-Alias fb Search-Branch
Set-Alias rs Reload-Profile
Set-Alias dash Jira-Dashboard
Set-Alias whoru Identify-Command
Set-Alias ep Edit-Profile
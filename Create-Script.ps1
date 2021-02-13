<#PSScriptInfo

.VERSION 0.1

.GUID beae9bf9-f016-416e-8443-d756a8799ff9

.AUTHOR David Walker, Sitecore Dave, Radical Dave

.COMPANYNAME David Walker, Sitecore Dave, Radical Dave

.COPYRIGHT David Walker, Sitecore Dave, Radical Dave

.TAGS powershell file io script powershellgallery template

.LICENSEURI https://github.com/Radical-Dave/Create-Script/blob/main/LICENSE

.PROJECTURI https://github.com/Radical-Dave/Create-Script

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


#>

<#
.SYNOPSIS
Create PowerShell Script in folder [Name]/[Name].ps1 based on template

.DESCRIPTION
Create PowerShell Script in folder [Name]/[Name].ps1 based on template
Template and Repos (aka Destination path) can be persisted using -PersistForCurrentUser

.EXAMPLE
PS> .\Create-Script 'name'

.EXAMPLE
PS> .\Create-Script 'name' 'template'

.EXAMPLE
PS> .\Create-Script 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Create-Script 'name' 'template' 'd:\repos' -PersistForCurrentUser

.Link
https://github.com/Radical-Dave/Create-Script

.OUTPUTS
    System.String
#>
#####################################################
#  Create-Script
#####################################################
[CmdletBinding(SupportsShouldProcess)]
Param(
	# Name of new script
	[Parameter(Mandatory=$false,Position=0)] [string]$name,
    # Description of script [default - from template]
	[Parameter(Mandatory=$false,Position=1)] [string]$description = "",
    # Name of template to use [default - template] - uses -PersisForCurrentUser
	[Parameter(Mandatory=$false,Position=2)] [string]$template = "",
    # Repos path - uses PersistForCurrentUser so it can run from anywhere, otherwise current working directory
	[Parameter(Mandatory=$false,Position=3)] [string]$repos,
	# Save repos path to env var for user
	[Parameter(Mandatory=$false)] [switch]$PersistForCurrentUser = $true,
    # Force - overwrite if index already exists
    [Parameter(Mandatory=$false)] [switch]$Force = $false
)
begin {
	$ErrorActionPreference = 'Stop'
	$PSScriptName = $MyInvocation.MyCommand.Name.Replace(".ps1","")
    $PSScriptPath = $MyInvocation.MyCommand.Path
    $PSScriptFolder = Split-Path $PSScriptPath -Parent
    $ReposFolder = Split-Path $PSScriptFolder -Parent
    if (!$name) { $name = "$PSScriptName-Test" }
	$PSCallingScript = if ($MyInvocation.PSCommandPath) { $MyInvocation.PSCommandPath | Split-Path -Parent } else { $null }
    if ($PSCallingScript) { Write-Verbose "PSCallingScript:$PSCallingScript"}
	Write-Verbose "$PSScriptName $name $template"

    $scope = "User" # Machine, Process
    $eKey = "cs"
    $rKey = "repos"
    $tKey = "template"

	if (!$repos) { # is there some git cmd/setting we can use?
		$repos = [Environment]::GetEnvironmentVariable("$eKey-$rKey", $scope)
		Write-Verbose "repos persisted using -PersistForCurrentUser:$repos"
		if (!$repos) {
			$repos = Get-Location
            if (($repos | Split-Path -Leaf) -eq $PSScriptName) { $repos = Split-Path $repos -Parent}
		}
	}
    Write-Verbose "repos:$repos"
    $path = Join-Path $repos $name
    Write-Verbose "path:$path"

    if (!$template) { # is there some git cmd/setting we can use?
		$template = [Environment]::GetEnvironmentVariable("$eKey-$tKey", $scope)
        Write-Verbose "template persisted using -PersistForCurrentUser:$template"
		if (!$template) {
			$template = $PSScriptPath
		}
	}

    if (!$description) { $description = "$name PowerShell Script"}
}
process {	
	Write-Verbose "$PSScriptName $name $template start"
    if($PSCmdlet.ShouldProcess($name)) {
        if ($PersistForCurrentUser) {
            Write-Verbose "PersistForCurrentUser-repos:$repos,template:$template"
            [Environment]::SetEnvironmentVariable("$eKey-$rKey", $repos, $scope)
            [Environment]::SetEnvironmentVariable("$eKey-$tKey", $template, $scope)                
            if (!$name) { Exit 0 }
        }

        if (Test-Path $path) {
            if (!$Force) {
                Write-Error "ERROR $path already exists. Use -Force to overwrite."
                EXIT 1
            } else {
                Write-Verbose "$path already exist. -Force used - removing."
                if ($pwd = $path) { Set-Location $ReposFolder }
                Remove-Item $path -Recurse -Force | Out-Null
            }
        }

        if (!(Test-Path $path)) {
            Write-Verbose "Creating: $path"
            New-Item -Path $path -ItemType Directory | Out-Null
        }

        if (Test-Path $template) {
            $content = Get-Content $template
        }

        Write-Verbose "content:$content"
        if ($template = $PSScriptName) {
            $content = $content.Replace("Create-Script", $name)
            $content = $content.Replace("beae9bf9-f016-416e-8443-d756a8799ff9", "$(New-Guid)")
            if ($env:USERNAME -ne "david") {
                $content = $content.Replace("David Walker, Sitecore Dave, Radical Dave", $env:USERNAME)
            }
            $content = $content.Replace("Create PowerShell Script in folder [Name]/[Name].ps1 based on template", $description)
            $content = $content.Replace("Template and Repos (aka Destination path) can be persisted using -PersistForCurrentUser", "")
        } else {
            $content = $content.Replace("@@guid@@", "$(New-Guid)")
            $content = $content.Replace("@@author@@", $env:USERNAME)
            $content = $content.Replace("@@description@@", $description)
        }
        $content | Out-File (Join-Path $path "$name.ps1")
    }
    Write-Verbose "$PSScriptName $name end"
    if ($PersistForCurrentUser) { Set-Location $path }
    return $path
}
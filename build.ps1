﻿#Requires -RunAsAdministrator
[cmdletbinding()]
param(
    [string[]]$Task = 'default'
)

if (!(Get-PackageProvider -Name Nuget -ErrorAction SilentlyContinue))
{
    Install-PackageProvider -Name NuGet -Force
}

$modulesToInstall = @(
    'Pester',
    'psake',
    'PSDeploy',
    'PSScriptAnalyzer'
    'cChoco' # Required by DSC Resource
    'xPSDesiredStateConfiguration' # Required by DSC Resource
)

ForEach ($module in $modulesToInstall)
{
    if (!(Get-Module -Name $module -ListAvailable))
    {
        Install-Module -Name $module -Force -Scope CurrentUser
    }
}

if (-not($env:APPVEYOR))
{
    $env:appveyor_build_version = '10.10.10'
    Write-Verbose "Not on AppVeyor, using fake version of $($env:appveyor_build_version)."
}

# Invoke PSake
Invoke-psake -buildFile "$PSScriptRoot\psakeBuild.ps1" -taskList $Task -parameters @{'build_version' = $env:appveyor_build_version} -Verbose:$VerbosePreference
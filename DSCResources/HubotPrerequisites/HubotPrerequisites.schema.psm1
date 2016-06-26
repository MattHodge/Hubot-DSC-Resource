Configuration HubotPrerequisites
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Present", "Absent")]
        [string]
        $Ensure
    )

    # Import the module that defines custom resources
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Name MSFT_xRemoteFile -ModuleName xPSDesiredStateConfiguration

    $nodeFile = 'node-v5.12.0-x64.msi'
    $gitFile = 'Git-2.9.0-64-bit.exe'
    $nssmFile = 'nssm-2.24.zip'

    xRemoteFile dlNode
    {
        Uri = 'https://nodejs.org/dist/v5.12.0/node-v5.12.0-x64.msi'
        DestinationPath = "$($env:Temp)\$($nodeFile)"
        MatchSource = $false
    }

    Package nodejs
    {
        Ensure = $Ensure
        Path  = "$($env:Temp)\$($nodeFile)"
        Name = "Node.js"
        ProductId = "CE9C30F7-140C-4A6B-95C8-8304CCBF0145"
        Arguments = '/qn ALLUSERS=1 REBOOT=ReallySuppress'
        DependsOn = '[xRemoteFile]dlNode'
        ReturnCode = 0
    }

    xRemoteFile dlGit
    {
        Uri = 'https://github.com/git-for-windows/git/releases/download/v2.9.0.windows.1/Git-2.9.0-64-bit.exe'
        DestinationPath = "$($env:Temp)\$($gitFile)"
        MatchSource = $false
    }

    Package git
    {
        Ensure = $Ensure
        Path  = "$($env:Temp)\$($gitFile)"
        Name = "Git version 2.9.0"
        ProductId = ""
        Arguments = '/VERYSILENT /NORESTART /NOCANCEL /SP- /COMPONENTS="icons,icons\quicklaunch,ext,ext\shellhere,ext\guihere,assoc,assoc_sh" /LOG'
        DependsOn = '[xRemoteFile]dlGit'
    }

    xRemoteFile dlnssm
    {
        Uri = 'https://nssm.cc/release/nssm-2.24.zip'
        DestinationPath = "$($env:Temp)\$($nssmFile)"
        MatchSource = $false
    }

    Archive nssm
    {
        Ensure = $Ensure
        Path = "$($env:Temp)\$($nssmFile)"
        Destination = "C:\nssm"         
        DependsOn = '[xRemoteFile]dlnssm'
    }
}
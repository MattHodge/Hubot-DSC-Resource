# Defines the values for the resource's Ensure property.
enum Ensure
{
    # The resource must be absent.
    Absent
    # The resource must be present.
    Present
}

class HubotHelpers
{
    [string] RefreshPathVariable ()
    {
        $updatedPath = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        return $updatedPath
    }

    [bool] CheckPathExists ([string]$Path)
    {
        if (Test-Path -Path $Path)
        {
            Write-Verbose "Directory $($Path) exists."
            return $true
        }
        else
        {
            Write-Verbose "Directory $($Path) exists."
            return $false
        }
    }

    [PSCustomObject] RunProcess([string]$FilePath, [string]$ArgumentList, [string]$WorkingDirectory)
    {
        $env:Path = [HubotHelpers]::new().RefreshPathVariable()

        $pinfo = New-Object System.Diagnostics.ProcessStartInfo

        if (-not([string]::IsNullOrEmpty($WorkingDirectory)))
        {
            $pinfo.WorkingDirectory = $WorkingDirectory
        }

        $pinfo.FileName = $FilePath
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $pinfo.StandardOutputEncoding = [System.Text.Encoding]::Unicode
        $pinfo.StandardErrorEncoding = [System.Text.Encoding]::Unicode
        $pinfo.Arguments = $ArgumentList
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
        $p.WaitForExit()
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()

        $output = @{}
        $output.filepath = $FilePath
        $output.arg = $ArgumentList
        $output.workingdirectory = $WorkingDirectory
        $output.stdout = $stdout
        $output.stderr = $stderr
        $output.exitcode = $p.ExitCode

        $returnObj =  New-Object -Property $output -TypeName PSCustomObject
        Write-Verbose $returnObj.stdout
        return $returnObj
    }

    [string] GetNSSMPath ()
    {
        if (Test-Path -Path 'C:\nssm')
        {
            # get latest version installed
            $path = ((Get-ChildItem -Path C:\nssm\*\win64\nssm.exe)[-1]).FullName
            Write-Verbose "Found nssm at $($path)"
            return $path
        }
        else
        {
            throw 'NSSM folder cannot be found at C:\nssm'
        } 
    }
}

[DscResource()]
class HubotInstall
{

    # A DSC resource must define at least one key property.
    [DscProperty(Key)]
    [string]$BotPath

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(NotConfigurable)]
    [String]$NodeModulesPath

    # Gets the resource's current state.
    [HubotInstall] Get()
    {
        $GetObject = [HubotInstall]::new()
        $GetObject.BotPath = $this.BotPath
        $GetObject.Ensure = $this.Ensure
        $GetObject.NodeModulesPath = Join-Path -Path $this.BotPath -ChildPath 'node_modules'


        if([HubotHelpers]::new().CheckPathExists($GetObject.NodeModulesPath))
        {
            $GetObject.Ensure = [Ensure]::Present
        }
        else
        {
            $GetObject.Ensure = [Ensure]::Absent
        }


        return $GetObject
    }

    # Sets the desired state of the resource.
    [void] Set()
    {
        $Helpers = [HubotHelpers]::new()
        
        $env:Path = $Helpers.RefreshPathVariable()              

        if (!($Helpers.CheckPathExists($this.BotPath)))
        {
            throw "The path $($this.BotPath) must exist and contain a Hubot installation in it. You can clone one from here: https://github.com/MattHodge/HubotWindows"
        }

        if (Get-Command -CommandType Application -Name npm -ErrorAction SilentlyContinue)
        {
            $npmPath = (Get-Command -CommandType Application -Name npm)[0].Source
        }
        else
        {
            throw "npm cannot be found. Cannot continue."
        }


        if ($this.Ensure -eq [Ensure]::Present)
        {
            $npmCmd = 'install'
        }
        else
        {
            $npmCmd = 'uninstall'
        }

        Write-Verbose -Message "$($npmCmd)ing CoffeeScript at $($this.BotPath)"

        Start-Process -FilePath $npmPath -ArgumentList "$($npmCmd) coffee-script" -Wait

        Write-Verbose "$($npmCmd)ing all required npm modules"

        Start-Process -FilePath $npmPath -ArgumentList $npmCmd -Wait

        if ($this.Ensure -eq [Ensure]::Absent)
        {
            Remove-Item -Path $this.NodeModulesPath -Force
        }
    }

    # Tests if the resource is in the desired state.
    [bool] Test()
    {
        $TestObject = $This.Get()

        # present case
        if ($TestObject.Ensure -eq [Ensure]::Present)
        {
            return $true
        }
        # absent case
        else
        {
            return $false
        }
    }
}

[DscResource()]
class HubotInstallService
{

    # Path where the Hubot is located
    [DscProperty(Key)]
    [string]$BotPath

    # Name for the Hubot service
    [DscProperty(Mandatory)]
    [string]$ServiceName

    # Credential to run the service under
    [DscProperty()]
    [PSCredential]$Credential

    # Bot adapter for Hubot to be used. Used as a paramater to start the server (-a $botadapter)
    [DscProperty(Mandatory)]
    [string]$BotAdapter

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(NotConfigurable)]
    [Boolean]$State_ServiceExists

    [DscProperty(NotConfigurable)]
    [Boolean]$State_ServiceRunning

    [DscProperty(NotConfigurable)]
    [string]$NSSMAppParameters

    [DscProperty(NotConfigurable)]
    [string[]]$NSSMCmdsToRun

    [DscProperty(NotConfigurable)]
    [string]$BotLoggingPath

    [DscProperty(NotConfigurable)]
    [Boolean]$State_NSSMAppParameters

    # Gets the resource's current state.
    [HubotInstallService] Get()
    {
        $Helpers = [HubotHelpers]::new()
        
        $GetObject = [HubotInstallService]::new()
        $GetObject.BotPath = $this.BotPath
        $GetObject.Ensure = $this.Ensure
        $GetObject.ServiceName = $this.ServiceName
        $GetObject.Credential = $this.Credential
        $GetObject.BotAdapter = $this.BotAdapter
        $GetObject.NSSMAppParameters = "/c .\bin\hubot.cmd -a $($this.BotAdapter)"

        # set default states to save having nested if statements
        $GetObject.State_ServiceExists = $false
        $GetObject.State_ServiceRunning = $false
        $GetObject.State_NSSMAppParameters = $false

        if (Get-Service -Name $this.ServiceName -ErrorAction SilentlyContinue)
        {
            $GetObject.State_ServiceExists = $true

            # Check service is running
            if ((Get-Service -Name $this.ServiceName).Status -eq 'Running')
            {
                $GetObject.State_ServiceRunning = $true
            }

            $nssmPath = $Helpers.GetNSSMPath()

            # check if appparams set correctly
            $currentAppParams = ($Helpers.RunProcess($nssmPath,"get $($this.ServiceName) AppParameters",$null)).stdout

            # need to use trim to remove white spaces
            if ([string]$currentAppParams.Trim() -eq [string]$GetObject.NSSMAppParameters)
            {
                $GetObject.State_NSSMAppParameters = $true
            }
        }

        # get the bot logging path
        $GetObject.BotLoggingPath = Join-Path -Path $GetObject.BotPath -ChildPath 'Logs'

        # build an array of NSSM Commands to execute based upon user input
        $GetObject.NSSMCmdsToRun = @(
            "install $($this.ServiceName) cmd.exe"
            "set $($this.ServiceName) AppDirectory $($GetObject.BotPath)"
            "set $($this.ServiceName) AppParameters ""/c .\bin\hubot.cmd -a $($GetObject.BotAdapter)"""
            "set $($this.ServiceName) AppStdout ""$($GetObject.BotLoggingPath)\$($GetObject.ServiceName)_log.txt"""
            "set $($this.ServiceName) AppStderr ""$($GetObject.BotLoggingPath)\$($GetObject.ServiceName)_error.txt"""
            "set $($this.ServiceName) AppDirectory $($GetObject.BotPath)"
            "set $($this.ServiceName) AppRotateFiles 1"
            "set $($this.ServiceName) AppRotateOnline 1"
            "set $($this.ServiceName) AppRotateSeconds 86400"
            "set $($this.ServiceName) Description Hubot Service"
            "set $($this.ServiceName) Start SERVICE_AUTO_START"
        )

        # if a credetial is passed with no password assume LocalSystem
        if ([string]::IsNullOrEmpty($GetObject.Credential))
        {
            Write-Verbose "No credential passed, using LocalSystem."
            $GetObject.NSSMCmdsToRun += "set $($GetObject.ServiceName) ObjectName LocalSystem"
        }
        # if a credential is passed with a password
        else
        {
            Write-Verbose "Credential passed, using username $($GetObject.Credential.UserName)."
            $GetObject.NSSMCmdsToRun += "set $($GetObject.ServiceName) ObjectName .\$($GetObject.Credential.UserName) $($GetObject.Credential.GetNetworkCredential().Password)"
        }

        return $GetObject
    }

    [void] Set()
    {
        $Helpers = [HubotHelpers]::new()

        $env:Path = $Helpers.RefreshPathVariable()

        $TestObject = $This.Get()
        
        $nssmPath = $Helpers.GetNSSMPath()

        if ($this.Ensure -eq [Ensure]::Present)
        {
            
            if ($TestObject.State_ServiceExists)
            {
                Write-Verbose "Removing old service"
                Stop-Service -Name $this.ServiceName -Force
                $Helpers.RunProcess($nssmPath,"remove $($this.ServiceName) confirm",$null) | Out-Null
            }

            # Create bot logging path
            Write-Verbose "Creating bot logging path at $($TestObject.BotLoggingPath)"
            New-Item -Path $TestObject.BotLoggingPath -Force -ItemType Directory

            ForEach ($cmd in $TestObject.NSSMCmdsToRun)
            {               
                $Helpers.RunProcess($nssmPath,$cmd,$null) | Out-Null
            }
            
            Start-Service -Name $this.ServiceName
        }
        else
        {
            Write-Verbose "Removing Bot Service $($this.ServiceName)"
            Stop-Service -Name $this.ServiceName -Force -ErrorAction SilentlyContinue
            $Helpers.RunProcess($nssmPath,"remove $($this.ServiceName) confirm",$null) | Out-Null
        }
    }

    # Tests if the resource is in the desired state.
    [bool] Test()
    {
        $TestObject = $This.Get()

        # present case
        if ($this.Ensure -eq [Ensure]::Present)
        {
            # If any of the possible states for the service are false, not in desired state
            return (-not($TestObject.psobject.Properties.Where({$PSItem.Name -like 'State_*'}).Value -contains $false))
        }
        # absent case
        else
        {
            return (-not($TestObject.State_ServiceExists))
        }
    }
}

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
        
        $currentEncoding = [Console]::OutputEncoding 
        # Handle capture of NSSM output without spaces
        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode

        $pinfo = New-Object System.Diagnostics.ProcessStartInfo

        if (-not([string]::IsNullOrEmpty($WorkingDirectory)))
        {
            $pinfo.WorkingDirectory = $WorkingDirectory
        }

        $pinfo.FileName = $FilePath
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $pinfo.Arguments = $ArgumentList
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
        $p.WaitForExit()
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()

        $output = @{}
        $output.stdout = $stdout
        $output.stderr = $stderr
        $output.exitcode = $p.ExitCode

        [Console]::OutputEncoding = $currentEncoding

        $returnObj =  New-Object -Property $output -TypeName PSCustomObject
        Write-Verbose $returnObj
        return $returnObj
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

    [DscProperty(NotConfigurable)]
    [Boolean]$NodeModulesPathExists

    # Gets the resource's current state.
    [HubotInstall] Get()
    {
        $GetObject = [HubotInstall]::new()
        $GetObject.BotPath = $this.BotPath
        $GetObject.Ensure = $this.Ensure
        $GetObject.NodeModulesPath = Join-Path -Path $this.BotPath -ChildPath 'node_modules'
        $GetObject.NodeModulesPathExists = [HubotHelpers]::new().CheckPathExists($GetObject.NodeModulesPath)

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


        if ($this.Ensure -eq [Ensure]::Present)
        {
            $npmCmd = 'install'
        }
        else
        {
            $npmCmd = 'uninstall'
        }

        Write-Verbose -Message "$($npmCmd)ing CoffeeScript at $($this.BotPath)"

        Start-Process -FilePath npm -ArgumentList "$($npmCmd) coffee-script" -Wait -NoNewWindow -WorkingDirectory $this.BotPath

        Write-Verbose "$($npmCmd)ing all required npm modules"

        $result = $Helpers.RunProcess('npm',$npmCmd,$this.BotPath)
        
        Write-Verbose $result

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
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $TestObject.NodeModulesPathExists
        }
        # absent case
        else
        {
            return (-not($TestObject.NodeModulesPathExists))
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

            # check if appparams set correctly
            $currentAppParams = ($Helpers.RunProcess('nssm',"get $($this.ServiceName) AppParameters",$null)).stdout

            # need to use trim to remove white spaces
            if ([string]$currentAppParams.Trim() -eq [string]$GetObject.NSSMAppParameters)
            {
                $GetObject.State_NSSMAppParameters = $true
            }
        }
        return $GetObject
    }

    [void] Set()
    {
        $Helpers = [HubotHelpers]::new()

        $env:Path = $Helpers.RefreshPathVariable()

        $TestObject = $This.Get()
        
        if (Get-Command -CommandType Application -Name nssm -ErrorAction SilentlyContinue)
        {
            $nssmPath = (Get-Command -CommandType Application -Name nssm).Source
        }
        else
        {
            throw "nssm.exe cannot be found. Cannot continue. Have you run the HubotInstall resource?"
        }

        if ($this.Ensure -eq [Ensure]::Present)
        {
            
            if ($TestObject.State_ServiceExists)
            {
                Write-Verbose "Removing old service"
                Stop-Service -Name $this.ServiceName -Force
                Start-Process -FilePath $nssmPath -ArgumentList "remove $($this.ServiceName) confirm" -Wait -NoNewWindow
            }

            $botLogPath = Join-Path -Path $this.BotPath -ChildPath 'Logs'
            Write-Verbose "Creating bot logging path at $($botLogPath)"
            New-Item -Path $botLogPath -Force -ItemType Directory

            $arrayOfCmds = @(
                "install $($this.ServiceName) cmd.exe"
                "set $($this.ServiceName) AppDirectory $($this.BotPath)"
                "set $($this.ServiceName) AppParameters ""/c .\bin\hubot.cmd -a $($this.BotAdapter)"""
                "set $($this.ServiceName) AppStdout ""$($botLogPath)\$($this.ServiceName)_log.txt"""
                "set $($this.ServiceName) AppStderr ""$($botLogPath)\$($this.ServiceName)_error.txt"""
                "set $($this.ServiceName) AppDirectory $($this.BotPath)"
                "set $($this.ServiceName) AppRotateFiles 1"
                "set $($this.ServiceName) AppRotateOnline 1"
                "set $($this.ServiceName) AppRotateSeconds 86400"
                "set $($this.ServiceName) Description Hubot Service"
                "set $($this.ServiceName) Start SERVICE_AUTO_START"
            )

            # if a credetial is passed with no password assume LocalSystem
            if ([string]::IsNullOrEmpty($this.Credential.UserName))
            {
                Write-Verbose "No credential passed, using LocalSystem."
                $arrayOfCmds += "set $($this.ServiceName) ObjectName LocalSystem"
            }
            # if a credential is passed with a password
            else
            {
                Write-Verbose "Credential passed, using username $($this.Credential.UserName)."
                $arrayOfCmds += "set $($this.ServiceName) ObjectName .\$($this.Credential.UserName) $($this.Credential.GetNetworkCredential().Password)"
            }

            ForEach ($cmd in $arrayOfCmds)
            {
                Write-Verbose "Running NSSM $($cmd)"
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

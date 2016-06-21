# Hubot (DSC Resource)
The **Hubot** module contains the `HubotPrerequisites`, `HubotInstall` and `HubotInstallService` DSC Resources to install Hubot on Windows.

This resource installs and runs Hubot as a service on Windows using NSSM.

I recommend using the [HubotWindows](https://github.com/MattHodge/HubotWindows) repository to get the Hubot setup on your node and use the following DSC resources to configure it.

For an introduction to using Hubot on Windows, take a look at [ChatOps on Windows with Hubot and PowerShell](https://hodgkins.io/chatops-on-windows-with-hubot-and-powershell).

## Resources

### HubotPrerequisites

Parameter | Notes |  Mandatory
| --- | --- | --- |
| ChocolateyInstallPath | Path to install Chocolatey | `No` |
| PsDscRunAsCredential | Credential to run the Chocolatey installations as. Recommend to use the same account you want to run the Hubot service under. | `No` |


### HubotInstall

Parameter | Notes |  Mandatory
| --- | --- | --- |
BotPath | Path that the Windows Hubot package is installed. (Get from here: https://github.com/MattHodge/HubotWindows) | `Yes`
Ensure | Ensures that the bot is Present or Absent | `Yes`

### HubotInstallService

Parameter | Notes |  Mandatory
| --- | --- | --- |
BotPath | Path that the Windows Hubot package is installed. (Get from here: https://github.com/MattHodge/HubotWindows) | `Yes`
ServiceName | Name to give the Hubot Windows service | `Yes`
Credential | Credential of account to run the Hubot service under. If left blank, the service will run under the `SYSTEM` account. | `No`
BotAdapter | The name of the Hubot adapter to use. (https://github.com/github/hubot/blob/master/docs/adapters.md) | `Yes`
Ensure | Ensures that the bot is Present or Absent | `Yes`

## Examples

You can find an installation example here: [dsc_configuration.ps1](Examples/dsc_configuration.ps1)

## Installation

To install the module, use:

`Install-Module -Name Hubot`

## Packaging

The DSC Resource Module is called `Hubot` and is available on the PowerShell Gallery:
* https://www.powershellgallery.com/packages/Hubot

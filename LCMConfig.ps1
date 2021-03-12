<#
.SYNOPSIS
Configure LCM.

.DESCRIPTION
Configure LCM.
The parameters have the original default values.
Only the value for RebootIfNeeded was changed to true.
Read more about LCM: https://docs.microsoft.com/en-us/powershell/dsc/metaconfig

.PARAMETER NodeName
Hostname of the machine where the configuration will be applied.

.PARAMETER RebootIfNeeded
Set this to $true to automatically reboot the node after a configuration that requires reboot is applied.

.PARAMETER RefreshMode
Specifies how the LCM gets configurations. The possible values are "Disabled", "Push", and "Pull". 

.EXAMPLE
. .\LCMConfig.ps1
LCMConfig -NodeName $NodeName
Set-DscLocalConfigurationManager -Path .\LCMConfig

#>
Configuration LCMConfig
{
    param
    (
        [Parameter(Mandatory)]
        [string]$NodeName,
        
        # [string]$DebugMode = 'None',

        [bool]$RebootIfNeeded = $true,

        # [string]$ConfigurationMode = 'ApplyAndAutoCorrect',

        # [bool]$AllowModuleOverwrite = $true,

        [string]$RefreshMode = 'Push'

        # [string]$ActionAfterReboot = 'ContinueConfiguration'
    )

    Node $NodeName
    {
        LocalConfigurationManager
        {
            # DebugMode = $DebugMode
            RebootNodeIfNeeded = $RebootIfNeeded
            # ConfigurationMode = $ConfigurationMode
            # AllowModuleOverwrite = $AllowModuleOverwrite
            RefreshMode = $RefreshMode
            # ActionAfterReboot = $ActionAfterReboot
        }
    }
}
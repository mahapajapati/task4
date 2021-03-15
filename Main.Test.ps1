<#

.DESCRIPTION
Tests to verify the execution of the DSCs that configure a node for task 4.

#>

Describe "NetworkSettings" {

    Context "When Network DSC runs" {

        $networkInfo = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object{ $_.IPEnabled -eq $true }

        It "Has the IP assigned" {
            $IPActual = (Get-NetIpAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress
            $IPExpected = "192.168.100.35"
            $IPActual | Should Be $IPExpected
        }

        It "Has specific gateway" {
            $gatewayActual = $networkInfo.DefaultIPGateway
            $gatewayExpected = '192.168.100.1'
            $gatewayActual[0] | Should Be $gatewayExpected
        }

        It "Has specific dns server" {
            $dnsActual =  (Get-DnsClientServerAddress -InterfaceAlias Ethernet -AddressFamily Ipv4).ServerAddresses
            $dnsExpected = "192.168.100.33"
            $dnsActual | Should Be $dnsExpected
        }
    }
}

Describe "DomainJoined" {

    Context "Verify the node is in the domain" {

        $inDomainActual = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
        $inDomainExpected = $true

        It "Joins the Domain" {
            $inDomainActual | Should Be $inDomainExpected
        }
    }
}

Describe "FeatureInstalled" {

    Context "When Windows Feature DSC runs" {

        $featureList = Get-WindowsFeature     

        $net35 = $featureList | Where-Object {$_.Name -eq 'NET-Framework-Core'}
        $net45 = $featureList | Where-Object {$_.Name -eq 'NET-Framework-45-Core'}

        It "Installs .NET Framework 3.5" {
            $value = $net35.InstallState
            $value | Should Be "Installed"
        }

        It "Installs .NET Framework 4.5" {
            $value = $net45.InstallState
            $value | Should Be "Installed"
        }
    }
}

Describe 'LCMConfigurations' {
    it 'Parameter RebootIfNeeded' {
       $LCMGotten = Get-DscLocalConfigurationManager
       $LCMGotten.RebootNodeIfNeeded | Should Be $true
    }
    it 'Parameter RefresMode' {
        $LCMGotten = Get-DscLocalConfigurationManager
        $LCMGotten.RefreshMode | Should Be "Push"
    }
}

Describe "RemoteDesktopUsers" {

    Context "When RemoteDesktopUsers group includes ADGroups" {

        $group = "Remote Desktop Users"
        $groupActualUsers = Get-LocalGroupMember -Group $group
        $groupDesiredUsers = @("TASKFOURTEST\Group1Task4","TASKFOURTEST\Group2Task4")

        It "Remote Desktop Users contains ADGroups" {
            $groupActualUsers.Name[0] | Should Be $groupDesiredUsers[0]
            $groupActualUsers.Name[1] | Should Be $groupDesiredUsers[1]
        }
    }
}

Describe "FolderPermissions" {

    Context "When Folder Permissions DSC runs" {

        $folderConfigurations = @{
            DSCTestPath = 'C:\DSCTest'
        }

        It "DSCTest Folder is created" {
            $folderExists = Test-Path $folderConfigurations.DSCTestPath
            $folderExists | Should Be $true
        }

        It "DSCTest Folder is shared" {
            $path = $($folderConfigurations.DSCTestPath).Replace('\','\\')
            $isShared = (Get-WmiObject -Class Win32_Share -Filter "Path='$path'")
            $isShared | Should Be $true
        }
    }
}

Describe "ServiceState" {

    Context "When service is up and running" {

        $service = "Spooler"
        $serviceActualStatus = Get-Service $service
        $serviceDesiredStatus = "Running"

        It "Remote Desktop Users contains ADGroups" {
            $serviceActualStatus.Status | Should Be $serviceDesiredStatus
        }
    }
}
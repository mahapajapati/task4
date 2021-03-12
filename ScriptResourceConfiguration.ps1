Configuration ScriptTest
{
    param
    (
        [Parameter(Mandatory)]
        [string]$NodeName
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    
    Node $NodeName
    {
        Script ScriptExample
        {
            SetScript = {
                $sw = New-Object System.IO.StreamWriter("C:\script.txt")
                $sw.WriteLine("startup_type='Automatic'")
                $sw.WriteLine("state='running'")
                $sw.Close()
            }
            TestScript = { Test-Path "C:\script.txt" }
            GetScript = { @{ Result = (Get-Content C:\script.txt) } }
        }
    }
}

Configuration ScriptTest2
{
    param
    (
        [Parameter(Mandatory)]
        [string]$NodeName
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    
    Node $NodeName
    {
        Script ScriptExample2
        {
            SetScript = {
            }
            GetScript = {
                $content = Get-Content ("C:\script.txt")
                return @{ 'Result' = "$content" }
            }
            TestScript = {
                # Create and invoke a scriptblock using the $GetScript automatic variable, which contains a string representation of the GetScript.
                $state = [scriptblock]::Create($GetScript).Invoke()
                $firstArgument = $false
                $secondArgument = $false
                foreach ($line in $state.Result) {
                    if($line -eq "startup_type='Automatic'") {
                        $firstArgument = $true
                    }
                    if($line -eq "state='running'") {
                        $secondArgument = $true
                    }
                }
                    
                if ($firstArgument -and $secondArgument) {
                    return $true
                }
                else { 
                    return $false
                }
            }
        }
    }
}

Configuration ScriptTest3
{
    param
    (
        [Parameter(Mandatory)]
        [string]$NodeName
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    
    Node $NodeName
    {
        Script ScriptExample3
        {
            SetScript = {
                New-Item 'C:\DSCTest' -ItemType Directory
                New-SMBShare -Name "DSCTestShared" -Path "C:\DSCTest"
            }
            TestScript = {
                # Get-SmbShare -Name DSCTestShared
                $result = Get-WmiObject -Class Win32_Share -ComputerName $NodeName -Filter "Path='C:\\DSCTest'"

                if ($result.length -gt 0 ) {
                    return $true
                }
                return $false
            }
            GetScript = { }
        }
    }
}
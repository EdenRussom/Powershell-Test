<#
    .Synopsis
    Tests a connection to CloudFlare DNS.
    .Description
    Displays diagnostic information for Internet Connection to CloudFlare's one.one.one.one DNS Server connection. It supports ping test, TCP test, route tracing, and route selection diagnostics. 
    .Parameter Location
    Changing this parameter will set location.
    .Parameter Computername
    The name or IP address of the remote computer you wish to test and to be connected to.
    .Parameter path
    The name of the folder where results will be saved. The default location is the current user's home directory.
    .Parameter Output
    Specifies the destination output when script is run. Acceptable values are:
        -Host (Screen)
        -Text (.txtfile)
        -CSV (.csv file)
    file out puts are saved to the user's home directory. The default destination is host.
    .Example
      .\Test-CloudFlare -Computername DC1
        Example 1:Test connectivity to CloudFalre DNS on the specified computer
    .Example 
      .\Test-CloudFlare -Computername DC1 -Output CSV
        Example 2:Test connectivity to CloudFlare and write results to a different output.
    .Example 
      .\Test-CloudFlare -Computername DC1 -path 'C:\Users\edenm\Desktop\Powershell Lab\Powershell Test\RemNetTest.csv'
      Test connectivity to CloudFlare and change the location where results files are saved
    .Notes
            Author : EDEN RUSSOM
            Last Edit 2021 24 10
            Version 1.0 -Enabled ComputerName to accept pipeline input
                        -Added aliases for ComputerName
                        -added for each loop for processing
                        -Modified retrieval for Test-NetConnection information
                        -Modified how output switch handles object output
                        -Added exception handling to the foreach loop
                        -Modified object creation to use [pscustomobject]
    #>  
    [CmdletBinding()]
    Param(
     [Parameter(Mandatory=$True, ValueFromPipeline=$True)] 
     
     [Alias('CN','Name')]
     [string[]]$computername,
     [Parameter(Mandatory=$False)] [String]$ParamPath = $env:USERPROFILE,
     [ValidateSet('Host','CSV', 'Text')]
        [string]$Output = "Host"
     )
     ForEach ($computer in $ComputerName) {
         Try{
    $params = @{
        'ComputerName' = $computer
        'ErrorAction'='Stop'
    }
    #Creates a new session to the remote computer(s)
    $session = New-PSSession @params
    Write-Verbose "Connecting to remote $computer"
    #Remotely runs Test-Connection to 1.1.1.1 on target computer(s) as a background job.
    Write-Verbose "Testing connection to one.one.one.one on $Computer ..."
    Enter-PSSession $session
    $DateTime = Get-Date
    $TestCF = Test-NetConnection -ComputerName 'one.one.one.one' -InformationLevel Detailed
    $OBJ = [pscustomobject]@{
        'ComputerName' = $computer
        'PingSuccess' = $TestCF.PingSucceeded
        'NameResolve' = $TestCF.NameResolutionSucceeded
        'ResolvedAddresses' = $TestCF.ResolvedAddresses
    }
    #Closes the session to the remote computer(s)
    Exit-PSSession
    Remove-PSSession $session
    } #try
    Catch{
     Write-Host "Remote connection to $computer failed." -ForegroundColor Red
    }
} #foreach
    
     
    #Pauses script processing to allow Test-Netconnection to complete.
    #Displays results based on -Output parameter
    Write-Verbose "Receiving test results"
    Switch ($Output){
    'Host' {
        $OBJ 
        Write-Verbose "Writing job results to output"
    }
    
    'CSV'{
        Write-Verbose "Receiving job as CSV"
        $OBJ | Export-CSV  -Path $ParamPath\TestResults.csv
    }
    
    'Text'{ 
    #Creates a text file containing the name of the computer being tested, the date time and the job output.
    Write-Verbose "Generating test results" 
    $OBJ | Out-File $ParamPath\TestResults.txt
    Add-Content $ParamPath\RemTest.txt -value $computer
    Add-Content $ParamPath\RemTest.txt -value $DateTime
    Add-Content $ParamPath\RemTest.txt -value (Get-Content $ParamPath\TestResults.txt)
    Remove-item $ParamPath\TestResults.txt
    
    Write-Verbose "Opening Results"
    notepad.exe $ParamPath\RemTest.txt
    }
    }#Switch
    
    Write-Verbose "Finished running test"
}#Function 
    
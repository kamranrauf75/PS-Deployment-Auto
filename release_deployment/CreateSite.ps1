

#function to write messages to log

function WriteToLogFile ($message)
{
    $message +" - "+ (Get-Date).ToString() >> $logfilepath
}

#function to check if the user has adminstrator privileges

function Check-IsElevated
 {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()

    $p = New-Object System.Security.Principal.WindowsPrincipal($id)

    if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
        { Write-Output $true }      
    else
        { Write-Output $false }   
 }

 if(-not(Check-IsElevated)){
    throw "Please run this script as an administrator"
 }
 
 $configFile = "D:\OtherProjects\On\release_deployment\ConfigPathsForCreateSite.JSON"
 $logfilepath = "logs\createlog.txt"
 
 if(Test-Path $logfilepath)
 {
     WriteToLogFile "------------------new run------------------"
 }

Import-Module WebAdministration -Force

function CreateSite($configFile){
    try{

    # Read the configuration file
        # $configFile = "D:\OtherProjects\On\release_deployment\ConfigPathsForCreateSite.JSON"
        $configData = Get-Content -Raw -Path $configFile | ConvertFrom-Json

    # Set the variables

        $WebsiteName = $configData.WebsiteName
        $PhysicalPath = $configData.PhysicalPath
        $Port = $configData.Port
        $Protocol = $configData.Protocol
        $IPAddress = $configData.IPAddress
        $HostHeader = $configData.HostHeader
        $AppPoolName = $configData.AppPoolName

        WriteToLogFile "WebsiteName: $WebsiteName"  
        
    
         # Check if the application pool exists
        if (Test-Path IIS:\AppPools\$AppPoolName) {
            Write-Host "Using existing application pool: $AppPoolName"
            WriteToLogFile "Using existing application pool: $AppPoolName"
        } else {
            # Create a new application pool
            New-WebAppPool -Name $AppPoolName
            Write-Host "Created new application pool: $AppPoolName"
            WriteToLogFile "Created new application pool: $AppPoolName"
        }

        # Check if the website exists
        if (Test-Path IIS:\Sites\$WebsiteName) {
            Write-Host "Website $WebsiteName already exists."
            WriteToLogFile "Website $WebsiteName already exists."
            return
        }else{
            # Create the website
            Write-Host "Creating website $WebsiteName"
            New-Item -Path "IIS:\Sites\" -Name $WebsiteName -Type Site -Bindings @{protocol=$Protocol;bindingInformation="*:"+$Port+":"} -PhysicalPath $PhysicalPath -ApplicationPool $AppPoolName
            Write-Host "Website created successfully and added to the application pool: $AppPoolName."
            WriteToLogFile "Website created successfully and added to the application pool: $AppPoolName."
        }

        # Success message
    }
    catch{
        Write-Host "Error creating site: $_"
    }

}

CreateSite $configFile 
function CreateSite(){
    try{

    # Read the configuration file
        $configFile = "path/to/config.json"
        $configData = Get-Content -Raw -Path $configFile | ConvertFrom-Json

    # Set the variables

        $WebsiteName = $configData.WebsiteName
        $PhysicalPath = $configData.PhysicalPath
        $Port = $configData.Port
        $BindingProtocol = $configData.BindingProtocol
        $IPAddress = $configData.IPAddress
        $HostHeader = $configData.HostHeader
        $AppPoolName = $configData.AppPoolName
        
        Import-Module WebAdministration
    
         # Check if the application pool exists
        if (Get-WebAppPool -Name $AppPoolName -ErrorAction SilentlyContinue) {
            Write-Host "Using existing application pool: $AppPoolName"
        } else {
            # Create a new application pool
            New-WebAppPool -Name $AppPoolName
            Write-Host "Created new application pool: $AppPoolName"
        }
    # Create the website

        # New-WebAppPool -Name $WebsiteName
        New-Website -Name $WebsiteName -PhysicalPath $PhysicalPath -Port $Port -BindingProtocol $BindingProtocol -IPAddress $IPAddress -HostHeader $HostHeader
        
        # Success message
        Write-Host "Website created successfully and added to the application pool: $AppPoolName."
    }
    catch{
        Write-Host "Error creating site: $_"
    }

}
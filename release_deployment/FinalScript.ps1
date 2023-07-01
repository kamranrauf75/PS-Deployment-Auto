

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

 #function to check if the website to which deployment is being made stopped if not then stop the website

 function Check-IsWebsiteRunning($websitePath){
  #$websitePath = "C:\inetpub\wwwroot\testweb"
  $website = Get-Website | Where-Object { $_.PhysicalPath -eq $websitePath }
    # Get the current state of the website
    $websiteName = $website.name
    if ($website.State -eq "Started") {
        # Stop the website if it is started
        Stop-WebSite -Name $websiteName
        Write-Host "Website $websiteName stopped for deployment."
    } 
 }

 function Extract-ZipFile($zipFile, $destination)
 {
     Add-Type -AssemblyName System.IO.Compression.FileSystem
     [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $destination)
    }
    
    # Function to compare files in two directories recursively
function Compare-Files($dirA, $dirB)
{
    $filesA = Get-ChildItem $dirA -File -Recurse | Select-Object -ExpandProperty Name
    $filesB = Get-ChildItem $dirB -File -Recurse | Select-Object -ExpandProperty Name
    
    $matchingFileNames = Compare-Object -ReferenceObject $filesA -DifferenceObject $filesB -IncludeEqual -ExcludeDifferent |
    Where-Object { $_.SideIndicator -eq '==' }
    
    # Loop through files in directory A and increment the count
    
    $matchingFileNamesCount = $matchingFileNames.Count
    
    $fileCountA = 0
    $fileCountB = 0
    
    Get-ChildItem $dirA -File -Recurse | ForEach-Object {
        $fileCountA++
    }
    
    Write-Host "number of files in A: $fileCountA"
    
    # Loop through files in directory B and increment the count
    Get-ChildItem $dirB -File -Recurse | ForEach-Object {
        $fileCountB++
    }
    Write-Host "number of files in A: $fileCountB"
    $fileCountA, $fileCountB, $matchingFileNamesCount
}

#Function to identify the percentage difference between backup and release file
function Compare-Files-Main($zipFileA, $zipFileB)
{
    
    # Create temporary directories to extract the zip files
    $tempDirA = New-Item -ItemType Directory -Path "C:\temp\extractA" -Force
    $tempDirB = New-Item -ItemType Directory -Path "C:\temp\extractB" -Force
    
    # Extract files from the zip archives
    Extract-ZipFile $zipFileA $tempDirA.FullName
    Extract-ZipFile $zipFileB $tempDirB.FullName
    
    # Compare files in the extracted directories
    $fileCountA, $fileCountB,$matchingFileNamesCount = Compare-Files $tempDirA.FullName $tempDirB.FullName
    
    $percentDiffwithA = ((($fileCountA - $matchingFileNamesCount) / $fileCountA)*100)
    $percentDiffwithB = ((($fileCountB - $matchingFileNamesCount) / $fileCountB)*100)
    
    #Write-Host $percentDiff
    
    # Cleanup - Remove temporary directories
    Remove-Item $tempDirA.FullName -Force -Recurse
    Remove-Item $tempDirB.FullName -Force -Recurse
    
    Write-Host "Percentage diff with A: $percentDiffwithA"
    Write-Host "Percentage diff with B: $percentDiffwithB"
    $percentDiffwithA, $percentDiffwithB 
}



function revert(){
    
    $Revert = Read-Host -Prompt 'Do you want to revert the deployment(y/n)?'
    
    if($Revert -eq 'y'){
        
        $Askagain = Read-Host -Prompt 'Are you sure(y/n)?'
        if ($Askagain -eq 'y'){
            WriteToLogFile "Reverting Changes"
            #Reverting the deployment
            $websitePath = Read-Host -Prompt 'Enter the deployment path '
            
            # check if backup path is valid
            while(!($websitePath) -or !(Test-Path -Path $websitePath)){
                Write-Output "The path you entered wasn't correct"
                $websitePath = Read-Host -Prompt 'Enter the deployment path '
            }
            $BackupPath = Read-Host -Prompt 'Enter the Backup path '
            while(!($BackupPath) -or !(Test-Path -Path $BackupPath) -or ((Get-ChildItem ($BackupPath + "\*zip") | Measure-Object).Count -eq 0)){
        if(!(Test-Path -Path $BackupPath)){
            Write-Output "The path you entered was not correct"
        }
        elseif((Get-ChildItem ($BackupPath + "\*zip") | Measure-Object).Count -eq 0){
            Write-Output "No Zip file exists in this folder"
        }
        $BackupPath = Read-Host -Prompt 'Enter the Backup path '
    }
    Get-ChildItem -Path ($BackupPath + "\*zip") | sort LastWriteTime -Descending | Format-Table -AutoSize
    $FileName = Read-Host -Prompt "Enter the complete file name to which you want to revert "
    
    #Reverting the deployment
    $FilePath = $BackupPath + "\" + $FileName
    while(!(Test-Path -Path $FilePath))
    {
        Write-Output "Name of the given file is wrong. Please enter again!"
        $FileName = Read-Host -Prompt "Enter the complete file name to which you want to revert "
        $FilePath = $BackupPath + "\" + $FileName
    }
    Remove-Item ($websitePath +"\*") -Force -Recurse
    Expand-Archive -Path ($FilePath) -DestinationPath $websitePath
    
}
elseif($Askagain -eq 'n'){
    Write-Output "Exiting"
    exit 55
    }
    #Write-Output "Done!!!"
}
elseif($Revert -eq 'n'){
    Write-Output "Exiting"
    exit 55
}

}



if(-not(Check-IsElevated)){
   throw "Please run this script as an administrator"
}

$logfilepath = "D:\Logging\log.txt"

if(Test-Path $logfilepath)
{
    WriteToLogFile "------------------new run------------------"
}

$User = Read-Host -Prompt 'Input the user name '

$Action = Read-Host -Prompt 'Do you want Deploy or Revert? Press d for deployment and r for reverting '

if ($Action -eq "r"){
    WriteToLogFile ("User chose to revert")
    revert
    exit 55
}elseif($Action -ne "d"){
    WriteToLogFile ("User chose to exit")
    exit 55
}

WriteToLogFile ("User chose to deploy")


#Log the user name
WriteToLogFile ($User + " initiated the Script")

# check if backup path is valid

$BackupPath = Read-Host -Prompt 'Enter the Backup path '

while(!($BackupPath) -or (!(Test-Path -Path $BackupPath))){
    Write-Output "The path you entered was not correct"
    $BackupPath = Read-Host -Prompt 'Enter the Backup path '
    }


WriteToLogFile ("User Provided this Backup path: " + $BackupPath)


$websitePath = Read-Host -Prompt 'Enter the deployment path '

# check if deployment path is valid

while(!($websitePath) -or (!(Test-Path -Path $websitePath))){
        Write-Output "The path you entered wasn't correct"
        $websitePath = Read-Host -Prompt 'Enter the deployment path: '
      
 
    }


Check-IsWebsiteRunning($websitePath) 

WriteToLogFile ("User Provided this deployment path: " + $websitePath)

$backUpfileName = "nan"

if(!((Get-ChildItem $websitePath | Measure-Object).Count -eq 0))
{
    $backUpfileName = "\archive $(get-date -f yyyy-MM-dd_HH-mm-ss).zip"
    Compress-Archive -Path ($websitePath +"\*") -DestinationPath ($BackupPath + $backUpfileName)
    WriteToLogFile ("Taking Backup from " + $websitePath + " to " + $BackupPath)

    # Remowing existing items from deployment after backing up
    Remove-Item ($websitePath +"\*") -Force -Recurse
    WriteToLogFile "Removing items from deployment path"
}
else {
    Write-Output "Deployment folder is empty so no backup file will be created."
    WriteToLogFile "Empty Deployment folder and no backup file created"
}


$SourcePath = Read-Host -Prompt 'Enter the Source path where the release is located '


#check if source path is valid or empty

while(!($SourcePath) -or !(Test-Path -Path $SourcePath) -or ((Get-ChildItem $sourcePath | Measure-Object).Count -eq 0)){
        if(!(Test-Path -Path $SourcePath)){
            Write-Output "The path you entered wasn't correct"}
        elseif(((Get-ChildItem $sourcePath | Measure-Object).Count -eq 0)){
        Write-Output "Source folder is empty!"}
        $SourcePath = Read-Host -Prompt 'Enter the Source path where the release is located '
     }


Get-ChildItem -Path ($SourcePath + "\*zip") | sort LastWriteTime -Descending | Format-Table -AutoSize
$FileName = Read-Host -Prompt "Enter the complete file name of the source file "
$SourceFilePath = $SourcePath + "\" + $FileName

while(!($SourceFilePath) -or !(Test-Path -Path $SourceFilePath))
    {
        Write-Output "Name of the given file is wrong. Please enter again!"
        $FileName = Read-Host -Prompt "Enter the complete file name of the source file "
        $SourceFilePath = $SourcePath + "\" + $FileName
    }


if ($backUpfileName -ne "nan")
{
    $BackupfilePath = $BackupPath + $backUpfileName

    $zipFileA = $BackupfilePath
    $zipFileB = $SourceFilePath


    $percentDiffwithA, $percentDiffwithB  = Compare-Files-Main $zipFileA $zipFileB

    Write-Output $percentDiffwithA
    Write-Output $percentDiffwithB


    if(($percentDiffwithA  -ge 30) -or ($percentDiffwithB -ge 30)){
        Write-Output "The source file matches only 30% or less with the backup file."
        $DecToCont = Read-Host -Prompt 'Are you sure you want to continue(y/n) '
        if($DecToCont -ne "y"){
            Write-Output "Deployment Aborted!!"}
    }
}


# Extracting the zip file to deployment
Expand-Archive -Path ($SourceFilePath) -DestinationPath $websitePath 

$FileSize = ((Get-Item ($SourceFilePath)).Length)/1000000
WriteToLogFile ("Unzipping and moving items from the source path " + $SourcePath + " to deployment path")
WriteToLogFile ("Size of the source file is " + $FileSize + " MB")
#WriteToLogFile "Deployment Successful"

$Revert = Read-Host -Prompt 'Do you want to revert the deployment(y/n)?'
if($Revert -eq 'y'){
  $Askagain = Read-Host -Prompt 'Are you sure(y/n)?'
  if ($Askagain -eq 'y'){

    WriteToLogFile "Reverting Changes"
    #Reverting the deployment

    Get-ChildItem -Path ($BackupPath + "\*zip") | sort LastWriteTime -Descending
    $FileName = Read-Host -Prompt "Enter the complete file name to which you want to revert "

    #Reverting the deployment
 
    $FilePath = $BackupPath + "\" + $FileName

    while(!($FilePath) -or !(Test-Path -Path $FilePath))
    {
       Write-Output "Name of the given file is wrong. Please enter again!"
       $FileName = Read-Host -Prompt "Enter the complete file name to which you want to revert "
       $FilePath = $BackupPath + "\" + $FileName

    }

    Remove-Item ($websitePath +"\*") -Force -Recurse
    Expand-Archive -Path ($FilePath) -DestinationPath $websitePath
    
    }
    elseif ($Askagain -eq 'n'){
        Write-Output "Exiting"
        exit 55
    }
    }
elseif ($Revert -eq 'n'){
    Write-Output "Exiting"
    exit 55
}


# deployed: C:\inetpub\wwwroot\testweb
# source: D:\DotNet Projects\Alpharel2
# backup: C:\inetpub\wwwroot\backup






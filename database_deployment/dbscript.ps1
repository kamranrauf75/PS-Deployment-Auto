﻿# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$JsonPathforRead = "database_deployment\ConfigPaths.JSON"

function Get-Path($ScriptPath, $filename)
{
    while(!($ScriptPath) -or !(Test-Path -Path $ScriptPath)){
        if(!(Test-Path -Path $ScriptPath)){
            Write-Output "The path you entered wasn't correct"}
        $ScriptPath = Read-Host -Prompt "Enter the path of: $filename"
    }
    $ScriptPath
}

function Read-Paths($JsonPathforRead){
    $JsonPath = "D:\OtherProjects\On\ConfigPaths.JSON"
    $json = Get-Content $JsonPath | Out-String | ConvertFrom-Json
    $OriginalScriptPath = $json.OriginalScriptPath
    $revertDbScriptJSONPath = $json.revertDbScriptJSONPath
    $connString = $json.connString

    $OriginalScriptPath = Get-Path $OriginalScriptPath "Original-Script"
    $revertDbScriptJSONPath = Get-Path $revertDbScriptJSONPath "Revert-Db-Script-JSON"

    $OriginalScriptPath, $revertDbScriptJSONPath, $connString
}

$logfilepath = "logs\dblog.txt"

$OriginalScriptPath, $revertDbScriptJSONPath, $connString = Read-Paths $JsonPathforRead

function WriteToLogFile ($message)
{
    $message +" - "+ (Get-Date).ToString() >> $logfilepath
}

if(Test-Path $logfilepath)
{
    WriteToLogFile "------------------new run------------------"
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

function Get-TableName($query){
    
    # Regular expression patterns to match the table name for different query types
    $selectPattern = "FROM\s+(\w+)"
    $updatePattern = "UPDATE\s+(\w+)"
    $deletePattern = "DELETE\s+FROM\s+(\w+)"
    $insertPattern = "INSERT\s+INTO\s+(\w+)"
    
    $selectPatternl = "from\s+(\w+)"
    $updatePatternl = "update\s+(\w+)"
    $deletePatternl = "delete\s+from\s+(\w+)"
    $insertPatternl = "insert\s+into\s+(\w+)"
    $insertPatterns = "insert\s+(\w+)"
    
    # Find the table name based on the query type using regular expressions
    if (($query -match $selectPattern) -or ($query -match $selectPatternl)) {
        $tableName = $Matches[1]
    } elseif (($query -match $updatePattern) -or ($query -match $updatePatternl)) {
        $tableName = $Matches[1]
    } elseif (($query -match $deletePattern) -or ($query -match $deletePatternl)) {
        $tableName = $Matches[1]
    } elseif (($query -match $insertPattern) -or ($query -match $insertPatternl) -or ($query -match $insertPatterns)) {
        $tableName = $Matches[1]
    } else {
        $tableName = "Table name not found."
    }
    $tableName
}

if(-not(Check-IsElevated)){
    throw "Please run this script as an administrator"
}


# $connString = "Server=kamranrauf;Database=testDb;User=ka;Password=test123"

WriteToLogFile "Db Script ran with connection string: $connString"
$conn = New-Object System.Data.SqlClient.SqlConnection $connString

$conn.Open()

$tran = $conn.BeginTransaction()
$errorM = ""
$table = ""
$hashmap = [ordered]@{}


try {
  
    $ScriptPath = $OriginalScriptPath

    #$ScriptPath = Get-Path
    
    $MyQuery = get-content $ScriptPath;

    WriteToLogFile "The content of the query is: $MyQuery"

    # Split the query into individual statements

    $delimiter = ";"
    
    $statements = $MyQuery -split $delimiter

    # Exclude empty or whitespace-only statements
    $statements = $statements | Where-Object { $_ -match '\S' }

    $statementCount = $statements.Count
    $totalRowsAffected = 0
    $count = 0
    foreach($statement in $statements)
    {
        if($statement -ne $null -and $statement -ne "")
        {
            # if($statement -match "insert" -or $statement -match "update" -or $statement -match "delete")
            # {
            $statement = $statement + ";"
            # }
            WriteToLogFile "Executing statement: $statement"
            $cmd = New-Object System.Data.SqlClient.SqlCommand($statement, $conn)
            $cmd.Transaction = $tran
            $rowsAffected = [int]$cmd.ExecuteNonQuery()
            if($rowsAffected -ne -1)
            {
                $totalRowsAffected += $rowsAffected
            }
            $hashKey = "Statement $count"
            $hashmap.add( $hashKey, $rowsAffected)
            $table = Get-TableName($statement)
            if($table -ne "Table name not found." -or $rowsAffected -eq -1)
                {
                    WriteToLogFile ("Rows affected of table: $table" + " are $rowsAffected")
                }
            $count++
        }
    }
    
    WriteToLogFile "Changes successfully made to Db and total rows affected are: $totalRowsAffected"

    #Write-Host "Changes successfully made to Db $rowsAffected" 
        
    $hashmap | ConvertTo-Json | Out-File "D:\OtherProjects\On\database_deployment\revertDbScript.json"
    $tran.Commit()

}    

catch {
    $tran.Rollback()
    Write-Host "Changes Rollbacked" 
    $errorM = $_.exception.message
    WriteToLogFile "Error caught: $errorM"
}
finally {
    $conn.Close()
    WriteToLogFile "Closing connection"
}
#Write-Output $error
$JsonPathforRead = "D:\OtherProjects\On\ConfigPaths.JSON"
 
function Get-Path($ScriptPath, $filename)
{
    #$ScriptPath = Read-Host -Prompt 'Enter the path of: $filename '
    #$ScriptPath = "D:\OtherProjects\On\database_deployment\revertDbScript.sql"

    while(!($ScriptPath) -or !(Test-Path -Path $ScriptPath)){
        if(!(Test-Path -Path $ScriptPath)){
            Write-Output "The path you entered wasn't correct"}
        $ScriptPath = Read-Host -Prompt "Enter the path of: $filename"
    }
    $ScriptPath
}

function Read-Paths($JsonPathforRead){
    
    $json = Get-Content $JsonPathforRead | Out-String | ConvertFrom-Json
    $OriginalScriptPath = $json.OriginalScriptPath
    $RevertScriptPath = $json.RevertScriptPath
    $revertDbScriptJSONPath = $json.revertDbScriptJSONPath
    $logfilepath = $json.logfilepath
    $revertlogfilepath = $json.revertlogfilepath

    $OriginalScriptPath = Get-Path $OriginalScriptPath "Original-Script"
    $RevertScriptPath = Get-Path $RevertScriptPath "Revert-Script"
    $revertDbScriptJSONPath = Get-Path $revertDbScriptJSONPath "Revert-Db-Script-JSON"
    $logfilepath = Get-Path $revertlogfilepath "Revert-Log-File"
    #assigned revert log file path to log file path 

    $OriginalScriptPath, $RevertScriptPath,$revertDbScriptJSONPath, $logfilepath
}


# populating paths from json file
$OriginalScriptPath, $RevertScriptPath, $revertDbScriptJSONPath, $logfilepath = Read-Paths $JsonPathforRead


function WriteToLogFile ($message)
{
    $message +" - "+ (Get-Date).ToString() >> $logfilepath
}


if(Test-Path $logfilepath)
{
    WriteToLogFile "------------------new run------------------"
}



function Get-HashTable-From-Json($JsonPath)
{
    $json = Get-Content $JsonPath | Out-String | ConvertFrom-Json
    $hashmap = [ordered]@{}
    foreach( $property in $json.psobject.properties.name )
    {
        $hashmap[$property] = $json.$property
    }
    $hashmap
}



function revert-Db-Changes($originalScript, $revertScript, $JsonPath){
    $delimiter = ";"
    $MyOQuery = get-content $originalScript;
    $MyRQuery = get-content $revertScript;

    $rstatements = $MyRQuery -split $delimiter
    # Exclude empty or whitespace-only statements
    $rstatements = $rstatements | Where-Object { $_ -match '\S' }
    $rstatementsCount = $rstatements.Count

    $ostatements = $MyOQuery -split $delimiter
    # Exclude empty or whitespace-only statements
    $ostatements = $ostatements | Where-Object { $_ -match '\S' }
    $ostatementsCount = $ostatements.Count
    if($rstatementsCount -ne $ostatementsCount)
    {
        Write-Output "The number of sql statements in the original script and revert script are not equal."
        return
    }
    
    $hashmap = Get-HashTable-From-Json $JsonPath
    $connString = "Server=kamranrauf;Database=testDb;User=ka;Password=test123"
    #$ScriptPath = "D:\OtherProjects\DbScript\revertDbScript.sql"
    # $ScriptPath = Get-Path

    run-Script $revertScript $connString $hashmap $rstatements 
}

function run-Script($ScriptPath, $connString, $hashmap, $statements){
    WriteToLogFile "Db Revert Script ran with connection string: $connString"
    $conn = New-Object System.Data.SqlClient.SqlConnection $connString
    
    $conn.Open()

    $tran = $conn.BeginTransaction()
    $errorM = ""
    $table = ""

    try {
    
        $counter = 0

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
                $hashmapSize = $hashmap.Count

                #reverse comparison of hashmap and revert script rows affected

                if ($hashmap[$hashmapSize - $counter - 1] -ne $rowsAffected){
                    WriteToLogFile "Error: The number of rows affected by the original query is not equal to the number of rows affected by the revert query"
                    throw "Error: The number of rows affected by the original query is not equal to the number of rows affected by the revert query"
                }

                $table = Get-TableName($statement)
                if($table -ne "Table name not found." -or $rowsAffected -eq -1)
                    {
                        WriteToLogFile ("Rows affected of table: $table" + " are $rowsAffected")
                    }
                $counter++
            }
        }

        WriteToLogFile "Reverts successfully made to Db and total rows affected are: $totalRowsAffected"

        #Write-Host "Changes successfully made to Db $rowsAffected" 
            
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

}


# $OgScriptPath = "D:\OtherProjects\On\database_deployment\originalDbScript.sql"
# $RevertScriptPath = "D:\OtherProjects\On\database_deployment\revertDbScript.sql"
# $RevertScriptJsonPath = "D:\OtherProjects\DbScript\revertDbScript.json"

# $OriginalScriptPath, $RevertScriptPath, $revertDbScriptJSONPath = Read-Paths $JsonPathforRead

# $RevertScriptPath = Get-Path
revert-Db-Changes $OriginalScriptPath $RevertScriptPath $revertDbScriptJSONPath


#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
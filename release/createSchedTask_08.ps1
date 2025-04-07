# CreateScheduledTasks_std_01
# simple userName/password solution
# script name schema: 04_test04_128cro3_01
# ---------------------------------------------------------09

# Use elevated execution
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Script requires administrative privileges. Restarting with elevation..."
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Define the task name and action
$taskPath = "radioVLCp"
$username = "DESKTOP-NJGU9I1\Jan"
$password = "=8RMeY\QOsc-FDP0~8.+"
# $taskName = "00_test03_01"  # $targetScriptName
# $scriptPath = "c:\Users\Jan\Dropbox\doc\rec\radio\scheVLC\"
# $scriptPath = $MyInvocation.MyCommand.Path
# $scriptName = "00_test_01.ps1"
$arg1 = "-NoProfile -ExecutionPolicy Bypass -File"
# $file = "$scriptPath$scriptName"
# $argAction = "$arg1 `"$file`""
# $title = $numRec + "_" + $titleRec + "_" + $durMinute

# Define the settings for the task, including setting it to wake the computer
$settings = New-ScheduledTaskSettingsSet `
    -WakeToRun `
    -Compatibility 'Win8' `
    -MultipleInstances Parallel
    # -ExecutionTimeLimit (New-TimeSpan -Hours 3) `

function Get-TargetScriptFilePath {
    param (
        [string]$destination,
        [string]$basename,
        [string]$sourceFilePath
    )
    
    # Split the basename into tokens
    $tokens = $basename -split ' '

    # Assign the first token to $targetScriptName
    $targetScriptName = $tokens[0]

    # Store the remaining tokens in an array called $triggers
    $triggers = $tokens[1..($tokens.Length - 1)]

    # Construct the target script file path
    $targetScriptNameFile = "$targetScriptName.ps1"
    $filePath = [string]::Join("\", $destination, $targetScriptNameFile)

    # Output the file path
    Write-Output "File: $filePath"

    # Create an array to hold the scheduled task triggers
    $taskTriggers = @()

    # Loop through each trigger and create a scheduled task trigger
    foreach ($trigger in $triggers) {
        # Split the trigger into type and time
        $typeTime = $trigger -split '_'
        if ($typeTime.Length -eq 2) {
            $typeOrDays = $typeTime[0]
            $time = $typeTime[1]

            if ($typeOrDays -eq "Daily") {
                # Create a daily scheduled task trigger
                $taskTriggers += New-ScheduledTaskTrigger -Daily -At $time
                Write-Output "Added Daily Trigger: Time - $time"
            } elseif ($typeOrDays -eq "OneTime") {
                # Create a one-time scheduled task trigger with date and time
                $dateTime = $time -split ';'
                if ($dateTime.Length -eq 2) {
                    $date = $dateTime[0]
                    $time = $dateTime[1]
                    $taskTriggers += New-ScheduledTaskTrigger -Once -At "$date $time"
                    Write-Output "Added One-Time Trigger: Date - $date, Time - $time"
                } else {
                    Write-Output "Invalid One-Time Trigger format. Expected format: OneTime_date_time"
                }
            } else {
                # Split multiple days by comma
                $days = $typeOrDays -split ','

                # Create a weekly scheduled task trigger for the specified days
                $taskTriggers += New-ScheduledTaskTrigger -Weekly -DaysOfWeek $days -At $time
                Write-Output "Added Weekly Trigger: Days - $($days -join ', '), Time - $time"
            }
        }
    }

    # Disable timezone synchronization for each trigger
    foreach ($trigger in $taskTriggers) {
        $trigger.SynchronizeAcrossTimeZone = $false
    }

    # Copy the source file to the new location
    Copy-Item -Path $sourceFilePath -Destination $filePath

    # Output the copied file path
    Write-Output "Copied to: $filePath"

    # Output the final array of task triggers
    # return $taskTriggers
    
    $file = "$filePath"
    $argAction = "$arg1 `"$file`""

    $action = New-ScheduledTaskAction `
    -Execute 'PowerShell' `
    -Argument $argAction `
    -WorkingDirectory $destination

    # Register the task v01
    Register-ScheduledTask `
        -TaskName $targetScriptName -TaskPath $taskPath `
        -Action $action -Trigger $taskTriggers `
        -User $username -Password $password `
        -RunLevel Highest `
        -Settings $settings `
        -Description "User/Password_v03"
}

# Get the directory of the script
$scriptDirectory = $PSScriptRoot
Write-Output "ScriptDirectory: $scriptDirectory"
# Get the parent directory (one level up)
$parentDirectory = Split-Path -Path $scriptDirectory -Parent
Write-Output "Parent Directory: $parentDirectory"
# Define the source file path
$sourceFilePath = Join-Path -Path $parentDirectory -ChildPath "release\00_recVLCv04_128cro3_01.ps1"
$destPath = Join-Path -Path $parentDirectory -ChildPath "scheVLC"
Write-Output "destPath: $destPath"

# Read the target script names from the file
$listFilePath = ".\list_06.txt"
$targetScriptNames = Get-Content -Path $listFilePath

# Loop through each target script name and call the function
foreach ($targetScriptName in $targetScriptNames) {
    Get-TargetScriptFilePath `
        -destination $destPath `
        -basename $targetScriptName `
        -sourceFilePath $sourceFilePath
    # Output the triggers array if needed
    # $triggersArray
}

# ---------------------------------------------------------11
### Key Changes:
# 1. **Function Parameter**: The `Get-TargetScriptFilePath`
# function now accepts an additional parameter, 
# `$sourceFilePath`, which is the path of the file to be copied.
# 2. **File Copying**: After processing the triggers, the script copies
#  the source file to the new target path using `Copy-Item`.
# 3. **Output Confirmation**: It outputs the path where the file was copied.

# ---------------------------------------------------------11
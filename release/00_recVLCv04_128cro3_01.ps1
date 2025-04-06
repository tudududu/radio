# Ensure that the execution policy allows your script to run
Set-ExecutionPolicy Bypass -Scope Process -Force

$scriptPath = $MyInvocation.MyCommand.Path
Write-Output "File Path:$scriptPath"
# Get the full path of the script

# Define the filename
#$filename = "00_test04_01.bat"
# Extract the file name from the path
$fileName = [System.IO.Path]::GetFileName($scriptPath)

# Output the file name
Write-Output "File Name: $fileName"

# Remove the file extension
$basename = [System.IO.Path]::GetFileNameWithoutExtension($filename)

# Split the basename into tokens
$tokens = $basename -split '_'

# Iterate through the tokens and assign them to variables dynamically
for ($i = 0; $i -lt $tokens.Length; $i++) {
    Set-Variable -Name "token$i" -Value $tokens[$i]
}

# Accessing the dynamically created variables
$numRec=$token0
$titleRec=$token1
$station=$token2
$durMinute=$token3

$title = $numRec + "_" + $titleRec + "_" + $station + "_" + $durMinute
# or
# $title = "$numRec $titleRec $durMinute"
# or
# $title = [string]::Join("_", $numRec, $titleRec, $durMinute)

Write-Output "numRec: $numRec"
Write-Output "titleRec: $titleRec"
Write-Output "station: $station"
Write-Output "durMinute: $durMinute"
Write-Output "title: $title"


# $title = "My Script Title"
Write-Host "$([char]0x1B)]0;$title$([char]0x7)"

# date yymmdd
$shortDate = Get-Date -Format "yyMMdd"
Write-Host $shortDate  # Output example: 241005

$shortTime = Get-Date -Format "HHmm"
Write-Host $shortTime  # Output example: 1856

$shortDateTime = Get-Date -Format "yyMMdd_HHmm"
Write-Host $shortDateTime  # Output example: 241005_1856

$userProfilePath = $env:USERPROFILE
Write-Host $userProfilePath  # Output example: C:\Users\YourUsername

$cesta="$userProfilePath\Documents\rec\vlc"
Write-Host $cesta

# or
# $cesta = Join-Path -Path $userProfilePath -ChildPath "Documents\rec"
# Write-Host $cesta  # Output example: C:\Users\Jan\Documents\rec

if (-Not (Test-Path -Path $cesta)) {
    New-Item -ItemType Directory -Path $cesta
}
# converting $durMinute to an integer
$durSec = [int]$durMinute * 60
# $recFileName=$titleRec + "_" + $shortDateTime + ".ogg"
$recFileName=$titleRec + "_" + $station + "_" + $shortDateTime + ".ogg"

# In powershell I wanto meake a conditional expression. 
# Based on input a string in variable $station I want to choose
# 1 out of 3 optional variables and assign it to the output
# variable $stream. Optional variables: $stream32, $stream256, $stream128

# Define your optional variables
$stream32 = "http://icecast2.play.cz:8000/cro3-32aac"
$stream256 = "http://amp1.cesnet.cz:8000/cro3-256.ogg"
$stream128 = "http://amp1.cesnet.cz:8000/cro3.ogg"
$stream256ddur = "http://amp1.cesnet.cz:8000/cro-d-dur-256.ogg"

# Use switch to assign the appropriate stream
switch ($station) {
    "32cro3" { $stream = $stream32 }
    "128cro3" { $stream = $stream128 }
    "256cro3" { $stream = $stream256 }
    "256ddur" { $stream = $stream256ddur }
    default { $stream = "Unknown station" }
}
# $stream = $stream128

# Output the result
Write-Host "Selected stream: $stream"


$pathApp = "C:\Program Files\VideoLAN\VLC\vlc.exe"
$param = ":sout=#duplicate{dst=std{access=file,mux=ogg,dst=$cesta\$recFileName}}"
Write-Host "recFileName: $recFileName"
Write-Host "durMinute: $durMinute"
Write-Host "durSec: $durSec"
# Start the process and capture its PID
$process = Start-Process -FilePath $pathApp -ArgumentList "$stream $param" -NoNewWindow -PassThru
$processId = $process.Id

# Wait for the desired time length
$timeLength = $durSec # Time length in seconds
Start-Sleep -Seconds $timeLength

# Terminate the process
Stop-Process -Id $processId
 #>
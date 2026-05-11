#requires -Version 5.1
# This script compares contents of four master folders and outputs a CSV file.
# Each group (e.g., E01, E02) is listed one after another in the CSV.
param()

# Prompt for master folder paths
$rawKmallMaster = Read-Host 'Enter path to Raw KMALL Master Folder'
$autoCleanKmallMaster = Read-Host 'Enter path to AutoClean KMALL Master Folder'
$tracklinesMaster = Read-Host 'Enter path to Tracklines Master Folder'
$gsfMaster = Read-Host 'Enter path to GSF Master Folder'

# Get all subfolder names (e.g., E01, E02, etc.) from all master folders
$rawKmallSubs = Get-ChildItem -Path $rawKmallMaster -Directory | ForEach-Object { $_.Name }
$autoCleanKmallSubs = Get-ChildItem -Path $autoCleanKmallMaster -Directory | ForEach-Object { $_.Name }
$tracklinesSubs = Get-ChildItem -Path $tracklinesMaster -Directory | ForEach-Object { $_.Name }
$gsfSubs = Get-ChildItem -Path $gsfMaster -Directory | ForEach-Object { $_.Name }

$allSubs = $rawKmallSubs + $autoCleanKmallSubs + $tracklinesSubs + $gsfSubs | Sort-Object -Unique

$outputPath = Join-Path -Path (Get-Location) -ChildPath 'FolderComparison.csv'
if (Test-Path $outputPath) { Remove-Item $outputPath }

foreach ($sub in $allSubs) {
    # Set up subfolder paths
    $rawKmallPath = Join-Path $rawKmallMaster $sub
    $autoCleanKmallPath = Join-Path $autoCleanKmallMaster $sub
    $tracklinesPath = Join-Path $tracklinesMaster $sub
    $gsfPath = Join-Path $gsfMaster $sub

    # Get file/folder names for comparison in each subfolder
    $rawKmallNames = if (Test-Path $rawKmallPath) { Get-ChildItem -Path $rawKmallPath -Filter '*.kmall' -File | ForEach-Object { $_.BaseName } } else { @() }
    $autoCleanKmallNames = if (Test-Path $autoCleanKmallPath) { Get-ChildItem -Path $autoCleanKmallPath -Filter '*.kmall' -File | ForEach-Object { $_.BaseName } } else { @() }
    # For Tracklines, look for the TrackLines_<sub> folder, then get subfolders inside it
    $tracklinesSubfolder = Join-Path $tracklinesPath ("TrackLines_" + $sub)
    $tracklineNames = if (Test-Path $tracklinesSubfolder) { Get-ChildItem -Path $tracklinesSubfolder -Directory | ForEach-Object { $_.Name } } else { @() }
    $gsfNames = if (Test-Path $gsfPath) { Get-ChildItem -Path $gsfPath -Filter '*.gsf' -File | ForEach-Object { $_.BaseName } } else { @() }

    # Get all unique names for this subfolder group
    $allNames = $rawKmallNames + $autoCleanKmallNames + $tracklineNames + $gsfNames | Sort-Object -Unique

    # Add a header for the group
    Add-Content -Path $outputPath -Value "Group: $sub"
    $header = 'Raw KMALL Folder,AutoClean KMALL Folder,Tracklines Folder,GSF Folder'
    Add-Content -Path $outputPath -Value $header

    foreach ($name in $allNames) {
        $rawVal = if ($rawKmallNames -contains $name) { $name } else { '' }
        $autoVal = if ($autoCleanKmallNames -contains $name) { $name } else { '' }
        $trackVal = if ($tracklineNames -contains $name) { $name } else { '' }
        $gsfVal = if ($gsfNames -contains $name) { $name } else { '' }
        $row = "$rawVal,$autoVal,$trackVal,$gsfVal"
        Add-Content -Path $outputPath -Value $row
    }
    # Add a blank line between groups
    Add-Content -Path $outputPath -Value ""
}
Write-Host "Comparison CSV created at: $outputPath"
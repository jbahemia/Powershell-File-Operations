# This script compares contents of four master folders and outputs an Excel file with each group as a worksheet.
# Renamed for clarity.
# Original filename: CompareFoldersToSpreadsheet.ps1

#requires -Version 5.1
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

$rows = @()
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

    foreach ($name in $allNames) {
        $rows += [PSCustomObject]@{
            'Group'                  = $sub
            'Raw KMALL Folder'       = if ($rawKmallNames -contains $name) { $name } else { '' }
            'AutoClean KMALL Folder' = if ($autoCleanKmallNames -contains $name) { $name } else { '' }
            'Tracklines Folder'      = if ($tracklineNames -contains $name) { $name } else { '' }
            'GSF Folder'             = if ($gsfNames -contains $name) { $name } else { '' }
        }
    }
}

# Output Excel file with each group as a worksheet (requires ImportExcel)
$outputPath = Join-Path -Path (Get-Location) -ChildPath 'FolderComparison.xlsx'

# Check for ImportExcel module
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Write-Host 'ImportExcel module not found. Installing...'
    Install-Module -Name ImportExcel -Scope CurrentUser -Force
}

# Group rows by project/group
$grouped = $rows | Group-Object Group

# Remove existing file if present
if (Test-Path $outputPath) { Remove-Item $outputPath }

foreach ($g in $grouped) {
    $sheetName = $g.Name
    $data = $g.Group | Select-Object 'Raw KMALL Folder', 'AutoClean KMALL Folder', 'Tracklines Folder', 'GSF Folder'
    $data | Export-Excel -Path $outputPath -WorksheetName $sheetName -AutoSize -Append:($true)
}

Write-Host "Comparison Excel file created at: $outputPath"
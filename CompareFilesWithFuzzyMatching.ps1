# PowerShell Script to Compare Files from Two Folders with Fuzzy Matching
# Outputs a CSV listing files with their best matches and similarity scores

param(
    [string]$Folder1,
    [string]$Folder2,
    [string]$OutputCSV
)

# Prompt for folders if not provided
if (-not $Folder1) {
    $Folder1 = Read-Host "Enter path to Folder 1"
}
if (-not $Folder2) {
    $Folder2 = Read-Host "Enter path to Folder 2"
}
if (-not $OutputCSV) {
    $OutputCSV = Read-Host "Enter output CSV file path (press Enter for default: FileComparison.csv)" 
    if (-not $OutputCSV) {
        $OutputCSV = ".\FileComparison.csv"
    }
}

# Verify folders exist
if (-not (Test-Path $Folder1 -PathType Container)) {
    Write-Error "Folder 1 not found: $Folder1"
    exit 1
}
if (-not (Test-Path $Folder2 -PathType Container)) {
    Write-Error "Folder 2 not found: $Folder2"
    exit 1
}

# Handle output path - if it's a directory, create a default filename
if (Test-Path $OutputCSV -PathType Container) {
    $OutputCSV = Join-Path $OutputCSV "FileComparison.csv"
}

# Create output directory if it doesn't exist
$OutputDir = Split-Path -Path $OutputCSV -Parent
if (-not (Test-Path $OutputDir -PathType Container)) {
    try {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    } catch {
        Write-Error "Cannot create output directory: $OutputDir"
        exit 1
    }
}

Write-Host "Comparing folders:`n  Folder 1: $Folder1`n  Folder 2: $Folder2`n  Output: $OutputCSV`n" -ForegroundColor Cyan

# Function to calculate similarity score between two strings using Levenshtein distance
function Get-LevenshteinDistance {
    param(
        [string]$String1,
        [string]$String2
    )
    
    $String1 = $String1.ToLower()
    $String2 = $String2.ToLower()
    
    $len1 = $String1.Length
    $len2 = $String2.Length
    
    if ($len1 -eq 0) { return $len2 }
    if ($len2 -eq 0) { return $len1 }
    
    # Create distance matrix
    $d = New-Object 'int[,]' ($len1 + 1), ($len2 + 1)
    
    for ($i = 0; $i -le $len1; $i++) { $d[$i, 0] = $i }
    for ($j = 0; $j -le $len2; $j++) { $d[0, $j] = $j }
    
    for ($i = 1; $i -le $len1; $i++) {
        for ($j = 1; $j -le $len2; $j++) {
            $cost = if ($String1[$i - 1] -eq $String2[$j - 1]) { 0 } else { 1 }
            $im1 = $i - 1
            $jm1 = $j - 1
            $val1 = $d[$im1, $j] + 1
            $val2 = $d[$i, $jm1] + 1
            $val3 = $d[$im1, $jm1] + $cost
            $d[$i, $j] = [Math]::Min([Math]::Min($val1, $val2), $val3)
        }
    }
    
    return $d[$len1, $len2]
}

# Function to calculate similarity percentage (0-100)
function Get-SimilarityScore {
    param(
        [string]$String1,
        [string]$String2
    )
    
    $maxLen = [Math]::Max($String1.Length, $String2.Length)
    if ($maxLen -eq 0) { return 100 }
    
    $distance = Get-LevenshteinDistance $String1 $String2
    $similarity = (1 - ($distance / $maxLen)) * 100
    
    return [Math]::Round($similarity, 2)
}

# Function to extract timestamp (yyMMddHHmmss) from filename
function Get-Timestamp {
    param(
        [string]$Filename
    )
    
    # Remove extension
    $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($Filename)
    
    # Split by underscore and look for 12-digit timestamp
    $parts = $nameWithoutExt -split '_'
    
    # Try to find a 12-digit timestamp in the parts
    foreach ($part in $parts) {
        if ($part -match '^(\d{12})') {
            return $matches[1]
        }
    }
    
    # Fallback: search for any 12 consecutive digits in the filename
    if ($nameWithoutExt -match '(\d{12})') {
        return $matches[1]
    }
    
    return "N/A"
}

# Function to format timestamp string (yyMMddHHmmss) as HH:mm:ss DD/MM/YY
function Format-Timestamp {
    param(
        [string]$TimeString
    )
    
    if ($TimeString -eq "N/A" -or $TimeString -notmatch '^\d{12}$') {
        return "N/A"
    }
    
    $year = $TimeString.Substring(0, 2)
    $month = $TimeString.Substring(2, 2)
    $day = $TimeString.Substring(4, 2)
    $hour = $TimeString.Substring(6, 2)
    $minute = $TimeString.Substring(8, 2)
    $second = $TimeString.Substring(10, 2)
    
    return "$($hour):$($minute):$($second) $($day)/$($month)/$($year)"
}

# Function to convert yyMMddHHmmss to DateTime
function ConvertToDateTime {
    param(
        [string]$TimeString
    )
    
    if ($TimeString -eq "N/A" -or $TimeString -notmatch '^\d{12}$') {
        return $null
    }
    
    $yy = [int]$TimeString.Substring(0, 2)
    $MM = [int]$TimeString.Substring(2, 2)
    $dd = [int]$TimeString.Substring(4, 2)
    $HH = [int]$TimeString.Substring(6, 2)
    $mm = [int]$TimeString.Substring(8, 2)
    $ss = [int]$TimeString.Substring(10, 2)
    
    # Convert 2-digit year to 4-digit (00-99 -> 2000-2099)
    $yyyy = if ($yy -le 50) { 2000 + $yy } else { 1900 + $yy }
    
    try {
        return [DateTime]::new($yyyy, $MM, $dd, $HH, $mm, $ss)
    } catch {
        return $null
    }
}

# Function to calculate time difference in a readable format
function Get-TimeDifference {
    param(
        [string]$TimeString1,
        [string]$TimeString2
    )
    
    $dt1 = ConvertToDateTime $TimeString1
    $dt2 = ConvertToDateTime $TimeString2
    
    if ($dt1 -eq $null -or $dt2 -eq $null) {
        return "N/A"
    }
    
    $diff = [Math]::Abs(($dt2 - $dt1).TotalSeconds)
    
    if ($diff -lt 60) {
        return "$([int]$diff)s"
    } elseif ($diff -lt 3600) {
        return "$([int]($diff / 60))m"
    } elseif ($diff -lt 86400) {
        return "$([int]($diff / 3600))h"
    } else {
        return "$([int]($diff / 86400))d"
    }
}

# Get all files from both folders (excluding system files)
Write-Host "Scanning Folder 1: $Folder1" -ForegroundColor Cyan
$files1 = @(Get-ChildItem -Path $Folder1 -File -Recurse -ErrorAction SilentlyContinue)
Write-Host "Found $($files1.Count) files in Folder 1" -ForegroundColor Green

Write-Host "Scanning Folder 2: $Folder2" -ForegroundColor Cyan
$files2 = @(Get-ChildItem -Path $Folder2 -File -Recurse -ErrorAction SilentlyContinue)
Write-Host "Found $($files2.Count) files in Folder 2" -ForegroundColor Green

# Create results array
$results = @()
$allMatches = @()

# For each file in Folder 1, find the best match in Folder 2
Write-Host "Performing fuzzy matching..." -ForegroundColor Cyan
$count = 0
foreach ($file1 in $files1) {
    $count++
    Write-Progress -Activity "Matching files" -Status "Processing $($file1.Name)" -PercentComplete (($count / $files1.Count) * 100)
    
    $bestMatch = $null
    $bestScore = 0
    
    foreach ($file2 in $files2) {
        # Compare file names without extension for better matching
        $name1 = [System.IO.Path]::GetFileNameWithoutExtension($file1.Name)
        $name2 = [System.IO.Path]::GetFileNameWithoutExtension($file2.Name)
        
        # Also compare full names
        $scoreWithoutExt = Get-SimilarityScore $name1 $name2
        $scoreFullName = Get-SimilarityScore $file1.Name $file2.Name
        
        # Use the higher score
        $score = [Math]::Max($scoreWithoutExt, $scoreFullName)
        
        if ($score -gt $bestScore) {
            $bestScore = $score
            $bestMatch = $file2
        }
    }
    
    # Store all potential matches for deconflicting later
    $allMatches += [PSCustomObject]@{
        'File1'        = $file1.Name
        'File1Path'    = $file1.FullName
        'File2'        = if ($bestMatch) { $bestMatch.Name } else { $null }
        'File2Path'    = if ($bestMatch) { $bestMatch.FullName } else { $null }
        'Score'        = $bestScore
    }
}

Write-Progress -Activity "Matching files" -Completed

# Deconflict matches - each file from Folder 2 can only be matched once
# If a file from Folder 2 has multiple matches, keep only the highest scoring one
$deconflicted = @()
$usedFile2 = @()

# Sort by score descending to process highest scoring matches first
$sortedMatches = $allMatches | Sort-Object Score -Descending

foreach ($match in $sortedMatches) {
    if ($match.File2 -and -not ($usedFile2 -contains $match.File2Path)) {
        # This Folder 2 file hasn't been used yet, so keep this match
        $deconflicted += $match
        $usedFile2 += $match.File2Path
    } else {
        # This Folder 2 file was already matched to a higher-scoring file, blank it out
        $deconflicted += [PSCustomObject]@{
            'File1'        = $match.File1
            'File1Path'    = $match.File1Path
            'File2'        = $null
            'File2Path'    = $null
            'Score'        = 0
        }
    }
}

# Sort results back to original Folder 1 order by match score descending
$results = $deconflicted | Sort-Object Score -Descending

# Convert to final output format
$finalResults = @()
foreach ($match in $results) {
    $ts1 = Get-Timestamp $match.File1
    $ts2 = if ($match.File2) { Get-Timestamp $match.File2 } else { "N/A" }
    
    $finalResults += [PSCustomObject]@{
        'Folder1_File'        = $match.File1
        'Folder1_Timestamp'   = Format-Timestamp $ts1
        'Folder2_File'        = if ($match.File2) { $match.File2 } else { "" }
        'Folder2_Timestamp'   = Format-Timestamp $ts2
        'TimeDifference'      = if ($match.File2) { Get-TimeDifference $ts1 $ts2 } else { "" }
        'MatchScore'          = $match.Score
    }
}

# Add unpaired files from Folder 2
Write-Host "Finding unpaired files from Folder 2..." -ForegroundColor Cyan
$usedFile2Paths = $results | Where-Object { $_.File2Path } | ForEach-Object { $_.File2Path }
foreach ($file2 in $files2) {
    if (-not ($usedFile2Paths -contains $file2.FullName)) {
        $ts2 = Get-Timestamp $file2.Name
        $finalResults += [PSCustomObject]@{
            'Folder1_File'        = ""
            'Folder1_Timestamp'   = ""
            'Folder2_File'        = $file2.Name
            'Folder2_Timestamp'   = Format-Timestamp $ts2
            'TimeDifference'      = ""
            'MatchScore'          = 0
        }
    }
}

# Export to CSV
Write-Host "Exporting results to CSV..." -ForegroundColor Cyan
$finalResults | Export-Csv -Path $OutputCSV -NoTypeInformation -Encoding UTF8

Write-Host "Complete! Results saved to: $OutputCSV" -ForegroundColor Green
Write-Host "Total files in Folder 1: $($files1.Count)" -ForegroundColor Yellow
Write-Host "Total files in Folder 2: $($files2.Count)" -ForegroundColor Yellow
$pairedCount = ($finalResults | Where-Object { $_.Folder2_File -ne '' }).Count
$unpairedCount = ($finalResults | Where-Object { $_.Folder1_File -eq '' }).Count
$highScoreCount = ($finalResults | Where-Object { $_.MatchScore -ge 80 }).Count
Write-Host "Paired files in Folder 2: $pairedCount" -ForegroundColor Yellow
Write-Host "Unpaired files in Folder 2: $unpairedCount" -ForegroundColor Yellow
Write-Host "Matches with score >= 80: $highScoreCount" -ForegroundColor Yellow

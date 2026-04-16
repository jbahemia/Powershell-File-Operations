# Script to rename files based on a tab-delimited mapping file
# Column 1: Original filename, Column 2: New filename

param(
    [string]$MappingFilePath = "C:\Users\james.bahemia\Visual Studio\Comparison Table Tabbed.txt",
    [string]$TargetFolderPath = "C:\temp\ZDA Naming\AML_MVP_#213160 - Copy for renaming"
)

# Validate inputs
if (-not (Test-Path $MappingFilePath)) {
    Write-Host "Error: Mapping file not found at $MappingFilePath" -ForegroundColor Red
    exit
}

if (-not (Test-Path $TargetFolderPath -PathType Container)) {
    Write-Host "Error: Target folder not found at $TargetFolderPath" -ForegroundColor Red
    exit
}

# Read the mapping file
$mappings = @()
$content = Get-Content $MappingFilePath
foreach ($line in $content) {
    if ($line.Trim()) {
        $parts = $line -split "`t"
        if ($parts.Count -eq 2) {
            # Extract filename before decimal (extension)
            $oldBase = $parts[0].Trim() -replace '\.[^.]*$', ''
            $newBase = $parts[1].Trim() -replace '\.[^.]*$', ''
            $mappings += @{
                OldName = $parts[0].Trim()
                OldBase = $oldBase
                NewBase = $newBase
            }
        }
    }
}

if ($mappings.Count -eq 0) {
    Write-Host "Error: No valid mappings found in the file" -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  PREVIEW: Files that will be renamed" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$failureCount = 0
$previewItems = @()

# Check which files exist and show preview
foreach ($mapping in $mappings) {
    $oldFilePath = Join-Path $TargetFolderPath $mapping.OldName
    
    if (Test-Path $oldFilePath) {
        # Get the original file extension
        $extension = [System.IO.Path]::GetExtension($mapping.OldName)
        $newName = $mapping.NewBase + $extension
        $newFilePath = Join-Path $TargetFolderPath $newName
        
        Write-Host "$($mapping.OldName)" -ForegroundColor Yellow -NoNewline
        Write-Host " -> " -ForegroundColor Gray -NoNewline
        Write-Host "$newName" -ForegroundColor Green
        $previewItems += @{
            OldPath = $oldFilePath
            OldName = $mapping.OldName
            NewName = $newName
            NewPath = $newFilePath
            Exists = $true
        }
        $successCount++
    }
    else {
        Write-Host "$($mapping.OldName)" -ForegroundColor DarkGray -NoNewline
        Write-Host " -> " -ForegroundColor Gray -NoNewline
        Write-Host "$($mapping.NewBase)" -ForegroundColor Red
        Write-Host "  (File not found)" -ForegroundColor Red
        $previewItems += @{
            OldPath = $oldFilePath
            OldName = $mapping.OldName
            NewName = $mapping.NewBase
            NewPath = $null
            Exists = $false
        }
        $failureCount++
    }
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Summary: $successCount file(s) found, $failureCount file(s) not found" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Ask for confirmation
$confirmation = Read-Host "Do you want to proceed with the rename? (yes/no)"

if ($confirmation -eq "yes" -or $confirmation -eq "y") {
    Write-Host ""
    Write-Host "Processing renames..." -ForegroundColor Cyan
    Write-Host ""
    
    $renamedCount = 0
    $skippedCount = 0
    
    foreach ($item in $previewItems) {
        if ($item.Exists) {
            try {
                Rename-Item -Path $item.OldPath -NewName $item.NewName -ErrorAction Stop
                Write-Host "[OK] Renamed: $($item.OldName) -> $($item.NewName)" -ForegroundColor Green
                $renamedCount++
            }
            catch {
                Write-Host "[FAILED] $($item.OldName): $($_.Exception.Message)" -ForegroundColor Red
                $skippedCount++
            }
        }
        else {
            $skippedCount++
        }
    }
    
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "Rename complete!" -ForegroundColor Cyan
    Write-Host "Successfully renamed: $renamedCount file(s)" -ForegroundColor Green
    Write-Host "Skipped: $skippedCount file(s)" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
}
else {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
}

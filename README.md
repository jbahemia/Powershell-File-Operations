## CompareFilesWithFuzzyMatching.ps1

This script is designed for **HIPP 13738**, where a different SVP file type was required compared to the initial submission. The issue was that the replacement files had slightly different timestamps in their filenames.

To resolve this, the script:
- Uses **fuzzy matching** to find the closest filename matches
- Applies a **similarity rating** to determine if files are actually equivalent

Once all matches are confirmed:
- Another script is used to rename the files
- This ensures compatibility with existing **graphs and spreadsheet outputs** generated using the original filenames

---

## CompareFoldersToSpreadsheet_CSV.ps1 / CompareFoldersToSpreadsheet_Excel.ps1

This script automates a **QC stage of HIPP delivery** by comparing CARIS project lines against:

- Spreadsheet lines  
- Raw KMALL  
- AutoClean KMALL  
- Trackline folders  
- GSF files  

### How it works:
- User points to a **parent folder** containing blocks (e.g. `A01`, `A02`, `A03`, etc.).
- Script will prompt user for each location sequentially, the AutoClean KMALL folder for instance would be "M:\Subsea\ProjectData\Current\13738\SI1058 - Year 1\07 Survey Data\Processed_Data\Autoclean KMALL\SOL"
- Matching is performed:
  - First by **folder name**
  - Then by **file/folder name**
- For the Trackline Folder item provide it the folder containing all projects, it will then go A01-TrackLines_A01 and then match the folder names in there to the other line items

After running:
- The user manually copies in:
  - CARIS lines  
  - Processing log lines  
- Differences are then reviewed

### Versions:
- **CSV version**
  - Uses a sequential CSV with headers
  - Works with **default PowerShell**

- **Excel version**
  - Generates a spreadsheet
  - Each block appears on a **separate tab**
  - Requires an additional (free) Excel plugin

---

## Convert-BwxsvpToSvp.ps1 / Convert-SvpToBwxsvp.ps1

Converts between:
- **Beamworx AutoClean SVP format** (`.bwxsvp`)
- **CARIS SVP format** (`.svp`)

**Input format:** ASCII files

---

## RenameFilesFromMapping.ps1

This script renames files using a **tab-delimited text file** with two columns:

- **Column 1** → Original filename  
- **Column 2** → New filename  

### Notes:
- Paths to:
  - The mapping file  
  - The target folder  
- Must be defined within the script

CompareFilesWithFuzzyMatching.ps1 

This script is designed for 13738 HIPPS where we needed to use a different SVP file type from the initial submission however they had slightly different timestamps in the file name. This meant we had to use fuzzy logic to find ones with the closest match as they would be equivalent. We then use the rating to identify if they actually are similar or not. Once we have a full match for everything we would use another script to rename them as we have graph and spreadheet outputs already created for the same profile but with the original names. Afterwards it all matched
------------------------------

CompareFoldersToSpreadsheet_CSV.ps1 / CompareFoldersToSpreadsheet_Excel.ps1 

This script is used to automate a QC stage of HIPP delivery where we compare the lines in a caris project to Spreadsheet lines/Raw KMALL/AutoClean KMALL/Trackline Folders/GSF Files. The script requires you to point to the parent folder with the blocks beneath it in our usual structure e.g. contains A01/A02/A03... It matches what to compare by folder name then by file/folder name. User should then manually copy in the Caris lines and the processing log lines to assess differences

_CSV version uses a sequential csv file separated by headers as for excel generation you need an additional free excel plugin. Works with default powershell. 
_Excel version generates a spreadsheet with each block on a new tab
------------------------------

Convert-BwxsvpToSvp.ps1 / Convert-SvpToBwxsvp.ps1

Converts between Beamworx AutoClean SVP format (.bwxsvp) and Caris SVP format (.svp). Inputs are ascii files
------------------------------

RenameFilesFromMapping.ps1

This script uses a tab delimited txt file with a column for what to find and a second column for what to rename it to. Column 1 is original name, column 2 is new name. Paths to the input naming text file and folder of files to rename are defined within the code.

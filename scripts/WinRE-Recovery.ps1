#requires -RunAsAdministrator
# Requires elevation to modify partitions & labels

Write-Host "🔍 Searching for Recovery Partition (Drive F:)..." -ForegroundColor Cyan

# 1. Discover if user associated recovery partition as F
$targetPartition = Get-Partition | Where-Object { $_.DriveLetter -eq 'F' }

if (-not $targetPartition) {
    Write-Host "❌ Error: Drive 'F:' not found. Please map the recovery partition to 'F:' before running this script." -ForegroundColor Red
    exit 1
}

# 2. Confirm/Update recovery files
Write-Host "📂 Checking WinRE file status..." -ForegroundColor Cyan
$destDir = "F:\WinRE"
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir | Out-Null }

$fileNames = @("Winre.wim", "WinRE.cpio.cab")
$sourcePaths = @(
    "$env:SystemRoot\System32\Recovery",
    "$env:SystemRoot\System32\WinRe"
)

# Check current status. If enabled, disable it to "stage" the Winre.wim file to the C: drive.
$reInfo = & reagentc.exe /info | Out-String
if ($reInfo -match "Enabled") {
    Write-Host "⚙️ WinRE is enabled. Staging files to C: drive..." -ForegroundColor Gray
    & reagentc.exe /disable | Out-String | Out-Null
    Start-Sleep -Seconds 2 # Give Windows a moment to move the file
}

$anyFileFound = $false

foreach ($fileName in $fileNames) {
    $bestSource = $null
    # Find the most recent version on C:
    foreach ($path in $sourcePaths) {
        $fullPath = Join-Path $path $fileName
        $item = Get-Item -Path $fullPath -Force -ErrorAction SilentlyContinue
        if ($item) {
            if (-not $bestSource -or ($item.LastWriteTime -gt (Get-Item -Path $bestSource -Force).LastWriteTime)) {
                $bestSource = $item.FullName
            }
        }
    }

    $targetFile = Join-Path $destDir $fileName
    
    if ($bestSource) {
        $anyFileFound = $true
        $needsUpdate = $false
        
        if (-not (Test-Path $targetFile)) {
            $needsUpdate = $true
        } elseif ((Get-Item -Path $bestSource -Force).LastWriteTime -gt (Get-Item -Path $targetFile -Force).LastWriteTime) {
            $needsUpdate = $true
        }

        if ($needsUpdate) {
            Write-Host "💾 Updating $fileName from $bestSource..." -ForegroundColor Yellow
            Copy-Item -Path $bestSource -Destination $targetFile -Force
        } else {
            Write-Host "✅ $fileName is already current." -ForegroundColor Green
        }
    } else {
        # If not on C, check if it at least exists on F
        if (-not (Test-Path $targetFile)) {
            Write-Warning "⚠️ Missing file: $fileName. Not found on C: or F:."
        } else {
            $anyFileFound = $true
            Write-Host "ℹ️ $fileName exists on F: but source on C: is missing. Keeping existing." -ForegroundColor Gray
        }
    }
}

if (-not $anyFileFound) {
    Write-Host "❌ WARNING: No recovery files found! You may need to create a backup for recovery purposes." -ForegroundColor Red -BackgroundColor Black
}

# 3. Label the partition
Write-Host "📝 Labeling partition..." -ForegroundColor Cyan
Get-Volume -DriveLetter 'F' | Set-Volume -NewFileSystemLabel "WinRE Backup" -ErrorAction SilentlyContinue

# 4. Remove associated drive letter
Write-Host "🔒 Hiding partition (removing drive letter F:)..." -ForegroundColor Cyan
Remove-PartitionAccessPath -DiskNumber $targetPartition.DiskNumber `
                           -PartitionNumber $targetPartition.PartitionNumber `
                           -AccessPath "F:\" -Confirm:$false

# Re-enable WinRE
Write-Host "🔧 Re-enabling Windows Recovery Environment..." -ForegroundColor Cyan
& reagentc.exe /enable | Out-String | Out-Null

# Final validation
if ((& reagentc.exe /info | Out-String) -match "Disabled") {
    Write-Warning "⚠️ WinRE could not be re-enabled. You may need to run 'reagentc /setreimage /path C:\Windows\System32\Recovery' manually."
}

Write-Host "`n✨ WinRE Management Task Complete." -ForegroundColor Green
Remove-Variable targetPartition, destDir, fileNames -ErrorAction SilentlyContinue

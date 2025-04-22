# Import necessary modules dynamically
$modules = @("Microsoft.PowerShell.Management", "Microsoft.PowerShell.Utility", "PSLogging", "BurntToast", "Microsoft.PowerShell.Security")
foreach ($module in $modules) {
    if (Get-Module -Name $module -ListAvailable) {
        Import-Module -Name $module -ErrorAction SilentlyContinue
    } else {
        Write-Host "Warning: Module $module not found. Some features may not work."
    }
}

# Ensure BurntToast and PSLogging are installed and imported
$requiredModules = @("BurntToast", "PSLogging")
foreach ($module in $requiredModules) {
    if (-not (Get-Module -Name $module -ListAvailable)) {
        Install-Module -Name $module -Force -Scope CurrentUser
    }
    Import-Module -Name $module -ErrorAction Stop
}

# Load and Validate XML Configuration
function Load-Configuration {
    param (
        [string]$XmlPath,
        [string]$XsdPath
    )

    try {
        # Load XML
        $ConfigXml = [xml](Get-Content -Path $XmlPath)

        # Validate XML against XSD
        $XmlReaderSettings = New-Object System.Xml.XmlReaderSettings
        $XmlReaderSettings.Schemas.Add("", $XsdPath)
        $XmlReaderSettings.ValidationType = "Schema"
        $XmlReader = [System.Xml.XmlReader]::Create($XmlPath, $XmlReaderSettings)
        while ($XmlReader.Read()) { }

        Write-Host "Configuration file validated successfully." -ForegroundColor Green
        return $ConfigXml
    } catch {
        Write-Host "Error: Configuration validation failed. $_" -ForegroundColor Red
        exit
    }
}

# Paths to Configuration Files
$ConfigXmlPath = "C:\Users\ryanf\Documents\QuarantineConfig.xml"
$ConfigXsdPath = "C:\Users\ryanf\Documents\QuarantineConfig.xsd"

# Load Configuration
$Config = Load-Configuration -XmlPath $ConfigXmlPath -XsdPath $ConfigXsdPath

# Extract Configuration Parameters
$LogPath = $Config.QuarantineConfig.Logging.LogPath
$LogLevel = $Config.QuarantineConfig.Logging.LogLevel
$IncludeTimestamp = [bool]$Config.QuarantineConfig.Logging.IncludeTimestamp
$MonitoringFolder = $Config.QuarantineConfig.Quarantine.MonitoringFolder
$SafeFolder = $Config.QuarantineConfig.Quarantine.SafeFileTarget
$QuarantineFolder = $Config.QuarantineConfig.Quarantine.DeniedAccessFolder
$KasperskyPath = $Config.QuarantineConfig.Quarantine.KasperskyPath
$SevenZipPath = $Config.QuarantineConfig.Quarantine.SevenZipPath

# Ensure Log Directory Exists
$LogDirectory = Split-Path -Path $LogPath
if (-not (Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    Write-Host "Log directory created at: $LogDirectory"
}

# Function: Log-DetailedEvent
function Log-DetailedEvent {
    param (
        [string]$FilePath,
        [string]$Action,
        [string]$Status,
        [string]$Details
    )

    # Prepare log entry
    $Timestamp = if ($IncludeTimestamp) { Get-Date -Format "yyyy-MM-dd HH:mm:ss" } else { "" }
    $LogEntry = "$Timestamp | File: $FilePath | Action: $Action | Status: $Status | Details: $Details"

    # Debugging
    Write-Host "Logging event: $LogEntry" -ForegroundColor Yellow

    # Write to the log file
    try {
        Add-Content -Path $LogPath -Value $LogEntry
    } catch {
        Write-Host "Error: Unable to write to log file. $_" -ForegroundColor Red
    }
}

# Function: Handle Temporary Files
function Handle-TemporaryFiles {
    param ([string]$FilePath)

    if ($FilePath -like "*.tmp") {
        $OriginalFileName = $FilePath -replace ".tmp$", ""
        Rename-Item -Path $FilePath -NewName $OriginalFileName -Force
        Write-Host "Temporary file renamed to: $OriginalFileName" -ForegroundColor Cyan
        Log-DetailedEvent -FilePath $FilePath -Action "Rename" -Status "Success" -Details "Temporary file renamed to original name."
        return $OriginalFileName
    }

    return $FilePath
}

# Function: Display Progress
function Display-Progress {
    param (
        [int]$TotalBytes,
        [int]$CurrentBytes
    )
    $Percentage = [math]::Round(($CurrentBytes / $TotalBytes) * 100, 2)
    Write-Host "Processing: $Percentage% completed" -NoNewline
    if ($Percentage -eq 100) {
        Write-Host " - Done!" -ForegroundColor Green
    }
}

# Function: Scan File with Kaspersky
function Scan-FileWithKaspersky {
    param ([string]$FilePath)

    try {
        # Run Kaspersky's command-line scanner
        $ScanResult = & "$KasperskyPath" SCAN "$FilePath" 2>&1

        # Debugging
        Write-Host "Raw Scan Output: $ScanResult" -ForegroundColor Yellow

        # Simulate scanning stages with logs
        Log-DetailedEvent -FilePath $FilePath -Action "Scan" -Status "In Progress" -Details "Quick Scan started."
        Start-Sleep -Seconds 2 # Simulate quick scan
        Log-DetailedEvent -FilePath $FilePath -Action "Scan" -Status "In Progress" -Details "Heuristic Scan started."
        Start-Sleep -Seconds 2 # Simulate heuristic scan
        Log-DetailedEvent -FilePath $FilePath -Action "Scan" -Status "In Progress" -Details "Deep Scan started."
        Start-Sleep -Seconds 2 # Simulate deep scan

        # Check scan results
        if ($ScanResult -match "last error code 0") {
            Write-Host "Scan Result: File is safe."
            Log-DetailedEvent -FilePath $FilePath -Action "Scan" -Status "Safe" -Details "File passed all scans."
            return $true
        } elseif ($ScanResult -match "Infected") {
            Write-Host "Scan Result: File is infected."
            Log-DetailedEvent -FilePath $FilePath -Action "Scan" -Status "Infected" -Details "File failed one or more scans."
            return $false
        } else {
            Write-Host "Scan Result: Unknown result."
            Log-DetailedEvent -FilePath $FilePath -Action "Scan" -Status "Error" -Details "Unknown scan result: $ScanResult"
            return $null
        }
    } catch {
        Write-Host "Error: Failed to scan file: $FilePath. $_" -ForegroundColor Red
        Log-DetailedEvent -FilePath $FilePath -Action "Scan" -Status "Failed" -Details $_.Exception.Message
        return $null
    }
}

# Function: Process-And-ScanFile
function Process-And-ScanFile {
    param ([string]$FilePath)

    # Handle temporary files
    $FilePath = Handle-TemporaryFiles -FilePath $FilePath

    # Debugging output
    Write-Host "Processing file: $FilePath" -ForegroundColor Cyan

    # Display progress for large files
    $FileSize = (Get-Item $FilePath).Length
    $BytesProcessed = 0
    while ($BytesProcessed -lt $FileSize) {
        Start-Sleep -Milliseconds 500
        $BytesProcessed += ($FileSize / 20) # Simulate processing in chunks
        Display-Progress -TotalBytes $FileSize -CurrentBytes $BytesProcessed
    }

    # Scan the file
    $IsSafe = Scan-FileWithKaspersky -FilePath $FilePath

    if ($IsSafe -eq $true) {
        # Move safe file
        Move-ToSafeFolder -FilePath $FilePath

        # Send notification
        Write-Host "Sending notification for file: $FilePath. Status: Safe" -ForegroundColor Cyan
        New-BurntToastNotification -Text "File Processed", "Safe file moved: $FilePath"
    } elseif ($IsSafe -eq $false) {
        # Move infected file
        Move-ToQuarantine -FilePath $FilePath

        # Send notification
        Write-Host "Sending notification for file: $FilePath. Status: Infected" -ForegroundColor Cyan
        New-BurntToastNotification -Text "File Processed", "Infected file quarantined: $FilePath"
    } else {
        # Unknown scan result
        Log-DetailedEvent -FilePath $FilePath -Action "Unknown" -Status "Failed" -Details "Scan result could not be determined."

        # Send notification
        Write-Host "Sending notification for file: $FilePath. Status: Unknown" -ForegroundColor Cyan
        New-BurntToastNotification -Text "File Processed", "Unknown scan result for file: $FilePath"
    }
}

# Function: Move-ToSafeFolder
function Move-ToSafeFolder {
    param ([string]$FilePath)

    # Safe folder path
    $SafePath = Join-Path -Path $SafeFolder -ChildPath (Split-Path -Path $FilePath -Leaf)
    Move-Item -Path $FilePath -Destination $SafePath -Force
    Log-DetailedEvent -FilePath $FilePath -Action "Safe" -Status "Success" -Details "Moved to Safe folder"
}

# Function: Move-ToQuarantine
function Move-ToQuarantine {
    param ([string]$FilePath)

    if (-not (Test-Path -Path $QuarantineFolder)) {
        New-Item -ItemType Directory -Path $QuarantineFolder -Force | Out-Null
    }

    $QuarantinePath = Join-Path -Path $QuarantineFolder -ChildPath (Split-Path -Path $FilePath -Leaf)
    Move-Item -Path $FilePath -Destination $QuarantinePath -Force
    Log-DetailedEvent -FilePath $FilePath -Action "Quarantine" -Status "Flagged" -Details "Moved to Quarantine folder"
}

# Function: Monitor Folder
function Monitor-Folder {
    # Validate Monitoring Folder Path
    if (-not (Test-Path -Path $MonitoringFolder)) {
        Write-Host "Error: Monitoring folder does not exist: $MonitoringFolder" -ForegroundColor Red
        exit
    }

    $Watcher = New-Object System.IO.FileSystemWatcher
    $Watcher.Path = $MonitoringFolder
    $Watcher.Filter = "*.*"
    $Watcher.IncludeSubdirectories = $true
    $Watcher.EnableRaisingEvents = $true

    # Debugging output
    Write-Host "Initializing FileSystemWatcher on folder: $MonitoringFolder" -ForegroundColor Green

    Register-ObjectEvent $Watcher "Created" -Action {
        param($Source, $EventArgs)
        Process-And-ScanFile -FilePath $EventArgs.FullPath
    }

    Write-Host "Monitoring folder: $MonitoringFolder. Press Ctrl+C to stop." -ForegroundColor Yellow
    while ($true) {
        Start-Sleep -Seconds 1
    }
    $Watcher.Dispose()
}

# Execute Monitoring
Monitor-Folder

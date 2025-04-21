# Variables
$TaskName = "QuarantineWatcherTask"
$ScriptPath = "C:\Users\ryanf\Documents\QuarantineWatcher.ps1"
$User = "ryanf"
$IntervalMinutes = 5
$RetryMinutes = 1
$RetryDurationMinutes = 4
$RandomDelay = "PT1M" # 1 minute random delay in ISO 8601 format

# Create the Action for the Task
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Minimized -File `"$ScriptPath`""

# Create the Periodic Trigger with Repetition and Random Delay
$PeriodicTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes($IntervalMinutes) `
    -RepetitionInterval (New-TimeSpan -Minutes $RetryMinutes) `
    -RepetitionDuration (New-TimeSpan -Minutes $RetryDurationMinutes) # Retry every 1 minute for 4 minutes
$PeriodicTrigger.RandomDelay = $RandomDelay # Add random delay of up to 1 minute

# Create Task Settings to Prevent Overlapping Instances
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable `
    -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes $IntervalMinutes)

# Register the Task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $PeriodicTrigger -User $User -Settings $Settings
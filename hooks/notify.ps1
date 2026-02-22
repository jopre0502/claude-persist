# Claude Code Windows Notification Script
# Enhanced with session information display
# Uses BurntToast if available, fallback to native API

param(
    [string]$Title = "Claude Code",
    [string]$Message = "Task abgeschlossen",
    [string]$SessionId = "",
    [string]$SessionName = "",
    [string]$Model = "",
    [string]$TokenUsage = ""
)

# 1. Play system sound
[System.Media.SystemSounds]::Asterisk.Play()

# 2. Build notification body with session info
$details = @()
if ($SessionName -and $SessionName -ne "null" -and $SessionName -ne "") {
    $details += "Session: $SessionName"
}
if ($Model -and $Model -ne "null" -and $Model -ne "") {
    $details += $Model
}
if ($TokenUsage -and $TokenUsage -ne "null" -and $TokenUsage -ne "") {
    $details += $TokenUsage
}

# Add timestamp
$timestamp = Get-Date -Format "HH:mm:ss"
$details += $timestamp

$subtitle = ""
if ($details.Count -gt 0) {
    $subtitle = $details -join " | "
}

# 3. Try BurntToast first (if installed), then native API
$usedBurntToast = $false

if (Get-Module -ListAvailable -Name BurntToast -ErrorAction SilentlyContinue) {
    try {
        Import-Module BurntToast -ErrorAction Stop
        if ($subtitle) {
            New-BurntToastNotification -Text $Title, $Message, $subtitle -Sound Default
        } else {
            New-BurntToastNotification -Text $Title, $Message -Sound Default
        }
        $usedBurntToast = $true
    } catch {
        $usedBurntToast = $false
    }
}

# 4. Fallback: Native Windows Toast API
if (-not $usedBurntToast) {
    try {
        # Load required assemblies
        [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

        # Build full message
        $fullMessage = $Message
        if ($subtitle) {
            $fullMessage = "$Message`r`n$subtitle"
        }

        # Escape XML special characters
        $escapedTitle = [System.Security.SecurityElement]::Escape($Title)
        $escapedMessage = [System.Security.SecurityElement]::Escape($fullMessage)

        $toastXml = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>$escapedTitle</text>
            <text>$escapedMessage</text>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:Notification.Default"/>
</toast>
"@

        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($toastXml)

        # Use PowerShell's AppId
        $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
        $toast = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId)
        $notification = [Windows.UI.Notifications.ToastNotification]::new($xml)
        $toast.Show($notification)
    } catch {
        # Ultimate fallback: Just use balloon tip via Windows Forms
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $balloon = New-Object System.Windows.Forms.NotifyIcon
            $balloon.Icon = [System.Drawing.SystemIcons]::Information
            $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
            $balloon.BalloonTipTitle = $Title
            $balloon.BalloonTipText = "$Message`r`n$subtitle"
            $balloon.Visible = $true
            $balloon.ShowBalloonTip(5000)
            Start-Sleep -Milliseconds 100
            $balloon.Dispose()
        } catch {
            # All notification methods failed, at least sound played
        }
    }
}

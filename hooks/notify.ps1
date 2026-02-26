# Claude Code Windows Notification Hook
# Reads JSON from stdin (Claude Code hook format)
# Uses BurntToast if available, fallback to native Toast API

# 1. Read JSON from stdin
$jsonInput = ""
try {
    $jsonInput = [Console]::In.ReadToEnd()
} catch {
    $jsonInput = ""
}

# 2. Parse JSON
$data = $null
if ($jsonInput) {
    try {
        $data = $jsonInput | ConvertFrom-Json
    } catch {
        $data = $null
    }
}

# 3. Extract notification type and map to German messages
$notifType = if ($data -and $data.type) { $data.type } else { "notification" }

switch ($notifType) {
    "permission_prompt" {
        $Title = "Claude Code - Berechtigung"
        $Message = "Deine Eingabe wird benoetigt"
    }
    "idle_prompt" {
        $Title = "Claude Code - Wartet"
        $Message = "Claude wartet auf deine Antwort"
    }
    "max_turns_reached" {
        $Title = "Claude Code - Limit"
        $Message = "Maximale Anzahl Turns erreicht"
    }
    "task_completed" {
        $Title = "Claude Code - Fertig"
        $Message = "Aufgabe abgeschlossen"
    }
    default {
        $Title = "Claude Code"
        $Message = "Aufgabe abgeschlossen"
    }
}

# 4. Extract session info
$SessionName = ""
if ($data) {
    if ($data.session -and $data.session.name) { $SessionName = $data.session.name }
    elseif ($data.session_name) { $SessionName = $data.session_name }
}

$Model = ""
if ($data) {
    if ($data.model -and $data.model.display_name) { $Model = $data.model.display_name }
    elseif ($data.model -and $data.model -is [string]) { $Model = $data.model }
}

# 5. Extract token usage
$TokenUsage = ""
if ($data -and $data.context_window -and $data.context_window.current_usage) {
    try {
        $usage = $data.context_window.current_usage
        $inputTok = if ($usage.input_tokens) { $usage.input_tokens } else { 0 }
        $cacheCr = if ($usage.cache_creation_input_tokens) { $usage.cache_creation_input_tokens } else { 0 }
        $cacheRd = if ($usage.cache_read_input_tokens) { $usage.cache_read_input_tokens } else { 0 }
        $curr = $inputTok + $cacheCr + $cacheRd
        $size = if ($data.context_window.context_window_size) { $data.context_window.context_window_size } else { 0 }
        if ($size -gt 0) {
            $pct = [math]::Floor($curr * 100 / $size)
            $currK = [math]::Floor($curr / 1000)
            $sizeK = [math]::Floor($size / 1000)
            $TokenUsage = "${currK}K/${sizeK}K (${pct}%)"
        }
    } catch {}
}

# 6. Build subtitle
$details = @()
if ($SessionName -and $SessionName -ne "null") { $details += "Session: $SessionName" }
if ($Model -and $Model -ne "null") { $details += $Model }
if ($TokenUsage) { $details += $TokenUsage }
$details += (Get-Date -Format "HH:mm:ss")
$subtitle = $details -join " | "

# 7. Play system sound
[System.Media.SystemSounds]::Asterisk.Play()

# 8. Try BurntToast first (if installed), then native API
$usedBurntToast = $false

if (Get-Module -ListAvailable -Name BurntToast -ErrorAction SilentlyContinue) {
    try {
        Import-Module BurntToast -ErrorAction Stop
        New-BurntToastNotification -Text $Title, $Message, $subtitle -Sound Default
        $usedBurntToast = $true
    } catch {
        $usedBurntToast = $false
    }
}

# 9. Fallback: Native Windows Toast API
if (-not $usedBurntToast) {
    try {
        [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

        $fullMessage = "$Message`r`n$subtitle"
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

        $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
        $toast = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId)
        $notification = [Windows.UI.Notifications.ToastNotification]::new($xml)
        $toast.Show($notification)
    } catch {
        # Ultimate fallback: balloon tip
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
            # All methods failed, at least sound played
        }
    }
}

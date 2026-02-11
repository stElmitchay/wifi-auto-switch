-- WiFi Auto-Switch Manager
-- A native macOS app to install, manage, and remove WiFi Auto-Switch

on run
	set installDir to (POSIX path of (path to home folder)) & ".wifi-auto-switch"
	set scriptPath to installDir & "/wifi-auto-switch.sh"
	set plistName to "com.user.wifi-auto-switch"
	set launchAgentPath to (POSIX path of (path to home folder)) & "Library/LaunchAgents/" & plistName & ".plist"

	-- Check if installed
	set isInstalled to fileExists(scriptPath)
	set isRunning to checkRunning(plistName)

	-- Build menu based on current state
	if isInstalled and isRunning then
		set statusText to "Status: Installed and Running"
		set menuOptions to {"Check Status", "Reinstall", "Uninstall", "Quit"}
	else if isInstalled and not isRunning then
		set statusText to "Status: Installed but Not Running"
		set menuOptions to {"Start Service", "Check Status", "Reinstall", "Uninstall", "Quit"}
	else
		set statusText to "Status: Not Installed"
		set menuOptions to {"Install", "Quit"}
	end if

	set userChoice to choose from list menuOptions with prompt statusText & "

Choose an action:" with title "WiFi Auto-Switch" default items {item 1 of menuOptions}

	if userChoice is false then return
	set userChoice to item 1 of userChoice

	if userChoice is "Install" or userChoice is "Reinstall" then
		doInstall(installDir, scriptPath, plistName, launchAgentPath)
	else if userChoice is "Uninstall" then
		doUninstall(installDir, plistName, launchAgentPath)
	else if userChoice is "Check Status" then
		doStatus(plistName)
	else if userChoice is "Start Service" then
		doStart(plistName, launchAgentPath)
	else if userChoice is "Quit" then
		return
	end if
end run

-- ===== Install =====
on doInstall(installDir, scriptPath, plistName, launchAgentPath)
	-- Find wifi-auto-switch.sh relative to this app
	set appPath to POSIX path of (path to me)
	set sourceDir to do shell script "dirname " & quoted form of appPath
	set sourceScript to sourceDir & "/wifi-auto-switch.sh"

	if not fileExists(sourceScript) then
		display alert "Script Not Found" message "Could not find wifi-auto-switch.sh in the same folder as this app." & return & return & "Make sure WiFi Auto-Switch.app and wifi-auto-switch.sh are in the same folder." as critical
		return
	end if

	-- Confirm install
	set confirmResult to display dialog "WiFi Auto-Switch will:" & return & return & ¬
		"  • Monitor your internet connection" & return & ¬
		"  • Auto-switch WiFi if it goes down" & return & ¬
		"  • Start automatically on login" & return & return & ¬
		"Install now?" with title "WiFi Auto-Switch — Install" buttons {"Cancel", "Install"} default button "Install" with icon note

	if button returned of confirmResult is "Cancel" then return

	-- Stop existing service
	try
		do shell script "launchctl bootout gui/$(id -u)/" & plistName & " 2>/dev/null || launchctl unload " & quoted form of launchAgentPath & " 2>/dev/null"
	end try

	-- Create install directory and copy script
	do shell script "mkdir -p " & quoted form of installDir
	do shell script "cp " & quoted form of sourceScript & " " & quoted form of scriptPath
	do shell script "chmod +x " & quoted form of scriptPath

	-- Create LaunchAgent plist
	set plistContent to "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>Label</key>
    <string>" & plistName & "</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>" & scriptPath & "</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/wifi-auto-switch.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/wifi-auto-switch.stderr.log</string>
</dict>
</plist>"

	set launchAgentsDir to (POSIX path of (path to home folder)) & "Library/LaunchAgents"
	do shell script "mkdir -p " & quoted form of launchAgentsDir
	do shell script "echo " & quoted form of plistContent & " > " & quoted form of launchAgentPath

	-- Load the service
	try
		do shell script "launchctl bootstrap gui/$(id -u) " & quoted form of launchAgentPath & " 2>/dev/null || launchctl load " & quoted form of launchAgentPath & " 2>/dev/null"
	end try

	delay 1

	if checkRunning(plistName) then
		display dialog "Installation complete!" & return & return & ¬
			"WiFi Auto-Switch is now running in the background and will start automatically when you log in." & return & return & ¬
			"You can re-open this app anytime to check status or uninstall." with title "WiFi Auto-Switch" buttons {"OK"} default button "OK" with icon note
	else
		display dialog "Installation complete, but the service may not have started yet." & return & return & ¬
			"Try logging out and back in, or re-open this app to check the status." with title "WiFi Auto-Switch" buttons {"OK"} default button "OK" with icon caution
	end if
end doInstall

-- ===== Uninstall =====
on doUninstall(installDir, plistName, launchAgentPath)
	set confirmResult to display dialog "This will stop WiFi Auto-Switch and remove it from your Mac." & return & return & ¬
		"Your WiFi settings will not be changed." & return & return & ¬
		"Continue?" with title "WiFi Auto-Switch — Uninstall" buttons {"Cancel", "Uninstall"} default button "Uninstall" with icon caution

	if button returned of confirmResult is "Cancel" then return

	-- Stop service
	try
		do shell script "launchctl bootout gui/$(id -u)/" & plistName & " 2>/dev/null || launchctl unload " & quoted form of launchAgentPath & " 2>/dev/null"
	end try

	-- Remove files
	try
		do shell script "rm -f " & quoted form of launchAgentPath
	end try
	try
		do shell script "rm -rf " & quoted form of installDir
	end try

	display dialog "WiFi Auto-Switch has been removed." & return & return & ¬
		"Your WiFi settings are unchanged — only the auto-switch tool was removed." with title "WiFi Auto-Switch" buttons {"OK"} default button "OK" with icon note
end doUninstall

-- ===== Status =====
on doStatus(plistName)
	set isRunning to checkRunning(plistName)

	-- Get current WiFi
	set currentWifi to "Unknown"
	try
		set wifiInterface to do shell script "networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}'"
		set currentWifi to do shell script "networksetup -getairportnetwork " & wifiInterface & " | sed 's/Current Wi-Fi Network: //'"
	end try

	-- Get recent logs
	set recentLogs to "(no logs yet)"
	set logFile to (POSIX path of (path to home folder)) & ".wifi-auto-switch.log"
	try
		set recentLogs to do shell script "tail -10 " & quoted form of logFile
	end try

	if isRunning then
		set statusLine to "Running"
	else
		set statusLine to "Not Running"
	end if

	display dialog "Service: " & statusLine & return & ¬
		"Current WiFi: " & currentWifi & return & return & ¬
		"— Recent Activity —" & return & recentLogs with title "WiFi Auto-Switch — Status" buttons {"OK"} default button "OK" with icon note
end doStatus

-- ===== Start Service =====
on doStart(plistName, launchAgentPath)
	if not fileExists(launchAgentPath) then
		display alert "Cannot Start" message "The LaunchAgent is missing. Please reinstall using the Install option." as critical
		return
	end if

	try
		do shell script "launchctl bootstrap gui/$(id -u) " & quoted form of launchAgentPath & " 2>/dev/null || launchctl load " & quoted form of launchAgentPath & " 2>/dev/null"
	end try

	delay 1

	if checkRunning(plistName) then
		display dialog "WiFi Auto-Switch has been started." with title "WiFi Auto-Switch" buttons {"OK"} default button "OK" with icon note
	else
		display dialog "Could not start the service. Try logging out and back in." with title "WiFi Auto-Switch" buttons {"OK"} default button "OK" with icon caution
	end if
end doStart

-- ===== Helpers =====
on fileExists(filePath)
	try
		do shell script "test -f " & quoted form of filePath
		return true
	on error
		return false
	end try
end fileExists

on checkRunning(plistName)
	try
		do shell script "launchctl list " & plistName & " 2>/dev/null"
		return true
	on error
		return false
	end try
end checkRunning

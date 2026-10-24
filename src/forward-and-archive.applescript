-- Forward and Archive for Apple Mail + Gmail
-- https://github.com/sbecker11/mail-forward-and-archive
--
-- Forwards every selected message in Apple Mail to a destination address,
-- archives the selection with Mail's own Archive command (Ctrl-Cmd-A),
-- and verifies that each message actually left the Inbox.
--
-- Designed to run inside a macOS Shortcuts "Run AppleScript" action.

-- ===== CONFIGURATION =====
-- acctName: the account's Description in Mail > Settings > Accounts
--           (often the email address, but not always). Used only for verification.
property acctName : "scbboston@gmail.com"
-- destAddress: where selected messages are forwarded.
property destAddress : "shawnbecker.recruiting@gmail.com"
-- ==========================

on run {input, parameters}
	set logLines to {}
	set msgRefs to {}
	set msgIds to {}
	
	-- 1. Capture the selection (does not move keyboard focus)
	tell application "Mail"
		set selectedMessages to selection
		set end of logLines to "Selected: " & (count of selectedMessages) & " message(s)"
		repeat with m in selectedMessages
			set end of msgRefs to (contents of m)
			try
				set end of msgIds to (message id of (contents of m))
			end try
		end repeat
	end tell
	if (count of msgRefs) is 0 then
		my showLog(logLines)
		return input
	end if
	
	-- 2. Archive FIRST, while focus is still on the message list.
	--    Ctrl-Cmd-A files messages into the account's Archive mailbox
	--    (set in Mail > Settings > Accounts > Mailbox Behaviors).
	try
		tell application "Mail" to activate
		tell application "System Events"
			repeat 20 times
				if frontmost of process "Mail" then exit repeat
				delay 0.25
			end repeat
			delay 0.5
			set frontApp to name of first process whose frontmost is true
			keystroke "a" using {control down, command down}
		end tell
		set end of logLines to "Archive keystroke sent (frontmost: " & frontApp & ")"
	on error errMsg number errNum
		set end of logLines to "Archive keystroke FAILED: " & errMsg & " (" & errNum & ")"
	end try
	delay 1
	
	-- 3. Forward each captured message (references stay valid after archiving)
	tell application "Mail"
		repeat with theMessage in msgRefs
			set theMessage to contents of theMessage
			try
				set theSubject to subject of theMessage
			on error
				set theSubject to "(subject unavailable)"
			end try
			set end of logLines to ""
			set end of logLines to "• " & theSubject
			try
				set forwarded to forward theMessage without opening window
				tell forwarded
					make new to recipient at end of to recipients with properties {address:(my destAddress)}
					send
				end tell
				set end of logLines to "   forwarded: OK"
			on error errMsg number errNum
				set end of logLines to "   forward FAILED: " & errMsg & " (" & errNum & ")"
			end try
		end repeat
	end tell
	
	-- 4. Verify (10 s total). Any error counts as STILL IN INBOX,
	--    so a Mail failure can never be reported as success.
	set end of logLines to ""
	set remaining to msgIds
	try
		tell application "Mail"
			set inboxBox to mailbox "INBOX" of account (my acctName)
			repeat 10 times
				set stillIn to {}
				repeat with mid in remaining
					set mid to contents of mid
					try
						if (count of (messages of inboxBox whose message id is mid)) > 0 then set end of stillIn to mid
					on error
						set end of stillIn to mid
					end try
				end repeat
				set remaining to stillIn
				if (count of remaining) is 0 then exit repeat
				delay 1
			end repeat
		end tell
	on error errMsg number errNum
		set end of logLines to "Verify FAILED: " & errMsg & " (" & errNum & ")"
	end try
	set end of logLines to "Out of Inbox: " & ((count of msgIds) - (count of remaining)) & " of " & (count of msgIds)
	repeat with mid in remaining
		set end of logLines to "   STILL IN INBOX: " & (contents of mid)
	end repeat
	
	my showLog(logLines)
	return input
end run

on showLog(logLines)
	set AppleScript's text item delimiters to linefeed
	set report to logLines as text
	set AppleScript's text item delimiters to ""
	set the clipboard to report
	tell application "Mail"
		activate
		display dialog "Forward and Archive finished (summary copied to clipboard). Press Return to close." default answer report buttons {"OK"} default button "OK"
	end tell
end showLog

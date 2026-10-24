-- Lists every Mail account (name + addresses) and its mailboxes, nested.
-- Run in Script Editor. Output is shown in a dialog and copied to the clipboard.
-- Names are bracketed so stray spaces are visible.

on run
	set out to {}
	tell application "Mail"
		repeat with a in accounts
			set end of out to "ACCOUNT: [" & (name of a) & "]  " & ((email addresses of a) as text)
			my listBoxes(a, "   ", out)
		end repeat
	end tell
	set AppleScript's text item delimiters to linefeed
	set report to out as text
	set AppleScript's text item delimiters to ""
	set the clipboard to report
	display dialog "Mailboxes (copied to clipboard):" default answer report buttons {"OK"} default button "OK"
end run

-- Note: the parameter is deliberately not named "container",
-- which is a reserved term in Mail's scripting dictionary.
on listBoxes(parentBox, indent, out)
	tell application "Mail"
		try
			set boxes to mailboxes of parentBox
		on error
			return
		end try
		repeat with mb in boxes
			set mb to contents of mb
			try
				set end of out to indent & "[" & (name of mb) & "]"
			end try
			my listBoxes(mb, indent & "   ", out)
		end repeat
	end tell
end listBoxes

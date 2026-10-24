# Mail Forward and Archive

A macOS Shortcut, written in AppleScript, that does three things in one step for whatever messages you've selected in **Apple Mail**:

1. **Archives** them out of the Inbox, using Mail's own Archive command.
2. **Forwards** each one, with its full original content, to an address you choose.
3. **Verifies** that each message actually left the Inbox, and shows a log of everything it did.

It was built for a Gmail account in Apple Mail, where the obvious AppleScript approaches don't work (see [Why it works this way](#why-it-works-this-way)). Typical use: send recruiter emails and job-alert digests from a personal inbox to a dedicated recruiting inbox and clear them out in one keystroke.

---

## Contents

- [Requirements](#requirements)
- [Setup](#setup)
- [Usage](#usage)
- [Reading the log](#reading-the-log)
- [How it works](#how-it-works)
- [Why it works this way](#why-it-works-this-way)
- [Troubleshooting](#troubleshooting)
- [Limitations](#limitations)
- [Repository layout](#repository-layout)
- [License](#license)

---

## Requirements

- macOS with **Apple Mail** and **Shortcuts**.
- A Gmail (IMAP) account set up in Mail. Other IMAP accounts will probably work, but they haven't been tested.
- Permission for Shortcuts to send keystrokes (Accessibility). Setup step 4 covers this.

---

## Setup

### 1. Create an archive label in Gmail

Create a regular Gmail label to hold archived messages, for example `NewArchived`. You can do this in Gmail on the web, or in Mail with **Mailbox → New Mailbox**, choosing your Gmail account as the **Location**. Don't put it under *On My Mac*.

Check that the label appears in Gmail's label list on the web.

> **Why not Gmail's built-in archive?** Mail's default "Archive" mailbox for Gmail is mapped to *All Mail*, and moves into All Mail don't reliably remove the Inbox label. A real label behaves like an ordinary folder.

### 2. Point Mail's Archive behavior at that label

**Mail → Settings → Accounts →** *(your Gmail account)* **→ Mailbox Behaviors → Archive Mailbox:** choose the label from step 1.

After this, ⌃⌘A, whether you press it or the script does, files messages into your label.

### 3. Configure the script

Open `src/forward-and-archive.applescript` and edit the two properties at the top:

```applescript
property acctName : "you@gmail.com"              -- account Description in Mail
property destAddress : "destination@example.com" -- where to forward
```

`acctName` must match the account's **Description** in *Mail → Settings → Accounts*. That's often, but not always, the email address. It's used only for the verification step. If you're unsure, run `tools/list-mailboxes.applescript` in Script Editor to see the exact account names.

### 4. Create the Shortcut

1. Open **Shortcuts**, create a new shortcut, and name it something like *Forward and Archive*.
2. Add a **Run AppleScript** action.
3. Replace its entire contents with the configured script from step 3.
4. Optional: in the shortcut's details, turn on **Pin in Menu Bar** and/or assign a **keyboard shortcut**.

Grant permissions on the first run:

- **System Settings → Privacy & Security → Accessibility:** enable **Shortcuts**. If you launch from the menu bar or a keyboard shortcut, also enable **Shortcuts Events** if it's listed.
- Allow Shortcuts to control **System Events** and **Mail** when prompted. If you clicked Don't Allow earlier, re-enable it under **Privacy & Security → Automation**.
- After changing Accessibility settings, quit Shortcuts completely (⌘Q) and reopen it.

---

## Usage

1. In Mail, click the account's **Inbox** in the sidebar, not All Mail or a smart mailbox.
2. Click a message in the list so keyboard focus is on the message list.
3. Select one or more messages (⌘-click or ⇧-click).
4. Run the shortcut.

A dialog shows the log, which is also copied to the clipboard.

Running the shortcut again on the same message forwards it again. If you don't want duplicates at the destination, deduplicate there.

---

## Reading the log

A successful run:

```
Selected: 6 message(s)
Archive keystroke sent (frontmost: Mail)

• SHAWN, I think this job might be right for you!
   forwarded: OK

• Your latest Oracle jobs
   forwarded: OK

Out of Inbox: 6 of 6
```

| Line | Meaning |
|---|---|
| `Selected: N message(s)` | What Mail reported as selected. |
| `Archive keystroke sent (frontmost: Mail)` | ⌃⌘A was sent while Mail was frontmost. If another app is named, the keystroke went to the wrong place. |
| `• <subject>` | The message's **subject line**. Job digests often use the first listing as the subject, but the whole message is forwarded. |
| `forwarded: OK` | The forward was created and sent. |
| `Out of Inbox: X of N` | Messages confirmed gone from the Inbox after up to 10 seconds. Any error during this check counts as *still in Inbox*, so a failure can't be reported as success. |
| `STILL IN INBOX: <message-id>` | That message didn't leave the Inbox. See [Troubleshooting](#troubleshooting). |

---

## How it works

1. **Capture.** Read Mail's selection and store a reference and Message-ID for each message. This doesn't move keyboard focus.
2. **Archive first.** Bring Mail to the front, wait until it's actually frontmost, and send ⌃⌘A. This has to happen *before* forwarding, because sending a forward moves focus away from the message list and the keystroke would then do nothing.
3. **Forward.** Forward each stored message, without opening a window, to `destAddress`. The references stay valid after archiving because Mail tends to hand the script the *All Mail* copy of a Gmail message, which archiving doesn't remove.
4. **Verify.** Poll the account's `INBOX` for each Message-ID for up to 10 seconds total.

---

## Why it works this way

This design came out of a long round of trial and error. If you want to adapt the script, here's what **didn't** work with Gmail in Apple Mail:

| Approach | Result |
|---|---|
| `move msg to mailbox "Archived"` | Error -1728. Gmail has no such folder unless you create the label. |
| `move msg to` Mail's "Archive" mailbox (mapped to All Mail) | Reported OK, but the message stayed in the Inbox. |
| Deciding "already archived" from `mailbox of msg` | Unreliable. Mail often returns the **All Mail** copy even when you selected the message in the Inbox. |
| Finding the Inbox copy by Message-ID and `move`-ing it to a real label | The label was added, but the Inbox copy stayed. With Gmail, an AppleScript `move` behaves like a **copy**. Turning on Gmail's IMAP Auto-Expunge didn't change this. |
| `set deleted status of msg to true` | **Crashed Mail.** Every later command failed with -609, "Connection is invalid". |
| Clicking *Message → Archive* via System Events | Unreliable. The menu item may be missing or disabled for the selection, and clicking a disabled item fails silently. |
| Sending ⌃⌘A *after* forwarding | Did nothing. Focus had left the message list. |
| **Sending ⌃⌘A *before* forwarding, with Archive pointed at a real label** | ✅ Works for one or many messages. |

Two other AppleScript pitfalls came up along the way:

- Don't name a variable or handler parameter `container` inside `tell application "Mail"`. It's a reserved term in Mail's dictionary and silently breaks lookups.
- Don't wrap verification in a bare `try` that ignores errors. A crashed Mail then looks like success.

---

## Troubleshooting

**`Archive keystroke FAILED: Shortcuts is not allowed to send keystrokes. (1002)`**
Grant Accessibility access (setup step 4). If it's already on, remove Shortcuts from the list with **−**, add it back, and relaunch Shortcuts.

**`Archive keystroke sent (frontmost: <something other than Mail>)`**
Mail didn't come to the front in time. Click into Mail's message list before running. If it keeps happening, increase the `delay 0.5` after the frontmost loop.

**`STILL IN INBOX` even though the keystroke was sent**
- Make sure you selected the messages in the account's **Inbox**, with focus on the message list.
- Press ⌃⌘A yourself on the same message. If that doesn't archive it either, it's a Mail or Gmail problem, not the script. Check *Mailbox Behaviors* (setup step 2).
- Force a refresh with **Mailbox → Get All New Mail**, or **Take All Accounts Offline** and then **Online**, and compare with Gmail on the web.

**`Verify FAILED: Mail got an error: Can't get mailbox "INBOX" of account …`**
`acctName` doesn't match the account's Description in Mail. Run `tools/list-mailboxes.applescript` to see the exact name.

**`forward FAILED: …`**
Check that the account can send mail and that `destAddress` is correct.

**Mail quit unexpectedly**
Make sure you're running the current script. Earlier experimental versions that set `deleted status` crash Mail. The current version starts its log with `Selected:` followed by `Archive keystroke sent`.

---

## Limitations

- **UI-dependent.** Archiving relies on a simulated ⌃⌘A, so Mail must be able to come to the front, and focus must be on the message list.
- **One account is verified.** Forwarding and archiving work for any selected messages, but verification only checks the Inbox of `acctName`.
- **No deduplication.** Re-running forwards again.
- **Tested setup:** Apple Mail with Gmail over IMAP, run from macOS Shortcuts in October 2026. Mail's scripting behavior changes between macOS releases.

---

## Repository layout

```
mail-forward-and-archive/
├── README.md
├── LICENSE
├── src/
│   └── forward-and-archive.applescript   # paste into a Shortcuts "Run AppleScript" action
└── tools/
    └── list-mailboxes.applescript        # diagnostic: list account and mailbox names
```

---

## License

MIT. See [LICENSE](LICENSE).

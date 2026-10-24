# Mail Forward and Archive

<img src="src/applescript-icon-mac-intel.png" alt="AppleScript" width="32" height="32">

An AppleScript for **Apple Mail**, run from a macOS Shortcut or a Hammerspoon hotkey, that does three things in one step for whatever messages you've selected:

1. **Archives** them out of the Inbox, using Mail's own Archive command.
2. **Forwards** each one, with its full original content, to an address you choose.
3. **Verifies** that each message actually left the Inbox, and shows a log of everything it did.

It was built for a Gmail account in Apple Mail, where the obvious AppleScript approaches don't work (see [Why it works this way](#why-it-works-this-way)). Typical use: send recruiter emails and job-alert digests from a personal inbox to a dedicated recruiting inbox and clear them out in one keystroke.

---

## Contents

- [Requirements](#requirements)
- [Setup](#setup)
- [Option B: Hammerspoon hotkey](#6-option-b-hammerspoon-hotkey)
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

- macOS with **Apple Mail**, plus either **Shortcuts** (built in) or **[Hammerspoon](https://www.hammerspoon.org/)** (free) to launch the script.
- A Gmail (IMAP) account set up in Mail. Other IMAP accounts will probably work, but they haven't been tested.
- Accessibility permission for whichever launcher you use, so it can send keystrokes. The setup steps cover this.

---

## Setup

### 1. Create the `NewArchived` label in Gmail on the web

The script archives into a normal Gmail label named `NewArchived`. Create that label in Gmail before you point Mail at it:

1. Open [Gmail](https://mail.google.com) in a browser and sign in to the account you use in Apple Mail.
2. In the left sidebar, scroll down and click **More** if the label list is collapsed.
3. At the bottom of the label list, click **Create new label**.
4. In **Please enter a new label name**, type `NewArchived`.
5. Leave **Nest label under** unchecked, so the label is top-level.
6. Click **Create**.

`NewArchived` should now appear in the sidebar label list. If **Create new label** is not in the sidebar, use **Settings** (the gear) → **See all settings** → **Labels** → **Create new label**, then use the same name.

You can instead create it from Apple Mail with **Mailbox → New Mailbox**, choosing your Gmail account as the **Location**. Don't put it under _On My Mac_.

After either method, confirm the label is visible in Gmail on the web, then in Apple Mail choose **Mailbox → Get All New Mail** so the new label is available in step 2.

> **Why not Gmail's built-in archive?** Mail's default "Archive" mailbox for Gmail is mapped to _All Mail_, and moves into All Mail don't reliably remove the Inbox label. A real label behaves like an ordinary folder.

### 2. Point Mail's Archive behavior at that label

**Mail → Settings → Accounts →** _(your Gmail account)_ **→ Mailbox Behaviors → Archive Mailbox:** choose the label from step 1.

After this, ⌃⌘A, whether you press it or the script does, files messages into your label.

### 3. Configure the script

Open `src/forward-and-archive.applescript` and edit the two properties at the top:

```applescript
property acctName : "you@gmail.com"              -- account Description in Mail
property destAddress : "destination@example.com" -- where to forward
```

`acctName` must match the account's **Description** in _Mail → Settings → Accounts_. That's often, but not always, the email address. It's used only for the verification step. If you're unsure, run `tools/list-mailboxes.applescript` in Script Editor to see the exact account names.

### 4. Run the script

There are two ways to run `src/forward-and-archive.applescript` on messages you have selected in the Inbox of the Mail account named by `acctName`. Hold ⌘ and click to select more than one message.

- **Option A.** A shortcut in the Shortcuts app. Continue with step 5.
- **Option B.** A Hammerspoon hotkey. Skip to [step 6](#6-option-b-hammerspoon-hotkey).

### 5. Option A: Create an Apple Shortcut

To use Hammerspoon instead, skip this step and go to [Option B](#6-option-b-hammerspoon-hotkey).

1. Open **Shortcuts**, create a new shortcut, and name it something like _Forward and Archive_.
2. Add a **Run AppleScript** action.
3. Replace its entire contents with the configured script from step 3.
4. Optional: in the shortcut's details, turn on **Pin in Menu Bar** and/or assign a **keyboard shortcut**.

Grant permissions on the first run:

- **System Settings → Privacy & Security → Accessibility:** enable **Shortcuts**. If you launch from the menu bar or a keyboard shortcut, also enable **Shortcuts Events** if it's listed.
- Allow Shortcuts to control **System Events** and **Mail** when prompted. If you clicked Don't Allow earlier, re-enable it under **Privacy & Security → Automation**.
- After changing Accessibility settings, quit Shortcuts completely (⌘Q) and reopen it.

---

## 6. Option B: Hammerspoon hotkey

[Hammerspoon](https://www.hammerspoon.org/) is a free macOS automation tool scripted in Lua. Use it instead of Shortcuts if you want a global hotkey that doesn't depend on the Shortcuts app or its permission prompts. It runs the **same** AppleScript.

Complete setup steps 1–2 (Gmail label and Mail's Archive behavior) first. You can skip step 3, because the installer fills in your addresses.

### Automatic install

From the repository folder:

```bash
./hammerspoon/install.sh
```

The installer:

1. Installs Hammerspoon with Homebrew (`brew install --cask hammerspoon`) if it isn't already installed.
2. Prompts for your Mail account Description (`acctName`) and the forward-to address (`destAddress`).
3. Copies a configured copy of the AppleScript and the Lua module into `~/.hammerspoon/`. Any existing copies are backed up as `.bak`.
4. Adds `require("forward-and-archive")` to `~/.hammerspoon/init.lua`, if it isn't already there.
5. Launches Hammerspoon.

To run it non-interactively:

```bash
ACCT_NAME="you@gmail.com" DEST_ADDRESS="destination@example.com" ./hammerspoon/install.sh
```

### Manual install

1. Install Hammerspoon: `brew install --cask hammerspoon`, or download it from hammerspoon.org.
2. Copy `src/forward-and-archive.applescript` to `~/.hammerspoon/` and edit the two properties at the top.
3. Copy `hammerspoon/forward-and-archive.lua` to `~/.hammerspoon/`.
4. Add this line to `~/.hammerspoon/init.lua`:
   ```lua
    require("forward-and-archive")
   ```

### After installing

1. **System Settings → Privacy & Security → Accessibility:** enable **Hammerspoon**.
2. Optional: in Hammerspoon's **Preferences**, turn on **Launch Hammerspoon at login**.
3. Click the Hammerspoon menu-bar icon and choose **Reload Config**.
4. In Mail, select messages in the Inbox and press **⌃⌥⌘F** (Control-Option-Command-F).
5. On the first run, allow control of **Mail** and **System Events** when prompted. If you missed the prompt, enable it under **Privacy & Security → Automation**.

The hotkey only acts when Mail is the frontmost app. Otherwise it shows an alert and does nothing. The result dialog and clipboard log are the same as with Shortcuts.

### Changing the hotkey

Edit the configuration block in `~/.hammerspoon/forward-and-archive.lua` and reload the config:

```lua
M.mods = { "ctrl", "alt", "cmd" }
M.key  = "F"
```

Release the hotkey promptly after pressing it. The script sends ⌃⌘A about half a second later, and modifier keys still held down could combine with it.

### Updating

After pulling a new version of the repository, re-run `./hammerspoon/install.sh`. It overwrites the installed copies, keeping `.bak` backups, and leaves `init.lua` alone if it's already set up.

### Uninstalling

Remove the `require("forward-and-archive")` line from `~/.hammerspoon/init.lua`, delete `~/.hammerspoon/forward-and-archive.*`, and reload the config.

---

## Usage

1. In Mail, click the account's **Inbox** in the sidebar, not All Mail or a smart mailbox.
2. Click a message in the list so keyboard focus is on the message list.
3. Select one or more messages (⌘-click or ⇧-click).
4. Run the shortcut, or press the Hammerspoon hotkey (⌃⌥⌘F by default).

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

| Line                                       | Meaning                                                                                                                                                           |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Selected: N message(s)`                   | What Mail reported as selected.                                                                                                                                   |
| `Archive keystroke sent (frontmost: Mail)` | ⌃⌘A was sent while Mail was frontmost. If another app is named, the keystroke went to the wrong place.                                                            |
| `• <subject>`                              | The message's **subject line**. Job digests often use the first listing as the subject, but the whole message is forwarded.                                       |
| `forwarded: OK`                            | The forward was created and sent.                                                                                                                                 |
| `Out of Inbox: X of N`                     | Messages confirmed gone from the Inbox after up to 10 seconds. Any error during this check counts as _still in Inbox_, so a failure can't be reported as success. |
| `STILL IN INBOX: <message-id>`             | That message didn't leave the Inbox. See [Troubleshooting](#troubleshooting).                                                                                     |

---

## How it works

1. **Capture.** Read Mail's selection and store a reference and Message-ID for each message. This doesn't move keyboard focus.
2. **Archive first.** Bring Mail to the front, wait until it's actually frontmost, and send ⌃⌘A. This has to happen _before_ forwarding, because sending a forward moves focus away from the message list and the keystroke would then do nothing.
3. **Forward.** Forward each stored message, without opening a window, to `destAddress`. The references stay valid after archiving because Mail tends to hand the script the _All Mail_ copy of a Gmail message, which archiving doesn't remove.
4. **Verify.** Poll the account's `INBOX` for each Message-ID for up to 10 seconds total.

---

## Why it works this way

This design came out of a long round of trial and error. If you want to adapt the script, here's what **didn't** work with Gmail in Apple Mail:

| Approach                                                                  | Result                                                                                                                                                              |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `move msg to mailbox "Archived"`                                          | Error -1728. Gmail has no such folder unless you create the label.                                                                                                  |
| `move msg to` Mail's "Archive" mailbox (mapped to All Mail)               | Reported OK, but the message stayed in the Inbox.                                                                                                                   |
| Deciding "already archived" from `mailbox of msg`                         | Unreliable. Mail often returns the **All Mail** copy even when you selected the message in the Inbox.                                                               |
| Finding the Inbox copy by Message-ID and `move`-ing it to a real label    | The label was added, but the Inbox copy stayed. With Gmail, an AppleScript `move` behaves like a **copy**. Turning on Gmail's IMAP Auto-Expunge didn't change this. |
| `set deleted status of msg to true`                                       | **Crashed Mail.** Every later command failed with -609, "Connection is invalid".                                                                                    |
| Clicking _Message → Archive_ via System Events                            | Unreliable. The menu item may be missing or disabled for the selection, and clicking a disabled item fails silently.                                                |
| Sending ⌃⌘A _after_ forwarding                                            | Did nothing. Focus had left the message list.                                                                                                                       |
| **Sending ⌃⌘A _before_ forwarding, with Archive pointed at a real label** | ✅ Works for one or many messages.                                                                                                                                  |

Two other AppleScript pitfalls came up along the way:

- Don't name a variable or handler parameter `container` inside `tell application "Mail"`. It's a reserved term in Mail's dictionary and silently breaks lookups.
- Don't wrap verification in a bare `try` that ignores errors. A crashed Mail then looks like success.

---

## Troubleshooting

`Archive keystroke FAILED: Shortcuts is not allowed to send keystrokes. (1002)`
Grant Accessibility access (step 5). If it's already on, remove Shortcuts from the list with **−**, add it back, and relaunch Shortcuts.

`Archive keystroke sent (frontmost: <something other than Mail>)`
Mail didn't come to the front in time. Click into Mail's message list before running. If it keeps happening, increase the `delay 0.5` after the frontmost loop.

`STILL IN INBOX` **even though the keystroke was sent**

- Make sure you selected the messages in the account's **Inbox**, with focus on the message list.
- Press ⌃⌘A yourself on the same message. If that doesn't archive it either, it's a Mail or Gmail problem, not the script. Check _Mailbox Behaviors_ (setup step 2).
- Force a refresh with **Mailbox → Get All New Mail**, or **Take All Accounts Offline** and then **Online**, and compare with Gmail on the web.

`Verify FAILED: Mail got an error: Can't get mailbox "INBOX" of account …`
`acctName` doesn't match the account's Description in Mail. Run `tools/list-mailboxes.applescript` to see the exact name.

`forward FAILED: …`
Check that the account can send mail and that `destAddress` is correct.

**Hammerspoon hotkey does nothing**
Make sure Mail is the frontmost app and that the config loaded: the Hammerspoon Console should show no errors after **Reload Config**. Check that `~/.hammerspoon/init.lua` contains `require("forward-and-archive")`, and that no other app has claimed the same hotkey.

**Hammerspoon:** `Forward and Archive failed — see Hammerspoon Console`
Open the Console from the Hammerspoon menu-bar icon. The osascript error is printed there. "Not allowed to send keystrokes" means Accessibility isn't enabled for Hammerspoon. "Not authorized to send Apple events" means the Automation permission was denied.

**Mail quit unexpectedly**
Make sure you're running the current script. Earlier experimental versions that set `deleted status` crash Mail. The current version starts its log with `Selected:` followed by `Archive keystroke sent`.

---

## Limitations

- **Hammerspoon launcher is new.** The AppleScript is the tested version, but the Hammerspoon launcher hasn't been run end-to-end yet. Please report any problems.
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
├── hammerspoon/
│   ├── forward-and-archive.lua           # Hammerspoon hotkey module
│   └── install.sh                        # installs Hammerspoon + hotkey
├── src/
│   └── forward-and-archive.applescript   # Shortcuts "Run AppleScript" action, or run by Hammerspoon
└── tools/
    └── list-mailboxes.applescript        # diagnostic: list account and mailbox names
```

---

## License

MIT. See [LICENSE](LICENSE).

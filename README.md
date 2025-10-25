# Radio Task Scheduler (VLC recorder)

This project creates Windows Task Scheduler tasks from a simple text “list” that defines task names and their triggers. Each list line turns into one scheduled task with one or more triggers, and a per-task PowerShell script is prepared for execution.

- Main script: `release\createSchedTask_08.ps1`
- Task folder in Task Scheduler: `\radioVLCp\`
- Template script copied per task: `release\00_recVLCv04_128cro3_01.ps1` → `scheVLC\<TaskId>.ps1`
- Input list (by default): `release\list_06.txt` (your repo also contains `release\list_06_baseList.txt`)

## Prerequisites

- Windows 11
- PowerShell 5.1 or 7.x (both supported; VS Code may default to Windows PowerShell 5.1)
- Run elevated (Administrator) — the script self-elevates if needed
- Allow script execution (at least for the current session)

Quick one-time session unblock:
```powershell
# Run in VS Code terminal before executing the script
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

## How to run

1) Open a VS Code terminal in this folder:
```powershell
cd C:\Users\Jan\Dropbox\doc\rec\radio\release
```

2) Ensure the input list exists:
- Default expected file: `.\list_06.txt`
- If your list is `list_06_baseList.txt`, either rename/copy it to `list_06.txt`:
```powershell
Copy-Item .\list_06_baseList.txt .\list_06.txt -Force
```

3) Run the scheduler builder:
```powershell
.\createSchedTask_08.ps1
```
- The script will elevate if not already elevated.
- When prompted for credentials, enter the password for the account configured in the script (default shown is `COMPUTERNAME\Jan`; you can also use `.\Jan`).

4) Verify created tasks:
```powershell
Get-ScheduledTask -TaskPath '\radioVLCp\'
```

5) Remove all tasks created by this project (if needed):
```powershell
Get-ScheduledTask -TaskPath '\radioVLCp\' | Unregister-ScheduledTask -Confirm:$false
```

## Data list language (how to write list_06.txt)

- Location: `release\list_06.txt`
- Each non-empty line defines ONE task with one or more triggers.
- Fields are space-separated:
  - First field = TaskId (also used for the generated script name)
  - Remaining fields = Triggers

General form:
```
<TaskId> <Trigger1> [<Trigger2> ... <TriggerN>]
```

TaskId
- A file/task-safe identifier (no invalid filename characters).
- Typical pattern you use: `NN_label_bitrateStream_duration`, e.g. `00_adHoc_128cro3_30`.
- The template script is copied to `scheVLC\<TaskId>.ps1`.

Triggers
- Triggers are written as a keyword (schedule type), followed by an underscore, followed by a time or date+time.
- Multiple triggers on the same line are all attached to the same task.
- Supported forms observed in your lists:
  1) One-time (absolute date and time)
     - `OneTime_YYYY-MM-DD;HH:MM` or `OneTime_YYYY-MM-DD;HH:MM:SS`
     - Example: `OneTime_2024-12-25;18:33`
  2) Daily at a specific time
     - `Daily_HH:MM` or `Daily_HH:MM:SS`
     - Example: `Daily_19:00`
  3) Specific days of week at a specific time
     - `<DayList>_HH:MM` or `_HH:MM:SS`
     - DayList is comma-separated full day names: Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday
     - Example: `Monday,Tuesday,Wednesday,Thursday,Friday_06:01:00`
       or `Saturday_09:00`

Formatting rules
- Date format: `YYYY-MM-DD`
- Time format: 24-hour `HH:MM` or `HH:MM:SS`
- Day names: full English names (case-insensitive), separated by commas with no spaces.
- Separate triggers by a single space.
- The local system’s time zone is used.

Examples from your lists
```
00_adHoc_128cro3_30 OneTime_2024-12-15;10:00
00_adHoc_128cro3_45 OneTime_2024-12-15;10:00
00_adHoc_128cro3_60 OneTime_2024-12-15;10:00

01_sobota_128cro3_61 Saturday_08:00 Saturday_09:00 Saturday_10:00

21_mozaika_128cro3_119 Monday,Tuesday,Wednesday,Thursday,Friday_06:01:00 Monday,Tuesday,Wednesday,Thursday,Friday_08:01

02_jazz_256cro3_31 Daily_11:00 Daily_18:00
```

Behavior
- Each line = one scheduled task named exactly as `<TaskId>`.
- All triggers on the line are merged into that one task.
- The task’s action runs the generated script `scheVLC\<TaskId>.ps1` (copied from the template).

Validation tips
- Ensure `OneTime_` dates are in the future (past dates won’t fire).
- Use colons for time, semicolon only between date and time in `OneTime_`.
- Avoid trailing commas in the day list.
- Keep TaskId unique within `\radioVLCp\`.

## Credentials and security

- The script registers tasks under a user account. Use backslash format:
  - Local account: `.\Jan` or `COMPUTERNAME\Jan`
  - Domain account: `DOMAIN\Jan`
- If you see “No mapping between account names and security IDs was done (0x80070534)”, the user name is not resolving:
```powershell
# Test the account resolves to a SID
([System.Security.Principal.NTAccount]"$env:COMPUTERNAME\Jan").Translate([System.Security.Principal.SecurityIdentifier])

# For a local account you can use:
$User = ".\Jan"
```
- You’ll be prompted for the password; it’s used only to register the task.
- Alternative: run as SYSTEM (no password) — requires adjusting the script to use a SYSTEM principal; note profile/network drive differences.

## VS Code and PowerShell note

If you see a warning about “PowerShell (x64) not found” and it falls back to Windows PowerShell 5.1, either:
- Install PowerShell 7: `winget install Microsoft.PowerShell`, then select it via “PowerShell: Show Session Menu”, or
- Set the default to “Windows PowerShell (x64)” in VS Code settings.

This project works with both 5.1 and 7+.

## Troubleshooting

- Script execution is disabled
  - Use one of:
    - Session only: `Set-ExecutionPolicy -Scope Process Bypass`
    - Per-user: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force`
    - One-shot: `powershell -NoProfile -ExecutionPolicy Bypass -File .\createSchedTask_08.ps1`
- Not elevated
  - Run VS Code as Administrator or let the script relaunch elevated.
- Username/SID mapping (0x80070534)
  - Use `.\Jan` or `COMPUTERNAME\Jan`, verify with the SID test above.
- Verify tasks created
  - `Get-ScheduledTask -TaskPath '\radioVLCp\'` and inspect triggers/actions.

## Optional tweaks

- If your list file is named differently, you can rename it to `list_06.txt`, or update the script to read `list_06_baseList.txt`.
- If you prefer to parameterize the list path, consider adding a `-ListPath` parameter in the script and default it to `.\list_06.txt`.

---
Maintainer: GitHub Copilot
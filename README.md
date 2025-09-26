# Nathanael's Opulent Powershell
This is a set of powershell functions, aliases, and commands for working on Newforma Project Center that I've developed during my time at Newforma.
Some examples of what it can do:
 - `x`: Runs `Kill-ClientApps` and `Stop-NewformaServices` in succession, much faster to type.
 - `s`: Runs `Start-NewformaServices`
 - `rs`: Runs `Kill-ClientApps`, `Stop-NewformaServices`, then `Start-NewformaServices`, restart all Newforma services with two characters
 - `pipes`: Lists all open named pipes, handy for debugging tray tools
 - `lo`: Deletes the NPC NK Logon token, allowing you to login as a different NK user for migration testing.
 - `bc`: Quickly build just the CPP projects.
 - `ba`: Quickly build just the All solution.
 - `bca`: Quickly build the CPP projects, then the All solution.
 - `in4`: Shortcut to Invoke-N4
 - `npc`: Shortcut to Invoke-NPC
 - `nix`: Open NIX in your default browser
 - `fb [branch]`: Searches for a branch on github
 - `sb [branch]`: Searches for a branch on github, then switches to it automatically and rebuilds NPC for you.
 - `dash`: Opens the dashboard for your current sprint on Jira.
 - `whoru [cmd]`: Tells you about a given PowerShell command.
 - `ep`: Opens your PowerShell profile in a text editor.
 - `mywork`: Shows open Jira issues assigned to you.
 - `todo {sprint #}`: Shows open Jira issues in your backlog, optionally filtered to a specific sprint number.
 - `grab [jira #]`: Assigns the given Jira issue to you and sets it to In Progress. *Note*: Jira numbers should not include the "NPC-" prefix.
 - `about [jira #]`:  Shows info about the given Jira issue in your console.  *Note*: Jira numbers should not include the "NPC-" prefix.
 - `showme [jira #]`: Opens the given Jira issue in your browser.  *Note*: Jira numbers should not include the "NPC-" prefix.
 - `backlog`: Opens your Jira backlog in your browser.

# Installation
Copy `Microsoft.Powershell_profile.ps1` to `Documents\WindowsPowerShell` on your system. Overwrite the current version - this one contains all of the same functionality, and more.
Run `Install-ACLI` if you don't already have Atlassian CLI.
Run `Install-Git` if you somehow don't already have Git CLI.
Run `Edit-Profile` and change the following:
 - Line 5: Change the path to the official Newforma Services PS1 to point to your repos directory, wherever you've put it.
 - Lines 256-260: Change "Eagle" to your scrum team.
 - Lines 264-290: If you don't work on NPC, change the "NPC-" prefix to match your Jira prefix.
 - Line 293: Change the url to your own scrum team's board.
 - Line 297: Change the url to your own scrum team's backlog.

# Roadmap
## Now
NOP is a cool set of utilities to help on working on NPC.

## Soon
Implement NHelp command, and automate the profile edits step of the installation process.

## Later
Implement more helper functions for working with Jira and GitHub.

## Even Later
Self-awareness, world domination.

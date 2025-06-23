# svn-unlocker

Remove forgotten SVN locks in one go — ideal when Unreal Engine or other binary assets get stuck in a “Locked by current user” state.

## Features

| Mode | What it does | Typical use-case |
|------|--------------|------------------|
| **Full Scan** | Checks every version-controlled file in the working copy | Generic SVN projects |
| **UE Optimised** | Only scans `.uasset`, `.umap`, `.utexture`, `.uplugin` | Large Unreal Engine projects; 10-100× faster |

* Prompts for working-copy path, SVN username, and desired mode  
* Shows progress and lists each locked file found  
* Confirms before breaking locks (`svn unlock --force`)  
* Pure PowerShell — no external modules

## Quick Start

```powershell
git clone https://github.com/<you>/svn-lock-sweeper.git
cd svn-lock-sweeper
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass   # if needed
.\unlock-locks.ps1

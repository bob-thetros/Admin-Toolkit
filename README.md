 Admin Closed Environment PowerShell Toolkit
A small collection of PowerShell scripts designed to help administrators manage network‑level access in a closed environment (typically isolated from the Internet).

The toolset installs applications, creates a checklist in the environment and generate reports useful to identifying changes on closed system – all of them are stored under C:\scripts\(Company Name) and secured with a self-signed certificate.

Disclaimer: The scripts deliberately interact with system‑critical components (gateway, firewall, etc.). Use at your own risk and only in environments where you have proper approvals.

📖 Overview
Feature	Description

Network reporting	Generates output in the c:\scripts\reports sub folder.changes 
Self‑signed signing	Sign any script with a trusted self‑signed certificate (generateselfsigned.ps1)
Admin vs. User execution	Most scripts require elevated privileges; reporting scripts can run as normal users
All scripts are tagged to be executed as Administrator when required.

If you run a script that requires admin rights and it fails, check the console output for the exact permission error.

📂 Repository Structure
Admin-Toolkit/
│
├─ README.md               ← This file (you're reading!)
├─ generate-selfsigned.ps1    # Creates / updates a self‑signed cert & signs scripts
├─ Installer.bat              # Loads the scripts from an A: mapped drive or USB storage drive.  
├─ Installer2ExternalUSB.bat  # Clones this to an external USB location.
├─ Company.txt                # Company Name to sub-folder location.
└─ Apps/					  # Used for localized installations for when Internet is not available
└─ reg/						  # Registry keys - Some useful things to be tweaked by editing for your environment.
└─ Fonts/					  # Additional fonts to be installed.  Barcode https://fonts.google.com/specimen/Libre+Barcode+128/license?preview.script=Latn General free non-bundled by MS.
└─ wallpaper/                 # Setting your wallpaper to something company specific.
└─ lgpo/                      # Since the environment is not AD connected, this is a backup, restore, and display of current applied policies.
└─ scripts/
   └─ (Company Name)       # <‑‑ where all script files are stored, e.g. C:\scripts(MyCo)
🛠️ Installation
Download the latest zip from the GitHub releases page or clone the repo:
git clone https://github.com/bob-thetros/Admin-Toolkit.git
# Then share from a network drive map a:\(Pre-Install)

🚀 Running the Scripts
All scripts are tagged for admin execution unless designed as a report.

If you get Access is denied, run them with:

runas /user:Administrator "C:\Scripts\<Company Name>\Menu.ps1"
They are each given descriptions read into the menu script.  So if you add to my scripts try to use the header format so the description loads when running the menu.

Only scripts signed with the generateselfsigned.ps1 certificate can be executed safely.


🔄 Contributing
If you want to add a new tool or improve an existing one contact me.  I could open write access for some significant contributors.

📄 License
This project is licensed under the MIT License – see the LICENSE file for details.

The apps folder will download installers with winget.  Since server environments don't work well with winget you may want to build the apps folder elsewhere first.  If there is a physical D drive these will be placed on the D drive and C as a fallback.

I have all of the scripts currently in a private repo and will be cleaning up a bit as I push them up here.

🙏 Thanks!
I appreciate your interest in this closed‑environment automation suite. Feel free to report bugs, suggest enhancements, or star the repo if you find it useful!

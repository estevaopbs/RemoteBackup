# RemoteBackup

RemoteBackup is a PowerShell script designed to automate the backup of files on remote Linux systems to a Windows computer using SSH. This tool leverages the `Posh-SSH` module to establish SSH connections and facilitate seamless backup operations. The script takes the path to a configuration `.ini` file as an argument, which contains the necessary parameters for configuring the backups.

## Table of Contents

- [RemoteBackup](#remotebackup)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Usage](#usage)
  - [Registry Storage](#registry-storage)
  - [Scheduling with Windows Task Scheduler](#scheduling-with-windows-task-scheduler)
  - [Contributing](#contributing)
  - [License](#license)

## Features

- Automated backup of remote files from Linux systems to a Windows machine.
- Supports SSH authentication using private keys or passwords.
- Configurable backup intervals, start times, end times, and the number of backups to keep.
- Stores backup history in the Windows registry.

## Requirements

- Windows operating system.
- PowerShell (5.1 or newer).
- `Posh-SSH` module installed. You can install it using the following command:
```powershell
Install-Module Posh-SSH
```

## Installation

1. Clone this GitHub repository to your local machine or download the source code as a ZIP file and extract it.
2. Open a PowerShell terminal and navigate to the directory where you cloned or extracted the project.
3. Ensure that the Posh-SSH module is installed (see Requirements).

## Configuration

Create a `.ini` file to define the backup settings for each remote system. The example provided in the project's root directory (`settings.ini`) illustrates the required format.

For each remote system, create a section in the `.ini` file with the following parameters:

- `user*`: Remote user to authenticate with.
- `host*`: Remote host address.
- `auth*`: Authentication method (privatekey or password).
- `privatekey`: Path to the private key file (required for private key authentication).
- `password`: Remote user password (required for password authentication).
- `port`: Remote SSH port (default is 22).
- `remote*`: List of directories and files to backup, separated by a comma `,` character.
- `local*`: Path to the local directory where backups will be stored.
- `interval*`: Backup interval, formatted as a valid PowerShell `TimeSpan` (D.HH.mm.SS).
- `start`: Date and time to start the backup (YYYY-MM-DD HH:mm:SS) in UTC time.
- `end`: Date and time to end the backup (YYYY-MM-DD HH:mm:SS) in UTC time.
- `keep`: Number of backups to retain (default is 2,147,483,647).

The asterisk `*` character marks the mandatory parameters.

## Usage

Execute the `RemoteBackup.ps1` script using PowerShell, providing the path to your configuration `.ini` file as an argument. For example:

```powershell
.\RemoteBackup.ps1 -SettingsPath "path/to/your/settings.ini"
```
The script will iterate over each section in the `.ini` file and perform the corresponding backups based on the provided settings.

## Registry Storage

RemoteBackup stores information about the latest backup dates in the Windows registry. This information helps manage the backup intervals and retention. You can find the stored data in the Windows Registry Editor under the following key:

```
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\RemoteBackup\
```
## Scheduling with Windows Task Scheduler

To automate backups at specific intervals, you can use Windows Task Scheduler. Create a new task and set the "Action" to run a program:

- Program/script: `powershell.exe`
- Add arguments: `-ExecutionPolicy Bypass -File "path/to/RemoteBackup.ps1" -SettingsPath "path/to/your/settings.ini"`

Configure the task's triggers to specify when and how often the script should run.

## Contributing

Contributions to this project are welcome. Feel free to submit issues, suggestions, or pull requests.

## License

This project is licensed under the MIT License.
<img src="assets/logo.png" alt="WinSpace" width="300">
A Linux-based utility for creating bootable Windows USB drives. Built with Flutter, WinSpace provides an intuitive graphical interface for Linux users who need to create Windows installation media quickly and easily.

## Features

- 🎯 **Easy-to-Use GUI**: Step-by-step wizard interface that guides you through the entire process
- 📥 **Download Windows ISOs**: Download Windows 11 or Windows 10 ISO files directly from Microsoft servers
- 📁 **Select Existing ISOs**: Use your own Windows ISO files if you already have them
- 🔌 **Automatic USB Detection**: Automatically detects and lists available USB drives
- ⚡ **Fast & Reliable**: Uses efficient Linux tools (`parted`, `mkfs.vfat`, `rsync`) for USB creation
- 📊 **Real-time Progress**: View detailed progress and terminal output during USB creation
- 🛡️ **Safe Operations**: Clear warnings and consent requirements before erasing USB drives
- 🎨 **Modern UI**: Clean, modern interface built with Flutter Material Design

## Supported Windows Versions

- **Windows 11 25H2** (Latest)
- **Windows 10 Version 22H2**

## Requirements

### System Requirements

- **Operating System**: Linux (tested on Ubuntu/Debian-based distributions)
- **Flutter SDK**: 3.10.0 or higher
- **Disk Space**: At least 8 GB free space for ISO downloads and USB creation
- **USB Drive**: Minimum 8 GB capacity (16 GB or larger recommended)

### System Dependencies

The following Linux packages are required for USB creation:

- `parted` - Partition management
- `mkfs.vfat` - FAT32 filesystem creation (usually in `dosfstools` package)
- `rsync` - File synchronization
- `pkexec` or `sudo` - For elevated privileges

Install dependencies on Ubuntu/Debian:
```bash
sudo apt update
sudo apt install -y parted dosfstools rsync policykit-1
```

For development, you'll also need:
```bash
sudo apt install -y ninja-build clang libgtk-3-dev mesa-utils build-essential cmake pkg-config
```

Or use the provided setup script:
```bash
chmod +x setup_linux_deps.sh
./setup_linux_deps.sh
```

## Installation

### From Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/DarkVertana/WinSpace.git
   cd WinSpace
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run -d linux
   ```

### Building for Linux

1. **Build the application**:
   ```bash
   flutter build linux
   ```

2. **Run the built application**:
   ```bash
   ./build/linux/x64/release/bundle/winspaces
   ```

## Usage

### Step 1: Launch WinSpace
Start the application and you'll see the welcome screen.

### Step 2: Choose ISO Source
- **Select ISO file**: Choose an existing Windows ISO file from your computer
- **Download ISO file**: Download Windows 11 or Windows 10 directly from Microsoft servers

### Step 3: Select Windows Version (if downloading)
If you chose to download, select your preferred Windows version:
- Windows 11 25H2
- Windows 10 Version 22H2

Each version shows release date and system requirements.

### Step 4: Select USB Drive
- Connect your USB drive
- Click "Refresh" if your drive isn't detected
- Select the USB drive you want to use

⚠️ **Warning**: All data on the selected USB drive will be permanently erased!

### Step 5: Confirm and Create
- Review the warning about data erasure
- Check the consent checkbox
- Click "Next" to begin USB creation

### Step 6: Monitor Progress
- Watch the real-time progress bar
- View terminal output for detailed status
- Wait for completion (this may take several minutes)

### Step 7: Complete!
Your bootable Windows USB drive is ready to use!

## How It Works

WinSpace uses standard Linux tools to create bootable USB drives:

1. **Unmounts** the USB device
2. **Creates** a new partition table (MSDOS)
3. **Formats** the USB drive as FAT32
4. **Mounts** the ISO and USB drive
5. **Copies** all Windows installation files using `rsync`
6. **Marks** the partition as bootable
7. **Unmounts** both drives

The process requires elevated privileges (via `pkexec` or `sudo`) to perform disk operations. You'll be prompted for your password once at the beginning of the USB creation process.

## Technical Details

- **Framework**: Flutter 3.10.0+
- **Language**: Dart
- **Platform**: Linux (primary), with support for other platforms
- **Key Dependencies**:
  - `url_launcher`: For opening external links
  - `http`: For downloading Windows ISOs
  - `path_provider`: For file system access
  - `file_picker`: For selecting ISO files

## Troubleshooting

### USB Device Not Detected
- Ensure the USB drive is properly connected
- Try clicking the "Refresh" button
- Check if the device appears in `lsblk` command
- Make sure the device is not mounted elsewhere

### Permission Denied Errors
- Ensure `pkexec` or `sudo` is installed
- Check that your user has permission to use `pkexec`
- Look for password dialog windows (may be behind the main window)

### Download Fails
- Check your internet connection
- Verify you have enough disk space
- Try downloading again (Microsoft servers may be temporarily unavailable)

### USB Creation Fails
- Ensure the USB drive is at least 8 GB
- Check that the ISO file is not corrupted
- Verify all required system tools are installed (`parted`, `mkfs.vfat`, `rsync`)
- Check terminal output for specific error messages

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you find WinSpace useful, consider supporting the project:

- ☕ [Buy Me a Coffee](https://buymeacoffee.com/pratikmore)

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Uses standard Linux tools for USB creation
- Windows ISO downloads from official Microsoft servers

## Disclaimer

WinSpace is an independent project and is not affiliated with Microsoft Corporation. Windows is a trademark of Microsoft Corporation. Use this tool at your own risk. Always backup important data before creating bootable USB drives.

---

**Made with ❤️ for Linux users**

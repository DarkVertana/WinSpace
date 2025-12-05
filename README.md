# WinSpace

**Professional Windows USB Bootable Media Creator for Linux**

WinSpace is a production-ready Flutter application that enables Linux users to create UEFI-compatible bootable Windows installation media with enterprise-grade reliability and security.

---

## Overview

WinSpace automates the entire process of creating bootable Windows USB drives on Linux systems. It handles ISO downloads, device detection, partition management, filesystem creation, and file synchronization with comprehensive error handling and real-time progress monitoring.

### Key Capabilities

- **Direct ISO Downloads**: Downloads Windows 11/10 ISOs directly from Microsoft's official distribution servers
- **UEFI Boot Support**: Creates GPT partition tables with Microsoft Basic Data partitions for maximum compatibility
- **Large File Handling**: Automatically splits `install.wim` files exceeding 4GB for FAT32 compatibility using `wimlib-imagex`
- **Device Recovery**: Detects and repairs corrupted USB drives before flashing
- **Real-time Monitoring**: Live terminal output with technical log messages for debugging and verification
- **Security**: Uses `pkexec` for privilege escalation with proper sandboxing considerations

---

## Technical Architecture

### Partitioning Strategy

WinSpace implements a UEFI-compatible partitioning scheme optimized for Windows installation media:

- **Partition Table**: GPT (GUID Partition Table) for UEFI compatibility
- **Partition Type**: Microsoft Basic Data (type 0700) - ensures visibility in Windows Setup
- **Filesystem**: FAT32 with 4096-byte cluster size for optimal compatibility
- **Boot Method**: UEFI firmware automatically detects `/EFI/Boot/bootx64.efi`

### File Handling

- **WIM Splitting**: Automatically detects `install.wim` files >4GB and splits into `.swm` chunks (3800MB each)
- **File Synchronization**: Uses `rsync` with `--no-owner --no-group` flags to prevent permission errors on FAT32
- **Progress Tracking**: Real-time file transfer progress with percentage completion

### Device Management

- **Corruption Detection**: Validates device accessibility using `blockdev --getsz`
- **Automatic Repair**: Uses `wipefs` and low-level `dd` operations to repair corrupted partition tables
- **Mount Management**: Implements lazy unmount (`umount -l`) to prevent blocking operations

---

## System Requirements

### Runtime Dependencies

| Package | Purpose | Installation |
|---------|---------|--------------|
| `parted` | Partition table management | `sudo apt install parted` |
| `dosfstools` | FAT32 filesystem creation | `sudo apt install dosfstools` |
| `rsync` | Efficient file synchronization | `sudo apt install rsync` |
| `wimtools` | WIM archive splitting | `sudo apt install wimtools` |
| `gdisk` | Advanced GPT partitioning (optional) | `sudo apt install gdisk` |
| `policykit-1` | Privilege escalation | `sudo apt install policykit-1` |

### Hardware Requirements

- **USB Drive**: Minimum 8GB capacity (16GB+ recommended for Windows 11)
- **Disk Space**: 8-10GB free space for ISO downloads and temporary files
- **Network**: Stable internet connection for ISO downloads (7-8GB files)

### Development Dependencies

```bash
sudo apt install -y ninja-build clang libgtk-3-dev mesa-utils \
  build-essential cmake pkg-config
```

---

## Installation

### Debian Package (Recommended)

```bash
# Download the latest .deb package from Releases
sudo dpkg -i winspaces_*.deb
sudo apt-get install -f  # Fix dependencies if needed
```

### From Source

```bash
git clone https://github.com/DarkVertana/WinSpace.git
cd WinSpace
flutter pub get
flutter build linux --release
./build/linux/x64/release/bundle/winspaces
```

---

## Usage Workflow

### 1. ISO Selection

**Option A: Download from Microsoft**
- Select "Download ISO file with app"
- Choose Windows version (11 25H2 or 10 22H2)
- Application downloads directly from Microsoft servers with progress tracking

**Option B: Use Existing ISO**
- Select "Select ISO file"
- Browse and select your Windows ISO file
- Application validates file size (minimum 3GB)

### 2. USB Device Selection

- Application automatically detects removable USB devices using `lsblk`
- Displays device model, size, and mount status
- Click "Refresh" to rescan for newly connected devices

### 3. USB Creation Process

The application performs the following operations (requires root privileges):

1. **Device Validation**: Checks device accessibility and detects corruption
2. **Partition Table Wipe**: Removes existing partition signatures
3. **GPT Initialization**: Creates new GPT partition table
4. **Partition Creation**: Creates Microsoft Basic Data partition (type 0700)
5. **Filesystem Formatting**: Formats partition as FAT32
6. **ISO Mounting**: Mounts Windows ISO as read-only loop device
7. **File Analysis**: Checks `install.wim` size for splitting requirements
8. **File Synchronization**: Copies all files using `rsync` (excludes `install.wim` if splitting needed)
9. **WIM Splitting**: Splits large `install.wim` into `.swm` chunks if >4GB
10. **EFI Configuration**: Ensures `bootx64.efi` is in `/EFI/Boot/` directory
11. **Verification**: Validates boot files and Windows sources directory
12. **Unmounting**: Safely unmounts all filesystems

### 4. Progress Monitoring

- Real-time progress bar with percentage completion
- Terminal output toggle for detailed technical logs
- Status messages for each operation phase
- Error reporting with specific failure points

---

## Technical Implementation Details

### Privilege Escalation

WinSpace uses `pkexec` (preferred) or `sudo` for privilege escalation:
- Single password prompt at process start
- All disk operations executed in single elevated session
- Process isolation for security

### Error Handling

- **Device Errors**: Automatic corruption detection and repair attempts
- **Network Errors**: HTTP status code validation and retry logic
- **File Errors**: WIM splitting fallback with automatic `wimtools` installation
- **Mount Errors**: Lazy unmount fallback to prevent blocking

### Logging System

Technical log messages use standardized prefixes:
- `[INFO]` - Informational messages
- `[WARN]` - Warning conditions
- `[ERROR]` - Error conditions
- `[OK]` - Successful operations

### Performance Optimizations

- **Reduced setState Calls**: Only updates UI when values actually change
- **Efficient List Operations**: Uses `removeRange()` for terminal output management
- **Stream Management**: Proper cleanup of subscriptions and timers
- **Memory Management**: Limits terminal output to last 100 lines

---

## Troubleshooting

### Device Not Detected

```bash
# Verify device is visible to system
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL

# Check if device is marked as removable
cat /sys/block/sdX/removable  # Should output "1"
```

### Permission Errors

- Ensure `pkexec` is installed: `sudo apt install policykit-1`
- Check PolicyKit configuration: `/etc/polkit-1/rules.d/`
- Verify user is in appropriate groups

### Corrupted Drive

WinSpace automatically attempts repair, but manual intervention may be required:

```bash
# Wipe all filesystem signatures
sudo wipefs -a /dev/sdX

# Clear partition table
sudo dd if=/dev/zero of=/dev/sdX bs=1M count=10

# Re-run WinSpace
```

### WIM Splitting Fails

```bash
# Install wimtools manually
sudo apt update
sudo apt install wimtools

# Verify installation
wimlib-imagex --version
```

### Download Failures

- Verify network connectivity
- Check available disk space: `df -h`
- Validate ISO URL accessibility
- Review terminal output for HTTP error codes

---

## Security Considerations

- **No Web Browser**: Eliminates attack surface from headless browsers
- **TLS Enforcement**: Forces TLS 1.2+ for all network operations
- **Input Validation**: All user inputs validated before processing
- **Process Isolation**: Elevated operations isolated to single script execution
- **Sandboxing**: Compatible with `bwrap` for additional isolation

---

## Development

### Building Release Package

```bash
flutter build linux --release
./build_deb.sh  # Creates .deb package
```

### Code Structure

- `lib/main.dart`: Main application logic and UI
- `linux/`: Linux-specific CMake configuration
- `assets/`: Application icons and resources

### Key Technologies

- **Flutter 3.10.0+**: Cross-platform UI framework
- **Dart 3.10.3+**: Programming language
- **GTK 3**: Linux desktop integration
- **CMake**: Native build system

---

## License

MIT License - See [LICENSE](LICENSE) file for details.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/DarkVertana/WinSpace/issues)
- **Contributions**: Pull requests welcome
- **Donations**: [Buy Me a Coffee](https://buymeacoffee.com/pratikmore)

---

## Disclaimer

WinSpace is an independent, open-source project and is not affiliated with Microsoft Corporation. Windows is a trademark of Microsoft Corporation. This tool is provided as-is without warranty. Always backup important data before creating bootable USB drives.

---

**Built with Flutter for Linux** | **Version 1.0.0**

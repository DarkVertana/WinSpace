import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:async';

void main() {
  runApp(const WinSpacesApp());
}

class WinSpacesApp extends StatelessWidget {
  const WinSpacesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WinSpace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WinSpacesMainWindow(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WinSpacesMainWindow extends StatefulWidget {
  const WinSpacesMainWindow({super.key});

  @override
  State<WinSpacesMainWindow> createState() => _WinSpacesMainWindowState();
}

class _WinSpacesMainWindowState extends State<WinSpacesMainWindow> {
  int _currentStep = 0; // 0: Welcome, 1: ISO Selection Method, 2: Windows Version (if download), 3: USB Selection, 4: Warning/Consent, 5: Progress, 6: Completion
  String? _isoSelectionMethod; // 'select' or 'download'
  String? _selectedISOPath;
  String? _selectedWindowsVersion;
  String? _selectedUSBDevice;
  bool _consentGiven = false;
  int _currentImageIndex = 0;
  double _progress = 0.0;
  final PageController _pageController = PageController();
  bool _isDownloading = false;
  bool _downloadComplete = false;
  String? _downloadedISOPath;
  String _downloadStatus = '';
  List<String> _availableUSBDevices = [];
  bool _isLoadingUSBDevices = false;
  bool _isCreatingUSB = false;
  String _usbCreationStatus = '';
  List<String> _terminalOutput = [];
  bool _showTerminal = false;
  
  final Map<String, Map<String, String>> _windowsVersions = {
    'Windows 11 25H2': {
      'releaseDate': 'October 2025',
      'requirements': '• Processor: 1 GHz or faster with 2 or more cores\n• RAM: 4 GB (64-bit)\n• Storage: 64 GB or larger\n• System firmware: UEFI, Secure Boot capable\n• TPM: Version 2.0\n• Graphics card: DirectX 12 compatible',
      'isoUrl': 'https://software.download.prss.microsoft.com/dbazure/Win11_25H2_EnglishInternational_x64.iso?t=5cb0d9a4-b2ee-46fe-8931-9cb67a97c9a1&P1=1764400342&P2=601&P3=2&P4=o%2b2WN8Cbm9X9qtZNFAMbWRZUbvrJ1gDWkVPgSmkdf4Y2ym8Rs2ZOdukCk4ct9uaTyh3ApfPhQUqoDpylm07urMHOrwkpVJLHvl%2bGgbmYALqA%2fY1rllRxm1hDHsjTh690KYtKcW8piCxCOKUD%2bze0Vs4%2fpLQFeaxWlf3wuaF36YaOlvRiR3%2fTBsRanY1BpGnuOW2%2bbqVtTvHdLjoutKqTaZ16gMoEHZKG0l6SN3fCwckIpqGdPExybVp20eGp0e0F%2fCpZCCHBkC8UlJ56U%2fOd%2bKAe7V6dCTSa8DGjbyb94mfDX1idwjOAd83dCR57Nbk8OQjvi1sLq9QLbSF8fvgNcA%3d%3d',
    },
    'Windows 10 Version 22H2': {
      'releaseDate': 'October 2022',
      'requirements': '• Processor: 1 GHz or faster\n• RAM: 1 GB (32-bit) or 2 GB (64-bit)\n• Storage: 16 GB (32-bit) or 20 GB (64-bit)\n• Graphics card: DirectX 9 or later',
      'isoUrl': 'https://software.download.prss.microsoft.com/dbazure/Win10_22H2_EnglishInternational_x64v1.iso?t=a8bcd97c-f61b-4fb8-8013-ec5ec878f630&P1=1764958805&P2=601&P3=2&P4=0%2fWwW4SOvfVoyYYncJcYjT6%2bOvTiKn%2bDRQYyJPf%2bz%2f4eBOSu6N5OKCmMCn8rTeMzpvvh5ccSfTFeO5zXHDOtm%2fQK3%2ffPJxmDMdlpw3Qh35f7DKaQfj%2fSvQ1R0z7wrIJNZo4YmmLfkBD7PtG3T2xcMSAgE%2fqk5aISa8FwCa0BkFksupjpSQm%2bqE3WfSz57fwkQqAmuZbIas7ids1qkQ6W2v5sZeCGCymsSs78Lwgbt0XviDCiorU4BZiH%2f%2fQdWLjlY1ggefTXKG8SG0B2TQd4kjNETENp9P79rZJbvjnFprE5%2bzLzSLdydv%2fTNZ7NhkvQ0ZGWpHrRFmDfNk%2fGavSFfw%3d%3d',
    },
  };

  void _handleNext() {
    if (_currentStep == 0) {
      // Welcome step - always can proceed
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      // ISO selection method step
      if (_isoSelectionMethod == 'select') {
        // If selecting ISO, need ISO file selected, then skip to step 3 (USB selection)
        if (_selectedISOPath != null) {
          setState(() {
            _currentStep = 3; // Skip step 2 (Windows version), go to USB selection
            _detectUSBDevices(); // Detect USB devices when entering USB selection step
          });
        }
      } else if (_isoSelectionMethod == 'download') {
        // If downloading, go to step 2 (Windows version selection)
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      // Windows version selection step - go to step 3 (USB selection)
      if (_selectedWindowsVersion != null) {
        setState(() {
          _currentStep = 3;
          _detectUSBDevices(); // Detect USB devices when entering USB selection step
        });
      }
    } else if (_currentStep == 3) {
      // USB selection step - go to warning/consent step
      if (_selectedUSBDevice != null) {
        setState(() => _currentStep = 4);
      }
    } else if (_currentStep == 4) {
      // Warning/Consent step - go to progress step
      if (_consentGiven) {
        setState(() {
          _currentStep = 5;
          _startProgress();
        });
      }
    } else if (_currentStep == 5) {
      // Progress step - finish (or show completion)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Windows USB installer created successfully!'),
        ),
      );
    }
  }

  void _startProgress() {
    // If user selected download method, start downloading ISO first
    if (_isoSelectionMethod == 'download' && _selectedWindowsVersion != null) {
      _downloadISO();
    } else {
      // If user selected ISO manually, skip download and go to USB creation
      _startUSBProcess();
    }
  }

  Future<void> _downloadISO() async {
    if (_selectedWindowsVersion == null) return;
    
    final versionInfo = _windowsVersions[_selectedWindowsVersion];
    final isoUrl = versionInfo?['isoUrl'];
    
    if (isoUrl == null) {
      setState(() {
        _downloadStatus = 'Error: ISO URL not found';
        _terminalOutput.add('✗ Error: ISO URL not found for $_selectedWindowsVersion');
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadComplete = false;
      _downloadStatus = 'Downloading ISO file...';
      _progress = 0.0;
      _showTerminal = true;
      _terminalOutput = ['Starting Windows ISO download...'];
      _terminalOutput.add('Version: $_selectedWindowsVersion');
    });

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(isoUrl));
      
      _addTerminalOutput('Connecting to Microsoft servers...');
      
      final response = await client.send(request);
      
      if (response.statusCode != 200) {
        _addTerminalOutput('✗ Error: Server returned status code ${response.statusCode}');
        setState(() {
          _isDownloading = false;
          _downloadStatus = 'Download failed: HTTP ${response.statusCode}';
        });
        client.close();
        return;
      }
      
      // Get download directory
      final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final fileName = _selectedWindowsVersion!.replaceAll(' ', '_').replaceAll('Version', '') + '.iso';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      // Track download progress
      final contentLength = response.contentLength ?? 0;
      final contentLengthMB = (contentLength / (1024 * 1024)).toStringAsFixed(0);
      
      _addTerminalOutput('Connected! Starting download...');
      _addTerminalOutput('File size: $contentLengthMB MB');
      _addTerminalOutput('Saving to: $filePath');
      _addTerminalOutput('');
      
      final sink = file.openWrite();
      int downloaded = 0;
      int lastLoggedPercent = -1;

      response.stream.listen(
        (List<int> chunk) {
          downloaded += chunk.length;
          sink.add(chunk);
          
          if (contentLength > 0 && mounted) {
            final percent = (downloaded / contentLength * 100).toInt();
            final downloadedMB = (downloaded / (1024 * 1024)).toStringAsFixed(0);
            
            setState(() {
              _progress = downloaded / contentLength;
              _downloadStatus = 'Downloading: $percent% ($downloadedMB MB / $contentLengthMB MB)';
            });
            
            // Log every 5% progress to terminal
            if (percent % 5 == 0 && percent != lastLoggedPercent) {
              lastLoggedPercent = percent;
              _addTerminalOutput('Download progress: $percent% ($downloadedMB MB / $contentLengthMB MB)');
            }
          }
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          client.close();
          
          if (mounted) {
            // Verify the downloaded file
            final downloadedFile = File(filePath);
            final fileExists = await downloadedFile.exists();
            final fileSize = fileExists ? await downloadedFile.length() : 0;
            
            _addTerminalOutput('');
            _addTerminalOutput('Download finished!');
            _addTerminalOutput('Verifying downloaded file...');
            _addTerminalOutput('File exists: $fileExists');
            _addTerminalOutput('File size: ${(fileSize / (1024 * 1024)).toStringAsFixed(0)} MB');
            
            // Check if file size is reasonable (at least 3GB for Windows ISO, typically 4-8GB)
            if (!fileExists || fileSize < 3 * 1024 * 1024 * 1024) {
              _addTerminalOutput('✗ Error: Downloaded file appears to be incomplete or corrupted');
              _addTerminalOutput('Expected 4-8 GB for Windows ISO, got ${(fileSize / (1024 * 1024)).toStringAsFixed(0)} MB');
              setState(() {
                _isDownloading = false;
                _downloadComplete = false;
                _downloadStatus = 'Download failed: File incomplete';
              });
              return;
            }
            
            _addTerminalOutput('✓ ISO file verified successfully!');
            _addTerminalOutput('');
            _addTerminalOutput('Starting USB creation process...');
            
            setState(() {
              _isDownloading = false;
              _downloadComplete = true;
              _downloadedISOPath = filePath;
              _downloadStatus = 'Download complete!';
              _progress = 1.0;
            });
            
            // Start USB process after download completes
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _startUSBProcess();
              }
            });
          }
        },
        onError: (error) {
          sink.close();
          client.close();
          if (mounted) {
            _addTerminalOutput('');
            _addTerminalOutput('✗ Download error: $error');
            setState(() {
              _isDownloading = false;
              _downloadStatus = 'Download failed: $error';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        _addTerminalOutput('✗ Download error: $e');
        setState(() {
          _isDownloading = false;
          _downloadStatus = 'Download error: $e';
        });
      }
    }
  }

  void _startUSBProcess() {
    // Start actual USB creation process
    _createBootableUSB();
  }

  Future<void> _createBootableUSB() async {
    if (_selectedUSBDevice == null) {
      setState(() {
        _usbCreationStatus = 'Error: No USB device selected';
      });
      return;
    }

    // Extract device path from selected device string (e.g., "/dev/sdb - Model (32 GB)" -> "/dev/sdb")
    final deviceMatch = RegExp(r'/dev/\w+').firstMatch(_selectedUSBDevice!);
    if (deviceMatch == null) {
      setState(() {
        _usbCreationStatus = 'Error: Invalid USB device format';
      });
      return;
    }
    final usbDevice = deviceMatch.group(0)!;

    // Get ISO path
    String? isoPath;
    if (_isoSelectionMethod == 'download' && _downloadedISOPath != null) {
      isoPath = _downloadedISOPath;
    } else if (_isoSelectionMethod == 'select' && _selectedISOPath != null) {
      isoPath = _selectedISOPath;
    }

    if (isoPath == null) {
      setState(() {
        _usbCreationStatus = 'Error: ISO file path not set';
        _terminalOutput.add('✗ Error: ISO file path not set');
      });
      return;
    }

    final isoFile = File(isoPath);
    if (!await isoFile.exists()) {
      setState(() {
        _usbCreationStatus = 'Error: ISO file not found at $isoPath';
        _terminalOutput.add('✗ Error: ISO file not found at $isoPath');
      });
      return;
    }

    // Verify ISO file size (should be at least 1GB for Windows)
    final isoSize = await isoFile.length();
    final isoSizeMB = (isoSize / (1024 * 1024)).toStringAsFixed(0);
    
    if (isoSize < 1024 * 1024 * 100) { // Less than 100MB is definitely wrong
      setState(() {
        _usbCreationStatus = 'Error: ISO file appears corrupted (only $isoSizeMB MB)';
        _terminalOutput.add('✗ Error: ISO file appears corrupted or incomplete');
        _terminalOutput.add('  File size: $isoSizeMB MB (expected 4-8 GB for Windows 10/11)');
      });
      return;
    }

    setState(() {
      _isCreatingUSB = true;
      _usbCreationStatus = 'Starting USB creation process...';
      _progress = 0.0;
      _showTerminal = true;
    });
    
    // Only reset terminal if not coming from download (to preserve download logs)
    if (_isoSelectionMethod != 'download') {
      setState(() {
        _terminalOutput = ['Starting Windows bootable USB creation process...'];
      });
    }
    
    _addTerminalOutput('');
    _addTerminalOutput('=== USB Creation Process ===');
    _addTerminalOutput('ISO file: $isoPath');
    _addTerminalOutput('ISO size: $isoSizeMB MB');
    _addTerminalOutput('USB device: $usbDevice');
    _addTerminalOutput('');
    _addTerminalOutput('Note: You will be prompted for your password ONCE to perform all disk operations.');

    // Create temp directories
    final tempDir = Directory.systemTemp.createTempSync('winspace_iso_');
    final usbMountDir = Directory.systemTemp.createTempSync('winspace_usb_');
    final scriptFile = File('${Directory.systemTemp.path}/winspace_usb_script_${DateTime.now().millisecondsSinceEpoch}.sh');

    try {
      // Create shell script with all commands for UEFI bootable USB
      // Uses Rufus-style partitioning for maximum compatibility
      // Handles large files (>4GB) by splitting install.wim for FAT32 compatibility
      // Use r'' for raw string to avoid interpolation issues, then replace variables
      final scriptContent = r'''#!/bin/bash
set -e

USB_DEVICE="USB_DEVICE_PLACEHOLDER"
ISO_PATH="ISO_PATH_PLACEHOLDER"
TEMP_DIR="TEMP_DIR_PLACEHOLDER"
USB_MOUNT_DIR="USB_MOUNT_DIR_PLACEHOLDER"

echo "Step 1: Unmounting USB device..."
umount "$USB_DEVICE"* 2>/dev/null || true
sleep 1

echo "Step 2: Wiping existing partition table..."
# Clear first and last 1MB to remove any existing partition signatures
dd if=/dev/zero of="$USB_DEVICE" bs=1M count=1 status=none 2>/dev/null || true
dd if=/dev/zero of="$USB_DEVICE" bs=1M seek=$(($(blockdev --getsz "$USB_DEVICE") / 2048 - 1)) count=1 status=none 2>/dev/null || true
sleep 0.5

echo "Step 2: Creating GPT partition table (Rufus-style for UEFI)..."
# Use sgdisk for precise GPT control (like Rufus does)
if command -v sgdisk &> /dev/null; then
    echo "Using sgdisk for GPT partitioning..."
    sgdisk --zap-all "$USB_DEVICE" 2>/dev/null || true
    # Create partition with type 0700 (Microsoft Basic Data) - NOT EFI System Partition
    # This is what Rufus uses - UEFI firmware will still find /EFI/Boot/bootx64.efi
    sgdisk -n 1:2048:0 -t 1:0700 -c 1:"WINSPACE" "$USB_DEVICE"
else
    echo "Using parted for GPT partitioning..."
    parted -s "$USB_DEVICE" mklabel gpt
    # Create partition starting at 1MiB for alignment
    parted -s "$USB_DEVICE" mkpart primary fat32 1MiB 100%
    parted -s "$USB_DEVICE" name 1 "WINSPACE"
    # DO NOT set esp flag - that hides the partition from Windows Setup!
    # Just set msftdata flag for Microsoft Basic Data type
    parted -s "$USB_DEVICE" set 1 msftdata on 2>/dev/null || true
fi
sleep 0.5

echo "Step 2: Probing partitions..."
partprobe "$USB_DEVICE"
sleep 2

# Detect partition name (handle both /dev/sdX1 and /dev/nvmeXn1p1 styles)
if [ -b "${USB_DEVICE}1" ]; then
    PARTITION="${USB_DEVICE}1"
elif [ -b "${USB_DEVICE}p1" ]; then
    PARTITION="${USB_DEVICE}p1"
else
    echo "ERROR: Could not find partition"
    exit 1
fi
echo "Partition detected: $PARTITION"

echo "Step 3: Formatting USB drive as FAT32 (large cluster for better compatibility)..."
# Use cluster size 4096 (default) which works well for most USB drives
# Label limited to 11 chars for FAT32
mkfs.fat -F 32 -n "WINSPACE" "$PARTITION"
sleep 1

echo "Step 4: Creating mount directories..."
mkdir -p "$TEMP_DIR"
mkdir -p "$USB_MOUNT_DIR"

echo "Step 4: Mounting ISO and USB drive..."
mount -o loop,ro "$ISO_PATH" "$TEMP_DIR"
mount "$PARTITION" "$USB_MOUNT_DIR"

echo "Step 5: Checking for large files (FAT32 has 4GB limit)..."

# Check if install.wim exists and is larger than 4GB (4294967296 bytes)
INSTALL_WIM=""
if [ -f "$TEMP_DIR/sources/install.wim" ]; then
    INSTALL_WIM="$TEMP_DIR/sources/install.wim"
elif [ -f "$TEMP_DIR/Sources/install.wim" ]; then
    INSTALL_WIM="$TEMP_DIR/Sources/install.wim"
fi

NEED_SPLIT=false
if [ -n "$INSTALL_WIM" ]; then
    WIM_SIZE=$(stat -c%s "$INSTALL_WIM" 2>/dev/null || echo "0")
    echo "Found install.wim: $((WIM_SIZE / 1024 / 1024)) MB"
    if [ "$WIM_SIZE" -gt 4294967296 ]; then
        echo "WARNING: install.wim is larger than 4GB ($((WIM_SIZE / 1024 / 1024)) MB)"
        echo "Will split into smaller files for FAT32 compatibility..."
        NEED_SPLIT=true
    fi
fi

echo "Step 6: Copying Windows files to USB drive..."
echo "This may take several minutes depending on ISO size..."

if [ "$NEED_SPLIT" = true ]; then
    # Copy all files EXCEPT install.wim (will handle separately)
    echo "Copying files (excluding large install.wim)..."
    rsync -r -v --progress --no-owner --no-group --exclude='install.wim' "$TEMP_DIR"/ "$USB_MOUNT_DIR"/
    
    echo "Step 6b: Splitting install.wim for FAT32 compatibility..."
    # Check if wimlib-imagex is available
    if command -v wimlib-imagex &> /dev/null; then
        echo "Using wimlib-imagex to split install.wim into 3800MB chunks..."
        mkdir -p "$USB_MOUNT_DIR/sources"
        wimlib-imagex split "$INSTALL_WIM" "$USB_MOUNT_DIR/sources/install.swm" 3800
        echo "Successfully split install.wim into .swm files"
    else
        echo "WARNING: wimlib-imagex not found. Attempting to install..."
        apt-get update && apt-get install -y wimtools 2>/dev/null || true
        
        if command -v wimlib-imagex &> /dev/null; then
            echo "Using wimlib-imagex to split install.wim..."
            mkdir -p "$USB_MOUNT_DIR/sources"
            wimlib-imagex split "$INSTALL_WIM" "$USB_MOUNT_DIR/sources/install.swm" 3800
            echo "Successfully split install.wim into .swm files"
        else
            echo "ERROR: Cannot split large file. Please install wimtools:"
            echo "  sudo apt install wimtools"
            echo "Then try again."
            exit 1
        fi
    fi
else
    # No large files, copy everything normally
    rsync -r -v --progress --no-owner --no-group "$TEMP_DIR"/ "$USB_MOUNT_DIR"/
fi

echo "Step 7: Ensuring EFI boot files are in correct location..."
# Create EFI Boot directory structure if not exists
mkdir -p "$USB_MOUNT_DIR/EFI/Boot"

# Copy bootx64.efi to the correct location (handles different case variations in ISO)
if [ -f "$USB_MOUNT_DIR/efi/boot/bootx64.efi" ]; then
    cp "$USB_MOUNT_DIR/efi/boot/bootx64.efi" "$USB_MOUNT_DIR/EFI/Boot/bootx64.efi" 2>/dev/null || true
elif [ -f "$USB_MOUNT_DIR/EFI/boot/bootx64.efi" ]; then
    cp "$USB_MOUNT_DIR/EFI/boot/bootx64.efi" "$USB_MOUNT_DIR/EFI/Boot/bootx64.efi" 2>/dev/null || true
elif [ -f "$TEMP_DIR/efi/boot/bootx64.efi" ]; then
    cp "$TEMP_DIR/efi/boot/bootx64.efi" "$USB_MOUNT_DIR/EFI/Boot/bootx64.efi"
elif [ -f "$TEMP_DIR/EFI/boot/bootx64.efi" ]; then
    cp "$TEMP_DIR/EFI/boot/bootx64.efi" "$USB_MOUNT_DIR/EFI/Boot/bootx64.efi"
fi

echo "Step 8: Verifying USB contents..."
echo "Checking for required boot files..."
if [ -f "$USB_MOUNT_DIR/EFI/Boot/bootx64.efi" ] || [ -f "$USB_MOUNT_DIR/efi/boot/bootx64.efi" ]; then
    echo "✓ EFI boot file found"
else
    echo "WARNING: EFI boot file not found - USB may not boot on UEFI systems"
fi
if [ -d "$USB_MOUNT_DIR/sources" ]; then
    echo "✓ Windows sources folder found"
fi

echo "Step 9: Syncing and unmounting drives..."
echo "Flushing all data to USB drive (this may take a moment)..."
sync
echo "Data sync complete."

# Function to unmount (non-blocking approach)
unmount_safe() {
    local mount_point=$1
    local name=$2
    
    echo "Unmounting $name..."
    
    # Try normal unmount first (non-blocking check)
    if umount "$mount_point" 2>/dev/null; then
        echo "$name unmounted successfully"
        return 0
    fi
    
    # If normal unmount failed, use lazy unmount (doesn't block)
    echo "Using lazy unmount for $name (non-blocking)..."
    umount -l "$mount_point" 2>/dev/null || true
    
    # Wait a moment for lazy unmount to process
    sleep 2
    
    # Check if still mounted
    if mountpoint -q "$mount_point" 2>/dev/null; then
        echo "Attempting force unmount for $name..."
        umount -f "$mount_point" 2>/dev/null || true
        sleep 1
        
        # Final check
        if mountpoint -q "$mount_point" 2>/dev/null; then
            echo "WARNING: $name may still be mounted at $mount_point"
            echo "This is usually safe - you can unmount manually later if needed"
            return 1
        else
            echo "✓ $name unmounted successfully (force)"
            return 0
        fi
    else
        echo "✓ $name unmounted successfully (lazy)"
        return 0
    fi
}

# Unmount ISO first
unmount_safe "$TEMP_DIR" "ISO"

# Check if anything is using the USB mount point (non-blocking, don't wait)
echo "Checking for processes accessing USB..."
lsof "$USB_MOUNT_DIR" 2>/dev/null | head -3 | grep -v COMMAND && echo "Note: Some processes may be accessing USB (this is usually fine)" || echo "No active processes found"

# Unmount USB drive
unmount_safe "$USB_MOUNT_DIR" "USB drive"

echo ""
echo "✓ UEFI bootable Windows USB created successfully!"
echo "You can safely remove the USB drive now."
'''
          .replaceAll('USB_DEVICE_PLACEHOLDER', usbDevice)
          .replaceAll('ISO_PATH_PLACEHOLDER', isoPath)
          .replaceAll('TEMP_DIR_PLACEHOLDER', tempDir.path)
          .replaceAll('USB_MOUNT_DIR_PLACEHOLDER', usbMountDir.path);

      await scriptFile.writeAsString(scriptContent);
      await Process.run('chmod', ['+x', scriptFile.path]);

      _addTerminalOutput('Created USB creation script');
      _addTerminalOutput('Requesting authentication (you will be prompted once)...');
      _addTerminalOutput('IMPORTANT: Look for a password dialog window - it may be behind this window!');
      _addTerminalOutput('Try Alt+Tab or check your taskbar for the password dialog.');

      // Get environment variables to ensure GUI dialogs work
      final env = Map<String, String>.from(Platform.environment);
      // Ensure DISPLAY is set for GUI dialogs
      if (!env.containsKey('DISPLAY') && Platform.isLinux) {
        env['DISPLAY'] = ':0';
      }

      // Run the entire script with elevated privileges using Process.start for real-time output
      Process process;
      try {
        // Try pkexec first (shows GUI password dialog)
        // Use --disable-internal-agent to ensure password prompt appears
        process = await Process.start(
          'pkexec',
          ['--disable-internal-agent', 'bash', scriptFile.path],
          environment: env,
          runInShell: false,
        );
        _addTerminalOutput('Using pkexec - please enter your password in the dialog window');
        _addTerminalOutput('Process started with PID: ${process.pid}');
      } catch (e) {
        // Fallback to sudo (shows terminal password prompt)
        _addTerminalOutput('pkexec not available, trying sudo...');
        _addTerminalOutput('Error: $e');
        _addTerminalOutput('Using sudo - password prompt will appear in terminal');
        process = await Process.start(
          'sudo',
          ['-S', 'bash', scriptFile.path],
          environment: env,
          runInShell: false,
        );
        _addTerminalOutput('Process started with PID: ${process.pid}');
        _addTerminalOutput('Note: sudo may require password input in terminal');
      }

      // Add a heartbeat to show the process is still running
      Timer? heartbeatTimer;
      heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          _addTerminalOutput('⏳ Waiting for authentication... (Process PID: ${process.pid})');
        }
      });

      // Track if we've received any output (to detect if process is stuck waiting for password)
      bool hasReceivedOutput = false;
      Timer? timeoutTimer;
      
      // Set a timeout to detect if process is stuck
      timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (!hasReceivedOutput && mounted) {
          _addTerminalOutput('');
          _addTerminalOutput('⚠️ WARNING: Process appears to be waiting for password input.');
          _addTerminalOutput('Please check for a password dialog window.');
          _addTerminalOutput('If no dialog appears, the process may need to be cancelled.');
        }
      });

      // Stream stdout in real-time
      process.stdout.transform(const SystemEncoding().decoder).listen((data) {
        hasReceivedOutput = true;
        timeoutTimer?.cancel();
        heartbeatTimer?.cancel();
        final lines = data.split('\n');
        for (var line in lines) {
          if (line.trim().isNotEmpty) {
            _addTerminalOutput(line);
            
            // Update progress based on steps
                            if (line.contains('Step 1:')) {
                              setState(() {
                                _progress = 0.05;
                                _usbCreationStatus = 'Unmounting USB device';
                              });
                            } else if (line.contains('Step 2: Wiping')) {
                              setState(() {
                                _progress = 0.08;
                                _usbCreationStatus = 'Wiping existing partition table';
                              });
                            } else if (line.contains('Step 2: Creating GPT')) {
                              setState(() {
                                _progress = 0.12;
                                _usbCreationStatus = 'Creating GPT partition (Rufus-style)';
                              });
                            } else if (line.contains('Using sgdisk')) {
                              setState(() {
                                _progress = 0.14;
                                _usbCreationStatus = 'Creating Microsoft Basic Data partition';
                              });
                            } else if (line.contains('Using parted')) {
                              setState(() {
                                _progress = 0.14;
                                _usbCreationStatus = 'Creating partition with parted';
                              });
                            } else if (line.contains('Step 3:')) {
                              setState(() {
                                _progress = 0.18;
                                _usbCreationStatus = 'Formatting USB drive as FAT32';
                              });
                            } else if (line.contains('Step 4: Mounting')) {
                              setState(() {
                                _progress = 0.22;
                                _usbCreationStatus = 'Mounting ISO and USB drive';
                              });
                            } else if (line.contains('Step 5:')) {
                              setState(() {
                                _progress = 0.25;
                                _usbCreationStatus = 'Checking for large files...';
                              });
                            } else if (line.contains('WARNING: install.wim is larger')) {
                              setState(() {
                                _progress = 0.28;
                                _usbCreationStatus = 'Large file detected, will split for FAT32';
                              });
                            } else if (line.contains('Step 6:') && !line.contains('Step 6b')) {
                              setState(() {
                                _progress = 0.30;
                                _usbCreationStatus = 'Copying Windows files';
                              });
                            } else if (line.contains('Step 6b:')) {
                              setState(() {
                                _progress = 0.75;
                                _usbCreationStatus = 'Splitting install.wim for FAT32';
                              });
                            } else if (line.contains('Successfully split')) {
                              setState(() {
                                _progress = 0.82;
                                _usbCreationStatus = 'Split complete!';
                              });
                            } else if (line.contains('%')) {
                              // Parse rsync progress (e.g., "1,234,567  50%")
                              final progressMatch = RegExp(r'(\d+)%').firstMatch(line);
                              if (progressMatch != null) {
                                final percent = int.tryParse(progressMatch.group(1) ?? '0') ?? 0;
                                setState(() {
                                  _progress = 0.30 + (percent / 100) * 0.45; // 30% to 75%
                                  _usbCreationStatus = 'Copying Windows files: $percent%';
                                });
                              }
                            } else if (line.contains('Step 7:')) {
                              setState(() {
                                _progress = 0.85;
                                _usbCreationStatus = 'Ensuring EFI boot files are correct';
                              });
                            } else if (line.contains('Step 8:')) {
                              setState(() {
                                _progress = 0.90;
                                _usbCreationStatus = 'Verifying USB contents';
                              });
                            } else if (line.contains('Step 9:')) {
                              setState(() {
                                _progress = 0.92;
                                _usbCreationStatus = 'Syncing and unmounting drives';
                              });
                            } else if (line.contains('Flushing all data')) {
                              setState(() {
                                _progress = 0.93;
                                _usbCreationStatus = 'Flushing data to USB...';
                              });
                            } else if (line.contains('Data sync complete')) {
                              setState(() {
                                _progress = 0.94;
                                _usbCreationStatus = 'Data sync complete';
                              });
                            } else if (line.contains('Unmounting ISO')) {
                              setState(() {
                                _progress = 0.95;
                                _usbCreationStatus = 'Unmounting ISO...';
                              });
                            } else if (line.contains('Unmounting USB')) {
                              setState(() {
                                _progress = 0.96;
                                _usbCreationStatus = 'Unmounting USB drive...';
                              });
                            } else if (line.contains('USB drive unmounted successfully') || 
                                       line.contains('ISO unmounted successfully')) {
                              setState(() {
                                _progress = 0.98;
                                _usbCreationStatus = 'Unmount complete';
                              });
                            } else if (line.contains('✓') && line.contains('UEFI bootable')) {
                              setState(() {
                                _progress = 1.0;
                                _usbCreationStatus = 'UEFI bootable USB created!';
                              });
                            } else if (line.contains('You can safely remove')) {
                              setState(() {
                                _progress = 1.0;
                                _usbCreationStatus = 'Complete! Safe to remove USB';
                              });
                            }
          }
        }
      });

      // Stream stderr in real-time
      process.stderr.transform(const SystemEncoding().decoder).listen((data) {
        hasReceivedOutput = true;
        timeoutTimer?.cancel();
        heartbeatTimer?.cancel();
        if (data.trim().isNotEmpty) {
          _addTerminalOutput('Error: $data');
        }
      });

      // Wait for process to complete with timeout
      int exitCode;
      try {
        exitCode = await process.exitCode.timeout(
          const Duration(minutes: 30),
          onTimeout: () {
            if (mounted) {
              _addTerminalOutput('');
              _addTerminalOutput('✗ ERROR: Process timed out after 30 minutes');
              _addTerminalOutput('The USB creation process may have failed or is stuck.');
            }
            process.kill();
            return -1;
          },
        );
      } catch (e) {
        if (mounted) {
          _addTerminalOutput('✗ ERROR: $e');
        }
        process.kill();
        exitCode = -1;
      } finally {
        timeoutTimer.cancel();
      }

      if (exitCode != 0) {
        throw Exception('Script failed with exit code $exitCode');
      }

      setState(() {
        _isCreatingUSB = false;
      });

      // Cleanup
      try {
        await tempDir.delete(recursive: true);
        await usbMountDir.delete(recursive: true);
        await scriptFile.delete();
      } catch (e) {
        // Ignore cleanup errors
      }

      // Auto-advance to completion step
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _currentStep = 6);
        }
      });

    } catch (e) {
      setState(() {
        _isCreatingUSB = false;
        _usbCreationStatus = 'Error: $e';
        _terminalOutput.add('✗ Error: $e');
      });
      
      // Cleanup on error
      try {
        await tempDir.delete(recursive: true);
        await usbMountDir.delete(recursive: true);
        if (await scriptFile.exists()) {
          await scriptFile.delete();
        }
      } catch (cleanupError) {
        // Ignore cleanup errors
      }
    }
  }

  void _addTerminalOutput(String line) {
    if (mounted) {
      setState(() {
        _terminalOutput.add(line);
        // Keep only last 100 lines
        if (_terminalOutput.length > 100) {
          _terminalOutput.removeAt(0);
        }
      });
    }
  }

  void _startImageSlider() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _currentStep == 5) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % 3;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startImageSlider();
      }
    });
  }

  void _animateProgress() {
    // Only animate if not downloading
    if (_isDownloading) return;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _currentStep == 5 && _progress < 1.0 && !_isDownloading) {
        setState(() {
          _progress += 0.01;
          if (_progress > 1.0) {
            _progress = 1.0;
            // Auto-advance to completion step after 1 second
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() => _currentStep = 6);
              }
            });
          }
        });
        _animateProgress();
      }
    });
  }

  void _handleBack() {
    if (_currentStep > 0) {
      if (_currentStep == 6) {
        // If on completion step, go back to progress
        setState(() {
          _currentStep = 5;
          _progress = 1.0;
        });
      } else if (_currentStep == 5) {
        // If on progress step, go back to warning/consent
        setState(() {
          _currentStep = 4;
          _progress = 0.0;
          _currentImageIndex = 0;
        });
      } else if (_currentStep == 4) {
        // If on warning/consent step, go back to USB selection
        setState(() => _currentStep = 3);
      } else if (_currentStep == 3) {
        // If on USB selection step, go back based on ISO method
        if (_isoSelectionMethod == 'select') {
          // If they selected ISO manually, go back to step 1
          setState(() => _currentStep = 1);
        } else {
          // If they chose to download, go back to step 2 (Windows version)
          setState(() => _currentStep = 2);
        }
      } else {
        setState(() => _currentStep = _currentStep - 1);
      }
    }
  }

  Future<void> _selectISOFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['iso'],
        dialogTitle: 'Select Windows ISO file',
      );

      if (result != null && result.files.single.path != null) {
        final isoPath = result.files.single.path!;
        setState(() {
          _selectedISOPath = isoPath;
        });
        
        // Auto-advance to USB selection step after ISO is selected
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _selectedISOPath != null) {
            setState(() {
              _currentStep = 3; // Go to USB selection
              _detectUSBDevices(); // Detect USB devices
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting ISO file: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _selectUSBDevice(String device) {
    setState(() {
      _selectedUSBDevice = device;
    });
  }

  Future<void> _detectUSBDevices() async {
    if (Platform.isLinux) {
      setState(() {
        _isLoadingUSBDevices = true;
        _availableUSBDevices = [];
      });

      try {
        // Use lsblk to list block devices
        final result = await Process.run('lsblk', [
          '-o', 'NAME,SIZE,TYPE,MOUNTPOINT,MODEL',
          '-J',
          '-b',
        ]);

        if (result.exitCode == 0) {
          final jsonData = jsonDecode(result.stdout as String);
          final List<dynamic> blockdevices = jsonData['blockdevices'] ?? [];
          final List<String> usbDevices = [];

          for (var device in blockdevices) {
            // Check if it's a disk (not a partition) and removable
            if (device['type'] == 'disk') {
              // Check if it's a USB device by checking /sys/block
              final deviceName = device['name'] as String;
              final devicePath = '/sys/block/$deviceName/removable';
              final removableFile = File(devicePath);
              
              if (await removableFile.exists()) {
                final removableContent = await removableFile.readAsString();
                if (removableContent.trim() == '1') {
                  // It's a removable device (likely USB)
                  final size = device['size'] ?? '0';
                  final model = device['model'] ?? 'Unknown';
                  final sizeGB = (int.tryParse(size.toString()) ?? 0) / (1024 * 1024 * 1024);
                  final sizeStr = sizeGB > 0 
                      ? '${sizeGB.toStringAsFixed(1)} GB'
                      : 'Unknown size';
                  
                  usbDevices.add('/dev/$deviceName - $model ($sizeStr)');
                }
              }
            }
          }

          setState(() {
            _availableUSBDevices = usbDevices;
            _isLoadingUSBDevices = false;
          });

          // If no devices found, show a message
          if (usbDevices.isEmpty && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No USB devices detected. Please connect a USB drive and refresh.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          setState(() {
            _isLoadingUSBDevices = false;
            _availableUSBDevices = [];
          });
        }
      } catch (e) {
        setState(() {
          _isLoadingUSBDevices = false;
          _availableUSBDevices = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error detecting USB devices: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      // For non-Linux platforms, use a fallback
      setState(() {
        _isLoadingUSBDevices = false;
        _availableUSBDevices = [
          '/dev/sdb - USB Device (Unknown size)',
        ];
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: _currentStep == 0
                ? _buildWelcomeStep()
                : _currentStep == 1
                    ? _buildISOMethodSelectionStep()
                    : _currentStep == 2
                        ? _buildWindowsVersionSelectionStep()
                        : _currentStep == 3
                            ? _buildUSBSelectionStep()
                            : _currentStep == 4
                                ? _buildWarningConsentStep()
                                : _currentStep == 5
                                    ? _buildProgressStep()
                                    : _buildCompletionStep(),
          ),
          // Bottom Section
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Welcome Icon/Logo
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/winspace.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Main Title
              const Center(
                child: Text(
                  'Welcome to WinSpace',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle
              Center(
                child: Text(
                  'Create a bootable Windows USB installer on Linux. Select your Windows ISO file and USB drive to get started.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildISOMethodSelectionStep() {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Title
                const Center(
                  child: Text(
                    'Choose how to get Windows ISO',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Center(
                  child: Text(
                    'You can either select an existing Windows ISO file from your computer or download it directly using this app.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Radio Options
                _buildRadioOption(
                  value: 'select',
                  title: 'Select ISO file',
                  description: 'Choose an existing Windows ISO file from your computer.',
                  isSelected: _isoSelectionMethod == 'select',
                ),
                const SizedBox(height: 24),
                _buildRadioOption(
                  value: 'download',
                  title: 'Download ISO file with app',
                  description: 'Download Windows ISO directly using this application.',
                  isSelected: _isoSelectionMethod == 'download',
                ),
                // Show ISO file selection if "Select ISO file" is chosen
                if (_isoSelectionMethod == 'select') ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Windows ISO File',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectISOFile,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedISOPath != null
                              ? Colors.blue[600]!
                              : Colors.grey[300]!,
                          width: _selectedISOPath != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: _selectedISOPath != null
                            ? Colors.blue[50]
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: _selectedISOPath != null
                                ? Colors.blue[600]
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedISOPath ?? 'Click to select Windows ISO file',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _selectedISOPath != null
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                    color: _selectedISOPath != null
                                        ? Colors.black87
                                        : Colors.grey[600],
                                  ),
                                ),
                                if (_selectedISOPath != null)
                                  Text(
                                    'ISO file selected',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWindowsVersionSelectionStep() {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Title
                const Center(
                  child: Text(
                    'Select Windows version',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Center(
                  child: Text(
                    'Choose the Windows version you want to download. Select a version to see its release date and system requirements.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Windows Version List
                ..._windowsVersions.keys.map((version) {
                  final isSelected = _selectedWindowsVersion == version;
                  final versionInfo = _windowsVersions[version]!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedWindowsVersion = version;
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue[600]!
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: isSelected
                              ? Colors.blue[50]
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: version,
                              groupValue: _selectedWindowsVersion,
                              onChanged: (val) {
                                setState(() {
                                  _selectedWindowsVersion = version;
                                });
                              },
                              activeColor: Colors.blue[600],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    version,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Release Date: ${versionInfo['releaseDate']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'System Requirements:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            versionInfo['requirements']!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700],
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUSBSelectionStep() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Title
                const Center(
                  child: Text(
                    'Select USB drive',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Center(
                  child: Text(
                    'Choose the USB drive where you want to create the bootable Windows installer. The USB drive will be formatted, so make sure to backup any important data.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              // Refresh button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _isLoadingUSBDevices ? null : _detectUSBDevices,
                    icon: _isLoadingUSBDevices
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    label: Text(_isLoadingUSBDevices ? 'Detecting...' : 'Refresh'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // USB Device List
              if (_isLoadingUSBDevices && _availableUSBDevices.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Detecting USB devices...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!_isLoadingUSBDevices && _availableUSBDevices.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.usb_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No USB devices detected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please connect a USB drive and click Refresh',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._availableUSBDevices.map((device) {
                  final isSelected = _selectedUSBDevice == device;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _selectUSBDevice(device),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue[600]!
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: isSelected
                            ? Colors.blue[50]
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: device,
                            groupValue: _selectedUSBDevice,
                            onChanged: (val) => _selectUSBDevice(device),
                            activeColor: Colors.blue[600],
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.usb,
                            color: isSelected
                                ? Colors.blue[600]
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              device,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              if (_selectedUSBDevice != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.orange[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Warning: All data on the selected USB drive will be erased.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningConsentStep() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Title
                const Center(
                  child: Text(
                    'Warning: USB Drive Will Be Erased',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Center(
                  child: Text(
                    'Your USB drive will be erased and a bootable partition will be created.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              // Warning Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.orange[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 24,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected USB Drive:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedUSBDevice ?? 'No USB drive selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Consent Checkbox
              InkWell(
                onTap: () {
                  setState(() {
                    _consentGiven = !_consentGiven;
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _consentGiven
                          ? Colors.blue[600]!
                          : Colors.grey[300]!,
                      width: _consentGiven ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    color: _consentGiven
                        ? Colors.blue[50]
                        : Colors.transparent,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _consentGiven,
                        onChanged: (val) {
                          setState(() {
                            _consentGiven = val ?? false;
                          });
                        },
                        activeColor: Colors.blue[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'I understand that all data on the USB drive will be permanently erased and consent to proceed.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep() {
    // Show download step if downloading
    if (_isDownloading || (!_downloadComplete && _isoSelectionMethod == 'download')) {
      return Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.download,
                          size: 56,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          _showTerminal ? Icons.terminal : Icons.terminal_outlined,
                          size: 32,
                          color: Colors.blue[600],
                        ),
                        tooltip: 'Toggle Terminal Output',
                        onPressed: () {
                          setState(() {
                            _showTerminal = !_showTerminal;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Downloading Windows ISO',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _downloadStatus,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(_progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_showTerminal) ...[
                    const SizedBox(height: 24),
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        reverse: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _terminalOutput.map((line) {
                            Color textColor = Colors.greenAccent;
                            if (line.contains('✗') || line.contains('Error')) {
                              textColor = Colors.redAccent;
                            } else if (line.contains('✓')) {
                              textColor = Colors.lightGreenAccent;
                            } else if (line.contains('===')) {
                              textColor = Colors.cyanAccent;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                line,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: textColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Show USB creation progress (combined with download if applicable)
    if (_isCreatingUSB || (_downloadComplete && _isoSelectionMethod == 'download')) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isCreatingUSB ? Icons.usb : Icons.check_circle,
                        size: 64,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        _showTerminal ? Icons.terminal : Icons.terminal_outlined,
                        size: 32,
                        color: Colors.blue[600],
                      ),
                      tooltip: 'Show Terminal Output',
                      onPressed: () {
                        setState(() {
                          _showTerminal = !_showTerminal;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  _isCreatingUSB ? 'Creating Windows Bootable USB' : 'Download Complete - Creating USB',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _isCreatingUSB ? _usbCreationStatus : 'Starting USB creation...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                  minHeight: 8,
                ),
                const SizedBox(height: 16),
                Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                if (_showTerminal) ...[
                  const SizedBox(height: 24),
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _terminalOutput.map((line) {
                          Color textColor = Colors.greenAccent;
                          if (line.contains('✗') || line.contains('Error')) {
                            textColor = Colors.redAccent;
                          } else if (line.contains('✓')) {
                            textColor = Colors.lightGreenAccent;
                          } else if (line.contains('===')) {
                            textColor = Colors.cyanAccent;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              line,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: textColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Show USB creation steps after download completes (fallback for manual ISO)
    final List<Map<String, dynamic>> progressImages = [
      {
        'title': 'Preparing USB Drive',
        'description': 'Formatting and preparing the USB drive for installation',
        'icon': Icons.usb,
      },
      {
        'title': 'Copying Windows Files',
        'description': 'Copying Windows installation files to USB drive',
        'icon': Icons.file_copy,
      },
      {
        'title': 'Creating Bootable Partition',
        'description': 'Setting up bootable partition on USB drive',
        'icon': Icons.storage,
      },
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image Slider
              SizedBox(
                height: 300,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: progressImages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = progressImages[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue[200]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              size: 64,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            item['title']!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              item['description']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 48),
              // Progress Bar
              Column(
                children: [
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue[600]!,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _progress < 1.0
                        ? 'Creating Windows USB installer...'
                        : 'Windows USB installer created successfully!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionStep() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green[600],
                ),
              ),
              const SizedBox(height: 32),
              // Success Title
              const Text(
                'Your Pendrive is Ready to Boot!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Success Message
              Text(
                'Your Windows USB installer has been created successfully. You can now use this USB drive to install Windows on your computer.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showAboutDialog,
                    icon: const Icon(Icons.info_outline, size: 22),
                    label: const Text(
                      'About',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 18,
                      ),
                      minimumSize: const Size(200, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () async {
                      // Open Buy Me a Coffee link
                      final Uri url = Uri.parse('https://buymeacoffee.com/pratikmore');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open the URL'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 200,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/bmc-button.png',
                          width: 200,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 28,
            color: Colors.blue[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRadioOption({
    required String value,
    required String title,
    required String description,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _isoSelectionMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
          color: isSelected ? Colors.blue[50] : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: value,
              groupValue: _isoSelectionMethod,
              onChanged: (val) {
                setState(() {
                  _isoSelectionMethod = val;
                });
              },
              activeColor: Colors.blue[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Icon/Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/winspace.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // App Name
              const Text(
                'WinSpace',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              // Version
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Description
              Text(
                'WinSpace is a Linux application for creating bootable Windows USB installers. '
                'Designed for Linux users who need to create Windows installation media quickly and easily.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Divider
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 16),
              // Features
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeatureItem(
                    Icons.download,
                    'Download\nISO',
                  ),
                  _buildFeatureItem(
                    Icons.usb,
                    'Create\nBootable USB',
                  ),
                  _buildFeatureItem(
                    Icons.speed,
                    'Fast &\nReliable',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final bool hideButtons = _currentStep >= 5; // Hide on steps 5 and 6
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          // Left Links
          Row(
            children: [
              Text(
                '© 2025 WinSpace',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '|',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () async {
                  // Open Buy Me a Coffee link
                  final Uri url = Uri.parse('https://buymeacoffee.com/pratikmore');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open the URL'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Support',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[700],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '|',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: _showAboutDialog,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'About',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[700],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          if (!hideButtons) ...[
            const Spacer(),
            // Right Buttons
            Row(
              children: [
                TextButton(
                  onPressed: _currentStep > 0 ? _handleBack : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 13,
                      color: _currentStep > 0
                          ? Colors.grey[700]
                          : Colors.grey[400],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _canProceed()
                      ? _handleNext
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentStep == 6 ? 'Finish' : 'Next',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _canProceed() {
    if (_currentStep == 0) {
      // Welcome step - always can proceed
      return true;
    } else if (_currentStep == 1) {
      // ISO method selection step
      if (_isoSelectionMethod == 'select') {
        // Need ISO file selected
        return _selectedISOPath != null;
      } else if (_isoSelectionMethod == 'download') {
        // Just need method selected to proceed to next step
        return true;
      }
      return false;
    } else if (_currentStep == 2) {
      // Windows version selection step - need version selected
      return _selectedWindowsVersion != null;
    } else if (_currentStep == 3) {
      // USB selection step - need USB device selected
      return _selectedUSBDevice != null;
    } else if (_currentStep == 4) {
      // Warning/Consent step - need consent checkbox checked
      return _consentGiven;
    } else if (_currentStep == 5) {
      // Progress step - always can proceed (or finish)
      return true;
    } else if (_currentStep == 6) {
      // Completion step - always can proceed (or finish)
      return true;
    }
    return false;
  }
}



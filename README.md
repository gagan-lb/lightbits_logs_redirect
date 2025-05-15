# Lightbits Log Redirection Setup

This guide explains how to use the `lightbits_logs_redirect.sh` script to redirect Lightbits service logs from `/var/log/messages` to a dedicated `/var/log/lightbits.messages` file.

## Purpose

The script configures rsyslog to:
- Redirect logs from Lightbits services and etcd to a dedicated log file using case-insensitive matching
- Set up proper permissions for the log file
- Configure log rotation
- Ensure configuration persists across system reboots
- Configure SELinux context for the new log file
- Test that the configuration is working correctly

## Requirements

- RHEL, Alma Linux, or Rocky Linux system (script will verify OS compatibility)
- Rsyslog installed (script will check this)
- Root/sudo access
- Lightbits services running on the system

## Installation Instructions

### 
1. Download the Script

2. Make the Script Executable
chmod +x lightbits_logs_redirect.sh

3. Run the Script with sudo
sudo ./lightbits_logs_redirect.sh

4. Expected Output
If successful, you should see output similar to:
Checking operating system compatibility...
Compatible OS detected: Rocky Linux 8.6 (Green Obsidian)
Setting up Lightbits log redirection...
Created rsyslog configuration file with case-insensitive matching
Created log file with proper permissions
Configured log rotation
Rsyslog is already enabled to start at boot: enabled
Rsyslog configuration is valid
Rsyslog service is running: active
Applied proper SELinux context to log file
SUCCESS: Log redirection is working correctly!

=== PERSISTENCE VERIFICATION ===
The following configurations will ensure persistence across reboots:
1. Rsyslog config file: ✓ Created
2. Rsyslog service: enabled
3. Log rotation config: ✓ Created
4. Log file permissions: -rw-r----- 1 root root 89 May 14 22:15 /var/log/lightbits.messages

Configuration complete. Lightbits logs will now be redirected to /var/log/lightbits.messages
This configuration will persist across system reboots.

To verify after reboot, run: grep lightbox-exporter /var/log/lightbits.messages

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
Compatible OS detected: Rocky Linux 9.3 (Blue Onyx)
Setting up Lightbits log redirection...
SUCCESS: Lightbits log redirection configured successfully!
Configuration complete. Lightbits logs will be redirected to /var/log/lightbits.messages


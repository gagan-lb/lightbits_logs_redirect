#!/bin/bash

# Run as root or with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

echo "Checking operating system compatibility..."

# Check if the OS is RHEL, Alma Linux, or Rocky Linux
if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [[ "$ID" != "rhel" && "$ID" != "almalinux" && "$ID" != "rocky" && "$ID_LIKE" != *"rhel"* ]]; then
        echo "ERROR: This script only supports RHEL, Alma Linux, and Rocky Linux."
        echo "Detected OS: $PRETTY_NAME"
        exit 1
    fi
    echo "Compatible OS detected: $PRETTY_NAME"
else
    echo "ERROR: Cannot determine the operating system. This script only supports RHEL, Alma Linux, and Rocky Linux."
    exit 1
fi

echo "Setting up Lightbits log redirection..."

# Check if rsyslog is installed
if ! command -v rsyslogd &> /dev/null; then
    echo "ERROR: rsyslog is not installed. Please install it first."
    echo "Run: sudo dnf install rsyslog"
    exit 1
fi

# Create enhanced rsyslog configuration file with ALL Lightbits services
printf '%s\n' \
'# Redirect Lightbits logs to /var/log/lightbits.messages' \
'# This covers both direct service logs and systemd messages about these services' \
'if ($programname contains_i "api-service" or' \
'    $programname contains_i "cluster-manager" or' \
'    $programname contains_i "discovery-service" or' \
'    $programname contains_i "lightbox-exporter" or' \
'    $programname contains_i "node-manager" or' \
'    $programname contains_i "profile-generator" or' \
'    $programname contains_i "upgrade-manager" or' \
'    $programname contains_i "lb_irq_balance" or' \
'    $programname contains_i "gftl" or' \
'    $programname contains_i "etcd") or' \
'   ($programname == "systemd" and' \
'    ($msg contains_i "api-service" or' \
'     $msg contains_i "cluster-manager" or' \
'     $msg contains_i "discovery-service" or' \
'     $msg contains_i "lightbox-exporter" or' \
'     $msg contains_i "node-manager" or' \
'     $msg contains_i "profile-generator" or' \
'     $msg contains_i "upgrade-manager" or' \
'     $msg contains_i "lb_irq_balance" or' \
'     $msg contains_i "gftl" or' \
'     $msg contains_i "etcd" or' \
'     $msg contains_i "Clustering API Service" or' \
'     $msg contains_i "NVMeOF Discovery Service" or' \
'     $msg contains_i "IRQ Balance Service")) then {' \
'    action(type="omfile" file="/var/log/lightbits.messages")' \
'    stop' \
'}' > /etc/rsyslog.d/10-lightbits.conf

# Create log file with proper permissions
touch /var/log/lightbits.messages
chown root:root /var/log/lightbits.messages
chmod 640 /var/log/lightbits.messages

# Configure log rotation
printf '%s\n' \
'/var/log/lightbits.messages {' \
'    rotate 7' \
'    daily' \
'    missingok' \
'    notifempty' \
'    compress' \
'    delaycompress' \
'    postrotate' \
'        /bin/systemctl reload rsyslog.service > /dev/null 2>&1 || true' \
'    endscript' \
'}' > /etc/logrotate.d/lightbits

# Ensure rsyslog is enabled to start on boot
systemctl enable rsyslog &>/dev/null

# Validate the new configuration
if ! rsyslogd -N1 &>/dev/null; then
    echo "ERROR: Rsyslog configuration validation failed. Please check the syntax manually."
    exit 1
fi

# Restart rsyslog
systemctl restart rsyslog

# Verify rsyslog is running
if ! systemctl is-active rsyslog &>/dev/null; then
    echo "ERROR: Failed to start rsyslog service. Please check system logs."
    exit 1
fi

# SELinux context for the log file
if command -v restorecon &> /dev/null; then
    restorecon -v /var/log/lightbits.messages &>/dev/null
fi

# Test with actual service names found in logs
logger -t "systemd" "Started gftl.service test message"
logger -t "systemd" "Stopping lb_irq_balance.service test message"
sleep 2

# Check if test messages appear in the log file
if grep -q "gftl.service\|lb_irq_balance" /var/log/lightbits.messages; then
    echo "SUCCESS: Lightbits log redirection configured successfully!"
else
    echo "WARNING: Test log entries not found. Configuration may need adjustment."
fi

echo "Configuration complete. Lightbits logs will be redirected to /var/log/lightbits.messages"

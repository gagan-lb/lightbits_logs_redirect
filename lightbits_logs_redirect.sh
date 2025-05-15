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

# Step 0: Check if rsyslog is installed
if ! command -v rsyslogd &> /dev/null; then
    echo "ERROR: rsyslog is not installed. Please install it first."
    echo "Run: sudo dnf install rsyslog"
    exit 1
fi

# Step 1: Create rsyslog configuration file with case-insensitive matching
cat > /etc/rsyslog.d/10-lightbits.conf << 'EOF'
# Redirect Lightbits logs to /var/log/lightbits.messages
if $programname contains_i "api-service" or 
   $programname contains_i "cluster-manager" or 
   $programname contains_i "discovery-service" or 
   $programname contains_i "lightbox-exporter" or 
   $programname contains_i "node-manager" or 
   $programname contains_i "profile-generator" or 
   $programname contains_i "upgrade-manager" or 
   $programname contains_i "etcd" then {
    action(type="omfile" file="/var/log/lightbits.messages")
    stop
}
EOF

echo "Created rsyslog configuration file with case-insensitive matching"

# Step 2: Create log file with proper permissions
touch /var/log/lightbits.messages
# On RHEL systems, root:root is often used for log files
chown root:root /var/log/lightbits.messages
chmod 640 /var/log/lightbits.messages

echo "Created log file with proper permissions"

# Step 3: Configure log rotation
cat > /etc/logrotate.d/lightbits << 'EOF'
/var/log/lightbits.messages {
    rotate 7
    daily
    missingok
    notifempty
    compress
    delaycompress
    postrotate
        /bin/systemctl reload rsyslog.service > /dev/null 2>&1 || true
    endscript
}
EOF

echo "Configured log rotation"

# Step 4: Ensure rsyslog is enabled to start on boot
if ! systemctl is-enabled rsyslog &>/dev/null; then
    echo "Enabling rsyslog to start automatically at boot"
    systemctl enable rsyslog
else
    echo "Rsyslog is already enabled to start at boot: $(systemctl is-enabled rsyslog)"
fi

# Verify it's actually enabled
RSYSLOG_ENABLED=$(systemctl is-enabled rsyslog)
if [ "$RSYSLOG_ENABLED" != "enabled" ]; then
    echo "WARNING: Failed to enable rsyslog service. Trying again..."
    systemctl enable rsyslog
    
    # Check one more time
    RSYSLOG_ENABLED=$(systemctl is-enabled rsyslog)
    if [ "$RSYSLOG_ENABLED" != "enabled" ]; then
        echo "ERROR: Could not enable rsyslog to start on boot. Please check your system configuration."
        exit 1
    fi
fi

# Step 5: Validate the new configuration
echo "Validating rsyslog configuration..."
if rsyslogd -N1; then
    echo "Rsyslog configuration is valid"
else
    echo "ERROR: Rsyslog configuration validation failed. Please check the syntax manually."
    exit 1
fi

# Step 6: Restart rsyslog
systemctl restart rsyslog

# Step 7: Verify rsyslog is running
if systemctl is-active rsyslog &>/dev/null; then
    echo "Rsyslog service is running: $(systemctl is-active rsyslog)"
else
    echo "ERROR: Failed to start rsyslog service. Please check system logs."
    exit 1
fi

# Step 8: SELinux context for the log file (RHEL systems often use SELinux)
if command -v restorecon &> /dev/null; then
    restorecon -v /var/log/lightbits.messages
    echo "Applied proper SELinux context to log file"
fi

# Step 9: Create a simple test log entry
logger -t "lightbox-exporter" "Test message to validate Lightbits log redirection"
sleep 2

# Check if the test message appears in the log file
if grep -q "Test message to validate Lightbits log redirection" /var/log/lightbits.messages; then
    echo "SUCCESS: Log redirection is working correctly!"
else
    echo "WARNING: Test log entry not found in /var/log/lightbits.messages. Please check configuration."
fi

echo ""
echo "=== PERSISTENCE VERIFICATION ==="
echo "The following configurations will ensure persistence across reboots:"
echo "1. Rsyslog config file: $([ -f /etc/rsyslog.d/10-lightbits.conf ] && echo "✓ Created" || echo "❌ Missing")"
echo "2. Rsyslog service: $(systemctl is-enabled rsyslog)"
echo "3. Log rotation config: $([ -f /etc/logrotate.d/lightbits ] && echo "✓ Created" || echo "❌ Missing")"
echo "4. Log file permissions: $([ -f /var/log/lightbits.messages ] && ls -l /var/log/lightbits.messages || echo "❌ Missing")"
echo ""
echo "Configuration complete. Lightbits logs will now be redirected to /var/log/lightbits.messages"
echo "This configuration will persist across system reboots."
echo ""
echo "To verify after reboot, run: grep lightbox-exporter /var/log/lightbits.messages"

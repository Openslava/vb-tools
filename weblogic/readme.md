# WebLogic Management Tools

A collection of shell scripts for managing Oracle WebLogic Server installations and domains.

## Quick Start - 3 Simple Steps

### Step 1: Download Oracle Files

Download and save to your Downloads folder:

- **Oracle JDK 8u461** - [Download here](https://www.oracle.com/java/technologies/javase-jdk8-doc-downloads.html)
- **WebLogic 12.2.1.4.0** - [Download here](https://www.oracle.com/qa/middleware/technologies/weblogic-server-downloads.html)

### Step 2: Run Setup

```powershell
# Basic setup with auto-generated password
.\weblogic\00_quick_start.ps1

# Custom admin password
.\weblogic\00_quick_start.ps1 -adminPassword "MySecurePassword123!"

# Full custom configuration
.\weblogic\00_quick_start.ps1 -domainName "production" -adminPassword "SecurePass123!" -adminPort 7002
```

┌─────────────────────────────────────┐
│ Linux System Level                  │
│ User: weblogic (owns files/processes)│
└─────────────────────────────────────┘
                  │
                  │ runs
                  ▼
┌─────────────────────────────────────┐
│ WebLogic Application Level          │
│ Admin User: admin (console login)   │
│ Password: testpwd1                   │
└─────────────────────────────────────┘

### Step 3: Set WSL Password When Prompted

During setup you'll be asked to set:

1. **WSL Username/Password** (first time WSL runs) - remember these for sudo

**WebLogic Admin Password** - either auto-generated or your custom password
2. **WebLogic Admin Password** - automatically generated and displayed like: `WlsaBc7Xm2nQ47!`

### You're Done! 🎉

- **WebLogic Console**: <http://localhost:7001/console>
- **Username**: admin
- **Password**: The generated password shown during setup

---

## Password Details

### WSL Password

- Set during first WSL installation
- Used for `sudo` commands
- Choose something you'll remember

### WebLogic Admin Password

- **Command-line parameter**: Set via `-adminPassword "YourPassword123!"`
- **Auto-generated**: Secure random password if not specified
- Format: `Wls[RandomChars][Timestamp]!`
- **SAVE THIS PASSWORD** - you need it for the admin console

#### Examples

```powershell
# Use custom password
.\weblogic\00_quick_start.ps1 -adminPassword "MySecurePassword123!"

# Use auto-generated password (shown during setup)
.\weblogic\00_quick_start.ps1

# Environment variable approach
$env:ADMIN_PASSWORD = "MyPassword123!"
.\weblogic\00_quick_start.ps1
```

## Manual Setup (Advanced)

If you prefer manual control or need custom configuration:

### Step-by-Step Commands

```bash
# 1. Install WebLogic (as root)
sudo ./01_set_weblogic.sh

# 2. Create domain (as root, auto-generates password)
sudo ./02_set_domain.sh [domain_name]

# 3. Start domain (as root)
sudo ./03_run_domain.sh [domain_name]
```

### Custom Password Setup

```bash
# Set custom password before creating domain
export ADMIN_PASSWORD="YourSecurePassword123!"
sudo ./02_set_domain.sh [domain_name]
```

### Requirements

- Oracle JDK 8+ and WebLogic 12.2.1.4.0 files in `/opt/oracle/install_files/`
- Oracle Linux WSL or similar Linux environment
- Root/sudo access

---

## Detailed Documentation

## Reference Documentation

### Scripts Overview

- **01_set_weblogic.sh** - Installs WebLogic Server and creates weblogic user
- **02_set_domain.sh** - Creates and configures WebLogic domains with secure passwords
- **03_run_domain.sh** - Starts and manages WebLogic domains

### Environment Structure

```bash
ORACLE_BASE="/opt/oracle"
ORACLE_HOME="$ORACLE_BASE/middleware"
WLS_HOME="$ORACLE_HOME/wlserver"
DOMAIN_HOME="$ORACLE_HOME/user_projects/domains"
```

### Troubleshooting

Common issues:

- **Permission Denied**: Ensure running with sudo/root access
- **Java Not Found**: Verify JDK files are in Downloads folder
- **Server Start Failure**: Check if port 7001 is available

### Features

- Automated installation and configuration
- Secure password generation
- Idempotent scripts (safe to run multiple times)
- Comprehensive error handling

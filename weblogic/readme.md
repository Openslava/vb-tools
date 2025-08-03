# WebLogic Management Tools

A collection of shell scripts for managing Oracle WebLogic Server installations and domains.

## quick start

see `00_quick_start.ps1` for a quick setup guide.

## Scripts Overview

1. **01_set_weblogic.sh**
   - Creates weblogic user if it doesn't exist
   - Installs and configures WebLogic Server
   - Sets up required environment variables
   - Prerequisites for domain creation

2. **02_set_domain.sh**
   - Creates and configures WebLogic domains
   - Sets up domain-specific configurations
   - Prepares the domain for first use

3. **03_run_domain.sh**
   - Manages WebLogic domain lifecycle
   - Starts/monitors the Admin Server
   - Provides status and log monitoring

## Requirements

- Linux/Unix environment (Oracle Linux WSL supported)
- Oracle WebLogic Server installation media
- JDK 8 or later installed at:
  - `/usr/java/latest` or
  - `/usr/lib/jvm/java-1.8.0`
- `weblogic` user account (will be created if doesn't exist)
- Root/sudo access for initial user creation

## Directory Structure

```text
weblogic/
├── 01_set_weblogic.sh  # WebLogic installation script
├── 02_set_domain.sh    # Domain creation script
├── 03_run_domain.sh    # Domain management script
└── readme.md          # This documentation
```

## Usage

### 1. Install WebLogic

```bash
# Run as root - creates weblogic user and installs WebLogic
sudo ./01_set_weblogic.sh
```

### 2. Create Domain

```bash
# Create domain with optional domain name
su - weblogic -c './02_set_domain.sh [domain_name]'
```

If the admin password is not set via the `ADMIN_PASSWORD` environment variable, the script will prompt for it interactively. The password must meet these requirements:

- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character

### 3. Start Domain

```bash
su - weblogic -c './03_run_domain.sh [domain_name]'
```

Default domain name is 'test_domain' if not specified.

## Environment Variables

The scripts use the following environment structure:

```bash
ORACLE_BASE="/opt/oracle"
ORACLE_HOME="$ORACLE_BASE/middleware"
MW_HOME="$ORACLE_HOME"
WLS_HOME="$MW_HOME/wlserver"
DOMAIN_HOME="$MW_HOME/user_projects/domains"
```

## Features

- Automated WebLogic installation and configuration
- Domain creation and management
- Server status monitoring
- Log viewing and management
- Node Manager integration
- Security best practices (no root execution)
- Comprehensive error handling and validation

## Monitoring

The `03_run_domain.sh` script provides:

- Real-time server status monitoring
- Access to server logs
- Admin console URL (default: `http://localhost:7001/console`)
- Node Manager status

## Troubleshooting

Common issues and solutions:

1. **Permission Denied**
   - Ensure running as `weblogic` user
   - Check file permissions

2. **Java Not Found**
   - Verify JDK installation
   - Check JAVA_HOME setting

3. **Server Start Failure**
   - Check server logs
   - Verify domain configuration
   - Ensure ports are available

## Security Notes

- Scripts must run as `weblogic` user
- Root execution is explicitly prevented
- Sensitive operations are validated
- Environment is isolated per domain

## Support

For issues or enhancements:

1. Check the error messages and logs
2. Review the requirements
3. Submit detailed bug reports if needed

## Best Practices

- Always run as `weblogic` user
- Monitor server logs during startup
- Back up domain configurations
- Follow security guidelines
- Keep WebLogic patched and updated

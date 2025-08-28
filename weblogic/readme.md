# WebLogic Tools 🚀

Oracle WebLogic Server installation and domain management.

## 🚀 Quick Start

### Download Oracle Files First

- **Oracle JDK 8u461** - [Download](https://www.oracle.com/java/technologies/javase-jdk8-doc-downloads.html)
- **WebLogic 12.2.1.4.0** - [Download](https://www.oracle.com/qa/middleware/technologies/weblogic-server-downloads.html)

### Run Setup

```powershell
# Complete setup (auto password)
.\weblogic\00_quick_start.ps1

# Custom password
.\weblogic\00_quick_start.ps1 -adminPassword "MySecurePassword123!"

# Full custom config  
.\weblogic\00_quick_start.ps1 -domainName "production" -adminPassword "SecurePass123!" -adminPort 7002
```

### Result ✅

- **WebLogic Console**: <http://localhost:7001/console>
- **Username**: `admin`
- **Password**: Generated/custom password from setup

## 📁 Scripts

- **01_set_weblogic.sh** - WebLogic Server installation
- **02_set_domain.sh** - Domain creation with secure passwords
- **03_run_domain.sh** - Domain startup/management

## 🔧 Manual Setup

```bash
# Step-by-step
sudo ./01_set_weblogic.sh
sudo ./02_set_domain.sh [domain_name]
sudo ./03_run_domain.sh [domain_name]

# Custom password
export ADMIN_PASSWORD="YourSecurePassword123!"
sudo ./02_set_domain.sh [domain_name]
```

## 🗂️ Structure

```bash
/opt/oracle/
├── middleware/        # ORACLE_HOME
│   ├── wlserver/     # WLS_HOME
│   └── user_projects/domains/  # Domains
```

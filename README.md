# VB-Tools

A collection of automation tools and utilities for Windows development environments, focusing on WSL (Windows Subsystem for Linux) and Oracle WebLogic Server setup.

## 🚀 Features

- **WSL Automation**: Automated installation, configuration, and DNS setup for Oracle Linux WSL
- **WebLogic Setup**: Streamlined Oracle WebLogic Server domain creation and management
- **Sample Applications**: Ready-to-deploy Java servlet applications for WebLogic testing
- **Development Tools**: Idempotent scripts with minimal user input for rapid environment setup

## 📋 Prerequisites

- Windows 10/11 with WSL support
- PowerShell 5.1 or later
- Administrator privileges for initial setup

## 🛠️ Quick Start

```powershell
# Clone the repository
git clone https://github.com/Openslava/vb-tools.git
cd vb-tools

# Run the complete setup (WSL + WebLogic)
.\weblogic\00_quick_start.ps1
```

## 📚 Documentation

### WSL Tools
- [WSL Setup Guide](./wsl/readme.md) - Complete WSL installation and configuration
- Automated Oracle Linux WSL deployment
- DNS configuration and network setup
- Development tools installation

### WebLogic Tools
- [WebLogic Setup Guide](./weblogic/readme.md) - Oracle WebLogic Server automation
- Domain creation and configuration
- Sample Java application deployment
- Admin console access and management

### Sample Applications
- [Java Servlet Sample](./weblogic/sample/readme.md) - Minimal WebLogic-ready web application
- Maven-based build system
- Version management and deployment guides

## 🔧 Project Structure

```
vb-tools/
├── wsl/                    # WSL automation scripts
│   ├── 00_quick_start.ps1  # WSL setup orchestrator
│   ├── 01_set_wsl.ps1      # WSL installation
│   ├── 02_set_dns.sh       # DNS configuration
│   └── 03_set_tools.ps1    # Development tools
├── weblogic/               # WebLogic automation
│   ├── 00_quick_start.ps1  # Complete WebLogic setup
│   ├── 01_set_weblogic.sh  # WebLogic installation
│   ├── 02_set_domain.sh    # Domain creation
│   ├── 03_run_domain.sh    # Domain startup
│   └── sample/             # Sample Java application
└── docs/                   # Additional documentation
```

## 🎯 Usage Examples

### WSL Only Setup
```powershell
.\wsl\00_quick_start.ps1
```

### WebLogic with Force Password Reset
```powershell
.\weblogic\00_quick_start.ps1 -forse
```

### Build and Deploy Sample App
```bash
cd weblogic/sample
export JAVA_HOME=/usr/java/latest
mvn clean package
# Deploy via WebLogic Admin Console
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Oracle for WebLogic Server and Oracle Linux
- Microsoft for Windows Subsystem for Linux
- The open-source community for inspiration and tools

## 📞 Support

For questions and support:
- Create an [Issue](https://github.com/Openslava/vb-tools/issues)
- Check existing [Discussions](https://github.com/Openslava/vb-tools/discussions)
- Review the documentation in each module's readme

---

**Made with ❤️ for developers who want rapid, reliable environment setup**

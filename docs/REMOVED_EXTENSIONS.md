# Removed/Unpublished Microsoft VS Code Extensions

**Report Generated:** 2025-12-05  
**Total Removed:** 296 extensions (135 unpublished + 161 non-Microsoft)  

---

## Summary

This document tracks extensions that were initially included but later removed from the documentation for the following reasons:

1. **Unpublished Extensions (135):** Marked as "unpublished" in VS Code Marketplace API and return 404 errors
2. **Non-Microsoft Publishers (161):** Extensions from third-party publishers that were incorrectly included due to API SearchText filter

---

## Section 1: Non-Microsoft Publisher Extensions (161 Removed - Dec 5, 2025)

These extensions were removed because they are **NOT published by Microsoft**. They were initially included because the API query used `filterType=10` (SearchText) which searches for "Microsoft" across all fields (name, description, tags), not just publisher.

**Root Cause:** Extensions mentioning "Microsoft" in their metadata (e.g., "for Microsoft Dynamics", "Microsoft Graph") were incorrectly included.

**Fix Applied:** Updated fetch script to filter by actual publisher identity using known Microsoft publisher patterns.

### Non-Microsoft Extensions by Publisher

**Total: 161 extensions from 141 different publishers**

*See validation report at: output/publisher_validation_report.json for complete details*

**Top Third-Party Publishers:**
- MAI-EngineeringSystems (4 extensions)
- Note2Link (4 extensions) 
- M. Eng. R. Batinov (3 extensions) - MSSQL tools
- Elio Struyf (3 extensions) - MS Graph tools
- Arm (2 extensions) - Arm debuggers
- And 136 more publishers

**Notable Removed Extensions:**
- **AlexanderSklarMSFT.midl** (156K installs) - MIDL 3.0 language support
- **kishoreithadi.dotnet-core-essentials** (164K installs) - Dotnet Core Essentials
- **nabsolutions.nabal** (97K installs) - NAB AL Tools (Business Central)
- **blindtiger.masm** (89K installs) - MASM assembler
- **generalov.tfs** (62K installs) - TFS extension
- **notblank00.hex-editor-tags** (50K installs) - Hex Editor with Tags
- **waldo.al-extension-pack** (86K installs) - AL Extension Pack (Business Central)

For the complete list of all 161 removed extensions with publisher details, install counts, and marketplace URLs, see: `output/publisher_validation_report.json`

---

## Section 2: Unpublished Microsoft Extensions (135 Removed)

---

## Section 2: Unpublished Microsoft Extensions (135 Removed)

These extensions were filtered out because they are marked as unpublished in the marketplace and return 404 errors when accessed. This includes both legitimate Microsoft extensions that were deprecated/retired and spam extensions that were removed.

---

## Top 20 Legitimate Microsoft Extensions (Removed/Deprecated)

Ranked by install count at time of removal:

### 1. Live Share Extension Pack
- **ID:** MS-vsliveshare.vsliveshare-pack
- **Installs:** 2.72M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=MS-vsliveshare.vsliveshare-pack (404)

### 2. Anaconda Extension Pack
- **ID:** ms-python.anaconda-extension-pack
- **Installs:** 2.47M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-python.anaconda-extension-pack (404)

### 3. Azure Repos
- **ID:** ms-vsts.team
- **Installs:** 1.21M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-vsts.team (404)

### 4. PostgreSQL
- **ID:** ms-ossdata.vscode-postgresql
- **Installs:** 0.95M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-ossdata.vscode-postgresql (404)

### 5. Visual Studio Codespaces
- **ID:** ms-vsonline.vsonline
- **Installs:** 0.53M
- **Status:** Unpublished (replaced by GitHub Codespaces)
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-vsonline.vsonline (404)

### 6. Remote - SSH: Explorer
- **ID:** ms-vscode-remote.remote-ssh-explorer
- **Installs:** 0.51M
- **Status:** Unpublished (functionality integrated into Remote - SSH)
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh-explorer (404)

### 7. PowerShell Preview
- **ID:** ms-vscode.PowerShell-Preview
- **Installs:** 0.30M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell-Preview (404)

### 8. Remote - SSH: Editing Configuration Files (Nightly)
- **ID:** ms-vscode-remote.remote-ssh-edit-nightly
- **Installs:** 0.12M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh-edit-nightly (404)

### 9. Remote - SSH (Nightly)
- **ID:** ms-vscode-remote.remote-ssh-nightly
- **Installs:** 0.10M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh-nightly (404)

### 10. JSCS Linting (deprecated)
- **ID:** ms-vscode.jscs
- **Installs:** 0.03M
- **Status:** Unpublished (deprecated)
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-vscode.jscs (404)

### 11. Data Access Migration Toolkit
- **ID:** ms-databasemigration.data-access-migration-toolkit
- **Installs:** 0.03M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-databasemigration.data-access-migration-toolkit (404)

### 12. English (United Kingdom) Language Pack
- **ID:** MS-CEINTL.vscode-language-pack-en-GB
- **Installs:** 0.03M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=MS-CEINTL.vscode-language-pack-en-GB (404)

### 13. OneDrive Browser
- **ID:** ms-vscode.onedrive-browser
- **Installs:** 0.03M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-vscode.onedrive-browser (404)

### 14. Deploy to Azure (deprecated)
- **ID:** ms-vscode-deploy-azure.azure-deploy
- **Installs:** 0.02M
- **Status:** Unpublished (deprecated)
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-vscode-deploy-azure.azure-deploy (404)

### 15. GitHub Issues
- **ID:** ms-vscode.github-issues-prs
- **Installs:** 0.02M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-vscode.github-issues-prs (404)

### 16. VS Code Selfhost Test Provider
- **ID:** ms-vscode.vscode-selfhost-test-provider
- **Installs:** 0.02M
- **Status:** Unpublished (internal tool)
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-selfhost-test-provider (404)

### 17. Azure Extension Pack
- **ID:** ms-vscode.vscode-azureextensionpack
- **Installs:** 0.02M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-azureextensionpack (404)

### 18. Device Simulator Express
- **ID:** ms-python.devicesimulatorexpress
- **Installs:** 0.01M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-python.devicesimulatorexpress (404)

### 19. CDB Debugger
- **ID:** MicrosoftDebuggingPlatform.vscode-cdb
- **Installs:** 0.01M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=MicrosoftDebuggingPlatform.vscode-cdb (404)

### 20. Remote - SSH: Explorer (Nightly)
- **ID:** ms-vscode-remote.remote-ssh-explorer-nightly
- **Installs:** 0.01M
- **Status:** Unpublished
- **Link:** https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh-explorer-nightly (404)

---

## Additional Notable Removed Extensions

- **Arduino (deprecated)** - vsciot-vscode.vscode-arduino
- **Azure IoT Tools** - vsciot-vscode.azure-iot-tools
- **Azure IoT Device Workbench** - vsciot-vscode.vscode-iot-workbench
- **Windows IoT Core Extension** - ms-iot.windowsiot
- **TFS** - ivangabriele.vscode-tfs
- **Ansible** - vscoss.vscode-ansible
- **Azure Dev Spaces** - azuredevspaces.azds
- **Azure Blockchain** - AzBlockchain.azure-blockchain
- **Azure Cosmos DB Graph (deprecated)** - ms-azuretools.vscode-cosmosdbgraph
- **Azure Cognitive Search** - ms-azuretools.vscode-azurecognitivesearch
- **Live Video Analytics on IoT Edge (deprecated)** - ms-azuretools.live-video-analytics-edge
- **Remote Repositories (Deprecated)** - ms-vscode.remotehub
- **GitHub Browser** - ms-vscode.github-browser
- **AutoRest** - ms-vscode.autorest
- **Quantum Development Kit (deprecated)** - quantum.quantum-devkit-vscode

---

## Spam/Malicious Extensions Removed

Approximately 80 extensions with names related to "Microsoft Office crack", "Microsoft Toolkit", activation tools, and other pirated software were also filtered out. These were from non-Microsoft publishers but contained "Microsoft" in their names.

---

## Impact

- **Before filtering:** 627 total extensions
- **After filtering:** 492 published extensions
- **Removed:** 135 unpublished extensions (21.5%)
- **404 Links eliminated:** 135 potential broken links

---

## Refactoring Benefits

1. ✅ Eliminated all 404 errors from documentation
2. ✅ Removed deprecated/retired extensions
3. ✅ Filtered out spam/malicious extensions
4. ✅ Ensured all links in documentation are valid
5. ✅ Created cleaner, more accurate reference guide

---

**Generated by:** fetch_all_extensions.ps1 (refactored version)  
**Validation by:** check_links_quick.ps1  
**Documentation:** Microsoft_VSCode_Extensions.md

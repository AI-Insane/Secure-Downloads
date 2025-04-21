# Secure Downloads

***Originally designed by myself to be used by myself for personal use, hoever i have decided to share it and allow its use by those requiring its functions, I offer no support on this script. All information is provided below in terms of whats needed for correct function and results***

**Secure Downloads** is a PowerShell-based tool designed to monitor, scan, and organize your files securely and efficiently. It integrates antivirus tools, supports archive extraction, logs activities, and provides desktop notifications. The tool is configurable via XML and leverages an XSD schema for validation.

---

## Features
- **Real-Time File Monitoring**: Automatically scans and processes files in specified directories.
- **Antivirus Integration**: Scans files for viruses using external antivirus tools.
- **Archive Handling**: Extracts files from archives (e.g., ZIP, RAR).
- **Quarantine Management**: Detects and isolates suspicious files.
- **Desktop Notifications**: Alerts users regarding file events and statuses.
- **Custom Configuration**: Easily modify behavior using an XML configuration file validated by an XSD schema.
- **Self-Repair**: Automatically repairs or regenerates corrupted configuration files.

---

## Project Structure
The project consists of the following main components:

### 1. **PowerShell Script** (`SecureDownloads.ps1`)
The main script that performs the following tasks:
- Monitors the specified download folder.
- Scans files using antivirus tools.
- Organizes files into designated folders.
- Provides notifications and logs file events.

### 2. **XML Configuration File** (`QuarantineConfig.xml`)
Defines the configuration for the script, including:
- Paths to monitor.
- Antivirus command-line arguments.
- Log directories.
- Archive extraction settings.
- Notification preferences.

Example XML:
```xml
<Configuration>
  <MonitorFolder>C:\Downloads</MonitorFolder>
  <LogFolder>C:\Logs</LogFolder>
  <Antivirus>
    <Command>path/to/antivirus.exe</Command>
    <Arguments>--scan --delete</Arguments>
  </Antivirus>
  <Notifications enabled="true" />
</Configuration>
```

### 3. **XSD Schema** (`QuarantineConfig.xsd`)
Ensures that the XML configuration file follows the correct structure and format. This helps validate user-defined configurations before execution.

Example XSD:
```xml
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="Configuration">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="MonitorFolder" type="xs:string" />
        <xs:element name="LogFolder" type="xs:string" />
        <xs:element name="Antivirus">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="Command" type="xs:string" />
              <xs:element name="Arguments" type="xs:string" />
            </xs:sequence>
          </xs:complexType>
        </xs:element>
        <xs:element name="Notifications">
          <xs:complexType>
            <xs:attribute name="enabled" type="xs:boolean" use="required" />
          </xs:complexType>
        </xs:element>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
```

---

## Getting Started

### **Prerequisites**
- PowerShell 5.1 or later.
- An antivirus tool with a command-line interface (e.g., Windows Defender, ClamAV).
- Optional: A ZIP extraction utility if handling archives.

### **Installation**
1. Clone the repository:
   ```bash
   git clone https://github.com/AI-Insane/Secure-Downloads.git
   ```
2. Place the `SecureDownloads.ps1`, `QuarantineConfig.xml`, and `QuarantineConfig.xsd` files in the same directory.

3. Customize the `QuarantineConfig.xml` file to match your system's configuration.

### **Usage**
Run the script in PowerShell:
```powershell
.\SecureDownloads.ps1
```

---

## Configuration

### **XML Configuration Details**
The `QuarantineConfig.xml` file allows you to customize the script's behavior. Below is an explanation of the key elements:
- **`MonitorFolder`**: The folder to monitor for new downloads.
- **`LogFolder`**: The folder where logs will be saved.
- **`Antivirus`**:
  - **`Command`**: Path to the antivirus executable.
  - **`Arguments`**: Command-line arguments to pass to the antivirus tool.
- **`Notifications`**: Enable or disable desktop notifications using the `enabled` attribute.

### **Validating XML**
To validate your XML file against the XSD schema:
1. Use an XML editor or online validator.
2. Ensure the XML follows the structure defined in `QuarantineConfig.xsd`.

---

## Logging
- Log files are saved in the directory specified in the `LogFolder` element of `QuarantineConfig.xml`.
- Logs include details about file scans, errors, and quarantined files.

---

## License
This project is licensed under the [Apache License 2.0](LICENSE).

---

## Contributing
Contributions are welcome! Create a pull request or open an issue to suggest improvements. (As the author, I would kindly request a tag or mention if using this but this is not required)

---

## Disclaimer
This software is provided "AS IS," without warranty of any kind. The authors are not responsible for any issues arising from its use.

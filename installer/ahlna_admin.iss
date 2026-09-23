; Inno Setup script for Ahlna Daquq Admin (Windows)
; Build the Flutter Windows release first:
;   build\windows\x64\runner\Release\ahlna_daquq.exe

[Setup]
AppName=Ahlna Daquq Admin
AppVersion=1.0.3
DefaultDirName={autopf}\AhlnaDaquqAdmin
DefaultGroupName=Ahlna Daquq
OutputDir=dist
OutputBaseFilename=AhlnaDaquqAdminInstaller
Compression=lzma
SolidCompression=yes
SetupIconFile=app_icon.ico
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Ahlna Daquq Admin"; Filename: "{app}\ahlna_daquq.exe"; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"
Name: "{autodesktop}\Ahlna Daquq Admin"; Filename: "{app}\ahlna_daquq.exe"; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon
Name: "{userstartup}\Ahlna Daquq Admin"; Filename: "{app}\ahlna_daquq.exe"; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"
Name: "{group}\Uninstall Ahlna Daquq Admin"; Filename: "{uninstallexe}"

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "AhlnaDaquqAdmin"; ValueData: """{app}\ahlna_daquq.exe"""

[Run]
Filename: "{app}\ahlna_daquq.exe"; Description: "تشغيل التطبيق"; Flags: nowait postinstall skipifsilent

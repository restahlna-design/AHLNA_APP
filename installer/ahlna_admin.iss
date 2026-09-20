; Inno Setup script for Ahlna Daquq Admin (Windows)
; Build the Flutter Windows release first:
;   build\windows\x64\runner\Release\ahlna_daquq.exe

[Setup]
AppName=Ahlna Daquq Admin
AppVersion=1.0.2
DefaultDirName={autopf}\AhlnaDaquqAdmin
DefaultGroupName=Ahlna Daquq
OutputDir=dist
OutputBaseFilename=AhlnaDaquqAdminInstaller
Compression=lzma
SolidCompression=yes
SetupIconFile=..\windows\runner\resources\app_icon.ico
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Ahlna Daquq Admin"; Filename: "{app}\ahlna_daquq.exe"
Name: "{autodesktop}\Ahlna Daquq Admin"; Filename: "{app}\ahlna_daquq.exe"; Tasks: desktopicon
Name: "{group}\Uninstall Ahlna Daquq Admin"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\ahlna_daquq.exe"; Description: "تشغيل التطبيق"; Flags: nowait postinstall skipifsilent

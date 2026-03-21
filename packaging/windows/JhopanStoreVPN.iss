#define MyAppName "JhopanStoreVPN"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "JhopanStore"
#define MyAppExeName "JhopanStoreVPN.exe"
#define MyAppIconFile "..\..\packaging\windows\app.ico"

[Setup]
AppId={{A1F77A8A-9B58-4F95-B5F5-5D2F8A4A91E0}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL=https://github.com/jhopan
AppSupportURL=https://github.com/jhopan
AppUpdatesURL=https://github.com/jhopan
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=..\..\dist\installer\windows
OutputBaseFilename=JhopanStoreVPN-Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
WizardStyle=modern
SetupIconFile={#MyAppIconFile}
UninstallDisplayIcon={app}\app.ico
UninstallDisplayName={#MyAppName}
DisableProgramGroupPage=yes
ChangesEnvironment=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop icon"; GroupDescription: "Additional icons:"
Name: "addtopath"; Description: "Add command to PATH (jhopanstorevpn)"; GroupDescription: "System integration:"

[Files]
Source: "..\..\dist\windows\JhopanStoreVPN.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\dist\windows\xray.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\dist\windows\wintun.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\dist\windows\assets\*"; DestDir: "{app}\assets"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#MyAppIconFile}"; DestDir: "{app}"; DestName: "app.ico"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app.ico"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app.ico"; Tasks: desktopicon

[Registry]
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\{#MyAppExeName}"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\{#MyAppExeName}"; ValueType: string; ValueName: "Path"; ValueData: "{app}"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\jhopanstorevpn.exe"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\jhopanstorevpn.exe"; ValueType: string; ValueName: "Path"; ValueData: "{app}"; Flags: uninsdeletevalue

[Code]
const
  EnvironmentKey = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment';

function AddPath(Path: string): Boolean;
var
  Paths: string;
begin
  Result := True;
  if not RegQueryStringValue(HKLM, EnvironmentKey, 'Path', Paths) then
    Paths := '';

  if Pos(';' + Lowercase(Path) + ';', ';' + Lowercase(Paths) + ';') = 0 then
  begin
    if (Paths <> '') and (Paths[Length(Paths)] <> ';') then
      Paths := Paths + ';';
    Paths := Paths + Path;
    Result := RegWriteStringValue(HKLM, EnvironmentKey, 'Path', Paths);
  end;
end;

function RemovePath(Path: string): Boolean;
var
  Paths: string;
  P: Integer;
begin
  Result := True;
  if not RegQueryStringValue(HKLM, EnvironmentKey, 'Path', Paths) then
    Exit;

  P := Pos(';' + Lowercase(Path) + ';', ';' + Lowercase(Paths) + ';');
  while P > 0 do
  begin
    Delete(Paths, P, Length(Path) + 1);
    P := Pos(';' + Lowercase(Path) + ';', ';' + Lowercase(Paths) + ';');
  end;

  while (Length(Paths) > 0) and (Paths[1] = ';') do
    Delete(Paths, 1, 1);
  while (Length(Paths) > 0) and (Paths[Length(Paths)] = ';') do
    Delete(Paths, Length(Paths), 1);

  Result := RegWriteStringValue(HKLM, EnvironmentKey, 'Path', Paths);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and WizardIsTaskSelected('addtopath') then
    AddPath(ExpandConstant('{app}'));
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    RemovePath(ExpandConstant('{app}'));
end;

procedure BroadcastEnvironmentChange;
var
  ResultCode: Integer;
begin
  Exec('rundll32.exe', 'user32.dll,UpdatePerUserSystemParameters', '', SW_HIDE, ewNoWait, ResultCode);
end;

procedure DeinitializeSetup;
begin
  BroadcastEnvironmentChange;
end;

procedure DeinitializeUninstall;
begin
  BroadcastEnvironmentChange;
end;

#define use_dotnetfx40full

#define MyAppSetupName 'SiQoL (by Renatto Machado)'
#define MyAppVersion '1.0.0.2'
#define MyCompanyName 'Renatto Machado'
#define MyCompanyIncName ''

[Setup]
AppName={#MyAppSetupName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppSetupName} {#MyAppVersion}
AppCopyright=Copyright © 2013 {#MyCompanyIncName}
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyCompanyIncName}
AppPublisher={#MyCompanyIncName}
OutputBaseFilename=Install {#MyAppSetupName} {#MyAppVersion}
DefaultGroupName={#MyAppSetupName}
DefaultDirName={pf}\SiQoL
UninstallDisplayIcon={app}\SiQoL.exe
OutputDir=bin
SourceDir=.
AllowNoIcons=yes
SolidCompression=true
WizardImageFile=.\src\img\wizard_large.bmp
WizardSmallImageFile=.\src\img\wizard_small.bmp
AppID={{16C44CF7-92DE-4AFE-A935-320CDF1DD48F}
InternalCompressLevel=max
ShowLanguageDialog=auto
LanguageDetectionMethod=locale
VersionInfoDescription=Instalador do {#MyAppSetupName}
VersionInfoCopyright={#MyCompanyName}
VersionInfoProductName={#MyAppSetupName}
VersionInfoProductVersion=1.0.0
UninstallDisplayName={#MyAppSetupName}
AppContact=renatto.machado@outlook.com
AppSupportPhone=(62) 3267-1500
SetupIconFile=.\src\img\setup.ico
PrivilegesRequired=admin
ArchitecturesAllowed=x86 x64 ia64
ArchitecturesInstallIn64BitMode=x64 ia64

[Languages]
Name: pt; MessagesFile: compiler:Languages\Portuguese.isl

[Tasks]

[Files]
Source: .\src\PoorMansTSqlFormatterLib35.dll; DestDir: {app}\
Source: .\src\SiQoL.exe; DestDir: {app}\

[Icons]
Name: {commonstartup}\SiQoL; Filename: {app}\SiQoL.exe; WorkingDir: {app}; IconFilename: {app}\SiQoL.ico

[Run]
Filename: {app}\SiQoL.exe; Description: {cm:LaunchProgram,SiQoL}; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: {app}\SiQoL.exe; WorkingDir: {app}; Languages: 

#include "scripts\products.iss"

#include "scripts\products\stringversion.iss"
#include "scripts\products\winversion.iss"
#include "scripts\products\fileversion.iss"
#include "scripts\products\dotnetfxversion.iss"

#ifdef use_dotnetfx40full
#include "scripts\products\dotnetfx40full.iss"
#endif


[CustomMessages]
win_sp_title=Windows %1 Service Pack %2


[Code]
function InitializeSetup(): boolean;
begin
	//init windows version
	initwinversion();

	// if no .netfx 4.0 is found, install the client (smallest)
#ifdef use_dotnetfx40full
	if not netfxinstalled(NetFx40Full, '') then
		dotnetfx40full();
#endif

	Result := true;
end;

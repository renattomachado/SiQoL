#include "isxdl\isxdl.iss"

[CustomMessages]
DependenciesDir=MyProgramDependencies

pt.depdownload_msg=� necess�rio instalar os seguintes aplicativos antes de continuar:%n%n%1%nDeseja baixar e instalar agora?
pt.depdownload_memo_title=Baixar dependencias
pt.depinstall_memo_title=Instalar dependencias
pt.depinstall_title=Instalando dependencias
pt.depinstall_description=Por favor, aguarde at� enquanto o Setup instala as depend�ncias no seu computador.
pt.depinstall_status=Instalando %1...
pt.depinstall_missing=%1 deve ser instalado antes da instala��o continuar. Por favor, instale %1 e execute a instala��o novamente.
pt.depinstall_error=Ocorreu um erro enquanto as depend�ncias eram instaladas. Por favor, reinicie o seu computador e execute o instalador novamente ou instale as seguintes depend�ncias manualmente:%n
pt.isxdl_langfile=portuguese.ini


[Files]
Source: scripts\isxdl\portuguese.ini; Flags: dontcopy

[Code]
const
  MB_ICONINFORMATION = $40;

var
  DataDirPage: TInputDirWizardPage;
  TimePage: TInputQueryWizardPage;


function MessageBox(hWnd: Integer; lpText, lpCaption: AnsiString; uType: Cardinal): Integer;
  external 'MessageBoxA@user32.dll stdcall';

procedure ExitProcess(exitCode:integer);
  external 'ExitProcess@kernel32.dll stdcall';

type
	TProduct = record
		File: String;
		Title: String;
		Parameters: String;
		InstallClean : boolean;
		MustRebootAfter : boolean;
	end;

	InstallResult = (InstallSuccessful, InstallRebootRequired, InstallError);

var
	installMemo, downloadMemo, downloadMessage: string;
	products: array of TProduct;
	delayedReboot: boolean;
	DependencyPage: TOutputProgressWizardPage;


procedure AddProduct(FileName, Parameters, Title, Size, URL: string; InstallClean : boolean; MustRebootAfter : boolean);
var
	path: string;
	i: Integer;
begin
	installMemo := installMemo + '%1' + Title + #13;

	path := ExpandConstant('{src}{\}') + CustomMessage('DependenciesDir') + '\' + FileName;
	if not FileExists(path) then begin
		path := ExpandConstant('{tmp}{\}') + FileName;

		isxdl_AddFile(URL, path);

		downloadMemo := downloadMemo + '%1' + Title + #13;
		downloadMessage := downloadMessage + '	' + Title + ' (' + Size + ')' + #13;
	end;

	i := GetArrayLength(products);
	SetArrayLength(products, i + 1);
	products[i].File := path;
	products[i].Title := Title;
	products[i].Parameters := Parameters;
	products[i].InstallClean := InstallClean;
	products[i].MustRebootAfter := MustRebootAfter;
end;

function SmartExec(prod : TProduct; var ResultCode : Integer) : boolean;
begin
	if (LowerCase(Copy(prod.File,Length(prod.File)-2,3)) = 'exe') then begin
		Result := Exec(prod.File, prod.Parameters, '', SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode);
	end else begin
		Result := ShellExec('', prod.File, prod.Parameters, '', SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode);
	end;
end;

function PendingReboot : boolean;
var	names: String;
begin
	if (RegQueryMultiStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager', 'PendingFileRenameOperations', names)) then begin
		Result := true;
	end else if ((RegQueryMultiStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager', 'SetupExecute', names)) and (names <> ''))  then begin
		Result := true;
	end else begin
		Result := false;
	end;
end;

function InstallProducts: InstallResult;
var
	ResultCode, i, productCount, finishCount: Integer;
begin
	Result := InstallSuccessful;
	productCount := GetArrayLength(products);

	if productCount > 0 then begin
		DependencyPage := CreateOutputProgressPage(CustomMessage('depinstall_title'), CustomMessage('depinstall_description'));
		DependencyPage.Show;

		for i := 0 to productCount - 1 do begin
			if (products[i].InstallClean and (delayedReboot or PendingReboot())) then begin
				Result := InstallRebootRequired;
				break;
			end;

			DependencyPage.SetText(FmtMessage(CustomMessage('depinstall_status'), [products[i].Title]), '');
			DependencyPage.SetProgress(i, productCount);

			if SmartExec(products[i], ResultCode) then begin
				//setup executed; ResultCode contains the exit code
				//MsgBox(products[i].Title + ' install executed. Result Code: ' + IntToStr(ResultCode), mbInformation, MB_OK);
				if (products[i].MustRebootAfter) then begin
					//delay reboot after install if we installed the last dependency anyways
					if (i = productCount - 1) then begin
						delayedReboot := true;
					end else begin
						Result := InstallRebootRequired;
					end;
					break;
				end else if (ResultCode = 0) then begin
					finishCount := finishCount + 1;
				end else if (ResultCode = 3010) then begin
					//ResultCode 3010: A restart is required to complete the installation. This message indicates success.
					delayedReboot := true;
					finishCount := finishCount + 1;
				end else begin
					Result := InstallError;
					break;
				end;
			end else begin
				//MsgBox(products[i].Title + ' install failed. Result Code: ' + IntToStr(ResultCode), mbInformation, MB_OK);
				Result := InstallError;
				break;
			end;
		end;

		//only leave not installed products for error message
		for i := 0 to productCount - finishCount - 1 do begin
			products[i] := products[i+finishCount];
		end;
		SetArrayLength(products, productCount - finishCount);

		DependencyPage.Hide;
	end;
end;

function PrepareToInstall(var NeedsRestart: boolean): String;
var
	i: Integer;
	s: string;
begin
	delayedReboot := false;

	case InstallProducts() of
		InstallError: begin
			s := CustomMessage('depinstall_error');

			for i := 0 to GetArrayLength(products) - 1 do begin
				s := s + #13 + '	' + products[i].Title;
			end;

			Result := s;
			end;
		InstallRebootRequired: begin
			Result := products[0].Title;
			NeedsRestart := true;

			//write into the registry that the installer needs to be executed again after restart
			RegWriteStringValue(HKEY_CURRENT_USER, 'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce', 'InstallBootstrap', ExpandConstant('{srcexe}'));
			end;
	end;
end;

function NeedRestart : boolean;
begin
	if (delayedReboot) then
		Result := true;
end;

function UpdateReadyMemo(Space, NewLine, MemoUserInfoInfo, MemoDirInfo, MemoTypeInfo, MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
var
	s: string;
begin
	if downloadMemo <> '' then
		s := s + CustomMessage('depdownload_memo_title') + ':' + NewLine + FmtMessage(downloadMemo, [Space]) + NewLine;
	if installMemo <> '' then
		s := s + CustomMessage('depinstall_memo_title') + ':' + NewLine + FmtMessage(installMemo, [Space]) + NewLine;

	s := s + MemoDirInfo + NewLine + NewLine + MemoGroupInfo

	if MemoTasksInfo <> '' then
		s := s + NewLine + NewLine + MemoTasksInfo;

	Result := s
end;

function NextButtonClick(CurPageID: Integer): boolean;
var
  ErrorCode: Integer;
begin
	Result := True;
	if CurPageID = wpReady then
	begin
		if downloadMemo <> '' then
		begin
			//change isxdl language only if it is not english because isxdl default language is already english
			if (ActiveLanguage() <> 'en') then
			begin
				ExtractTemporaryFile(CustomMessage('isxdl_langfile'));
				isxdl_SetOption('language', ExpandConstant('{tmp}{\}') + CustomMessage('isxdl_langfile'));
			end;

			if SuppressibleMsgBox(FmtMessage(CustomMessage('depdownload_msg'), [downloadMessage]), mbConfirmation, MB_YESNO, IDYES) = IDNO then
				Result := false
			else if isxdl_DownloadFiles(StrToInt(ExpandConstant('{wizardhwnd}'))) = 0 then
				Result := false;
		end;
	end
	else
	if CurPageID = wpSelectDir then
    begin

	end

    Result := true;
end;

function IsX86: boolean;
begin
	Result := (ProcessorArchitecture = paX86) or (ProcessorArchitecture = paUnknown);
end;

function IsX64: boolean;
begin
	Result := Is64BitInstallMode and (ProcessorArchitecture = paX64);
end;

function IsIA64: boolean;
begin
	Result := Is64BitInstallMode and (ProcessorArchitecture = paIA64);
end;

function GetString(x86, x64, ia64: String): String;
begin
	if IsX64() and (x64 <> '') then begin
		Result := x64;
	end else if IsIA64() and (ia64 <> '') then begin
		Result := ia64;
	end else begin
		Result := x86;
	end;
end;

function GetArchitectureString(): String;
begin
	if IsX64() then begin
		Result := '_x64';
	end else if IsIA64() then begin
		Result := '_ia64';
	end else begin
		Result := '';
	end;
end;

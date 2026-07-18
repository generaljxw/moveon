; installer/setup.iss — MoveOn Windows 安装脚本
; 使用 Inno Setup 6 编译
; 编译命令: "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\setup.iss

[Setup]
AppName=动起来 MoveOn
AppVersion=1.0.0
AppPublisher=MoveOn Team
DefaultDirName={autopf}\MoveOn
DefaultGroupName=动起来 MoveOn
OutputBaseFilename=MoveOn-Setup-1.0.0
; 许可协议文件（可选，后续版本添加）
; LicenseFile=..\LICENSE.txt
WizardStyle=modern
DisableWelcomePage=no
; 默认安装语言：中文
ShowLanguageDialog=no

[Languages]
Name: "chinese"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
; 创建桌面快捷方式，默认勾选
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加图标:"; Flags: checkedonce

[Files]
; Flutter Release 构建产物
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; 开始菜单快捷方式
Name: "{group}\动起来 MoveOn"; Filename: "{app}\moveon.exe"
; 卸载快捷方式
Name: "{group}\卸载 MoveOn"; Filename: "{uninstallexe}"
; 桌面快捷方式
Name: "{commondesktop}\动起来 MoveOn"; Filename: "{app}\moveon.exe"; Tasks: desktopicon

[Run]
; 安装完成后运行应用，默认勾选
Filename: "{app}\moveon.exe"; Description: "运行 MoveOn"; Flags: nowait postinstall skipifsilent unchecked

[UninstallDelete]
; 卸载时清理
Type: filesandordirs; Name: "{app}"

[Code]
// 取消安装确认对话框（SR1 3a/5b/7c/8a）
procedure CancelButtonClick(CurPageID: Integer; var Cancel, Confirm: Boolean);
begin
  Confirm := True;
  if MsgBox('安装尚未完成，是否确认退出安装？', mbConfirmation, MB_YESNO) = IDNO then
    Cancel := False;
end;

// 安装完成页面询问是否保留用户数据（SR3 5a）
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    if MsgBox('是否保留用户数据（练习模组等）？', mbConfirmation, MB_YESNO) = IDYES then
      // 保留用户数据：不删除 AppData 中的数据库文件
    else
      // 后续版本：清理 AppData/Local/MoveOn 目录
  end;
end;

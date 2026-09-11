Unicode true
RequestExecutionLevel user

!include "MUI2.nsh"
!include "FileFunc.nsh"

!ifndef ARCHIFY_STAGE_DIR
  !error "ARCHIFY_STAGE_DIR define is required"
!endif
!ifndef ARCHIFY_OUTPUT_FILE
  !error "ARCHIFY_OUTPUT_FILE define is required"
!endif
!ifndef ARCHIFY_VERSION
  !error "ARCHIFY_VERSION define is required"
!endif

Name "Archify"
OutFile "${ARCHIFY_OUTPUT_FILE}"
InstallDir "$PROFILE\.raven\workspace\skills\archify"
InstallDirRegKey HKCU "Software\Archify" "InstallDir"
BrandingText "Archify Windows Installer"
ShowInstDetails show
ShowUninstDetails show

!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Var ParentDir
Var BackupDir
Var UninstallerPath

Section "Install"
  SetShellVarContext current
  ${GetParent} "$INSTDIR" $ParentDir
  StrCpy $BackupDir "$INSTDIR.backup"
  StrCpy $UninstallerPath "$ParentDir\archify-uninstall.exe"

  CreateDirectory "$ParentDir"
  IfFileExists "$INSTDIR\*.*" 0 +6
    DetailPrint "Backing up existing installation to $BackupDir"
    RMDir /r "$BackupDir"
    Rename "$INSTDIR" "$BackupDir"
    IfErrors 0 +2
      Abort "Failed to back up the existing Archify installation at $INSTDIR"

  SetOutPath "$INSTDIR"
  File /r "${ARCHIFY_STAGE_DIR}/*"

  WriteUninstaller "$UninstallerPath"
  WriteRegStr HKCU "Software\Archify" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Archify" "DisplayName" "Archify"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Archify" "DisplayVersion" "${ARCHIFY_VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Archify" "Publisher" "tt-a1i"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Archify" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Archify" "UninstallString" '"$UninstallerPath"'
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Archify" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Archify" "NoRepair" 1
SectionEnd

Section "Uninstall"
  SetShellVarContext current
  ReadRegStr $0 HKCU "Software\Archify" "InstallDir"
  StrCmp $0 "" 0 +2
    StrCpy $0 "$PROFILE\.raven\workspace\skills\archify"
  ${GetParent} "$0" $1
  Delete /REBOOTOK "$1\archify-uninstall.exe"
  RMDir /r "$0"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Archify"
  DeleteRegKey HKCU "Software\Archify"
SectionEnd

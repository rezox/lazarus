{
  Copyright (C) 2013 Tim Sinaeve tim.sinaeve@gmail.com

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}

unit Notepas_Forms_Main;

{$mode delphi}

//*****************************************************************************

interface

uses
  Classes, SysUtils, Forms, Controls, ComCtrls, ActnList, ExtCtrls,  Menus,
  Buttons, StdCtrls,

  LResources,

  EditBtn,

  simpleipc,

  ts_components_docking, ts_components_docking_storage,
  // for debugging
  sharedlogger,
  {$ifdef windows}
  ipcchannel,
  {$endif}

  SynEdit,

  ts_Editor_Interfaces;

{
  KNOWN PROBLEMS
    - Close all but current tab does not work in all cases
    - encoding support needs to be implemented
    - support for alternative line endings needs to be implemented
    - saving loading in different encodings

  TODO
    - Dequote lines in code shaper
    - cheat panel with shortcut/button overview for all supported actions

  IDEAS
    - surround with function for selected block (as in Notepad2)
    - duplicate lines
    - draw tables
    - status bar builder
}

//=============================================================================

type

  { TfrmMain }

  TfrmMain = class(TForm)
    {$region 'designer controls' /fold}
    aclMain               : TActionList;
    actAbout              : TAction;
    actCloseAllOtherPages : TAction;
    actInspect            : TAction;
    btnEncoding           : TSpeedButton;
    btnFileName           : TSpeedButton;
    btnHighlighter        : TSpeedButton;
    btnLineBreakStyle     : TSpeedButton;
    btnSelectionMode      : TSpeedButton;
    imlMain               : TImageList;
    lblHeader             : TLabel;
    MenuItem1: TMenuItem;
    mnuMain               : TMainMenu;
    pnlSelectionMode      : TPanel;
    pnlTop                : TPanel;
    pnlTool               : TPanel;
    pnlLineBreakStyle     : TPanel;
    pnlFileName           : TPanel;
    pnlHighlighter        : TPanel;
    pnlEncoding           : TPanel;
    pnlModified           : TPanel;
    pnlViewerCount        : TPanel;
    pnlSize               : TPanel;
    pnlPosition           : TPanel;
    pnlInsertMode         : TPanel;
    pnlStatusBar          : TPanel;
    btnCloseToolView      : TSpeedButton;
    splVertical           : TSplitter;
    tlbMain               : TToolBar;
    {$endregion}

    {$region 'action handlers' /fold}
    procedure actAboutExecute(Sender: TObject);
    {$endregion}

    {$region 'event handlers' /fold}
    procedure ActionListExecute(AAction: TBasicAction; var Handled: Boolean);
    procedure AHSActivateSite(Sender: TObject);
    procedure AnchorDockPageControlChanging(Sender: TObject; var AllowChange: Boolean);
    procedure btnEncodingClick(Sender: TObject);
    procedure btnFileNameClick(Sender: TObject);
    procedure btnHighlighterClick(Sender: TObject);
    procedure btnLineBreakStyleClick(Sender: TObject);
    procedure btnSelectionModeClick(Sender: TObject);
    procedure btnCloseToolViewClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure FormWindowStateChange(Sender: TObject);
    {$endregion}
  private
    {$region 'property access methods' /fold}
    function GetActions: IEditorActions;
    function GetEditor: IEditorView;
    function GetManager: IEditorManager;
    function GetMenus: IEditorMenus;
    function GetSettings: IEditorSettings;
    function GetViews: IEditorViews;
    {$endregion}

    procedure InitDebugAction(const AActionName: string);

    // event handlers
    procedure EVActiveViewChange(Sender: TObject);
    procedure EVAddEditorView(Sender: TObject; AEditorView: IEditorView);
    procedure EVStatusChange(Sender: TObject; Changes: TSynStatusChanges);
    procedure EVOpenOtherInstance(Sender: TObject; const AParams: array of string);

    procedure EditorSettingsChangedHandler(Sender: TObject);

  protected
    procedure AddDockingMenuItems;
    procedure AddMainMenus;
    procedure AssignEvents;
    procedure ConfigureAvailableActions;
    procedure UpdateCaptions;
    procedure UpdateStatusBar;
    procedure UpdateEditorViewCaptions;

    procedure DisplayToolForm(
            AAction   : TAction;
      const AFormName : string;
            ASetFocus : Boolean = False
    );

  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure UpdateActions; override;

    property Manager: IEditorManager
      read GetManager;

    property Editor: IEditorView
      read GetEditor;

    property Actions: IEditorActions
      read GetActions;

    property Views: IEditorViews
      read GetViews;

    property Menus: IEditorMenus
      read GetMenus;

    property Settings: IEditorSettings
      read GetSettings;
  end;

var
  frmMain: TfrmMain;

//*****************************************************************************

implementation

{$R *.lfm}

uses
  StrUtils, FileUtil, TypInfo,

  SynEditTypes,

  ts_Core_Utils, ts_Core_VersionInfo, ts_Core_Helpers,

  ts_Editor_Manager, ts_Editor_Resources, ts_Editor_AboutDialog,
  ts_Editor_Helpers;

//=============================================================================

resourcestring
  SModified              = 'Modified';
  SToolformDoesNotExist  = 'Toolform with name %s does not exist!';

{$region 'construction and destruction' /fold}
//*****************************************************************************
// construction and destruction                                          BEGIN
//*****************************************************************************

procedure TfrmMain.AfterConstruction;
var
  I  : Integer;
  EV : IEditorEvents;
  V  : IEditorView;
  S  : string;
begin
  inherited AfterConstruction;
  Manager.PersistSettings := True;
  mnuMain.Items.Clear;
  ConfigureAvailableActions;
  DockMaster.MakeDockSite(Self, [akTop, akBottom, akRight, akLeft], admrpChild);
  AddDockingMenuItems;
  AddStandardEditorToolbarButtons(tlbMain);
  AddMainMenus;
  Settings.FormSettings.AssignTo(Self);
  if Settings.DebugMode then
  begin
    // for debugging
    Logger.MaxStackCount := 5; // more than 5 give problems when exception is raised when stackinfo is not available
    AddEditorDebugMenu(mnuMain);
  end;
  Manager.Actions['actNewSharedView'].Visible := Settings.DebugMode;
  pnlViewerCount.Visible := Settings.DebugMode;

  EV := Manager.Events;
  EV.OnActiveViewChange  := EVActiveViewChange;
  EV.OnStatusChange      := EVStatusChange;
  EV.OnOpenOtherInstance := EVOpenOtherInstance;
  EV.OnAddEditorView     := EVAddEditorView;
  Settings.AddEditorSettingsChangedHandler(EditorSettingsChangedHandler);
  if ParamCount > 0 then
  begin
    for I := 1 to Paramcount do
    begin
      S := ParamStr(I);
      if I = 1 then
        V := Manager.OpenFile(S)
      else
        Manager.OpenFile(S);
    end;
  end
  else
  begin
    V := Manager.NewFile(SNewEditorViewFileName);
  end;
  pnlHighlighter.PopupMenu    := Menus.HighlighterPopupMenu;
  btnHighlighter.PopupMenu    := Menus.HighlighterPopupMenu;
  btnEncoding.PopupMenu       := Menus.EncodingPopupMenu;
  btnLineBreakStyle.PopupMenu := Menus.LineBreakStylePopupMenu;
  btnSelectionMode.PopupMenu  := Menus.SelectionModePopupMenu;
  Manager.Actions.ActionList.OnExecute  := ActionListExecute;
  Manager.ActiveView := V;
  DoubleBuffered := True;
end;

procedure TfrmMain.BeforeDestruction;
begin
  Settings.FormSettings.Assign(Self);
  inherited BeforeDestruction;
end;

//*****************************************************************************
// construction and destruction                                            END
//*****************************************************************************
{$endregion}

{$region 'property access mehods' /fold}
//*****************************************************************************
// property access methods                                               BEGIN
//*****************************************************************************

function TfrmMain.GetManager: IEditorManager;
begin
  Result := EditorManager;
end;

function TfrmMain.GetActions: IEditorActions;
begin
  Result := Manager.Actions;
end;

function TfrmMain.GetEditor: IEditorView;
begin
  Result := Manager.ActiveView;
end;

function TfrmMain.GetMenus: IEditorMenus;
begin
  Result := Manager.Menus;
end;

function TfrmMain.GetSettings: IEditorSettings;
begin
  Result := Manager.Settings;
end;

function TfrmMain.GetViews: IEditorViews;
begin
  Result := Manager.Views;
end;

//*****************************************************************************
// property access methods                                                 END
//*****************************************************************************
{$endregion}

{$region 'action handlers' /fold}
//*****************************************************************************
// action handlers                                                       BEGIN
//*****************************************************************************

procedure TfrmMain.actAboutExecute(Sender: TObject);
begin
  ShowAboutDialog;  // not shown -> manager shows about dialog for the moment
end;

//*****************************************************************************
// action handlers                                                         END
//*****************************************************************************
{$endregion}

{$region 'event handlers' /fold}
//*****************************************************************************
// event handlers                                                        BEGIN
//*****************************************************************************

{ TODO: needs to be refactored. }

procedure TfrmMain.ActionListExecute(AAction: TBasicAction; var Handled: Boolean);
var
  A : TAction;
  S : string;
begin
  A := TAction(AAction);
  S := A.Name;
  if S = 'actShapeCode' then
    DisplayToolForm(A, 'frmCodeShaper')
  else if S = 'actSearch' then
    DisplayToolForm(A, 'frmSearchForm', True)
  else if S = 'actSearchReplace' then
    DisplayToolForm(A, 'frmSearchForm', True)
  else if S = 'actShowPreview' then
    DisplayToolForm(A, 'frmPreview')
  else if S = 'actTestForm' then
    DisplayToolForm(A, 'frmTest')
  else if S = 'actSelectionInfo' then
    DisplayToolForm(A, 'frmSelectionInfo')
  else if S = 'actAlignSelection' then
    DisplayToolForm(A, 'frmAlignLines')
  else if S = 'actXMLTree' then
    DisplayToolForm(A, 'frmXmlTree');
{$region 'docking support' /fold}
/// below works to support docking toolforms!
{
  below works to support docking toolforms!
  ADHS: TAnchorDockHostSite;

  if AAction.Name = 'actFindNext' then
  begin
    Actions.FindReplaceDialog;
    DockMaster.MakeDockable(Actions.FindReplaceDialog);
    DockMaster.ManualDock(DockMaster.GetAnchorSite(Actions.FindReplaceDialog),Self, alRight);
  end;
  DockMaster.BeginUpdate;
  DockMaster.MakeDockable(CodeShaperForm.CodeShaperForm);
  ADHS := DockMaster.GetAnchorSite(CodeShaperForm.CodeShaperForm);
  ADHS.BeginUpdateLayout;
  DockMaster.ManualDock(ADHS, FToolForm, alLeft);
  ADHS.EndUpdateLayout;
  DockMaster.EndUpdate;
}
{$endregion}
end;

procedure TfrmMain.AHSActivateSite(Sender: TObject);
var
  AHS : TAnchorDockHostSite;
  C   : TControl;
begin
  AHS := TAnchorDockHostSite(Sender);
  if AHS.SiteType = adhstOneControl then
  begin
    C := DockMaster.GetControl(AHS);
    if C is IEditorView then
      (C as IEditorView).Activate;
  end;
end;

procedure TfrmMain.EVStatusChange(Sender: TObject; Changes: TSynStatusChanges);
begin
  if scModified in Changes then
  begin
    // TODO: draw icon in tabsheet indicating that there was a change
  end;
end;

procedure TfrmMain.btnEncodingClick(Sender: TObject);
begin
  btnEncoding.PopupMenu.PopUp;
end;

procedure TfrmMain.btnFileNameClick(Sender: TObject);
begin
{$ifdef windows}
  ExploreFile(Editor.FileName);
{$endif}
end;

procedure TfrmMain.btnHighlighterClick(Sender: TObject);
begin
  btnHighlighter.PopupMenu.PopUp;
end;

procedure TfrmMain.btnLineBreakStyleClick(Sender: TObject);
begin
  btnLineBreakStyle.PopupMenu.PopUp;
end;

procedure TfrmMain.btnSelectionModeClick(Sender: TObject);
begin
  btnSelectionMode.PopupMenu.PopUp;
end;

procedure TfrmMain.EVActiveViewChange(Sender: TObject);
begin
  if Assigned(Editor) then
    DockMaster.MakeVisible(Editor.Form, True);
end;

procedure TfrmMain.EVOpenOtherInstance(Sender: TObject;
  const AParams: array of string);
var
  I : Integer;
  S : string;
  V : IEditorView;
begin
  for I := Low(AParams) to High(AParams) do
  begin
    S := AParams[I];
    if I = Low(AParams) then
      V := Manager.OpenFile(S)
    else
      Manager.OpenFile(S);
  end;
  V.Activate;
end;

procedure TfrmMain.EditorSettingsChangedHandler(Sender: TObject);
begin
  WindowState := Settings.FormSettings.WindowState;
  FormStyle := Settings.FormSettings.FormStyle;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  CanClose := Actions['actExit'].Execute;
end;

procedure TfrmMain.FormDropFiles(Sender: TObject;
  const FileNames: array of string);
var
  S : string;
  V : IEditorView;
  I : Integer;
begin
  if Assigned(Editor) then
    V := Editor;
  DisableAutoSizing;
  try
    for I := Low(FileNames) to High(FileNames) do
    begin
      S := FileNames[I];
      if I = Low(FileNames) then
        V := Manager.OpenFile(S)
      else
        Manager.OpenFile(S)
    end;
  finally
    EnableAutoSizing;
  end;
  V.Activate;
end;

procedure TfrmMain.FormWindowStateChange(Sender: TObject);
begin
  Settings.FormSettings.WindowState := WindowState;
end;

procedure TfrmMain.btnCloseToolViewClick(Sender: TObject);
var
  I : Integer;
begin
  pnlTool.Visible := False;
  splVertical.Visible := False;
  for I := 0 to Manager.ToolViews.Count - 1 do
  begin
    Manager.ToolViews.Views[I].Visible := False;
  end;
end;

procedure TfrmMain.EVAddEditorView(Sender: TObject; AEditorView: IEditorView);
var
  V   : IEditorView;
  AHS : TAnchorDockHostSite;
begin
  DisableAutoSizing;
  try
    V := AEditorView;
    V.Form.DisableAutoSizing;
    try
      DockMaster.MakeDockable(V.Form);
      AHS := DockMaster.GetAnchorSite(V.Form);
      if Assigned(AEditorView.MasterView) then
      begin
        V.Form.Width := Self.Width div 2;
        DockMaster.ManualDock(
          AHS,
          DockMaster.GetAnchorSite(V.MasterView.Form),
          alRight,
          AEditorView.MasterView.Form
        );
        AEditorView.MasterView.Form.Width := Self.Width div 2;
      end
      else
      begin
        DockMaster.ManualDock(AHS, Self, alClient);
        AHS.Header.Visible := Views.Count > 1;
        AHS.Header.HeaderPosition := adlhpTop;
      end;
      AHS.OnActivateSite := AHSActivateSite;
      V.OnDropFiles := FormDropFiles;
      V.Editor.PopupMenu := Menus.EditorPopupMenu;
      UpdateEditorViewCaptions;
    finally
      V.Form.EnableAutoSizing;
    end;
  finally
    EnableAutoSizing;
  end;
end;

procedure TfrmMain.AnchorDockPageControlChanging(Sender: TObject;
  var AllowChange: Boolean);
begin
  (Sender as TAnchorDockPageControl).GetActiveSite.Show;
end;

//*****************************************************************************
// event handlers                                                          END
//*****************************************************************************
{$endregion}

{$region 'private methods' /fold}
//*****************************************************************************
// private methods                                                       BEGIN
//*****************************************************************************

procedure TfrmMain.InitDebugAction(const AActionName: string);
begin
  Actions[AActionName].Enabled := Settings.DebugMode;
  Actions[AActionName].Visible := Settings.DebugMode;
end;

//*****************************************************************************
// private methods                                                         END
//*****************************************************************************
{$endregion}

{$region 'protected methods' /fold}
//*****************************************************************************
// protected methods                                                     BEGIN
//*****************************************************************************

procedure TfrmMain.AddDockingMenuItems;
var
  MI  : TMenuItem;
  PPM : TPopupMenu;
begin
  PPM := DockMaster.GetPopupMenu;
  MI := TMenuItem.Create(PPM);
  MI.Action := Actions['actCloseOthers'];
  PPM.Items.Add(MI);
end;

procedure TfrmMain.AddMainMenus;
begin
  mnuMain.Images := EditorManager.Actions.ActionList.Images;
  AddEditorFileMenu(mnuMain);
  AddEditorEditMenu(mnuMain);
  AddEditorSelectionMenu(mnuMain);
  AddEditorInsertMenu(mnuMain);
  AddEditorSearchMenu(mnuMain);
  AddEditorViewMenu(mnuMain);
  AddEditorToolsMenu(mnuMain);
  AddEditorSettingsMenu(mnuMain);
  AddEditorHighlightersMenu(mnuMain);
  AddEditorHelpMenu(mnuMain);
end;

procedure TfrmMain.AssignEvents;
var
  C: TComponent;
  I: Integer;
begin
  for I := 0 to DockMaster.ComponentCount - 1 do
  begin
    C := DockMaster.Components[I];
    if C is TAnchorDockPageControl then
      TAnchorDockPageControl(C).OnChanging := AnchorDockPageControlChanging;
  end;
end;

{ Hide actions that are not (fully) implemented or supported. }

procedure TfrmMain.ConfigureAvailableActions;
begin
  // TODO: maintain a list with Available actions in the manager instance !!!
  InitDebugAction('actMonitorChanges');
  InitDebugAction('actShowActions');
  InitDebugAction('actLoadHighlighterFromFile');
  InitDebugAction('actInspect');
  InitDebugAction('actSortSelection');
  InitDebugAction('actPrint');
  InitDebugAction('actPrintPreview');
  InitDebugAction('actPageSetup');
  InitDebugAction('actNewSharedView');
end;

procedure TfrmMain.UpdateCaptions;
var
  S : string;
begin
  S := ExtractFileNameOnly(Application.ExeName);
  if FileExists(Editor.FileName) then
    Caption := Format('%s - %s',  [Editor.FileName, S])
  else
    Caption := S;
  Application.Title := Caption;
end;

procedure TfrmMain.UpdateStatusBar;
var
  S : string;
begin
  pnlPosition.Caption :=
    Format('%1d:%1d / %1d | %1d', [
      Editor.CaretX,
      Editor.CaretY,
      Editor.Lines.Count,
      Editor.SelStart
    ]);


  pnlViewerCount.Caption := IntToStr(Views.Count);
  pnlSize.Caption := FormatByteText(Editor.TextSize);

  if Assigned(Editor.HighlighterItem) then
    btnHighlighter.Caption := Editor.HighlighterItem.Description;
  if Editor.InsertMode then
    pnlInsertMode.Caption := 'INS'
  else
    pnlInsertMode.Caption := 'OVR';
  btnFileName.Caption := Editor.FileName;
  btnFileName.Hint := Editor.FileName;
  btnEncoding.Caption := UpperCase(Editor.Encoding);
  btnLineBreakStyle.Caption := Editor.LineBreakStyle;
  S := GetEnumName(TypeInfo(TSynSelectionMode), Ord(Editor.SelectionMode));
  S := System.Copy(S, 3, Length(S));
  btnSelectionMode.Caption := S;
  pnlModified.Caption := IfThen(Editor.Modified, SModified, '');
  OptimizeWidth(pnlViewerCount);
  OptimizeWidth(pnlPosition);
  OptimizeWidth(pnlSize);
  OptimizeWidth(pnlInsertMode);
  OptimizeWidth(pnlModified);

  pnlHighlighter.Width :=
    GetTextWidth(btnHighlighter.Caption, btnHighlighter.Font) + 10;
  pnlEncoding.Width := GetTextWidth(btnEncoding.Caption, btnEncoding.Font) + 10;
  pnlSelectionMode.Width :=
    GetTextWidth(btnSelectionMode.Caption, btnSelectionMode.Font) + 10;
  pnlFileName.Width := GetTextWidth(btnFileName.Caption, btnFileName.Font) + 10;
  pnlLineBreakStyle.Width :=
    GetTextWidth(btnLineBreakStyle.Caption, btnLineBreakStyle.Font) + 10;
end;

procedure TfrmMain.UpdateEditorViewCaptions;
var
  V : IEditorView;
  I : Integer;
begin
  for I := 0 to Views.Count - 1 do
  begin
    V := Views[I];
    V.Form.Caption := ExtractFileName(V.FileName);
  end;
end;

procedure TfrmMain.DisplayToolForm(AAction: TAction; const AFormName: string;
  ASetFocus: Boolean);
var
  TV : IEditorToolView;
begin
  TV := EditorManager.ToolViews[AFormName];
  if Assigned(TV) then
  begin
    lblHeader.Caption := TV.Form.Caption;
    AssignFormParent(TV.Form, pnlTool);
    TV.Visible := AAction.Checked;
    pnlTool.Visible := AAction.Checked;
    splVertical.Visible := AAction.Checked;
    if TV.Visible then
      TV.UpdateView;
    if ASetFocus and TV.Form.CanFocus then
      TV.Form.SetFocus;
  end
  else
    raise Exception.CreateFmt(SToolformDoesNotExist, [AFormName]);
end;

procedure TfrmMain.UpdateActions;
begin
  inherited UpdateActions;
  if Assigned(Manager.ActiveView) then
  begin
    UpdateCaptions;
    UpdateStatusBar;
  end;
  if Assigned(Settings) then
  begin

  end;
end;

//*****************************************************************************
// protected methods                                                       END
//*****************************************************************************
{$endregion}

initialization
{$I notepas_forms_main.lrs}
{$ifdef windows}
  Logger.Channels.Add(TIPCChannel.Create);
{$endif}

end.

{
  Copyright (C) 2013-2018 Tim Sinaeve tim.sinaeve@gmail.com

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

unit ts.Editor.ScriptEditor.ToolView;

{$MODE DELPHI}

interface

uses
  Controls, ExtCtrls, ActnList, ComCtrls,

  ts.Editor.ToolView.Base, ts.Editor.Interfaces;

type
  TfrmScriptEditor = class(TCustomEditorToolView, IEditorToolView)
    aclMain    : TActionList;
    actExecute : TAction;
    imlMain    : TImageList;
    pnlLeft    : TPanel;
    pnlRight   : TPanel;
    pnlBottom  : TPanel;
    pnlMain    : TPanel;
    tlbMain    : TToolBar;
    btnExecute : TToolButton;

    procedure actExecuteExecute(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private
    FScriptEditor        : IEditorView;
    FScriptEditorManager : IEditorManager;

  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

  end;

implementation

{$R *.lfm}

uses
  LazFileUtils,

  ts.Editor.Factories;

{$REGION 'construction and destruction'}
procedure TfrmScriptEditor.AfterConstruction;
begin
  inherited AfterConstruction;
  // The script editor uses a dedicated editor manager
  FScriptEditorManager :=
    TEditorFactories.CreateManager(Self, Manager.Settings);
end;

procedure TfrmScriptEditor.BeforeDestruction;
begin
  FScriptEditor := nil;
  FScriptEditorManager := nil;
  inherited BeforeDestruction;
end;
{$ENDREGION}

{$REGION 'event handlers'}
procedure TfrmScriptEditor.FormShow(Sender: TObject);
begin
  if not Assigned(FScriptEditor) then
  begin
    FScriptEditor := TEditorFactories.CreateView(
      pnlLeft,
      FScriptEditorManager,
      'ScriptEditor',
      '',
      'PAS'
    );
  end;

  if FileExistsUTF8('notepas.dws') then
    FScriptEditor.Load('notepas.dws');
end;
{$ENDREGION}

{$REGION 'action handlers'}
procedure TfrmScriptEditor.actExecuteExecute(Sender: TObject);
begin
  //
end;
{$ENDREGION}

end.


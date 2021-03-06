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

unit SnippetSource.Forms.SettingsDialog;

{$MODE DELPHI}

{ Manages settings for SnippetSource. }

interface

uses
  Classes, SysUtils, DB, FileUtil, Forms, Controls, Graphics, Dialogs,
  ComCtrls, StdCtrls, ActnList,

  RTTICtrls, DBGrids, ExtCtrls, Buttons, EditBtn, Grids,

  VirtualTrees,

  ts.RichEditor.Interfaces,

  SnippetSource.Interfaces;

type

  { TfrmSettingsDialog }

  TfrmSettingsDialog = class(TForm)
    {$REGION 'designer controls'}
    aclMain                   : TActionList;
    actCreateNewDatabase      : TAction;
    actDeleteDatabase         : TAction;
    actClose                  : TAction;
    actDatabaseIntegrityCheck : TAction;
    actDatabaseVacuum         : TAction;
    actDataBaseShrinkMemory   : TAction;
    actOpenDatabase           : TAction;
    actOpenGlyphs             : TAction;
    actRefreshGlyphs          : TAction;
    btnCreateNewDatabase      : TBitBtn;
    btnDatabaseIntegrityCheck : TBitBtn;
    btnClose                  : TBitBtn;
    btnDatabaseShrinkMemory   : TBitBtn;
    btnDatabaseVacuum         : TBitBtn;
    btnDeleteDatabase         : TBitBtn;
    btnOpenDatabase           : TBitBtn;
    btnOpenGlyphs             : TButton;
    btnRefresh                : TButton;
    cbxImageList              : TComboBox;
    dlgOpen                   : TOpenDialog;
    dscGlyph                  : TDatasource;
    dscHighlighter            : TDatasource;
    edtDatabaseFile           : TFileNameEdit;
    grdGlyph                  : TDBGrid;
    grdHighlighters           : TDBGrid;
    grdDBInfo                 : TStringGrid;
    grpDatabaseInfo           : TGroupBox;
    grpLayout                 : TGroupBox;
    Highlighters              : TTabSheet;
    lblDataBaseFile           : TLabel;
    pnlBottom                 : TPanel;
    pgcMain                   : TPageControl;
    tsApplicationSettings     : TTabSheet;
    tsDataBase                : TTabSheet;
    tsImages                  : TTabSheet;
    vstImageList              : TVirtualStringTree;
    {$ENDREGION}

    procedure actCloseExecute(Sender: TObject);
    procedure actCreateNewDatabaseExecute(Sender: TObject);
    procedure actDatabaseIntegrityCheckExecute(Sender: TObject);
    procedure actDataBaseShrinkMemoryExecute(Sender: TObject);
    procedure actDatabaseVacuumExecute(Sender: TObject);
    procedure actDeleteDatabaseExecute(Sender: TObject);
    procedure actOpenDatabaseExecute(Sender: TObject);
    procedure actOpenGlyphsExecute(Sender: TObject);
    procedure actRefreshGlyphsExecute(Sender: TObject);

    procedure cbxImageListDrawItem(
      Control : TWinControl;
      Index   : Integer;
      ARect   : TRect;
      State   : TOwnerDrawState
    );
    procedure chkAutomaticIndexClick(Sender: TObject);
    procedure dscGlyphStateChange(Sender: TObject);
    procedure dscGlyphUpdateData(Sender: TObject);
    procedure edtDatabaseFileButtonClick(Sender: TObject);
    procedure pgcMainChange(Sender: TObject);

    procedure vstImageListAfterCellPaint(
      Sender         : TBaseVirtualTree;
      TargetCanvas   : TCanvas;
      Node           : PVirtualNode;
      Column         : TColumnIndex;
      const CellRect : TRect
    );
    procedure vstImageListGetText(
      Sender       : TBaseVirtualTree;
      Node         : PVirtualNode;
      Column       : TColumnIndex;
      TextType     : TVSTTextType;
      var CellText : string
    );

  private
    FData              : IInterface;
    FRichEditorManager : IRichEditorManager;
    FRichEditor        : IRichEditorView;

    function GetConnection: IConnection;
    function GetGlyphDS: TDataSet;
    function GetSQLite: ISQLite;

    procedure LoadImage(const AFileName, AFieldName: string);

    procedure UpdateDataBaseInfo;

  public
    constructor Create(
      AOwner : TComponent;
      AData  : IInterface
    ); reintroduce; virtual;

    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure UpdateActions; override;


    property Connection: IConnection
      read GetConnection;

    property GlyphDS: TDataSet
      read GetGlyphDS;

    property SQLite: ISQLite
      read GetSQLite;

  end;

procedure ExecuteSettingsDialog(const AData: IInterface);

implementation

{$R *.lfm}

uses
  ts.Core.Utils,

  SnippetSource.Resources;

var
  FSettings: TfrmSettingsDialog;

procedure ExecuteSettingsDialog(const AData: IInterface);
begin
  if not Assigned(FSettings) then
    FSettings := TfrmSettingsDialog.Create(Application, AData);
  FSettings.ShowModal;
end;

{$REGION 'construction and destruction'}
constructor TfrmSettingsDialog.Create(AOwner: TComponent; AData: IInterface);
begin
  inherited Create(AOwner);
  FData := AData;
  dscGlyph.DataSet := (FData as IGlyphs).GlyphDataSet;
//  grdGlyph.Images := (FData as IGlyphs).GlyphList;
//  grdGlyph.Header.Columns[3].MaxWidth := 50;
  //dscHighlighter.DataSet := (FData as IHighlighters).HighlighterDataSet;
end;

procedure TfrmSettingsDialog.AfterConstruction;
var
  I: Integer;
begin
  inherited AfterConstruction;
  edtDatabaseFile.FileName := Connection.FileName;
  vstImageList.RootNodeCount :=  (FData as IGlyphs).ImageList.Count;
  cbxImageList.Clear;
  for I := 0 to (FData as IGlyphs).ImageList.Count - 1 do
  begin
    cbxImageList.AddItem('', nil);
  end;
  UpdateDataBaseInfo;
end;

procedure TfrmSettingsDialog.BeforeDestruction;
begin
  FData := nil;
  inherited BeforeDestruction;
end;
{$ENDREGION}

{$REGION 'property access mehods'}
function TfrmSettingsDialog.GetConnection: IConnection;
begin
  Result := FData as IConnection;
end;

function TfrmSettingsDialog.GetGlyphDS: TDataSet;
begin
  Result := (FData as IGlyphs).GlyphDataSet;
end;

function TfrmSettingsDialog.GetSQLite: ISQLite;
begin
  Result := FData as ISQLite;
end;
{$ENDREGION}

{$REGION 'action handlers'}
procedure TfrmSettingsDialog.actOpenDatabaseExecute(Sender: TObject);
begin
  Connection.FileName := edtDatabaseFile.FileName;
end;

procedure TfrmSettingsDialog.actOpenGlyphsExecute(Sender: TObject);
var
  sFile: string;
  sExt : string;
begin
  if dlgOpen.Execute then
  begin
    for sFile in dlgOpen.Files do
    begin
      if FileExists(sFile) then
      begin
       // Sender.InsertNode(Sender.DropTargetNode, AAttachMode);
        if not (GlyphDS.State in dsEditModes) then
          GlyphDS.Append;
        LoadImage(sFile, 'Image');
        sExt := ExtractFileExt(sFile);
        sExt := LowerCase(StringReplace(sExt, '.', '', []));
        //GlyphDS.FieldByName('ImageType').AsString := sExt;
        GlyphDS.FieldByName('Name').AsString := ExtractFileName(sFile);
        //GlyphDS.FieldByName('ParentID').AsInteger := iParent;
        //GlyphDS.FieldByName('NodeType').AsInteger := 0;
        GlyphDS.Post;
      end;
    end;
  end;
end;

procedure TfrmSettingsDialog.actRefreshGlyphsExecute(Sender: TObject);
begin
  GlyphDS.Refresh;
  //(FData as IGlyphs).LoadGlyphs;
  vstImageList.RootNodeCount :=  (FData as IGlyphs).ImageList.Count;
end;

procedure TfrmSettingsDialog.actCreateNewDatabaseExecute(Sender: TObject);
begin
  Connection.FileName := edtDatabaseFile.FileName;
  Connection.CreateNewDatabase;
end;

procedure TfrmSettingsDialog.actDatabaseIntegrityCheckExecute(Sender: TObject);
begin
  SQLite.IntegrityCheck;
  UpdateDataBaseInfo;
end;

procedure TfrmSettingsDialog.actDataBaseShrinkMemoryExecute(Sender: TObject);
begin
  SQLite.ShrinkMemory;
end;

procedure TfrmSettingsDialog.actDatabaseVacuumExecute(Sender: TObject);
begin
  SQLite.Vacuum;
  UpdateDataBaseInfo;
end;

procedure TfrmSettingsDialog.actCloseExecute(Sender: TObject);
begin
  Close;
end;

procedure TfrmSettingsDialog.actDeleteDatabaseExecute(Sender: TObject);
begin
  if FileExists(edtDatabaseFile.FileName) then
    DeleteFile(edtDatabaseFile.FileName);
end;
{$ENDREGION}

{$REGION 'event handlers'}
procedure TfrmSettingsDialog.cbxImageListDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  Pos: Integer;
  C: TComboBox;
begin
  C := Control as TComboBox;
  // This ensures the correct highlight color is used
  C.Canvas.FillRect(ARect);
  Pos := ARect.Left + ((ARect.Right - ARect.Left) div 2) - 8;
  // This line draws the actual bitmap
  (FData as IGlyphs).ImageList.Draw(C.Canvas , Pos, ARect.Top, Index);

  //  This line writes the text after the bitmap*)
  //combobox1.canvas.textout(rect.left+imagelist1.width+2,rect.top,
  //                        combobox1.items[index]);



  //Pos := ARect.Left + ((ARect.Right - ARect.Left) div 2) - 8;

end;

procedure TfrmSettingsDialog.chkAutomaticIndexClick(Sender: TObject);
begin
  //SQLiteSettings.AutomaticIndex := chkAutomaticIndex.Checked;
end;

procedure TfrmSettingsDialog.dscGlyphStateChange(Sender: TObject);
begin
  //(FData as IGlyphs).LoadGlyphs;
  //vstImageList.RootNodeCount :=  (FData as IGlyphs).ImageList.Count;
end;

procedure TfrmSettingsDialog.dscGlyphUpdateData(Sender: TObject);
begin
  //(FData as IGlyphs).LoadGlyphs;
  //vstImageList.RootNodeCount :=  (FData as IGlyphs).ImageList.Count;
end;

procedure TfrmSettingsDialog.edtDatabaseFileButtonClick(Sender: TObject);
begin

end;

procedure TfrmSettingsDialog.pgcMainChange(Sender: TObject);
begin
  UpdateDataBaseInfo;
end;

//procedure TfrmSettingsDialog.grdGlyphAfterCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; const CellRect: TRect);
//var
//  Pos: Integer;
//begin
//  if Column = 3 then
//  begin
//    Pos := CellRect.Left + ((CellRect.Right - CellRect.Left) div 2) - 8;
//    (FData as IGlyphs).GlyphList.Draw(TargetCanvas, Pos, CellRect.Top, Node^.Index);
//  end;
//end;

//procedure TfrmSettingsDialog.grdGlyphGetRecordCount(Sender: TCustomVirtualDBGrid; var RecordCount: longint);
//begin
//    vstImageList.RootNodeCount :=  (FData as IGlyphs).ImageList.Count;
//end;

//procedure TfrmSettingsDialog.grdHighlightersAfterCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; const CellRect: TRect);
//var
//  Pos: Integer;
//begin
//  if Column = 3 then
//  begin
//    Pos := CellRect.Left + ((CellRect.Right - CellRect.Left) div 2) - 8;
//    (FData as IGlyphs).ImageList.Draw(TargetCanvas, Pos, CellRect.Top, StrToIntDef(grdHighlighters.Text[Node, Column-1], 0));
//  end;
//end;
//
procedure TfrmSettingsDialog.vstImageListAfterCellPaint(Sender:
  TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column:
  TColumnIndex; const CellRect: TRect);
var
  Pos: Integer;
begin
  if Column = 1 then
  begin
    Pos := CellRect.Left + ((CellRect.Right - CellRect.Left) div 2) - 8;
    (FData as IGlyphs).ImageList.Draw(TargetCanvas, Pos, CellRect.Top, Node^.Index);
  end;
end;

procedure TfrmSettingsDialog.vstImageListGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
begin
  if Column = 0 then
    CellText := IntToStr(Node^.Index)
  else
    CellText := '';
end;
{$ENDREGION}

{$REGION 'private methods'}
procedure TfrmSettingsDialog.LoadImage(const AFileName, AFieldName: string);
var
  F  : TBlobField;
  MS : TMemoryStream;
  P  : TPicture;
begin
  if FileExists(AFileName) then
  begin
    F := TBlobField(GlyphDS.FieldByName(AFieldName));
    MS := TMemoryStream.Create;
    try
      P := TPicture.Create;
      try
        P.LoadFromFile(AFileName);
      //        P.Bitmap.TransparentColor := clDefault;
      //        P.Bitmap.Transparent := True;
        P.Graphic.SaveToStream(MS);
        MS.Position := 0;
        F.LoadFromStream(MS);
      finally
        FreeAndNil(P);
      end;
    finally
      FreeAndNil(MS);
    end;
  end;
end;

procedure TfrmSettingsDialog.UpdateDataBaseInfo;
begin
  grdDBInfo.Cells[1, 0] := SQLite.DBVersion;
  grdDBInfo.Cells[1, 1] := FormatByteText(SQLite.Size);
  grdDBInfo.Cells[1, 2] := DateTimeToStr(GetFileCreationTime(Connection.FileName));
  grdDBInfo.Cells[1, 3] := DateTimeToStr(FileDateToDateTime(FileAge(Connection.FileName)));
end;

{$ENDREGION}

{$REGION 'public methods'}
procedure TfrmSettingsDialog.UpdateActions;
var
  S: string;
begin
  inherited UpdateActions;
  S := edtDatabaseFile.FileName;
  actOpenDatabase.Enabled := FileExists(S) and (Connection.FileName <> S);
  actCreateNewDatabase.Enabled := not FileExists(S);
  actDeleteDatabase.Enabled := FileExists(S);

end;
{$ENDREGION}

end.


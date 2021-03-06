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

unit SnippetSource.Interfaces;

{$MODE DELPHI}

{ Main application interfaces. }

interface

uses
  Classes, SysUtils, Controls,
  db, sqldb;

type
  IConnection = interface
  ['{8F9C0BCC-16D3-49A3-984A-415520289A2F}']
    {$REGION 'property access mehods'}
    function GetFileName: string;
    procedure SetFileName(AValue: string);
    function GetAutoApplyUpdates: Boolean;
    procedure SetAutoApplyUpdates(AValue: Boolean);
    function GetAutoCommit: Boolean;
    procedure SetAutoCommit(AValue: Boolean);
    {$ENDREGION}

    procedure CreateNewDatabase;
    procedure Execute(const ASQL: string);
    procedure Commit;
    procedure Rollback;
    procedure StartTransaction;
    procedure EndTransaction;

    property AutoApplyUpdates: Boolean
      read GetAutoApplyUpdates write SetAutoApplyUpdates;

    property AutoCommit: Boolean
      read GetAutoCommit write SetAutoCommit;

    property FileName: string
      read GetFileName write SetFileName;
  end;

  { ISQLite }

  ISQLite = interface
  ['{334F8C6C-B0C9-4A40-BA70-DEBAFAAE9442}']
  function GetDBVersion: string;
    {$REGION 'property access mehods'}
    function GetReadOnly: Boolean;
    function GetSize: Int64;
    procedure SetReadOnly(AValue: Boolean);
    {$ENDREGION}

    function IntegrityCheck: Boolean;
    procedure ShrinkMemory;
    procedure Vacuum;

    property ReadOnly: Boolean
      read GetReadOnly write SetReadOnly;

    property Size: Int64
      read GetSize;

    property DBVersion: string
      read GetDBVersion;
  end;

  ISnippet = interface
  ['{72ECC77F-765D-417E-ABCE-D78355A53CB7}']
    {$REGION 'property access mehods'}
    function GetImageIndex: Integer;
    procedure SetDateCreated(AValue: TDateTime);
    function GetDateCreated: TDateTime;
    procedure SetDateModified(AValue: TDateTime);
    function GetDateModified: TDateTime;
    function GetComment: string;
    function GetCommentRtf: string;
    function GetFoldLevel: Integer;
    function GetFoldState: string;
    function GetHighlighter: string;
    function GetId: Integer;
    function GetNodeName: string;
    function GetNodePath: string;
    function GetNodeTypeId: Integer;
    function GetParentId: Integer;
    function GetText: string;
    procedure SetComment(AValue: string);
    procedure SetCommentRtf(AValue: string);
    procedure SetFoldLevel(AValue: Integer);
    procedure SetFoldState(AValue: string);
    procedure SetHighlighter(AValue: string);
    procedure SetImageIndex(AValue: Integer);
    procedure SetNodeName(AValue: string);
    procedure SetNodePath(AValue: string);
    procedure SetNodeTypeId(AValue: Integer);
    procedure SetParentId(AValue: Integer);
    procedure SetText(AValue: string);
    {$ENDREGION}

    property Comment: string
      read GetComment write SetComment;

    property CommentRtf: string
      read GetCommentRtf write SetCommentRtf;

    property DateCreated: TDateTime
      read GetDateCreated write SetDateCreated;

    property DateModified: TDateTime
      read GetDateModified write SetDateModified;

    property FoldLevel: Integer
      read GetFoldLevel write SetFoldLevel;

    property FoldState: string
      read GetFoldState write SetFoldState;

    property Highlighter: string
      read GetHighlighter write SetHighlighter;

    property Id: Integer
      read GetId;

    property NodeName: string
      read GetNodeName write SetNodeName;

    property NodePath: string
      read GetNodePath write SetNodePath;

    property NodeTypeId: Integer
      read GetNodeTypeId write SetNodeTypeId;

    property ParentId: Integer
      read GetParentId write SetParentId;

    property Text: string
      read GetText write SetText;

    property ImageIndex: Integer
      read GetImageIndex write SetImageIndex;
  end;

  IDataSet = interface
  ['{13211D24-9ECD-42BE-AB95-C4F833D123E6}']
    {$REGION 'property access mehods'}
    function GetActive: Boolean;
    procedure SetActive(AValue: Boolean);
    function GetDataSet: TSQLQuery;
    function GetRecordCount: Integer;
    {$ENDREGION}

    function Post: Boolean;
    function Append: Boolean;
    function Edit: Boolean;
    function ApplyUpdates: Boolean;

    procedure DisableControls;
    procedure EnableControls;
    procedure BeginBulkInserts;
    procedure EndBulkInserts;

    property Active: Boolean
      read GetActive write SetActive;

    property RecordCount: Integer
      read GetRecordCount;

    property DataSet: TSQLQuery
      read GetDataSet;
  end;

  ILookup = interface
  ['{6B45FCDB-7F36-450D-9C2E-820C69204F4D}']
    {$REGION 'property access mehods'}
    function GetLookupDataSet: TDataSet;
    {$ENDREGION}

    procedure Lookup(
      const ASearchString : string;
      ASearchInText       : Boolean;
      ASearchInName       : Boolean;
      ASearchInComment    : Boolean
    );

    property LookupDataSet: TDataSet
      read GetLookupDataSet;
  end;

  IGlyphs = interface
  ['{E3C86684-4FD7-4EB5-8097-06ED826061C8}']
    {$REGION 'property access mehods'}
    function GetGlyphDataSet: TDataSet;
    function GetGlyphList: TImageList;
    function GetImageList: TImageList;
    {$ENDREGION}

    property GlyphDataSet: TDataSet
      read GetGlyphDataSet;

    property ImageList: TImageList
      read GetImageList;

    property GlyphList: TImageList
      read GetGlyphList;
  end;

  { ISettings }

  ISettings = interface
  ['{60E1B364-44E0-4A91-B12B-EF21059AC8C9}']
    function GetDataBase: string;
    procedure SetDataBase(const AValue: string);

    property DataBase: string
      read GetDataBase write SetDataBase;
  end;

implementation

end.


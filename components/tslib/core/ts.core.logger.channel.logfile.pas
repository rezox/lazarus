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

unit ts.Core.Logger.Channel.LogFile;

{ Copyright (C) 2006 Luiz Américo Pereira Câmara

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
{$ifdef fpc}
{$mode objfpc}{$H+}
{$endif}

interface

uses
  {$ifndef fpc}fpccompat,{$endif} Classes, SysUtils,

  ts.Core.Logger, ts.Core.Logger.Interfaces;

type

  TFileChannelOption = (fcoShowHeader, fcoShowPrefix, fcoShowTime);

  TFileChannelOptions = set of TFileChannelOption;

  { TFileChannel }

  TFileChannel = class (TLogChannel)
  private
    FFileHandle: Text;
    FFileName: String;
    FRelativeIdent: Integer;
    FBaseIdent: Integer;
    FShowHeader: Boolean;
    FShowTime: Boolean;
    FShowPrefix: Boolean;
    procedure SetShowTime(const AValue: Boolean);
    procedure UpdateIdentation;
    procedure WriteStrings(AStream: TStream);
    procedure WriteComponent(AStream: TStream);
  public
    constructor Create(const AFileName: string; AChannelOptions: TFileChannelOptions = [fcoShowHeader, fcoShowTime]);
    procedure Clear; override;
    procedure Deliver(const AMsg: TLogMessage);override;
    procedure Init; override;
    property ShowHeader: Boolean read FShowHeader write FShowHeader;
    property ShowPrefix: Boolean read FShowPrefix write FShowPrefix;
    property ShowTime: Boolean read FShowTime write SetShowTime;
  end;

implementation

uses
  FileUtil;

const
  LogPrefixes: array [lmtInfo..lmtCounter] of String = (
    'INFO',
    'ERROR',
    'WARNING',
    'VALUE',
    '>>ENTER METHOD',
    '<<EXIT METHOD',
    'CONDITIONAL',
    'CHECKPOINT',
    'STRINGS',
    'CALL STACK',
    'OBJECT',
    'EXCEPTION',
    'BITMAP',
    'HEAP INFO',
    'MEMORY',
    '','','','','',
    'WATCH',
    'COUNTER');

{ TFileChannel }

procedure TFileChannel.UpdateIdentation;
var
  S : string;
begin
  S:='';
  if FShowTime then
    S:=FormatDateTime('hh:nn:ss:zzz',Time);
  FBaseIdent:=Length(S)+3;
end;

procedure TFileChannel.SetShowTime(const AValue: Boolean);
begin
  FShowTime:=AValue;
  UpdateIdentation;
end;

procedure TFileChannel.WriteStrings(AStream: TStream);
var
  I : Integer;
begin
  if AStream.Size = 0 then Exit;
  with TStringList.Create do
  try
    AStream.Position := 0;
    LoadFromStream(AStream);
    for I := 0 to Count - 1 do
      WriteLn(FFileHandle, Space( FRelativeIdent + FBaseIdent) + Strings[I]);
  finally
    Destroy;
  end;
end;

procedure TFileChannel.WriteComponent(AStream: TStream);
var
  TextStream: TStringStream;
begin
  TextStream:=TStringStream.Create('');
  AStream.Seek(0,soFromBeginning);
  ObjectBinaryToText(AStream,TextStream);
  //todo: better handling of format
  Write(FFileHandle,TextStream.DataString);
  TextStream.Destroy;
end;

constructor TFileChannel.Create(const AFileName: string;
  AChannelOptions: TFileChannelOptions);
begin
  FShowPrefix := fcoShowPrefix in AChannelOptions;
  FShowTime   := fcoShowTime in AChannelOptions;
  FShowHeader := fcoShowHeader in AChannelOptions;
  Active      := True;
  FFileName   := AFileName;
end;

procedure TFileChannel.Clear;
begin
  Rewrite(FFileHandle);
end;

procedure TFileChannel.Deliver(const AMsg: TLogMessage);
begin
  //Exit method identation must be set before
  if (AMsg.MsgType = Integer(lmtLeaveMethod)) and (FRelativeIdent >= 2) then
    Dec(FRelativeIdent, 2);
  Append(FFileHandle);
  try
    if FShowTime then
      Write(FFileHandle, FormatDateTime('hh:nn:ss:zzz', AMsg.TimeStamp) + ' ');
    Write(FFileHandle, Space(FRelativeIdent));
    if FShowPrefix then
      Write(FFileHandle, LogPrefixes[TLogMessageType(AMsg.MsgType)] + ': ');
    Writeln(FFileHandle, AMsg.Text);
    if AMsg.Data <> nil then
    begin
      case TLogMessageType(AMsg.MsgType) of
        lmtStrings, lmtCallStack, lmtHeapInfo, lmtException: WriteStrings(AMsg.Data);
        lmtObject: WriteComponent(AMsg.Data);
      end;
    end;
  finally
    Close(FFileHandle);
    //Update enter method identation
    if TLogMessageType(AMsg.MsgType) = lmtEnterMethod then
      Inc(FRelativeIdent, 2);
  end;
end;

procedure TFileChannel.Init;
begin
  Assign(FFileHandle,FFileName);
  if FileExists(FFileName) then
    Append(FFileHandle)
  else
    Rewrite(FFileHandle);
  if FShowHeader then
    WriteLn(FFileHandle,'=== Log Session Started at ',DateTimeToStr(Now),' by ',ApplicationName,' ===');
  Close(FFileHandle);
  UpdateIdentation;
end;

end.


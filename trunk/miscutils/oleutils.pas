unit oleutils;

{ OLE helper functions

  Copyright (C) 2007 Luiz Am�rico Pereira C�mara
  pascalive@bol.com.br

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}


//todo: add error handling

{$mode objfpc}{$H+}

interface
{$ifdef Windows}
uses
  Windows, Classes, SysUtils, ActiveX;

type

  { TOLEStream }

  TOLEStream = class (TStream)
  private
    FSrcStream: IStream;
    procedure InternalSetSize(NewSize: LARGE_INTEGER);
  public
    constructor Create(const Stream: IStream);
    function Read(var Buffer; Count: Integer): Integer; override;
    function Seek(Offset: Integer; Origin: Word): Integer; overload; override;
    procedure SetSize(const NewSize: Int64); override;
    procedure SetSize(NewSize: Longint); override;
    function Write(const Buffer; Count: Integer): Integer; override;
  end;
{$endif}
implementation
{$ifdef Windows}

function ErrorString(Error: HRESULT): String;
begin
  case Error of
    E_PENDING: Result:='E_PENDING';
    S_FALSE: Result:='S_FALSE';
    STG_E_MEDIUMFULL: Result:='STG_E_MEDIUMFULL';
    STG_E_ACCESSDENIED: Result:= 'STG_E_ACCESSDENIED';
    STG_E_CANTSAVE: Result:='STG_E_CANTSAVE';
    STG_E_INVALIDPOINTER: Result:='STG_E_INVALIDPOINTER';
    STG_E_REVERTED: Result:='STG_E_REVERTED';
    STG_E_WRITEFAULT: Result:='STG_E_WRITEFAULT';
    STG_E_INVALIDFUNCTION: Result:='STG_E_INVALIDFUNCTION';
 else
   Result:='Unknow error';
 end;
  
end;

{ TOLEStream }

constructor TOLEStream.Create(const Stream: IStream);
begin
  inherited Create;
  FSrcStream:=Stream;
end;

function TOLEStream.Read(var Buffer; Count: Integer): Integer;
var
  Res: HRESULT;
begin
  Res:=FSrcStream.Read(@Buffer, Count, @Result);
  if Res <> S_OK then
    Raise Exception.Create('TOLEStream - Error while reading: '+ErrorString(Res));
end;

function TOLEStream.Seek(Offset: Integer; Origin: Word): Integer;
var
  liResult, liOffset : LARGE_INTEGER;
  Res: HRESULT;
begin
  //soFrom* constants are equal to STREAM_SEEK_* constants. Assume it here
  liOffset.LowPart:=Offset;
  liOffset.HighPart:=0;
  Res:=FSrcStream.Seek(liOffset, Origin, liResult);
  Result:=liResult.LowPart;
  if Res <> S_OK then
    Raise Exception.Create('TOLEStream - Error while seeking: '+ErrorString(Res));
end;

procedure TOLEStream.SetSize(NewSize: Longint);
var
  liSize: LARGE_INTEGER;
begin
  liSize.LowPart:=NewSize;
  liSize.HighPart:=0;
  InternalSetSize(liSize);
end;

procedure TOLEStream.SetSize(const NewSize: Int64);
var
  liSize: LARGE_INTEGER;
begin
  liSize.QuadPart:=NewSize;
  InternalSetSize(liSize);
end;

procedure TOLEStream.InternalSetSize(NewSize: LARGE_INTEGER);
var
  Res:HRESULT;
begin
  Res:=FSrcStream.SetSize(NewSize);
  if Res <> S_OK then
    Raise Exception.Create('TOLEStream - Error while setting size: '+ErrorString(Res));
end;

function TOLEStream.Write(const Buffer; Count: Integer): Integer;
var
  Res: HRESULT;
begin
  Res:=FSrcStream.Write(@Buffer,Count,@Result);
  if Res <> S_OK then
    Raise Exception.Create('TOLEStream - Error while writing: '+ErrorString(Res));
end;
{$endif}
end.


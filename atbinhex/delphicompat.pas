unit delphicompat;

{$mode objfpc}{$H+}

interface

uses
  LMessages,LCLIntf, Types, LCLType;

const
  //Messages
  WM_GETDLGCODE = LM_GETDLGCODE;
  WM_ERASEBKGND = LM_ERASEBKGND;
  WM_VSCROLL = LM_VSCROLL;
  WM_HSCROLL = LM_HSCROLL;

  //Misc Constants
  MAXSHORT = $7FFF;
  
type
  //TWM* types
  TMessage = TLMessage;
  TWMHScroll = TLMHScroll;
  TWMVScroll = TLMVScroll;

//Unicode functions

function ExtTextOutW(DC: HDC; X, Y: Integer; Options: LongInt; Rect: PRect;
  Str: PWideChar; Count: LongInt; Dx: PInteger): Boolean;

function TextOutW(DC: HDC; X,Y : Integer; Str : PWideChar; Count: Integer) : Boolean;

function GetTextExtentPoint32W(DC: HDC; Str: PWideChar; Count: Integer; var Size: TSize): Boolean;

function GetTextExtentPointW(DC: HDC; Str: PWideChar; Count: Integer; var Size: TSize): Boolean;

function GetTextExtentExPoint(DC: HDC; p2: PChar; p3, p4: Integer; p5, p6: PInteger; var p7: TSize): BOOL;

function GetTextExtentExPointW(DC: HDC; p2: PWideChar; p3, p4: Integer; p5, p6: PInteger; var p7: TSize): BOOL;

implementation

function ExtTextOutW(DC: HDC; X, Y: Integer; Options: LongInt; Rect: PRect;
  Str: PWideChar; Count: LongInt; Dx: PInteger): Boolean;
var
 TempStr: String;
begin
  TempStr:=WideCharToString(Str);
  Result:= ExtTextOut(DC, X, Y, Options, Rect, PChar(TempStr), Length(TempStr), Dx);
end;

function TextOutW(DC: HDC; X,Y : Integer; Str : PWideChar; Count: Integer) : Boolean;
var
 TempStr: String;
begin
  TempStr:=WideCharToString(Str);
  TextOut(DC,X,Y,PChar(TempStr),Count);
end;

function GetTextExtentPoint32W(DC: HDC; Str: PWideChar; Count: Integer; var Size: TSize): Boolean;
var
 TempStr: String;
begin
  TempStr:=WideCharToString(Str);
  Result:=GetTextExtentPoint(DC, PChar(TempStr), Length(TempStr), Size);
end;

function GetTextExtentPointW(DC: HDC; Str: PWideChar; Count: Integer; var Size: TSize): Boolean;
var
 TempStr: String;
begin
  TempStr:=WideCharToString(Str);
  Result:=GetTextExtentPoint(DC, PChar(TempStr), Length(TempStr), Size);
end;

function GetTextExtentExPoint(DC: HDC; p2: PChar; p3, p4: Integer; p5,
  p6: PInteger; var p7: TSize): BOOL;
begin
  {$INFO Implement GetTextExtentExPoint}
end;

function GetTextExtentExPointW(DC: HDC; p2: PWideChar; p3, p4: Integer; p5,
  p6: PInteger; var p7: TSize): BOOL;
begin

end;

end.


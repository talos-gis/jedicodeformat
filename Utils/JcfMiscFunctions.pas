unit JcfMiscFunctions;

{(*}
(*------------------------------------------------------------------------------
 Delphi Code formatter source code 

The Original Code is JcfMiscFunctions, released May 2003.
The Initial Developer of the Original Code is Anthony Steele. 
Portions created by Anthony Steele are Copyright (C) 1999-2000 Anthony Steele.
All Rights Reserved. 
Contributor(s): Anthony Steele.
functions Str2Float and Float2Str from Ralf Steinhaeusser

The contents of this file are subject to the Mozilla Public License Version 1.1
(the "License"). you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.mozilla.org/NPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied.
See the License for the specific language governing rights and limitations 
under the License.
------------------------------------------------------------------------------*)
{*)}


{ AFS 15 Jan 2k

  This project uses very little in the way of internal function libs
  as most is covered by JCL
  I was using ComponentFunctions from my Jedi VCL kit
  however that is causing linkage problems with the IDE plugin - it is a package
  and 2 packages can't package the same stuff,
  also it creates version dependencies - it bombed with the different version
  of ComponentFunctions that I have at work

  So I am importing just what I need from ComponentFunctions here
}

interface

function PadNumber(const pi: integer): ansistring;
function StrHasAlpha(const str: ansistring): boolean;
function GetLastDir(psPath: string): string;

function StrToBoolean(ps: string): boolean;

function Str2Float(s: string): double;
function Float2Str(const d: double): string;


{ delphi-string wrapper for the win32 pchar api }
function GetWinDir: string;

{not really a file fn - string file name manipulation}
function SetFileNameExtension(const psFileName, psExt: string): string;

procedure AdvanceTextPos(const ps: string; var piX, piY: integer);
function LastLineLength(const ps: string): integer;

implementation

uses
  { delphi }SysUtils, Windows,
  { jcl }JclStrings, JclFileUtils, JclSysUtils;

function StrToBoolean(ps: string): boolean;
begin
  Result := StrIsOneOf(ps, ['t', 'true', 'y', 'yes', '1']);
end;

{ these come from Ralf Steinhaeusser
  you see, in Germany, the default decimal sep char is a ',' not a '.'
  values with a '.' will not be read correctly  by StrToFloat
  and values written will contain a ','

  We want the config files to be portable so
  *always* use the '.' character when reading or writing
  This is not for localised display, but for consistent storage
}
//  like StrToFloat but expects a "." instead of the decimal-seperator-character
function Str2Float(s: string): double;
var
  code: integer;
begin
  // de-localise the string if need be
  if (DecimalSeparator <> '.') and (Pos(DecimalSeparator, s) > 0) then
  begin
    StrReplace(s, DecimalSeparator, '.');
  end;

  Val(s, Result, Code);
  if code <> 0 then
    raise EConvertError.Create('Str2Float: ' + s +
      ' is not a valid floating point string');
end;

// Like FloatToStr, but gives back a dot (.) as decimalseparator
function Float2Str(const d: double): string;
var
  OrgSep: char;
begin
  OrgSep := DecimalSeparator;
  DecimalSeparator := '.';
  Result := FloatToStr(d);
  DecimalSeparator := OrgSep;
end;

function PadNumber(const pi: integer): ansistring;
begin
  Result := IntToStrZeroPad(pi, 3);
end;

function StrHasAlpha(const str: ansistring): boolean;
var
  liLoop: integer;
begin
  Result := False;

  for liLoop := 1 to Length(str) do
  begin
    if CharIsAlpha(str[liLoop]) then
    begin
      Result := True;
      break;
    end;
  end;
end;

function GetLastDir(psPath: string): string;
var
  liPos: integer;
begin
  Result := '';
  if psPath = '' then
    exit;

  { is this a path ? }
  if not (DirectoryExists(psPath)) and FileExists(psPath) then
  begin
    // must be a file - remove the last bit
    liPos := StrLastPos(PathSeparator, psPath);
    if liPos > 0 then
      psPath := StrLeft(psPath, liPos - 1);
  end;

  liPos := StrLastPos(PathSeparator, psPath);
  if liPos > 0 then
    Result := StrRestOf(psPath, liPos + 1);
end;

function GetWinDir: string;
const
  LEN: integer = 255;
var
  lsBuffer: string;
begin
  SetLength(lsBuffer, LEN);
  FillChar(pchar(lsBuffer)^, LEN, 0);

  GetWindowsDirectory(pchar(lsBuffer), LEN);

  Result := Trim(lsBuffer);
end;

function SetFileNameExtension(const psFileName, psExt: string): string;
var
  liMainFileNameLength: integer;
  lsOldExt: string;
begin
  if PathExtractFileNameNoExt(psFileName) = '' then
  begin
    Result := '';
    exit;
  end;

  lsOldExt := ExtractFileExt(psFileName);
  liMainFileNameLength := Length(psFileName) - Length(lsOldExt);
  Result   := StrLeft(psFileName, liMainFileNameLength);

  Result := Result + '.' + psExt;
end;

{ given an existing source pos, and a text string that adds at that pos,
  calculate the new text pos
  - if the text does not contain a newline, add its length onto the Xpos
  - if the text contains newlines, then add on to the Y pos, and
    set the X pos to the text length after the last newline }
procedure AdvanceTextPos(const ps: string; var piX, piY: integer);
var
  liLastPos: integer;
begin
  if (ps = AnsiCarriageReturn) or (ps = AnsiCrLf) or (ps = AnsiLineFeed) then
  begin
    Inc(piY);
    piX := 1; // XPos is indexed from 1
  end
  else
  begin

    liLastPos := StrLastPos(AnsiLineBreak, ps);
    if liLastPos <= 0 then
    begin
      piX := piX + Length(ps);
    end
    else
    begin
      // multiline
      piY := piY + StrStrCount(ps, AnsiLineBreak);
      PiX := Length(ps) - (liLastPos + Length(AnsiLineBreak));
    end;
  end;
end;

{ in a multiline sting, how many chars on last line (after last return) }
function LastLineLength(const ps: string): integer;
var
  liPos: integer;
begin
  liPos := StrLastPos(AnsiLineBreak, ps);
  if liPos <= 0 then
    Result := Length(ps)
  else
    Result := Length(ps) - (liPos + Length(AnsiLineBreak));

end;

end.

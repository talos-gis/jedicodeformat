unit IdentifierCaps;

{(*}
(*------------------------------------------------------------------------------
 Delphi Code formatter source code

The Original Code is IdentifierCaps, released June 2005.
The Initial Developer of the Original Code is Anthony Steele.
Portions created by Anthony Steele are Copyright (C) 2005 Anthony Steele.
All Rights Reserved.
Contributor(s): Anthony Steele.

The contents of this file are subject to the Mozilla Public License Version 1.1
(the "License"). you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.mozilla.org/NPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied.
See the License for the specific language governing rights and limitations
under the License.
------------------------------------------------------------------------------*)
{*)}

{ AFS 30 December 2002
    - fix capitalisation on specified words
}
interface

uses SwitchableVisitor;

type
  TIdentifierCaps = class(TSwitchableVisitor)
  private
    fiCount: integer;
    lsLastChange: string;

  protected
    function EnabledVisitSourceToken(const pcNode: TObject): boolean; override;
  public
    constructor Create; override;

    function IsIncludedInSettings: boolean; override;
    { return true if you want the message logged}
    function FinalSummary(var psMessage: string): boolean; override;
  end;

implementation

uses
  SysUtils,
  SourceToken, Tokens, ParseTreeNodeType, JcfSettings, FormatFlags, TokenUtils;


function Excluded(const pt: TSourceToken): boolean;
begin
  Result := False;

  { directives in context are excluded }
  if IsDirectiveInContext(pt) then
  begin
    Result := True;
    exit;
  end;

  // asm has other rules
  if pt.HasParentNode(nAsm) then
  begin
    Result := True;
    exit;
  end;


  { built in types that are actually being used as types are excluded
    eg.
    // this use of 'integer' is definitly the type
    var li: integer;

    // this use is definitely not
    function Integer(const ps: string): integer;

    // this use is ambigous
    li := Integer(SomeVar);

   user defined types are things that we often *want* to set a specific caps on
   so they are not excluded }

  if (pt.TokenType in BuiltInTypes) and (pt.HasParentNode(nType)) then
  begin
    Result := True;
    exit;
  end;
end;


{ TIdentifierCaps }

constructor TIdentifierCaps.Create;
begin
  inherited;
  fiCount      := 0;
  lsLastChange := '';
  FormatFlags  := FormatFlags + [eCapsSpecificWord];
end;

function TIdentifierCaps.FinalSummary(var psMessage: string): boolean;
begin
  Result := (fiCount > 0);

  if Result then
  begin
    psMessage := 'Identifier caps: ';

    if fiCount = 1 then
      psMessage := psMessage + 'One change was made: ' + lsLastChange
    else
      psMessage := psMessage + IntToStr(fiCount) + ' changes were made';
  end;
end;

function TIdentifierCaps.EnabledVisitSourceToken(const pcNode: TObject): Boolean;
var
  lcSourceToken: TSourceToken;
  lsChange:      string;
begin
  Result := False;
  lcSourceToken := TSourceToken(pcNode);

  if lcSourceToken.HasParentNode(nIdentifier, 2) then
  begin
    if FormatSettings.IdentifierCaps.Enabled and FormatSettings.IdentifierCaps.HasWord(lcSourceToken.SourceCode) then
    begin
      // get the fixed version
      lsChange := FormatSettings.IdentifierCaps.CapitaliseWord(lcSourceToken.SourceCode);

      // case-sensitive test - see if anything to do.
      if AnsiCompareStr(lcSourceToken.SourceCode, lsChange) <> 0 then
      begin
        lsLastChange := lcSourceToken.SourceCode + ' to ' + lsChange;
        lcSourceToken.SourceCode := lsChange;
        Inc(fiCount);
      end;
    end;
  end
  else
  begin
    if FormatSettings.NotIdentifierCaps.Enabled and FormatSettings.NotIdentifierCaps.HasWord(lcSourceToken.SourceCode) then
    begin
      // get the fixed version
      lsChange := FormatSettings.NotIdentifierCaps.CapitaliseWord(lcSourceToken.SourceCode);

      // case-sensitive test - see if anything to do.
      if AnsiCompareStr(lcSourceToken.SourceCode, lsChange) <> 0 then
      begin
        lsLastChange := lcSourceToken.SourceCode + ' to ' + lsChange;
        lcSourceToken.SourceCode := lsChange;
        Inc(fiCount);
      end;
    end;
  end;
end;

function TIdentifierCaps.IsIncludedInSettings: boolean;
begin
  Result := FormatSettings.IdentifierCaps.Enabled or
    FormatSettings.NotIdentifierCaps.Enabled;
end;

end.
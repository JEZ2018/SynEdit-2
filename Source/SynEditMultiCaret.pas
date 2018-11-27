{ -------------------------------------------------------------------------------
  The contents of this file are subject to the Mozilla Public License
  Version 1.1 (the "License"); you may not use this file except in compliance
  with the License. You may obtain a copy of the License at
  http://www.mozilla.org/MPL/

  Software distributed under the License is distributed on an "AS IS" basis,
  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
  the specific language governing rights and limitations under the License.

  The Original Code is SynEditWordWrap.pas by Flávio Etrusco, released 2003-12-11.
  Unicode translation by Maël Hörz.
  All Rights Reserved.

  Contributors to the SynEdit and mwEdit projects are listed in the
  Contributors.txt file.

  Alternatively, the contents of this file may be used under the terms of the
  GNU General Public License Version 2 or later (the "GPL"), in which case
  the provisions of the GPL are applicable instead of those above.
  If you wish to allow use of your version of this file only under the terms
  of the GPL and not to allow others to use your version of this file
  under the MPL, indicate your decision by deleting the provisions above and
  replace them with the notice and other provisions required by the GPL.
  If you do not delete the provisions above, a recipient may use your version
  of this file under either the MPL or the GPL.
  ------------------------------------------------------------------------------- }
unit SynEditMultiCaret;

interface
uses
  Math,
  System.Generics.Collections;

type

  TCaretItem = class
  strict private
    FPosX: Integer;
    FPosY: Integer;
    FSelLen: Integer;
  public
    constructor Create; overload;
    constructor Create(PosX, PosY, SelLen: Integer); overload;
    property PosX: Integer read FPosX write FPosX;
    property PosY: INteger read FPosY write FPosy;
    property SelLen: Integer read FSelLen write FSelLen;
  end;

  TCarets = class
  strict private
    FList: TList<TCaretItem>;
    function GetItem(Index: Integer): TCaretItem;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Add(APosX, APosY, ASelLen: Integer);
    procedure Assign(Other: TCarets);
    procedure Clear;
    procedure Delete(Index: Integer);
    function Count: Integer;
    function InRange(N: Integer): Boolean;
    property Items[N: Integer]: TCaretItem read GetItem; default;
    function IndexOf(APosX, APosY: Integer): Integer;
    function IsLineListed(APosY: Integer): Boolean;
  end;

implementation

{ TCarets }

procedure TCarets.Add(APosX, APosY, ASelLen: Integer);
begin
  FList.Add(
    TCaretItem.Create(APosX, APosY, ASelLen)
  );
end;

procedure TCarets.Assign(Other: TCarets);
begin

end;

procedure TCarets.Clear;
var
  Item: TCaretItem;
begin
  for Item in FList do
    Item.Free;
  FList.Free;
end;

function TCarets.Count: Integer;
begin
  Result := FList.Count
end;

constructor TCarets.Create;
begin
  inherited;
  FList:= TList<TCaretItem>.Create;
end;

procedure TCarets.Delete(Index: Integer);
begin
  if InRange(Index) then
  begin
    FList[Index].Free;
    FList.Delete(Index);
  end;
end;

destructor TCarets.Destroy;
begin

  inherited;
end;

function TCarets.GetItem(Index: Integer): TCaretItem;
begin
  if InRange(Index) then
    Result:= FList[Index]
  else
    Result:= nil;
end;

function TCarets.IndexOf(APosX, APosY: Integer): Integer;
var
  I: Integer;
  Item: TCaretItem;
begin
  Result:= -1;
  for I := 0 to FList.Count-1 do begin
    Item := FList[I];
    if (Item.PosX = APosX) and (Item.PosY = APosY)  then
      Exit(I)
  end;
end;

function TCarets.InRange(N: Integer): Boolean;
begin
  Result := Math.InRange(N, 0, FList.Count-1)
end;

function TCarets.IsLineListed(APosY: Integer): boolean;
var
  Item: TCaretItem;
begin
  Result:= False;
  for Item in FList do begin
    if Item.PosY = APosY then
      Exit(True)
  end;
end;

{ TCaretItem }

constructor TCaretItem.Create;
begin
  FPosX := -1;
  FPosY := -1;
end;

constructor TCaretItem.Create(PosX, PosY, SelLen: Integer);
begin
  FPosX := PosX;
  FPosY := PosY;
  FSelLen := SelLen;
end;

end.
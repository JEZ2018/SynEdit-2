{ -------------------------------------------------------------------------------
  The contents of this file are subject to the Mozilla Public License
  Version 1.1 (the "License"); you may not use this file except in compliance
  with the License. You may obtain a copy of the License at
  http://www.mozilla.org/MPL/

  Software distributed under the License is distributed on an "AS IS" basis,
  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
  the specific language governing rights and limitations under the License.

  The Original Code is SynEditWordWrap.pas by Fl�vio Etrusco, released 2003-12-11.
  Unicode translation by Ma�l H�rz.
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
  Graphics,
  ExtCtrls,
  Classes,
  System.Types,
  System.Generics.Collections;

type

  TCaretItem = class
  type
    TOnMoved = procedure(Sender: TCaretItem; const PointFrom: TPoint;
      const PointTo: TPoint) of object;
    TOnSelLenChanged = procedure(Sender: TCaretItem; const ValueFrom: Integer;
      const ValueTo: Integer) of object;
    TOnVisibleChanged = procedure(Sender: TCaretItem) of object;
  strict private
    FIndex: Integer;
    FPosX: Integer;
    FPosY: Integer;
    FSelLen: Integer;
    FVisible: Boolean;
    FOnMoved: TOnMoved;
    FOnVisibleChanged: TOnVisibleChanged;
    FOnSelLenChanged: TOnSelLenChanged;
    procedure SetPosX(const Value: Integer);
    procedure SetPosY(const Value: Integer);
    procedure SetSelLen(const Value: Integer);
    procedure SetVisible(const Value: Boolean);
  protected
    property Index: Integer read FIndex write FIndex;
    property OnMoved: TOnMoved read FOnMoved write FOnMoved;
    property OnSelLenChanged: TOnSelLenChanged read FOnSelLenChanged
      write FOnSelLenChanged;
    property OnVisibleChanged: TOnVisibleChanged read FOnVisibleChanged
      write FOnVisibleChanged;
  public
    constructor Create; overload;
    constructor Create(PosX, PosY, SelLen: Integer); overload;
    function ToPoint: TPoint;
    property PosX: Integer read FPosX write SetPosX;
    property PosY: INteger read FPosY write SetPosY;
    property SelLen: Integer read FSelLen write SetSelLen;
    property Visible: Boolean read FVisible write SetVisible;
  end;

  TCarets = class
  strict private
    FList: TList<TCaretItem>;
    FOnChanged: TNotifyEvent;
    FOnBeforeClear: TNotifyEvent;
    FOnBeforeCaretDelete: TNotifyEvent;
    function GetItem(Index: Integer): TCaretItem;
    function GetDefaultCaret: TCaretItem;
  protected
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property OnBeforeClear: TNotifyEvent read FOnBeforeClear
      write FOnBeforeClear;
    property OnBeforeCaretDelete: TNotifyEvent read FOnBeforeCaretDelete
      write FOnBeforeCaretDelete;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Add(APosX, APosY, ASelLen: Integer);
    procedure Assign(Other: TCarets);
    procedure Clear(const ExcludeDefaultCaret: Boolean=True);
    procedure Delete(Index: Integer);
    function Count: Integer;
    function InRange(N: Integer): Boolean;
    property Items[N: Integer]: TCaretItem read GetItem; default;
    property DefaultCaret: TCaretItem read GetDefaultCaret;
    function IndexOf(APosX, APosY: Integer): Integer;
    function IsLineListed(APosY: Integer): Boolean;
    function GetEnumerator: TEnumerator<TCaretItem>;
  end;

  IAbstractEditor = interface
    function GetCanvas: TCanvas;
    function GetClientRect: TRect;
    property Canvas: TCanvas read GetCanvas;
    property ClientRect: TRect read GetClientRect;
  end;

  TCaretShape = record
    Width: Integer;
    Height: Integer;
    Offset: TPoint;
  public
    constructor Create(const aWidth, aHeight: Integer); overload;
    constructor Create(const aWidth, aHeight: Integer; const aOffset: TPoint); overload;
    procedure SetToDefault;
    class operator Equal(a: TCaretShape; b: TCaretShape): Boolean;
  end;

  TMultiCaretController = class
  strict private
    FEditor: IAbstractEditor;
    FCarets: TCarets;
    FBlinkTimer: TTimer;
    FShown: Boolean;
    FActive: Boolean;
    FShape: TCaretShape;
    function CaretPointToRect(const CaretPoint: TPoint): TRect;
    procedure SetActive(const Value: Boolean);
    procedure SetShape(const Value: TCaretShape);
    procedure InvertRects;
    procedure Blink(Sender: TObject);
    procedure DoCaretsChanged(Sender: TObject);
    procedure DoBeforeCaretsClear(Sender: TObject);
    procedure DoBeforeCaretsDelete(Sender: TObject);
    procedure DoCaretMoved(Sender: TCaretItem; const PointFrom: TPoint;
      const PointTo: TPoint);
    procedure DoCaretSelLenChanged(Sender: TCaretItem; const ValueFrom: Integer;
      const ValueTo: Integer);
    procedure DoCaretVisibleChanged(Sender: TCaretItem);
  public
    constructor Create(Editor: IAbstractEditor);
    destructor Destroy; override;
    procedure Paint;
    procedure Flash;
    property Active: Boolean read FActive write SetActive;
    property Carets: TCarets read FCarets;
    property Shape: TCaretShape read FShape write SetShape;
  end;

implementation
uses Windows;

{ TCarets }

procedure TCarets.Add(APosX, APosY, ASelLen: Integer);
var
  Caret: TCaretItem;
begin
  Caret := TCaretItem.Create(APosX, APosY, ASelLen);
  FList.Add(Caret);
  Caret.Index := FList.Count-1;
  if Assigned(FOnChanged) then
    FOnChanged(Self)
end;

procedure TCarets.Assign(Other: TCarets);
var
  I: Integer;
begin
  Clear;
  for I := 0 to Other.Count-1 do begin
    Add(Other[I].PosX, Other[I].PosY, Other[I].SelLen)
  end;
end;

procedure TCarets.Clear(const ExcludeDefaultCaret: Boolean);
var
  Item: TCaretItem;
begin
  if ExcludeDefaultCaret then begin
    while Count > 1 do
      Delete(0);
  end
  else begin
    if Assigned(FOnBeforeClear) then
      FOnBeforeClear(Self);
    for Item in FList do
      Item.Free;
    FList.Clear;
  end;
  if Assigned(FOnChanged) then
    FOnChanged(Self)
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
var
  I: Integer;
begin
  if InRange(Index) then
  begin
    if Assigned(FOnBeforeCaretDelete) then
      FOnBeforeCaretDelete(FList[Index]);
    FList[Index].Free;
    FList.Delete(Index);
    for I := Index to FList.Count-1 do
      FList[I].Index := FList[I].Index - 1;
  end;
  if Assigned(FOnChanged) then
    FOnChanged(Self)
end;

destructor TCarets.Destroy;
begin

  inherited;
end;

function TCarets.GetDefaultCaret: TCaretItem;
begin
  if Count = 0 then begin
    Add(0, 0, 0);
  end;
  Result := FList.Last;
end;

function TCarets.GetEnumerator: TEnumerator<TCaretItem>;
begin
  Result := FList.GetEnumerator
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
  FVisible := True;
end;

constructor TCaretItem.Create(PosX, PosY, SelLen: Integer);
begin
  Create;
  FPosX := PosX;
  FPosY := PosY;
  FSelLen := SelLen;
end;

procedure TCaretItem.SetPosX(const Value: Integer);
var
  PointFrom: TPoint;
begin
  if Value <> FPosX then begin
    PointFrom := ToPoint;
    FPosX := Value;
    if Assigned(FOnMoved) then
      FOnMoved(Self, PointFrom, ToPoint)
  end;
end;

procedure TCaretItem.SetPosY(const Value: Integer);
var
  PointFrom: TPoint;
begin
  if Value <> FPosY then begin
    PointFrom := ToPoint;
    FPosY := Value;
    if Assigned(FOnMoved) then
      FOnMoved(Self, PointFrom, ToPoint)
  end;
end;

procedure TCaretItem.SetSelLen(const Value: Integer);
var
  ValueFrom: Integer;
begin
  if (Value <> FSelLen) and (Value >= 0) then begin
    ValueFrom := FSelLen;
    FSelLen := Value;
    if Assigned(FOnSelLenChanged) then
      FOnSelLenChanged(Self, ValueFrom, FSelLen)
  end;
end;

procedure TCaretItem.SetVisible(const Value: Boolean);
begin
  if Value <> FVisible then begin
    FVisible := Value;
    if Assigned(FOnVisibleChanged) then
      FOnVisibleChanged(Self)
  end;
end;

function TCaretItem.ToPoint: TPoint;
begin
  Result := Point(FPosX, FPosY);
end;

{ TMultiCaretController }

procedure TMultiCaretController.Blink(Sender: TObject);
begin
  FShown := not FShown;
  InvertRects
end;

function TMultiCaretController.CaretPointToRect(const CaretPoint: TPoint): TRect;
var
  P: TPoint;
  CaretHeight, CaretWidth: Integer;

begin
  CaretHeight := FShape.Height;
  CaretWidth := FShape.Width;
  P := CaretPoint;
  Inc(P.Y, FShape.Offset.Y);
  Inc(P.X, FShape.Offset.X);
  Result := Rect(P.X, P.Y, P.X + CaretWidth, P.Y + CaretHeight);
end;

constructor TMultiCaretController.Create(Editor: IAbstractEditor);
begin
  FBlinkTimer := TTimer.Create(nil);
  FBlinkTimer.Interval := GetCaretBlinkTime;
  FBlinkTimer.OnTimer := Blink;
  FBlinkTimer.Enabled := False;

  FCarets := TCarets.Create;
  FCarets.OnChanged := DoCaretsChanged;
  FCarets.OnBeforeClear := DoBeforeCaretsClear;

  FEditor := Editor;
end;

destructor TMultiCaretController.Destroy;
begin
  FBlinkTimer.Free;
  FCarets.Free;
  inherited;
end;

procedure TMultiCaretController.InvertRects;
var
  Caret: TCaretItem;
  P: TPoint;
  R, R2: TRect;

begin
  for Caret in FCarets do
    if Caret.Visible then begin
      R := CaretPointToRect(Caret.ToPoint);
      if IntersectRect(R2, R, FEditor.GetClientRect) then
        InvertRect(FEditor.GetCanvas.Handle, R);
    end;
end;


procedure TMultiCaretController.DoBeforeCaretsClear(Sender: TObject);
begin
  if FShown then
    InvertRects;
end;

procedure TMultiCaretController.DoBeforeCaretsDelete(Sender: TObject);
var
  R, R2: TRect;
  Caret: TCaretItem;

begin
  if FShown then begin
    Caret := TCaretItem(Sender);
    R := CaretPointToRect(Caret.ToPoint);
    if IntersectRect(R2, R, FEditor.GetClientRect) then
      InvertRect(FEditor.GetCanvas.Handle, R);
  end;
end;

procedure TMultiCaretController.DoCaretMoved(Sender: TCaretItem;
  const PointFrom, PointTo: TPoint);
var
  RectFrom, RectTo, R2: TRect;

begin
  if FShown then begin
    RectFrom := CaretPointToRect(PointFrom);
    RectTo := CaretPointToRect(PointTo);
    if IntersectRect(R2, RectFrom, FEditor.GetClientRect) then
      InvertRect(FEditor.GetCanvas.Handle, RectFrom);
    if IntersectRect(R2, RectTo, FEditor.GetClientRect) then
      InvertRect(FEditor.GetCanvas.Handle, RectTo);
  end;
end;

procedure TMultiCaretController.Paint;
begin
  if FShown then
    InvertRects
end;

procedure TMultiCaretController.SetActive(const Value: Boolean);
begin
  if FActive <> Value then begin
    if FShown then
      InvertRects;
    FActive := Value;
    FShown := False;
    FBlinkTimer.Enabled := Value and (FCarets.Count > 0);
  end;
end;

procedure TMultiCaretController.SetShape(const Value: TCaretShape);
begin
  if not (FShape = Value) then begin
    if FShown then
      InvertRects;
    FShape := Value;
    if FShown then
      InvertRects;
  end;
end;

procedure TMultiCaretController.DoCaretsChanged(Sender: TObject);
var
  Caret: TCaretItem;
begin
  for Caret in FCarets do begin
    if not Assigned(Caret.OnMoved) then
      Caret.OnMoved := DoCaretMoved;
    if not Assigned(Caret.OnSelLenChanged) then
      Caret.OnSelLenChanged := DoCaretSelLenChanged;
    if not Assigned(Caret.OnVisibleChanged) then
      Caret.OnVisibleChanged := DoCaretVisibleChanged;
  end;
  FBlinkTimer.Enabled := FActive and (FCarets.Count > 0);
end;

procedure TMultiCaretController.DoCaretSelLenChanged(Sender: TCaretItem;
  const ValueFrom, ValueTo: Integer);
begin
  // TODO
end;

procedure TMultiCaretController.DoCaretVisibleChanged(Sender: TCaretItem);
var
  R, R2: TRect;

begin
  if FShown then begin
    R := CaretPointToRect(Sender.ToPoint);
      if IntersectRect(R2, R, FEditor.GetClientRect) then
        InvertRect(FEditor.GetCanvas.Handle, R);
  end;
end;

procedure TMultiCaretController.Flash;
begin
  OutputDebugString('Flash');
  if not FShown then begin
    FShown := True;
    InvertRects;
    // restart blink timer
    FBlinkTimer.Enabled := False;
    FBlinkTimer.Enabled := True;
  end;
end;

{ TCaretShape }

constructor TCaretShape.Create(const aWidth, aHeight: Integer;
  const aOffset: TPoint);
begin
  Create(aWidth, aHeight);
  Offset := aOffset;
end;

constructor TCaretShape.Create(const aWidth, aHeight: Integer);
begin
  Width := aWidth;
  Height := aHeight;
end;

class operator TCaretShape.Equal(a, b: TCaretShape): Boolean;
begin
  Result := (a.Width = b.Width) and (a.Height = b.Height) and (a.Offset = b.Offset)
end;

procedure TCaretShape.SetToDefault;
begin
  Width := 2;
  Height := 10;
  Offset := Point(0, 0);
end;

end.
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
  Graphics,
  SysUtils,
  ExtCtrls,
  Classes,
  SynEditKeyCmds,
  SynEditTextBuffer,
  SynEditTypes,
  System.Types,
  System.Generics.Collections;

const
  // Editor commands that will be intercepted and executed in SandBox
  SANDBOX_COMMANDS: array[0..10] of Integer = (ecChar, ecPaste, ecLineBreak,
    ecMoveLineDown, ecMoveLineUp, ecCopyLineDown, ecCopyLineUp,
    ecDeleteLastChar, ecDeleteChar, ecSelLeft, ecSelRight);

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
    procedure SaveToStream(S: TStream);
    function LoadFromStream(S: TStream): Boolean;
  public
    constructor Create; overload;
    constructor Create(PosX, PosY, SelLen: Integer); overload;
    destructor Destroy; override;
    function ToPoint: TPoint;
    property PosX: Integer read FPosX write SetPosX;
    property PosY: INteger read FPosY write SetPosY;
    property SelLen: Integer read FSelLen write SetSelLen;
    property Visible: Boolean read FVisible write SetVisible;
  end;

  TCarets = class
  strict private
    FList: TList<TCaretItem>;
    FLine: TList<TCaretItem>;
    FColumn: TList<TCaretItem>;
    FSortedList: TList<TCaretItem>;
    FOnChanged: TNotifyEvent;
    FOnBeforeClear: TNotifyEvent;
    FOnAfterClear: TNotifyEvent;
    FOnBeforeCaretDelete: TNotifyEvent;
    function GetItem(Index: Integer): TCaretItem;
    function CompareCarets(const Left, Right: TCaretItem): Integer;
  private
    FDefaultCaret: TCaretItem;
    function GetDefaultCaretSafe: TCaretItem;
    procedure SaveToStream(S: TStream);
    function LoadFromStream(S: TStream): Boolean;
  protected
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property OnBeforeClear: TNotifyEvent read FOnBeforeClear
      write FOnBeforeClear;
    property OnAfterClear: TNotifyEvent read FOnAfterClear write FOnAfterClear;
    property OnBeforeCaretDelete: TNotifyEvent read FOnBeforeCaretDelete
      write FOnBeforeCaretDelete;
    function GetLineNeighboursOnRight(Caret: TCaretItem): TList<TCaretItem>;
    function GetColumnNeighboursOnBottom(Caret: TCaretItem): TList<TCaretItem>;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function Add(APosX, APosY, ASelLen: Integer): TCaretItem;
    procedure Clear(ExcludeDefaultCaret: Boolean = True);
    procedure Delete(Index: Integer);
    function Count: Integer;
    function InRange(N: Integer): Boolean;
    function Sorted:  TList<TCaretItem>;
    property Items[N: Integer]: TCaretItem read GetItem; default;
    property DefaultCaret: TCaretItem read GetDefaultCaretSafe;
    function IndexOf(APosX, APosY: Integer): Integer;
    function IsLineListed(APosY: Integer): Boolean;
    function GetEnumerator: TEnumerator<TCaretItem>;
    function Store: TBytes;
    function Load(const B: TBytes): Boolean;
  end;

  IAbstractEditor = interface
    function GetCanvas: TCanvas;
    function GetClientRect: TRect;
    function GetUndoList: TSynEditUndoList;
    function GetBlockBegin: TBufferCoord;
    function GetBlockEnd: TBufferCoord;
    function GetCaretXY: TBufferCoord;
    function GetDisplayXY: TDisplayCoord;
    function GetTextHeight: Integer;
    function DisplayCoord2CaretXY(const Coord: TDisplayCoord): TPoint;
    function PixelsToNearestRowColumn(aX, aY: Integer): TDisplayCoord;
    procedure SetBlockBegin(Value: TBufferCoord);
    procedure SetBlockEnd(Value: TBufferCoord);
    property Canvas: TCanvas read GetCanvas;
    property ClientRect: TRect read GetClientRect;
    property UndoList: TSynEditUndoList read GetUndoList;
    property BlockBegin: TBufferCoord read GetBlockBegin write SetBlockBegin;
    property BlockEnd: TBufferCoord read GetBlockEnd write SetBlockEnd;
    property TextHeight: Integer read GetTextHeight;
    procedure ComputeCaret(X, Y: Integer);
    procedure RegisterCommandHandler(const AHandlerProc: THookedCommandEvent;
      AHandlerData: pointer);
    procedure ExecuteCommand(Command: TSynEditorCommand; AChar: WideChar;
      Data: pointer);
    procedure InvalidateRect(const aRect: TRect; aErase: Boolean);
    function BufferToDisplayPos(const p: TBufferCoord): TDisplayCoord;
    function DisplayToBufferPos(const p: TDisplayCoord): TBufferCoord;
    procedure BeginUpdate;
    procedure EndUpdate;
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
    FCommandsList: TList<Integer>;
    FSandBoxContext: Boolean;
    function CaretPointToRect(const CaretPoint: TPoint): TRect;
    function CaretSelectionRect(Caret: TCaretItem): TRect;
    procedure SetActive(const Value: Boolean);
    procedure SetShape(const Value: TCaretShape);
    procedure InvertRects;
    procedure Blink(Sender: TObject);
    procedure DoCaretsChanged(Sender: TObject);
    procedure DoBeforeAfterCaretsClear(Sender: TObject);
    procedure DoBeforeCaretsDelete(Sender: TObject);
    procedure DoCaretMoved(Sender: TCaretItem; const PointFrom: TPoint;
      const PointTo: TPoint);
    procedure DefaultCaretMoved(const PointFrom: TPoint; const PointTo: TPoint);
    procedure DoCaretSelLenChanged(Sender: TCaretItem; const ValueFrom: Integer;
      const ValueTo: Integer);
    procedure DoCaretVisibleChanged(Sender: TCaretItem);
    // Entry point of SandBox for executing commands
    procedure EditorCommandSandBoxEntryPoint(Sender: TObject;
      AfterProcessing: Boolean; var Handled: Boolean;
      var Command: TSynEditorCommand; var AChar: WideChar;
      Data: pointer; HandlerData: pointer);
    procedure SandBox(Command: TSynEditorCommand; AChar: WideChar;
      Data: Pointer);
    function IsSelectionCommand(Command: TSynEditorCommand): Boolean;
  public
    constructor Create(Editor: IAbstractEditor);
    destructor Destroy; override;
    procedure Paint;
    procedure Flash;
    procedure MoveY(Delta: Integer);
    procedure MoveX(Delta: Integer);
    procedure Unselect;
    property Active: Boolean read FActive write SetActive;
    property Carets: TCarets read FCarets;
    property Shape: TCaretShape read FShape write SetShape;
    function Exists(const PosX: Integer; const PosY: Integer): Boolean;
    {$IFDEF DEBUG}
    procedure ShowDebugState;
    procedure InvertShown;
    {$ENDIF}
  end;

implementation
uses Windows, System.Generics.Defaults;


{ TCarets }

function TCarets.Add(APosX, APosY, ASelLen: Integer): TCaretItem;
begin
  Result := TCaretItem.Create(APosX, APosY, ASelLen);
  FList.Add(Result);
  Result.Index := FList.Count-1;
  if Assigned(FOnChanged) then
    FOnChanged(Self)
end;

procedure TCarets.Clear(ExcludeDefaultCaret: Boolean);
var
  Item: TCaretItem;
  Def: TCaretItem;
begin
  if ExcludeDefaultCaret then begin
    if Count < 2 then
      Exit;
    if Assigned(FOnBeforeClear) then
      FOnBeforeClear(Self);
    Def := DefaultCaret;
    for Item in FList do begin
      if Item <> Def then
        Item.Free;
    end;
    FList.Clear;
    FList.Add(Def);
    Def.Index := 0;
    if Assigned(FOnAfterClear) then
      FOnAfterClear(Self);
  end
  else begin
    if Count < 1 then
      Exit;
    if Assigned(FOnBeforeClear) then
      FOnBeforeClear(Self);
    for Item in FList do
      Item.Free;
    FList.Clear;
    FDefaultCaret := nil;
    if Assigned(FOnAfterClear) then
      FOnAfterClear(Self);
  end;
  if Assigned(FOnChanged) then
    FOnChanged(Self)
end;

function TCarets.CompareCarets(const Left, Right: TCaretItem): Integer;
begin
  Result := Left.PosX - Right.PosX;
  if Result = 0 then
    Result := Left.PosY - Right.PosY
end;

function TCarets.Count: Integer;
begin
  Result := FList.Count
end;

constructor TCarets.Create;
begin
  inherited;
  FList:= TList<TCaretItem>.Create;
  FLine:= TList<TCaretItem>.Create;
  FColumn := TList<TCaretItem>.Create;
  FSortedList := TList<TCaretItem>.Create;
end;

procedure TCarets.Delete(Index: Integer);
var
  I: Integer;
begin
  if InRange(Index) then
  begin
    if Assigned(FOnBeforeCaretDelete) then
      FOnBeforeCaretDelete(FList[Index]);
    if FList[Index] = FDefaultCaret then
      FDefaultCaret := nil;
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
  Clear;
  FList.Free;
  FLine.Free;
  FColumn.Free;
  FSortedList.Free;
  inherited;
end;

function TCarets.GetColumnNeighboursOnBottom(
  Caret: TCaretItem): TList<TCaretItem>;
var
  Iter: TCaretItem;
begin
  FColumn.Clear;
  for Iter in FList do begin
    if (Iter <> Caret) and (Iter.PosY > Caret.PosY) then begin
      FColumn.Add(Iter)
    end;
  end;
  FColumn.Sort(TComparer<TCaretItem>.Construct(CompareCarets));
  Result := FColumn;
end;

function TCarets.GetDefaultCaretSafe: TCaretItem;
var
  Caret: TCaretItem;
begin
  if FList.Count = 0 then begin
    Caret := Add(0, 0, 0);
    Caret.Visible := False;
    FDefaultCaret := Caret;
  end;
  Result := FDefaultCaret;
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

function TCarets.GetLineNeighboursOnRight(Caret: TCaretItem): TList<TCaretItem>;
var
  Iter: TCaretItem;
begin
  FLine.Clear;
  for Iter in FList do begin
    if (Iter <> Caret) and (Iter.PosY = Caret.PosY) and (Iter.PosX > Caret.PosX) then begin
      FLine.Add(Iter)
    end;
  end;
  FLine.Sort(TComparer<TCaretItem>.Construct(CompareCarets));
  Result := FLine;
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

function TCarets.Load(const B: TBytes): Boolean;
var
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;
  try
    M.Write(Pointer(B)^, Length(B));
    M.Seek(0, soFromBeginning);
    Result := LoadFromStream(M);
  finally
    M.Free
  end;
end;

function TCarets.LoadFromStream(S: TStream): Boolean;
var
  DefCaretIndex, Count, I, J: Integer;
  Pos, LastPos: Int64;
  NewList: TList<TCaretItem>;
  Caret: TCaretItem;
begin
  Result := False;
  Pos := S.Position;
  LastPos := S.Seek(0, soFromEnd);
  if (LastPos - Pos) < (SizeOf(DefCaretIndex) + SizeOf(Count)) then
    Exit(False);
  S.Position := Pos;
  S.Read(DefCaretIndex, SizeOf(DefCaretIndex));
  S.Read(Count, SizeOf(Count));
  NewList := TList<TCaretItem>.Create;
  try
    try
      for I := 1 to Count do begin
        Caret := TCaretItem.Create;
        Caret.Index := I-1;
        if not Caret.LoadFromStream(S) then
          Abort;
        NewList.Add(Caret);
      end;
      Clear(False);
      for I := 0 to NewList.Count-1 do begin
        Caret := NewList[I];
        FList.Add(Caret);
        Caret.Index := I;
        if Caret.Index = DefCaretIndex then
          FDefaultCaret := Caret;
      end;
      Result := True;
      if Assigned(FOnChanged) then
        FOnChanged(Self);
    except on EAbort do
      for J := 0 to NewList.Count-1 do
        NewList[J].Free;
    end;
  finally
    NewList.Free
  end;
end;

procedure TCarets.SaveToStream(S: TStream);
var
  DefCaretIndex, Count, I: Integer;
  Caret: TCaretItem;
begin
  if Assigned(FDefaultCaret) then
    DefCaretIndex := FDefaultCaret.Index
  else
    DefCaretIndex := -1;
  S.Write(DefCaretIndex, SizeOf(DefCaretIndex));
  Count := FList.Count;
  S.Write(Count, SizeOf(Count));
  for Caret in FList do
    Caret.SaveToStream(S);
end;

function TCarets.Sorted: TList<TCaretItem>;
var
  Iter: TCaretItem;
begin
  FSortedList.Clear;
  for Iter in FList do
    FSortedList.Add(Iter);
  FSortedList.Sort(TComparer<TCaretItem>.Construct(CompareCarets));
  Result := FSortedList;
end;

function TCarets.Store: TBytes;
var
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;
  try
    SaveToStream(M);
    SetLength(Result, M.Position);
    M.Seek(0, soFromBeginning);
    M.Read(Pointer(Result)^, Length(Result))
  finally
    M.Free
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

destructor TCaretItem.Destroy;
begin
  // Raise events to repaint Editor rect
  Visible := False;
  inherited;
end;

function TCaretItem.LoadFromStream(S: TStream): Boolean;
begin
  Result := (S.Read(FPosX, SizeOf(FPosX)) = SizeOf(FPosX))
    and (S.Read(FPosY, SizeOf(FPosY)) = SizeOf(FPosY))
    and (S.Read(FSelLen, SizeOf(FSelLen)) = SizeOf(FSelLen))
    and (S.Read(FVisible, SizeOf(FVisible)) = SizeOf(FVisible))
end;

procedure TCaretItem.SaveToStream(S: TStream);
begin
  S.Write(FPosX, SizeOf(FPosX));
  S.Write(FPosY, SizeOf(FPosY));
  S.Write(FSelLen, SizeOf(FSelLen));
  S.Write(FVisible, SizeOf(FVisible));
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
  InvertRects;
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

function TMultiCaretController.CaretSelectionRect(Caret: TCaretItem): TRect;
begin
  Result := TRect.Create(Caret.ToPoint, -Caret.SelLen, FEditor.TextHeight);
  Result.NormalizeRect;
end;

constructor TMultiCaretController.Create(Editor: IAbstractEditor);
var
  I: Integer;

begin
  FBlinkTimer := TTimer.Create(nil);
  FBlinkTimer.Interval := GetCaretBlinkTime;
  FBlinkTimer.OnTimer := Blink;
  FBlinkTimer.Enabled := False;

  FCarets := TCarets.Create;
  FCarets.OnChanged := DoCaretsChanged;
  FCarets.OnBeforeClear := DoBeforeAfterCaretsClear;
  FCarets.OnAfterClear := DoBeforeAfterCaretsClear;

  FCommandsList := TList<Integer>.Create;
  for I := 0 to High(SANDBOX_COMMANDS) do
    FCommandsList.Add(SANDBOX_COMMANDS[I]);
  FCommandsList.Sort;

  FEditor := Editor;
  FEditor.RegisterCommandHandler(EditorCommandSandBoxEntryPoint, nil);
end;

procedure TMultiCaretController.DefaultCaretMoved(const PointFrom,
  PointTo: TPoint);
var
  Caret: TCaretItem;
  Delta: TPoint;
  NewPos: TPoint;
begin
  if FSandBoxContext then begin
    Delta.X := PointTo.X - PointFrom.X;
    Delta.Y := PointTo.Y - PointFrom.Y;
    for Caret in FCarets do begin
      if Caret = Carets.FDefaultCaret then
        Continue;
      // prepare
      NewPos := TPoint.Create(Caret.PosX + Delta.X, Caret.PosY + Delta.Y);
      NewPos := FEditor.DisplayCoord2CaretXY(FEditor.PixelsToNearestRowColumn(NewPos.X, NewPos.Y));
      // apply new values
      Caret.PosX := NewPos.X;
      Caret.PosY := NewPos.Y;
    end;
  end;
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

  procedure ProcessCaret(Crt: TCaretItem);
  begin
    if Crt.Visible then begin
      R := CaretPointToRect(Crt.ToPoint);
      if IntersectRect(R2, R, FEditor.GetClientRect) then
        InvertRect(FEditor.GetCanvas.Handle, R);
    end;
  end;

begin
  for Caret in FCarets do
    ProcessCaret(Caret);
end;


procedure TMultiCaretController.InvertShown;
begin
  FShown := not FShown
end;

function TMultiCaretController.IsSelectionCommand(Command: TSynEditorCommand): Boolean;
begin
  Result := InRange(Command, ecSelLeft, ecSelGotoXY)
end;

procedure TMultiCaretController.MoveX(Delta: Integer);
var
  Caret: TCaretItem;
begin
  for Caret in FCarets do begin
    Caret.PosX := Caret.PosX + Delta
  end;
end;

procedure TMultiCaretController.MoveY(Delta: Integer);
var
  Caret: TCaretItem;
begin
  for Caret in FCarets do begin
    Caret.PosY := Caret.PosY + Delta
  end;
end;

procedure TMultiCaretController.DoBeforeAfterCaretsClear(Sender: TObject);
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
  if Sender = Carets.FDefaultCaret then
    DefaultCaretMoved(PointFrom, PointTo);
end;

procedure TMultiCaretController.Paint;
var
  Caret: TCaretItem;
  Rect: TRect;
begin
  if FShown then
    InvertRects;
  // repaint selection area
  for Caret in FCarets do begin
    if Caret.SelLen <> 0 then begin
      Rect := CaretSelectionRect(Caret);
      FEditor.Canvas.Brush.Color := clBlue;
      FEditor.Canvas.Brush.Style := bsSolid;
      InvertRect(FEditor.GetCanvas.Handle, Rect);
     // FEditor.Canvas.FillRect(Rect);
//
//      FEditor.InvalidateRect(R, False);
    end;
  end;
end;

procedure TMultiCaretController.SandBox(Command: TSynEditorCommand;
  AChar: WideChar; Data: Pointer);
var
  DefCaret, ActiveCaret: TCaretItem;
  DeltaX, DeltaY, NewSelLen: Integer;
  BeforeXY, AfterXY, DeltaXY: TPoint;
  BlockBegin, BlockEnd: TBufferCoord;
  RightLineSide, BottomColumnSide: TList<TCaretItem>;
  Neighbour: TCaretItem;
begin
  // Store context
  DefCaret := FCarets.FDefaultCaret;
  BlockBegin := FEditor.BlockBegin;
  BlockEnd := FEditor.BlockEnd;
  //
  FEditor.BeginUpdate;
  if not IsSelectionCommand(Command) then begin
    FEditor.UndoList.BeginMultiBlock;
    FEditor.UndoList.AddMultiCaretChange(FCarets.Store);
  end;
  try
    for ActiveCaret in FCarets do begin
      // implicitly set default caret
      FCarets.FDefaultCaret := ActiveCaret;
      FEditor.ComputeCaret(ActiveCaret.PosX, ActiveCaret.PosY);
      BeforeXY := FEditor.DisplayCoord2CaretXY(FEditor.GetDisplayXY);
      // neighbours
      RightLineSide := FCarets.GetLineNeighboursOnRight(ActiveCaret);
      BottomColumnSide := FCarets.GetColumnNeighboursOnBottom(ActiveCaret);
      // store Editor context
      FEditor.BlockBegin := FEditor.DisplayToBufferPos(FEditor.GetDisplayXY);
      FEditor.ExecuteCommand(Command, AChar, Data);
      // deltas
      AfterXY := FEditor.DisplayCoord2CaretXY(FEditor.BufferToDisplayPos(FEditor.GetCaretXY));
      DeltaXY := AfterXY.Subtract(BeforeXY);
      // correct neighbours coords according to deltas
      if (RightLineSide.Count > 0) and (DeltaXY.X > 0) then begin
        for Neighbour in RightLineSide do
          Neighbour.PosX := Neighbour.PosX + DeltaXY.X
      end;
      if (BottomColumnSide.Count > 0) and (DeltaXY.Y > 0) then begin
        for Neighbour in BottomColumnSide do
          Neighbour.PosY := Neighbour.PosY + DeltaXY.Y
      end;
    end;
    if IsSelectionCommand(Command) then begin
      NewSelLen := ActiveCaret.SelLen + AfterXY.X - BeforeXY.X;
      for ActiveCaret in FCarets do begin
        ActiveCaret.SelLen := NewSelLen
      end;
    end;
  finally
    if not IsSelectionCommand(Command) then begin
      FEditor.UndoList.EndMultiBlock;
    end;
    FEditor.EndUpdate;
    // Restore context
    FCarets.FDefaultCaret := DefCaret;
    FEditor.BlockBegin := BlockBegin;
    FEditor.BlockEnd := BlockEnd;
  end;
end;

procedure TMultiCaretController.SetActive(const Value: Boolean);
begin
  if FActive <> Value then begin
    if FShown then
      InvertRects;
    FActive := Value;
    FShown := False;
    FBlinkTimer.Enabled := Value;
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

{$IFDEF DEBUG}
procedure TMultiCaretController.ShowDebugState;
var
  Comma: TStringList;
  Caret: TCaretItem;
  S: string;
begin
  Comma := TStringList.Create;
  try
    Comma.Add(Format('FShown: %s, FActive: %s',
      [BoolToStr(FShown, True), BoolToStr(FActive, True)]));
    Comma.Add('Carets: ');
    for Caret in FCarets do begin
      S := Format('[X: %d; Y: %d; Visible: %s]', [Caret.PosX, Caret.PosY, BoolToStr(Caret.Visible, True)]);
      Comma.Add(S)
    end;
    S := Comma.CommaText;
    OutputDebugString(PChar(S));
  finally
    Comma.Free;
  end;
end;
procedure TMultiCaretController.Unselect;
var
  Caret: TCaretItem;
begin
  for Caret in FCarets do begin
    Caret.SelLen := 0;
  end;
end;

{$ENDIF}

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
end;

procedure TMultiCaretController.DoCaretSelLenChanged(Sender: TCaretItem;
  const ValueFrom, ValueTo: Integer);
begin
  // nothing
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

procedure TMultiCaretController.EditorCommandSandBoxEntryPoint(Sender: TObject;
  AfterProcessing: Boolean; var Handled: Boolean;
  var Command: TSynEditorCommand; var AChar: WideChar; Data,
  HandlerData: pointer);
begin
  if FCarets.Count > 1 then begin
    Handled := (not AfterProcessing) and (FCommandsList.IndexOf(Command) <> -1);
    if Handled then begin
      if not FSandBoxContext then begin
        FSandBoxContext := True;
        try
          SandBox(Command, AChar, Data);
        finally
          FSandBoxContext := False;
        end;
      end;
    end
  end
  else
    Handled := False
end;

function TMultiCaretController.Exists(const PosX, PosY: Integer): Boolean;
var
  Iter: TCaretItem;
  IterRect, TmpRect, ShotRect: TRect;

begin
  Result := False;
  for Iter in FCarets do begin
    IterRect := CaretPointToRect(Iter.ToPoint);
    ShotRect := CaretPointToRect(TPoint.Create(PosX, PosY));
    if IntersectRect(TmpRect, ShotRect, IterRect) then
      Exit(True)
  end;
end;

procedure TMultiCaretController.Flash;
begin
  {$IFDEF DEBUG}
  OutputDebugString('Flash');
  {$ENDIF}
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
  FillChar(Offset, SizeOf(Offset), 0);
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
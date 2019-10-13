// generates formatted Pascal code from a token collection
// Original Author:     Egbert van Nes (http://www.dow.wau.nl/aew/People/Egbert_van_Nes.html)
// Contributors:        Thomas Mueller (http://www.dummzeuch.de)
//                      Jens Borrisholt (Jens@borrisholt.dk) - Cleaning up the code, and making it aware of several language features

unit GX_CodeFormatterFormatter;

{$I GX_CondDefine.inc}

// this unit uses Assert(False, 'trace') for trace logging (for the line numbers)
// by default, we turn it off
{$C-}
{$IFDEF ASSERT_TRACING}
{$C+}
{$ENDIF}

interface

uses
  SysUtils,
  Classes,
  GX_GenericUtils,
  GX_CodeFormatterTypes,
  GX_CodeFormatterStack,
  GX_CodeFormatterTokens,
  GX_CodeFormatterTokenList,
  GX_CodeFormatterSettings;

type
  TCodeFormatterFormatter = class
  private
    FSettings: TCodeFormatterSettings;
    FTokens: TPascalTokenList;
    FTokenIdx: Integer;
    FPrevToken: TPascalToken;
    FCurrentToken: TPascalToken;
    FCurrentRType: TReservedType;
    FPrevLine: TLineFeed;
    FPrevPrevLine: TLineFeed;
    FHasAligned: Boolean;
    // the StackStack is used to preserve indenting over IFDEF/ELSE/ENDIF statments
    FStackStack: TCodeFormatterStack;
    FStack: TCodeFormatterSegment;
    FLastPopResType: TReservedType;
    // True between 'interface' and 'implementation'
    FIsInInterfacePart: Boolean;
    FWrapIndent: Boolean;
    // stores WrapIndent from before an opening bracket until the closing one
    FOldWrapIndent: Boolean;
    procedure UppercaseCompilerDirective(_Token: TPascalToken);
    function NoBeginTryIndent(_rType: TReservedType): Boolean;
    procedure SetPrevLineIndent(_Additional: Integer);
    procedure DecPrevLineIndent;

    {: replaces a TExpression with a TAlignExpression }
    function AlignExpression(_Idx: Integer; _Pos: Integer): TPascalToken;
    procedure CheckWrapping;
    function PrevTokenIsRType(_rType: TReservedType): Boolean;
    function PrevTokenIsWType(_wType: TWordType): Boolean;
    procedure CheckBlankLinesAroundProc;
    procedure PutCommentBefore(const _Comment: TGXUnicodeString);
    procedure FormatAsm(_NTmp: Integer);
    procedure AdjustSpacing(_CurrentToken, _PrevToken: TPascalToken; _TokenIdx: Integer);

    {: return token with index Idx or nil if out of bounds }
    function GetToken(_Idx: Integer): TPascalToken; overload;
    {: get token with index Idx, returns False if index is out of bounds }
    function GetToken(_Idx: Integer; out _Token: TPascalToken): Boolean; overload;

    {: Check whether the token at index Idx has the reserved type RType
       @param Idx is the index of the token to check
       @param RType is the queried reserverd type
       @returns true, if the token has the queried type, false otherwise }
    function TokenAtIs(_Idx: Integer; _rType: TReservedType): Boolean;

    function GetNextNoComment(_StartPos: Integer; out _Offset: Integer): TPascalToken; overload;
    function GetNextNoComment(_StartPos: Integer; out _Token: TPascalToken; out _Offset: Integer): Boolean; overload;
    function GetNextNoComment(_StartPos: Integer; out _Token: TPascalToken): Boolean; overload;

    function InsertBlankLines(_AtIndex, _NLines: Integer): TLineFeed;
    function AssertLineFeedAfter(_StartPos: Integer): TLineFeed;
    procedure CheckSlashComment;
    procedure ComplexIfElse(_NTmp: Integer);
    procedure CheckShortLine;

    ///<summary>
    /// This function does the actual formatting </summary>
    procedure doExecute(_Tokens: TPascalTokenList);
    procedure HandleIf;
    procedure HandleThen;
    procedure HandleColon(_RemoveMe: Integer);
    procedure HandleElse(_NTmp: Integer);
    function DetectGenericStart(_TokenIdx: Integer): Boolean;
    procedure CheckIndent(var NTmp: Integer; var PrevOldNspaces: Integer);
    procedure HandleCapitalization(_CurrentToken: TPascalToken);
    property Settings: TCodeFormatterSettings read FSettings write FSettings;
  public
    class procedure Execute(_Tokens: TPascalTokenList; _Settings: TCodeFormatterSettings);
    constructor Create(_Settings: TCodeFormatterSettings);
    destructor Destroy; override;
  end;

implementation

uses
{$IFDEF GX_VER250_up}
  AnsiStrings,
{$ENDIF}
  GX_CodeFormatterUnicode,
  GX_dzAssertTrace;

class procedure TCodeFormatterFormatter.Execute(_Tokens: TPascalTokenList; _Settings: TCodeFormatterSettings);
var
  Formatter: TCodeFormatterFormatter;
begin
  Formatter := TCodeFormatterFormatter.Create(_Settings);
  try
    Formatter.doExecute(_Tokens);
  finally
    Formatter.Free;
  end;
end;

constructor TCodeFormatterFormatter.Create(_Settings: TCodeFormatterSettings);
begin
  inherited Create;
  FSettings := _Settings;
  FHasAligned := False;
  FPrevLine := nil;
  FStack := TCodeFormatterSegment.Create;
end;

destructor TCodeFormatterFormatter.Destroy;
begin
  FStack.Free;
  inherited;
end;

function TCodeFormatterFormatter.AlignExpression(_Idx: Integer; _Pos: Integer): TPascalToken;
var
  OldExpr: TExpression;
begin
  FHasAligned := True;
  OldExpr := TExpression(FTokens.Extract(_Idx));
  Result := TAlignExpression.Create(OldExpr, _Pos);
  FTokens.AtInsert(_Idx, Result);
  OldExpr.Free;
end;

function TCodeFormatterFormatter.DetectGenericStart(_TokenIdx: Integer): Boolean;
var
  Next: TPascalToken;
  Idx: Integer;
  Offset: Integer;
  exp: TGXUnicodeString;
  rType: TReservedType;
begin
  Result := False;

  if FCurrentRType <> rtLogOper then
    Exit; //==>

  if not FCurrentToken.GetExpression(exp) or (exp <> '<') then
    Exit; //==>

  if not PrevTokenIsWType(wtWord) then
    Exit; //==>

  Idx := 0;
  rType := FStack.GetType(Idx);
  while rType = rtGenericStart do begin
    Inc(Idx);
    rType := FStack.GetType(Idx);
  end;
  if rType in [rtClass, rtType, rtVar, rtProcedure, rtProcDeclare] then begin
    Result := True;
    Exit; //==>
  end;

  // These were the easy cases.
  // Now we must detect whether a '<' is followed by a '>' with reasonable intermediate tokens.

  if not GetNextNoComment(_TokenIdx, Next, Offset) then
    Exit; //==>

  // the next token must be an identifier (= rtNothing) (correct?)
  if (Next.ReservedType <> rtNothing) or (Next.WordType <> wtWord) then
    Exit; //==>

  Idx := _TokenIdx + Offset;
  while GetNextNoComment(Idx, Next, Offset) do begin
    case Next.ReservedType of
      rtLogOper: begin
          if Next.GetExpression(exp) and (exp = '>') then begin
            Result := True;
            Exit; //==>
          end;
          // no '>' ? -> no Generic
          Exit; //==>
        end;
      // also allowed:
      rtNothing: begin
          // but only an identifier (correct?)
          if Next.WordType <> wtWord then
            Exit; //==>
        end;
      rtComma: begin
        // OK
        end;
      // anything else?
    else
      Exit; //==>
    end;
    Inc(Idx, Offset + 1);
  end;
end;

procedure TCodeFormatterFormatter.HandleCapitalization(_CurrentToken: TPascalToken);
var
  rType: TReservedType;
  wType: TWordType;
begin
  rType := _CurrentToken.ReservedType;
  wType := _CurrentToken.WordType;

  if not (rType in NoReservedTypes) then
    _CurrentToken.ExpressionCase := Settings.ReservedCase
  else if rType in StandardDirectives then
    _CurrentToken.ExpressionCase := Settings.StandDirectivesCase
  else begin
    _CurrentToken.ExpressionCase := rfUnchanged;
    if wType = wtWord then begin
      // todo: this shouldn't be a method of the Settings object
      Settings.HandleCapitalization(_CurrentToken);
    end;
  end;
end;

procedure TCodeFormatterFormatter.AdjustSpacing(_CurrentToken, _PrevToken: TPascalToken; _TokenIdx: Integer);
var
  Prev2: TPascalToken;
  rType: TReservedType;
  wType: TWordType;
  Idx: Integer;
  exp: TGXUnicodeString;
begin
  if _CurrentToken = nil then
    Exit;

  rType := _CurrentToken.ReservedType;
  wType := _CurrentToken.WordType;

  { TODO -otwm : This doesn't really belong here, it has nothing to do with spacing
                 it also unnecessarily sets each token's case three times }
  HandleCapitalization(_CurrentToken);

  Assert(False, 'trace');
  case rType of
    rtThen, rtOf, rtElse, rtDo, rtAsm: begin
        Assert(False, 'trace');
        _CurrentToken.SetSpace([spBefore, spAfter], True);
      end;

    rtEnd, rtFuncDirective: begin
        Assert(False, 'trace');
        _CurrentToken.SetSpace([spBefore], True);
      end;

    rtIf, rtUntil, rtWhile, rtCase, rtRecord: begin
        Assert(False, 'trace');
        _CurrentToken.SetSpace([spAfter], True);
      end;

    rtLogOper: begin
        Assert(False, 'trace');
        if not _CurrentToken.GetExpression(exp) then
          raise EFormatException.Create('Programmer error: GetExpression for logical operator returned False');

        if (exp = '<') then begin
          Assert(False, 'trace');
          if DetectGenericStart(_TokenIdx) then begin
            Assert(False, 'trace');
            FStack.Push(rtGenericStart, 0);
            _CurrentToken.SetSpace([], True)
          end else begin
            Assert(False, 'trace');
            _CurrentToken.SetSpace(Settings.SpaceOperators, True);
          end;
        end else if exp = '>' then begin
          Assert(False, 'trace');
          if FStack.HasType(rtGenericStart) then begin
            Assert(False, 'trace');
            _CurrentToken.SetSpace([], True);
            repeat
              Assert(False, 'trace');
              FLastPopResType := FStack.Pop;
            until (FLastPopResType = rtGenericStart) or FStack.IsEmpty;
          end else
            _CurrentToken.SetSpace(Settings.SpaceOperators, True);
        end else
          _CurrentToken.SetSpace(Settings.SpaceOperators, True);
      end;

    rtOper, rtMathOper, rtPlus, rtMinus, rtEquals: begin
        Assert(False, 'trace');
        _CurrentToken.SetSpace(Settings.SpaceOperators, True);
      end;

    rtAssignOper: begin
        Assert(False, 'trace');
        _CurrentToken.SetSpace(Settings.SpaceEqualOper, True);
      end;

    rtColon: begin
        Assert(False, 'trace');
        _CurrentToken.SetSpace(Settings.SpaceColon, True);
      end;

    rtSemiColon: begin
        Assert(False, 'trace');
        _CurrentToken.SetSpace(Settings.SpaceSemiColon, True);
      end;

    rtComma: begin
        Assert(False, 'trace');
        _CurrentToken.SetSpace(Settings.SpaceComma, True);
      end;

    rtLeftBr: begin
        Assert(False, 'trace');
        _CurrentToken.SetSpace(Settings.SpaceLeftBr, True);
        if _PrevToken.ReservedType = rtLeftBr then begin
          Assert(False, 'trace');
          _CurrentToken.SetSpace([spBefore], False);
        end;
      end;

    rtLeftHook: begin
        Assert(False, 'trace');
        _CurrentToken.SetSpace(Settings.SpaceLeftHook, True);
        if _PrevToken.ReservedType = rtLeftHook then begin
          Assert(False, 'trace');
          _CurrentToken.SetSpace([spBefore], False);
        end;
      end;

    rtRightBr: begin
        Assert(False, 'trace');
        _CurrentToken.SetSpace(Settings.SpaceRightBr, True);
      end;

    rtRightHook: begin
        Assert(False, 'trace');
        _CurrentToken.SetSpace(Settings.SpaceRightHook, True);
      end;
  end;

  // todo: This doesn't belong here, it's about the case of hex numbers, not spacing
  if (wType = wtHexNumber) and Settings.UpperNumbers then begin
    Assert(False, 'trace');
    _CurrentToken.SetExpressionCase(rfUpperCase);
  end;

  { delimiter between 2 words (necessary) }

  if _PrevToken = nil then begin
    Assert(False, 'trace');
    Exit;
  end;

  { append space after : , ; }
  if Settings.SpaceOperators <> [] then begin
    Assert(False, 'trace');
    if wType in [wtString, wtFullComment, wtHalfComment, wtHalfStarComment] then begin
      Assert(False, 'trace');
      if not (_PrevToken.ReservedType in [rtDotDot, rtLineFeed]) then begin
        Assert(False, 'trace');
        _CurrentToken.SetSpace([spBefore], True);
      end;
    end;
  end;

  if rType in [rtMinus, rtPlus] then begin
    Prev2 := _PrevToken;
    Idx := 0;

    while (Prev2 <> nil) and (Prev2.ReservedType in [rtComment, rtLineFeed]) do begin
      Assert(False, 'trace');
      Inc(Idx);
      if Idx > _TokenIdx then begin
        Assert(False, 'trace');
        Prev2 := nil;
      end else begin
        Assert(False, 'trace');
        Prev2 := FTokens[_TokenIdx - Idx];
      end;
    end;

    if (Prev2 <> nil) and (Prev2.ReservedType in [rtOper,
      rtMathOper, rtPlus, rtMinus, rtSemiColon, rtOf,
        rtMinus, rtLogOper, rtEquals, rtAssignOper, rtLeftBr,
        rtLeftHook, rtComma, rtDefault]) then begin
      Assert(False, 'trace');
      _CurrentToken.SetSpace([spAfter], False); { sign operator }
    end;
  end;

  if rType = rtLeftHook then begin
    Assert(False, 'trace');
    if not (_PrevToken.ReservedType in [rtReserved, rtNothing, rtRightBr, rtRightHook]) then begin
      Assert(False, 'trace');
      _CurrentToken.SetSpace([spBefore], True);
    end;
  end;

  if _CurrentToken.Space(spBefore)
    and (_PrevToken.ReservedType in [rtLeftBr, rtLeftHook, rtLineFeed]) then begin
    Assert(False, 'trace');
    _CurrentToken.SetSpace([spBefore], False);
  end;

  if (_PrevToken.WordType in [wtWord, wtNumber, wtHexNumber, wtString])
    and (wType in [wtWord, wtNumber, wtHexNumber]) then begin
    Assert(False, 'trace');
    _CurrentToken.SetSpace([spBefore], True);
  end;

  if _CurrentToken.Space(spBefore) and _PrevToken.Space(spAfter) then begin
    Assert(False, 'trace');
    _PrevToken.SetSpace([spAfter], False); { avoid double spaces }
  end;
end;

function TCodeFormatterFormatter.TokenAtIs(_Idx: Integer; _rType: TReservedType): Boolean;
var
  Token: TPascalToken;
begin
  Result := GetToken(_Idx, Token);
  if Result then
    Result := (Token.ReservedType = _rType);
end;

function TCodeFormatterFormatter.GetToken(_Idx: Integer): TPascalToken;
begin
  GetToken(_Idx, Result);
end;

function TCodeFormatterFormatter.GetToken(_Idx: Integer; out _Token: TPascalToken): Boolean;
begin
  Result := (_Idx >= 0) and (_Idx < FTokens.Count);
  if Result then
    _Token := FTokens[_Idx]
  else
    _Token := nil;
end;

function TCodeFormatterFormatter.GetNextNoComment(_StartPos: Integer; out _Offset: Integer): TPascalToken;
begin
  if not GetNextNoComment(_StartPos, Result, _Offset) then
    Result := nil;
end;

function TCodeFormatterFormatter.GetNextNoComment(_StartPos: Integer; out _Token: TPascalToken; out _Offset: Integer): Boolean;
begin
  _Offset := 0;

  repeat
    Inc(_Offset);
    Result := GetToken(_StartPos + _Offset, _Token);
  until not Result or (_Token.ReservedType <> rtComment);
end;

function TCodeFormatterFormatter.GetNextNoComment(_StartPos: Integer; out _Token: TPascalToken): Boolean;
var
  Offset: Integer;
begin
  Result := GetNextNoComment(_StartPos, _Token, Offset);
end;

function TCodeFormatterFormatter.InsertBlankLines(_AtIndex, _NLines: Integer): TLineFeed;
var
  LineIdx: Integer;
  NextToken: TPascalToken;
begin
  Result := FPrevLine;

  for LineIdx := 0 to _NLines - 1 do begin //FI:W528
    Result := TLineFeed.Create(0, Settings.SpacePerIndent);
    Result.SetIndent(FStack.nIndent);
    NextToken := GetToken(_AtIndex);

    { TODO -otwm -ccheck : is the if statement necessary? }
    if NextToken.Space(spBefore) then
      NextToken.SetSpace([spBefore], False);

    FTokens.AtInsert(_AtIndex, Result);
    AdjustSpacing(NextToken, Result, _AtIndex);
  end;

  if _AtIndex <= FTokenIdx then
    Inc(FTokenIdx, _NLines);
end;

function TCodeFormatterFormatter.AssertLineFeedAfter(_StartPos: Integer): TLineFeed;
var
  Next: TPascalToken;
  Offset: Integer;
begin
  if GetNextNoComment(_StartPos, Next, Offset) and (Next.ReservedType <> rtLineFeed) then
    Result := InsertBlankLines(_StartPos + Offset, 1)
  else
    Result := FPrevLine;
end;

procedure TCodeFormatterFormatter.DecPrevLineIndent;
begin
  if FPrevLine <> nil then
    FPrevLine.IncIndent(-1);
end;

procedure TCodeFormatterFormatter.SetPrevLineIndent(_Additional: Integer);
begin
  if FPrevLine <> nil then
    FPrevLine.SetIndent(FStack.nIndent + _Additional + FStack.ProcLevel);
end;

function TCodeFormatterFormatter.NoBeginTryIndent(_rType: TReservedType): Boolean;
begin
  Result := not (
    (Settings.IndentBegin and (_rType = rtBegin))
    or (Settings.IndentTry and (_rType = rtTry))
    )
    and (FStack.GetTopType in [rtDo, rtThen, rtIfElse]);
end;

procedure TCodeFormatterFormatter.UppercaseCompilerDirective(_Token: TPascalToken);
var
  Idx: Integer;
  s: TGXUnicodeString;
begin
  _Token.GetExpression(s);
  Idx := 2;
  while (Idx < Length(s)) and (s[Idx] <> Space) and (s[Idx] <> Tab) do begin
    s[Idx] := UpCase(s[Idx]);
    Inc(Idx);
  end;

  _Token.SetExpression(s);
end;

function TCodeFormatterFormatter.PrevTokenIsRType(_rType: TReservedType): Boolean;
begin
  Result := Assigned(FPrevToken) and (FPrevToken.ReservedType = _rType);
end;

function TCodeFormatterFormatter.PrevTokenIsWType(_wType: TWordType): Boolean;
begin
  Result := Assigned(FPrevToken) and (FPrevToken.WordType = _wType);
end;

{: checks and corrects the number of blank lines before a procedure / function declaration }

procedure TCodeFormatterFormatter.CheckBlankLinesAroundProc;
var
  k: Integer;
  Prev2: TPascalToken;
begin
  if (FPrevToken <> nil) then begin
    k := 1;
    if FPrevToken.ReservedType = rtClass then begin
      // class procedure / function
      k := 2;
      Prev2 := GetToken(FTokenIdx - 2);
    end else // just procedure / function
      Prev2 := FPrevToken;
    if (Prev2 <> nil) and (Prev2.ReservedType <> rtLineFeed) then begin
      // no line feed at all -> add two for an empty line
      FPrevLine := InsertBlankLines(FTokenIdx - k, 2);
      FPrevToken := FPrevLine;
    end else begin
      // we got one linefeed already, check if there is another one -> empty line
      Inc(k);
      if GetToken(FTokenIdx - k, Prev2) and (Prev2.ReservedType <> rtLineFeed) then begin
        // no, only one -> add one for an empty line
        FPrevLine := InsertBlankLines(FTokenIdx - k + 1, 1);
        FPrevToken := FPrevLine;
      end;
    end;
  end;
end;

procedure TCodeFormatterFormatter.PutCommentBefore(const _Comment: TGXUnicodeString);
var
  j: Integer;
  P: TPascalToken;
  s: TGXUnicodeString;
begin
  j := FTokenIdx - 2;
  P := GetToken(j);

  s := _Comment;

  if P.ReservedType = rtComment then
    P.SetExpression(s)
  else begin
    P := TExpression.Create(wtWord, s);
    P.SetReservedType(rtComment);
    FTokens.AtInsert(FTokenIdx, P);
    Inc(FTokenIdx);
    P := TLineFeed.Create(0, Settings.SpacePerIndent);
    TLineFeed(P).SetIndent(FStack.nIndent);
    FTokens.AtInsert(FTokenIdx, P);
    Inc(FTokenIdx);
  end;
end;

// When we enter this method FCurrentToken is 'asm' and FCurrentRType os rtAsm

procedure TCodeFormatterFormatter.FormatAsm(_NTmp: Integer);
begin
  // remove var / type stuff
  while FStack.GetTopType in [rtVar, rtType] do
    FStack.Pop;

  // no additional indentation for
  // procedure xxx;
  // asm
  if FStack.GetTopType = rtProcedure then begin
    FStack.Pop;
    DecPrevLineIndent;
  end;

  FStack.Push(FCurrentRType, 0);

  // twm: now we handle all asm statements until we hit an 'end'
  // rather ugly
  FCurrentToken := GetToken(FTokenIdx);

  while (FTokenIdx < FTokens.Count - 1) and (FCurrentToken.ReservedType <> rtEnd) do begin
    if FCurrentToken.ReservedType = rtLineFeed then begin
      FPrevLine := TLineFeed(FCurrentToken);
      FPrevLine.NoOfSpaces := FPrevLine.OldNoOfSpaces;
    end;

    AdjustSpacing(FCurrentToken, FPrevToken, FTokenIdx);
    Inc(FTokenIdx);
    FPrevToken := FCurrentToken;
    FCurrentToken := GetToken(FTokenIdx);
  end;

  if FTokenIdx < FTokens.Count then
    SetPrevLineIndent(_NTmp);

  Dec(FTokenIdx);
end;

procedure TCodeFormatterFormatter.CheckSlashComment;
var
  Token: TPascalToken;
  PrevPasWord: TPascalToken;
  Expression: TGXUnicodeString;
  PrevExpression: TGXUnicodeString;
  i: Integer;
begin
  if GetToken(FTokenIdx - 1, FPrevToken) and (FPrevToken.ReservedType = rtComment)
    and FPrevToken.GetExpression(PrevExpression) and (PrevExpression[1] = '/') then begin
    // fix for situation with a // comment on prev line: begin becomes part of the comment
    if FPrevToken.ChangeComment('{') then begin
      FPrevToken.SetSpace([spAfter], True);
    end else begin
      i := 0;
      Token := nil;

      repeat
        PrevPasWord := Token;
        Token := GetToken(FTokenIdx + i);
        Inc(i);
      until (Token = nil) or (Token.ReservedType = rtLineFeed);

      Dec(i);
      if (PrevPasWord.ReservedType = rtComment)
        and PrevPasWord.GetExpression(Expression)
        and (Expression[1] = '/') then begin
        FPrevToken.SetExpression('{' + Copy(PrevExpression, 2, 999999) + '}');
        Exit;
      end else
        FTokens.Extract(FTokenIdx - 1);

      FTokens.AtInsert(FTokenIdx + i, FPrevToken);
      FPrevToken := GetToken(FTokenIdx - 1);
      AdjustSpacing(FPrevToken, GetToken(FTokenIdx - 2), FTokenIdx - 1);
      FCurrentToken := GetToken(FTokenIdx);
    end;
  end;

  FPrevLine := FPrevPrevLine;
end;

procedure TCodeFormatterFormatter.ComplexIfElse(_NTmp: Integer);
begin
  while not FStack.IsEmpty and (FLastPopResType <> rtThen) do begin
    FLastPopResType := FStack.Pop;
    if FLastPopResType = rtIfElse then
      ComplexIfElse(_NTmp);
  end;

  SetPrevLineIndent(_NTmp);
end;

procedure TCodeFormatterFormatter.CheckShortLine;
var
  Token: TPascalToken;

  function TokenRType: TReservedType;
  begin
    if Token = nil then
      Result := rtNothing
    else
      Result := Token.ReservedType;
  end;

var
  Offset: Integer;
begin { CheckShortLine }
  Offset := 1;
  Token := GetToken(FTokenIdx + Offset);
  if TokenRType <> rtLineFeed then
    Exit;

  while not ((TokenRType in [rtSemiColon, rtBegin, rtElse, rtDo, rtWhile, rtOn, rtThen, rtCase])
    or ((Offset > 1) and (Token.ReservedType = rtLineFeed))) do begin
    Inc(Offset);
    Token := GetToken(FTokenIdx + Offset);
  end;

  if TokenRType = rtSemiColon then
    FTokens.Extract(FTokenIdx + 1).Free;
end;

procedure TCodeFormatterFormatter.HandleIf;
begin
  if Settings.FeedAfterThen and not Settings.FeedElseIf
    and (FStack.GetTopType = rtIfElse) and (FPrevToken = FPrevLine) then begin
    FTokens.Extract(FTokenIdx - 1).Free;
    Dec(FTokenIdx);
    CheckSlashComment;
  end else begin
    if Settings.FeedElseIf and (FPrevToken <> FPrevLine) then begin
      FPrevLine := AssertLineFeedAfter(FTokenIdx - 1);
      FPrevToken := FPrevLine;
    end;
  end;

  if PrevTokenIsRType(rtElse)
    or (Settings.NoIndentElseIf and (FStack.GetTopType = rtIfElse)) then begin
    FStack.Pop;
    if FStack.GetTopType = rtThen then
      FStack.Pop;
    FWrapIndent := True;
    FStack.Push(rtIfElse, 0);
  end else
    FStack.Push(rtIf, 0);
end;

procedure TCodeFormatterFormatter.HandleThen;
begin
  if FStack.GetTopType in [rtIf, rtIfElse] then begin
    FWrapIndent := False;
    FLastPopResType := FStack.Pop;
    if Settings.NoFeedBeforeThen and (FPrevToken = FPrevLine)
      and (GetToken(FTokenIdx - 1).ReservedType <> rtComment) then begin
      FTokens.Extract(FTokenIdx - 1).Free;
      Dec(FTokenIdx);
      CheckSlashComment;
    end;
    if Settings.FeedAfterThen then begin
      if AssertLineFeedAfter(FTokenIdx) <> FPrevLine then begin
        if (FLastPopResType = rtIf) and Settings.ExceptSingle then
          CheckShortLine;
      end;
    end;
    FStack.Push(rtThen, 1);
  end;
end;

procedure TCodeFormatterFormatter.HandleColon(_RemoveMe: Integer);
begin
  case FStack.GetTopType of
    rtOf: begin
        FStack.Push(FCurrentRType, 1);
        if Settings.FeedAfterThen then begin
          if (GetNextNoComment(FTokenIdx, _RemoveMe).ReservedType = rtBegin)
            and (AssertLineFeedAfter(FTokenIdx) <> FPrevLine) then
            CheckShortLine;
        end;
        FWrapIndent := False;
      end;

    rtClassDecl: begin
        FStack.Pop;
        FStack.Push(rtClass, 1);
      end;

    rtVar:
      if Settings.AlignVar then
        FCurrentToken := AlignExpression(FTokenIdx, Settings.AlignVarPos);

    rtProcedure, rtProcDeclare:
      ; // do nothing
  else
    // label????
    FWrapIndent := False;
  end;
end;

procedure TCodeFormatterFormatter.HandleElse(_NTmp: Integer);
var
  Next: TPascalToken;
begin
  FLastPopResType := rtNothing;

  while not FStack.IsEmpty and not (FStack.GetTopType in [rtThen, rtOf, rtTry]) do
    FLastPopResType := FStack.Pop;

  if FLastPopResType = rtIfElse then
    ComplexIfElse(_NTmp);

  if (Settings.FeedRoundBegin = Hanging)
    and (FPrevToken <> nil)
    and TokenAtIs(FTokenIdx - 1, rtLineFeed)
    and TokenAtIs(FTokenIdx - 2, rtEnd) then begin
    FTokens.Extract(FTokenIdx - 1).Free;
    Dec(FTokenIdx);
    FPrevLine := nil;
    FPrevToken := FPrevLine;
  end;

  if Settings.FeedAfterThen then begin
    if (FPrevToken <> nil)
      and ((Settings.FeedRoundBegin <> Hanging) or not TokenAtIs(FTokenIdx - 1, rtEnd))
      and not TokenAtIs(FTokenIdx - 1, rtLineFeed) then begin
      FPrevLine := AssertLineFeedAfter(FTokenIdx - 1);
      FPrevToken := FPrevLine;
    end;

    if GetNextNoComment(FTokenIdx, Next)
      and (Next.ReservedType <> rtIf) then
      AssertLineFeedAfter(FTokenIdx);
  end;

  FStack.GetTopIndent;
  if FPrevToken = FPrevLine then
    SetPrevLineIndent(_NTmp);

  if Settings.FeedBeforeElse then begin
    if not TokenAtIs(FTokenIdx - 1, rtLineFeed) then begin
      FPrevLine := AssertLineFeedAfter(FTokenIdx - 1);
      FPrevToken := FPrevLine;
    end;
  end;

  if Settings.IndentTryElse and (FStack.GetTopType = rtTry) then begin
    FStack.nIndent := FStack.nIndent + 1;
    SetPrevLineIndent(_NTmp);
  end else if Settings.IndentCaseElse and (FStack.GetTopType = rtOf) then begin
    FStack.nIndent := FStack.nIndent + 1;
    SetPrevLineIndent(_NTmp);
  end;

  if FStack.GetTopType = rtThen then
    FStack.Push(rtIfElse, 1)
  else
    FStack.Push(rtElse, 1);

  FWrapIndent := False;
end;

procedure TCodeFormatterFormatter.CheckIndent;
var
  RemoveMe: Integer;
  Next: TPascalToken;
  TempWordIdx: Integer;
  Prev1: TPascalToken;
  FunctDeclare, IsDelegate, NoBlankLine: Boolean;
  FeedRound: TFeedBegin;
  wType: TWordType;
begin
  if FCurrentToken = nil then
    Exit;

  FCurrentRType := FCurrentToken.ReservedType;
  wType := FCurrentToken.WordType;

  { This handles the case where a reserved word was used as the name of
    a class member. Is that even allowed? }
  if (FCurrentRType in [rtWhile, rtEnd, rtRepeat, rtBegin, rtUses, rtTry,
    rtProgram, rtType, rtVar, rtIf, rtThen, rtElse] + StandardDirectives)
    and PrevTokenIsRType(rtDot) then begin
    Assert(False, 'trace');
    FCurrentToken.SetReservedType(rtNothing);
    FCurrentRType := rtNothing;
  end;

  { SetSpacing; }
  case FCurrentRType of
    rtIf:
      HandleIf;

    rtThen:
      HandleThen;

    rtColon:
      HandleColon(RemoveMe);

    rtElse:
      HandleElse(NTmp);

    rtRepeat, rtRecord: begin
        FStack.Push(FCurrentRType, 1);
        FWrapIndent := False;
      end;

    rtClass: begin
        if not (GetNextNoComment(FTokenIdx, Next)
          and (Next.ReservedType in [rtProcedure, rtProcDeclare, rtOf, rtVar])) then begin
            { not a "class function" or "class of" declaration }
          FWrapIndent := False;
          FStack.Push(rtClassDecl, 1);
        end else
            { first assume that it is a class declaration
              the first procedure replaces it with rtClass }
          FCurrentToken.SetSpace([spAfter], True);
      end;

    rtUntil: begin
        repeat
          FLastPopResType := FStack.Pop;
        until (FLastPopResType = rtRepeat) or FStack.IsEmpty;
        SetPrevLineIndent(NTmp);
      end;

    rtLeftBr: begin
        Assert(False, 'trace');
        if (FStack.GetTopType = rtLeftBr) then begin
          Assert(False, 'trace');
          FStack.Push(FCurrentRType, 0)
        end else begin
          Assert(False, 'trace');
          FOldWrapIndent := FWrapIndent;
          if (FStack.ProcLevel <= 0) or (FStack.GetTopType <> rtProcedure) then begin
            Assert(False, 'trace');
              // not very clean
            FStack.Push(FCurrentRType, 1);
          end else begin
            Assert(False, 'trace');
            RemoveMe := 1;
            while (FTokenIdx > RemoveMe) and (GetToken(FTokenIdx - RemoveMe, Next)
              and (Next.ReservedType in [rtDot, rtNothing])) do begin
              Assert(False, 'trace');
              Inc(RemoveMe);
            end;
            if (Next <> nil) and (Next.ReservedType = rtProcedure) then begin
              Assert(False, 'trace');
              FStack.Push(FCurrentRType, 0);
            end else begin
              Assert(False, 'trace');
              FStack.Push(FCurrentRType, 1);
            end;
          end;
          Assert(False, 'trace');
          FWrapIndent := False;
        end;
      end;

    rtWhile: begin
       // Helper For
        if not PrevTokenIsRType(rtReserved) then
          FStack.Push(FCurrentRType, 0);
      end;

    rtLeftHook: begin
        // left hook = '['
        Assert(False, 'trace');
        if PrevTokenIsWType(wtWord) and SameText(FPrevToken.GetContent, 'array') then begin
          // this is an ugly workaround for the test case
          // testfile_ConstArray
          // At least it doesn't seem to break anything else though
          // -- 2019-10-06 twm
          Assert(False, 'trace');
          FStack.Push(FCurrentRType, 0);
        end else begin
          Assert(False, 'trace');
          FWrapIndent := False;
          Assert(False, 'trace');
          FStack.Push(FCurrentRType, 1);
        end;
      end;

    rtOn: begin
        FStack.Push(FCurrentRType, 0);
      end;

    rtRightBr: begin
        Assert(False, 'trace');
        repeat
          Assert(False, 'trace');
          FLastPopResType := FStack.Pop;
        until (FLastPopResType = rtLeftBr) or FStack.IsEmpty;

        if FStack.GetTopType <> rtLeftBr then begin
          Assert(False, 'trace');
          FWrapIndent := FOldWrapIndent;
        end;
      end;

    rtRightHook: begin
        // right hook = ']'
        Assert(False, 'trace');
        repeat
          Assert(False, 'trace');
          FLastPopResType := FStack.Pop;
        until (FLastPopResType = rtLeftHook) or FStack.IsEmpty;

        Assert(False, 'trace');
        if FStack.GetTopType = rtClassDecl then begin
          // Interface GUID
          Assert(False, 'trace');
          FWrapIndent := False;
//          end else if FStack.GetTopType = rtLeftHook then begin
//            Assert(False, 'trace');
//            FWrapIndent := FOldHookWrapIndent;
        end;
      end;

    rtExcept: begin
        while not FStack.IsEmpty and (FStack.GetTopType <> rtTry) do
          FStack.Pop;

        FStack.GetTopIndent;
        SetPrevLineIndent(NTmp);
        FStack.nIndent := FStack.nIndent + 1;
        FWrapIndent := False;
      end;

    rtVisibility:
      if FStack.GetTopType in [rtClass, rtClassDecl, rtRecord] then begin
        if PrevTokenIsRType(rtLineFeed) then begin
          DecPrevLineIndent;
          FWrapIndent := False;
        end;
      end else if (FStack.GetTopType in [rtVar, rtType]) and (FStack.GetType(1) in [rtClass, rtClassDecl, rtRecord]) then begin
        FStack.Pop;
        DecPrevLineIndent;
        DecPrevLineIndent;
        FWrapIndent := False;
      end else
        FCurrentToken.SetReservedType(rtNothing);

    rtOf: begin
        case FStack.GetTopType of
          rtCase: begin
              FStack.Push(FCurrentRType, 1);
              if Settings.FeedAfterThen then
                AssertLineFeedAfter(FTokenIdx);
              FWrapIndent := False;
            end;
          rtRecord:
            FWrapIndent := False;
        end;
      end;

    rtLineFeed: begin
        if FStack.IsEmpty then begin
          Assert(False, 'trace');
          FWrapIndent := False;
//        end else if FStack.GetTopType in [rtIf, rtIfElse] then begin
        end else if FStack.GetTopType in [rtIf] then begin
          Assert(False, 'trace');
          FWrapIndent := True;
        end;

        if Settings.RemoveDoubleBlank and (FTokenIdx >= 2) and (FPrevToken <> nil)
          and (FPrevToken = FPrevLine) and (FTokens[FTokenIdx - 2] = FPrevPrevLine) then begin
          Assert(False, 'trace');
          FTokens.Extract(FTokenIdx - 2).Free;
          Dec(FTokenIdx);
        end;

        if GetNextNoComment(FTokenIdx, Next) then begin
          if Next.ReservedType in [rtElse, rtIfElse, rtBegin, rtEnd, rtUntil, rtExcept] then begin
            Assert(False, 'trace');
            FWrapIndent := False;
          end;

          if FWrapIndent and not Settings.NoIndentVarDecl then begin
            Assert(False, 'trace');
            NTmp := 1;
          end else begin
            Assert(False, 'trace');
            NTmp := 0;
          end;

          if Next.ReservedType in [rtLineFeed] then begin
            Assert(False, 'trace');
            FWrapIndent := False;
          end else if FStack.GetTopType in [rtUses, rtLeftBr] then begin
            Assert(False, 'trace');
            FWrapIndent := False;
          end else if FStack.GetTopType in [rtLeftHook] then begin
            Assert(False, 'trace');
            FWrapIndent := False;
          end else begin
            Assert(False, 'trace');
            FWrapIndent := True;
          end;
        end;

        FPrevPrevLine := FPrevLine;
        FPrevLine := TLineFeed(FCurrentToken);
        SetPrevLineIndent(NTmp);
      end;

    rtAsm: begin
        FormatAsm(NTmp);
        Exit;
      end;

    rtComma: begin
        if FStack.GetTopType = rtUses then begin
          if (Settings.NoIndentUsesComma) and (FPrevToken is TLineFeed) then
            SetPrevLineIndent(-1)
            { TODO -cfixme : The options NoIndentUsesComma and FeedEachUnit don't work well
              with each other so for now we ignore FeedEachUnit if NoIndentUsesComma is true. }
          else if Settings.FeedEachUnit then begin
            Next := GetNextNoComment(FTokenIdx, RemoveMe);
            if Next.ReservedType <> rtLineFeed then
              AssertLineFeedAfter(FTokenIdx);
          end;
        end;
      end;

    rtProgram, rtUses, rtInitialization:
      if FStack.GetTopType <> rtLeftBr then begin
        Next := GetNextNoComment(FTokenIdx, RemoveMe);

        if (FCurrentRType = rtUses) and (FStack.GetTopType in [rtProcedure, rtProcDeclare, rtClass]) then
          FCurrentToken.SetReservedType(rtNothing)
        else begin
          DecPrevLineIndent;
          FStack.Clear;
          FStack.Push(FCurrentRType, 1);
          FWrapIndent := False;
        end;
      end;

    rtAbsolute:
      if not (FStack.GetTopType in [rtVar, rtType]) then
        FCurrentToken.SetReservedType(rtNothing)
      else begin
        Next := GetNextNoComment(FTokenIdx, RemoveMe);
        if Next.ReservedType = rtColon then begin
          DecPrevLineIndent;
          FCurrentToken.SetReservedType(rtNothing);
        end;
      end;

    rtFuncDirective, rtDefault: begin
        Next := GetNextNoComment(FTokenIdx, RemoveMe);
        if (Next.ReservedType = rtColon)
          or not (FStack.GetTopType in [rtProcedure, rtProcDeclare, rtClass])
          or (FPrevToken.ReservedType in [rtProcedure, rtProcDeclare, rtDot]) then
          FCurrentToken.SetReservedType(rtNothing);
      end;

    rtForward: begin
        if FStack.GetTopType in [rtProcedure, rtProcDeclare] then
          FStack.Pop
        else
          FCurrentToken.SetReservedType(rtNothing);
      end;

    rtProcedure: begin
        if FStack.GetTopType in [rtClassDecl, rtRecord] then begin
          FStack.Pop;
          FStack.Push(rtClass, 1);
        end else if (FStack.GetTopType in [rtVar, rtType])
          and (FStack.GetType(1) in [rtClass, rtClassDecl, rtRecord])
          and (FPrevToken.ReservedType <> rtEquals) then begin
          // There was a nested class/record declaration that ended
          FStack.Pop;
          FStack.Pop;
          FStack.Push(rtClass, 1);
          DecPrevLineIndent;
        end;
        Prev1 := FPrevToken;
        TempWordIdx := FTokenIdx;

        if Prev1 <> nil then begin
          while (TempWordIdx > 0) and (Prev1.ReservedType in [rtComment, rtLineFeed]) do begin
            Dec(TempWordIdx);
            Prev1 := FTokens[TempWordIdx];
          end;

          FunctDeclare := (Prev1 <> nil) and (Prev1.ReservedType in [rtEquals, rtColon, rtComma, rtLeftBr]);
        end else
          FunctDeclare := False;

        NoBlankLine := False;
        IsDelegate := False;

        if not FunctDeclare then begin
          RemoveMe := 0;
          repeat
            Inc(RemoveMe);
            if GetToken(FTokenIdx + RemoveMe, Next) then
              if Next.ReservedType = rtLeftBr then
                repeat
                  Inc(RemoveMe);
                until not GetToken(FTokenIdx + RemoveMe, Next) or (Next.ReservedType = rtRightBr);
          until (Next = nil) or (Next.ReservedType in [rtSemiColon, rtBegin]);

          // Begin before a SemiColon, presume that is a anonymous delegate...
          if Next.ReservedType = rtBegin then begin
            IsDelegate := True;
            Next.AddOption(toFeedNewLine); // Force NewLine Feed!
          end;

          if Next <> nil then begin
            repeat
              Inc(RemoveMe);
            until not GetToken(FTokenIdx + RemoveMe, Next) or not (Next.ReservedType in [rtLineFeed, rtComment]);

            if (Next <> nil) and (Next.ReservedType = rtForward) then
              NoBlankLine := True;
          end;
        end;

        if not (FunctDeclare or FIsInInterfacePart or (FStack.GetTopType = rtClass)) then begin
          if not FStack.HasType(rtProcedure) then begin
            if not IsDelegate then begin

              if (FStack.nIndent > 0) then begin
                FStack.nIndent := 0;
                SetPrevLineIndent(NTmp);
              end;

              FStack.ProcLevel := 0;
              if Settings.BlankProc and not NoBlankLine then
                CheckBlankLinesAroundProc;

              if Settings.CommentFunction then
                PutCommentBefore('{ procedure }');
            end;
          end else begin
            if Settings.BlankSubProc and not NoBlankLine then
              CheckBlankLinesAroundProc;

            FStack.ProcLevel := FStack.ProcLevel + 1;

            if FStack.nIndent = 0 then begin
              SetPrevLineIndent(NTmp);
              FStack.nIndent := FStack.nIndent + 1;
            end;
          end;

          FStack.Push(rtProcedure, 0);
        end else begin
          // Array of Procedure, Reference To Function...
          if (FStack.GetTopType = rtType) and Assigned(Prev1) and (Prev1.ReservedType in [rtOf, rtOper, rtComma]) then begin
            // SetPrevLineIndent(NTmp);
            //
            // FStack.ProcLevel := FStack.ProcLevel + 1;
            ////              FStack.Push(FCurrentRType  , 1);
            //
          end else begin
            if (not FunctDeclare) and (not (FStack.GetTopType = rtClass)) then begin
              FStack.nIndent := 0;
              SetPrevLineIndent(NTmp);
            end;

            FStack.Push(rtProcDeclare, 0);
          end;
        end;
      end;

    rtInterface: begin
        if PrevTokenIsRType(rtEquals) then begin
          { declaration of a OLE object: IClass = interface [' dfgsgdf'] }
          FStack.Push(rtClassDecl, 1);
        end else begin
          FIsInInterfacePart := True;
          DecPrevLineIndent;
        end;

        FWrapIndent := False;
      end;

    rtImplementation: begin
        FStack.Clear;
        FIsInInterfacePart := False;
        FWrapIndent := False;
        { DecPrevIndent; }
        { nIndent := 0; }
        SetPrevLineIndent(NTmp);
      end;

    rtBegin, rtTry: begin
        while FStack.GetTopType in [rtVar, rtType] do
          FStack.Pop;

        if FStack.GetTopType in [rtProcedure, rtProgram] then
          FStack.Pop;

        if FStack.IsEmpty then
          FStack.nIndent := 0;

        if NoBeginTryIndent(FCurrentRType) then
          FStack.nIndent := FStack.nIndent - 1;

        case FCurrentRType of
          rtBegin:
            if FCurrentToken.HasOption(toFeedNewLine) then
              FeedRound := NewLine
            else
              FeedRound := Settings.FeedRoundBegin;
          rtTry:
            FeedRound := Settings.FeedRoundTry;
        else
          FeedRound := Unchanged;
        end;

        case FeedRound of
          Hanging: begin
              if (FStack.GetTopType in [rtDo, rtThen, rtIfElse, rtElse, rtColon])
                and (FPrevToken <> nil) and (GetToken(FTokenIdx - 1) = FPrevLine) then begin
                FTokens.Extract(FTokenIdx - 1).Free;
                Dec(FTokenIdx);
                CheckSlashComment;
              end;

              AssertLineFeedAfter(FTokenIdx);
            end;

          NewLine: begin
              if (FPrevToken <> nil) and (GetToken(FTokenIdx - 1).ReservedType <> rtLineFeed) then begin
                FPrevLine := AssertLineFeedAfter(FTokenIdx - 1);
                FPrevToken := FPrevLine;
              end;

              AssertLineFeedAfter(FTokenIdx);
            end;
        end;

        FStack.Push(FCurrentRType, 1);
        if FPrevToken = FPrevLine then begin
          SetPrevLineIndent(NTmp);
          DecPrevLineIndent;
        end;

        FWrapIndent := False;
      end;

    rtEquals:
      if Settings.AlignVar and (FStack.GetTopType = rtVar) then
        FCurrentToken := AlignExpression(FTokenIdx, Settings.AlignVarPos);

    rtVar, rtType:
      if not (FStack.GetTopType in [rtLeftBr, rtLeftHook]) then begin
        FWrapIndent := False;
        if FStack.nIndent < 1 then
          FStack.nIndent := 1;
        if (FStack.GetTopType in [rtVar, rtType]) then begin
          if (FCurrentRType = rtType) and PrevTokenIsRType(rtEquals) then begin
            // in classes.pas I found
            // t = type AnsiString
            FStack.Pop
          end else if FStack.GetType(1) in [rtClass, rtClassDecl, rtRecord] then begin
            FStack.Pop;
            DecPrevLineIndent;
          end else
            FStack.Pop;
        end;
        if (FStack.GetTopType in [rtClass, rtClassDecl, rtRecord]) then begin
          FStack.Push(FCurrentRType, 1);
        end else begin
          if (FStack.GetTopType = rtProcDeclare) then begin
              // inline function
            FStack.Push(FCurrentRType, 1);
            if not PrevTokenIsRType(rtEquals) then begin
              if Settings.FeedAfterVar then
                AssertLineFeedAfter(FTokenIdx);
            end;
          end else begin
            FStack.Push(FCurrentRType, 0);
            if not PrevTokenIsRType(rtEquals) then begin
              DecPrevLineIndent;
              if Settings.FeedAfterVar then
                AssertLineFeedAfter(FTokenIdx);
            end;
          end;
        end;
      end;

    rtCase:
      if not (FStack.GetTopType in [rtRecord, rtLeftBr]) then
        FStack.Push(FCurrentRType, 0)
      else begin
        FWrapIndent := False;
        FStack.Push(rtRecCase, 1);
      end;

    rtDo:
      if FStack.GetTopType in [rtWhile, rtOn] then begin
        FLastPopResType := FStack.GetTopType;
        FStack.Push(FCurrentRType, 1);
        FWrapIndent := False;

        if Settings.NoFeedBeforeThen and (FPrevToken = FPrevLine) then begin
          FTokens.Extract(FTokenIdx - 1).Free;
          Dec(FTokenIdx);
          CheckSlashComment;
        end;

        if Settings.FeedAfterThen then begin
          if AssertLineFeedAfter(FTokenIdx) <> FPrevLine then begin
            if (FLastPopResType in [rtOn, rtWhile]) and Settings.ExceptSingle then
              CheckShortLine;
          end;
        end;
      end;

    rtEnd: begin
        FWrapIndent := False;

        repeat
          FLastPopResType := FStack.Pop;
        until FStack.IsEmpty or (FLastPopResType in [rtClass, rtClassDecl, rtRecord, rtTry, rtCase, rtBegin, rtAsm (* , rtVisibility *)]);

        if FStack.IsEmpty then
          FStack.nIndent := 0
        else begin
          if (FLastPopResType = rtCase) and (FStack.GetTopType = rtClass) then
            FLastPopResType := FStack.Pop;
        end;

        if Settings.FeedBeforeEnd and (FPrevToken <> nil)
          and (GetToken(FTokenIdx - 1).ReservedType <> rtLineFeed) then begin
          FPrevLine := AssertLineFeedAfter(FTokenIdx - 1);
          FPrevToken := FPrevLine;
        end;

        if (FPrevToken = FPrevLine) then
          SetPrevLineIndent(NTmp);

        if NoBeginTryIndent(FCurrentRType) then
          FStack.nIndent := FStack.nIndent + 1;
      end;

    rtComment: begin
        if Settings.IndentComments and (FStack.GetTopType <> rtLeftHook) then
          FWrapIndent := False;

        if FStack.IsEmpty and (FStack.nIndent > 0) then begin
          FStack.nIndent := 0;
          SetPrevLineIndent(NTmp);
        end;

        AdjustSpacing(GetToken(FTokenIdx + 1), FCurrentToken, FTokenIdx + 1);
        if (FPrevLine <> nil) and (FPrevLine = FPrevToken) then begin
          if not Settings.IndentComments
            or (FCurrentToken.WordType in [wtFullOutComment, wtHalfOutComment]) then
            FPrevLine.NoOfSpaces := FPrevLine.OldNoOfSpaces
          else begin
            if PrevOldNspaces >= 0 then
              FPrevLine.NoOfSpaces := FPrevLine.NoOfSpaces +
                (FPrevLine.OldNoOfSpaces - PrevOldNspaces)
            else
              PrevOldNspaces := FPrevLine.OldNoOfSpaces;
          end;
        end else if Settings.AlignComments and (FCurrentToken.WordType = wtFullComment) then begin
          if GetToken(FTokenIdx + 1, Next) and (Next.ReservedType = rtLineFeed) then
            FCurrentToken := AlignExpression(FTokenIdx, Settings.AlignCommentPos);
        end;
      end;

    rtSemiColon:
      if not (FStack.GetTopType in [rtLeftBr, rtLeftHook]) then begin
        if (FStack.GetTopType = rtUses) and (Settings.NoIndentUsesComma) and (FPrevToken is TLineFeed) then
          SetPrevLineIndent(-1);

        while not FStack.IsEmpty and (FStack.GetTopType in [rtDo, rtWhile,
          rtProcDeclare, rtThen, rtProgram, rtUses, rtColon, rtClassDecl])
          or (FStack.GetTopType = rtIfElse) do
          FStack.Pop;

        FWrapIndent := False;
        RemoveMe := 0;

        repeat
          Inc(RemoveMe);
        until not GetToken(FTokenIdx + RemoveMe, Next) or (not (Next.ReservedType in [{ rtComment, }rtLineFeed]));

        if Next <> nil then begin
          if (Next.ReservedType = rtAbsolute)
            or ((FStack.GetTopType in [rtProcedure, rtProcDeclare, rtClass])
            and (Next.ReservedType in [rtFuncDirective, rtForward])
            and (FStack.ProcLevel = 0)) then
            FWrapIndent := True
          else if Settings.FeedAfterSemiColon
            and not (Next.ReservedType in [rtForward, rtFuncDirective, rtDefault]) then
            AssertLineFeedAfter(FTokenIdx);
        end;
      end;

    rtCompIf: begin
        // push current stack to preserve indenting from before the ifdef
        FStackStack.Push(FStack.Clone);
      end;
    rtCompElse: begin
        if not FStackStack.IsEmpty then begin
          // Free current stack and take a copy of the one from before the corresponding ifdef.
          FStack.Free;
          FStack := FStackStack.Top.Clone;
        end;
      end;
    rtCompEndif: begin
        // pop and free the saved stack
        if not FStackStack.IsEmpty then
          FStackStack.Pop.Free;
      end;
  end; // case FCurrentRType

  Assert(False, 'trace');
  AdjustSpacing(FCurrentToken, FPrevToken, FTokenIdx);

  if not (FCurrentRType in [rtLineFeed, rtComment]) then begin
    Assert(False, 'trace');
    PrevOldNspaces := -1;
  end;
  Assert(False, Format('PrevOldNSpaces=%d', [PrevOldNspaces]));

  if wType = wtCompDirective then begin
    FWrapIndent := False;

    if not Settings.IndentCompDirectives and PrevTokenIsRType(rtLineFeed) then begin
      Assert(False, 'trace');
      NTmp := -FStack.nIndent;
      Assert(False, Format('NTmp=%d', [NTmp]));
      SetPrevLineIndent(NTmp);
    end;

    if Settings.UpperCompDirectives then
      UppercaseCompilerDirective(FCurrentToken);
  end;

  FPrevToken := FCurrentToken;
end;

procedure TCodeFormatterFormatter.doExecute(_Tokens: TPascalTokenList);
var
  NTmp: Integer;
  PrevOldNspaces: Integer;
begin
  FTokens := _Tokens;

  if Settings.ChangeIndent then begin
    FPrevLine := nil;
    FPrevPrevLine := nil;
    FPrevToken := nil;
    FWrapIndent := True;
    FIsInInterfacePart := False;
    NTmp := 0;
    PrevOldNspaces := -1;
    // the StackStack is used to preserve indenting over IFDEF/ELSE/ENDIF statements
    FStackStack := TCodeFormatterStack.Create;
    try
      FTokenIdx := 0;
      while GetToken(FTokenIdx, FCurrentToken) do begin
//        if (FCurrentToken is TExpression) and (FCurrentToken.GetContent = 'if') then
//          gblAssertTraceOn := True;
//        if (FCurrentToken is TExpression) and (FCurrentToken.GetContent = 'Welt') then
//          gblAssertTraceOn := False;
        Assert(False, Format('CurrentToken: "%s" (%s)', [FCurrentToken.GetContent, FCurrentToken.ClassName]));
        if FWrapIndent then
          Assert(False, 'WrapIndent: True')
        else
          Assert(False, 'WrapIndent: False');
        CheckIndent(NTmp, PrevOldNspaces);
        Inc(FTokenIdx);
      end;
    finally
      FreeAndNil(FStackStack);
    end;
    gblAssertTraceOn := False;
  end;

  // remove empty lines from the end
  FTokenIdx := FTokens.Count - 1;
  while (FTokenIdx > 0) and TokenAtIs(FTokenIdx, rtLineFeed) do begin
    FTokens.Extract(FTokenIdx).Free;
    Dec(FTokenIdx);
  end;

  if Settings.WrapLines or FHasAligned then
    CheckWrapping;
end;

procedure TCodeFormatterFormatter.CheckWrapping;
var
  HasInserted: Boolean;

  procedure InsertLinefeed(ATokenIdx: Integer);
  var
    PrevPrevLine: TLineFeed;
  begin
    PrevPrevLine := FPrevLine;
    FPrevLine := TLineFeed.Create(PrevPrevLine.OldNoOfSpaces, Settings.SpacePerIndent);
    FPrevLine.NoOfSpaces := PrevPrevLine.NoOfSpaces;
    FPrevLine.Wrapped := True;
    GetToken(ATokenIdx).SetSpace([spBefore], False);
    FTokens.AtInsert(ATokenIdx, FPrevLine);
    HasInserted := True;
  end;

var
  TokenIdx, j, k: Integer;
  K2, LineLen: Integer;
  Token: TPascalToken;
  Expression: TAlignExpression;
begin
  LineLen := 0;
  FPrevLine := nil;
  j := 0;
  TokenIdx := 0;
  while TokenIdx < FTokens.Count do begin
    Token := GetToken(TokenIdx);
    // GetLength as a side effect, adjusts the alignment
    Token.GetLength(LineLen);

    if Settings.WrapLines and (Token is TAlignExpression)
      and (LineLen > Settings.WrapPosition) then begin
      Expression := Token as TAlignExpression;
      k := Expression.NoOfSpaces - LineLen - Settings.WrapPosition;

      if k < 1 then
        Expression.NoOfSpaces := 1
      else
        Expression.NoOfSpaces := k;

      LineLen := Settings.WrapPosition;
    end;

    if Token.ReservedType = rtLineFeed then begin
      FPrevLine := TLineFeed(Token);
      if (LineLen > Settings.WrapPosition) then
        LineLen := 0;

      j := TokenIdx;
    end;

    if Settings.WrapLines and (LineLen > Settings.WrapPosition) and (TokenIdx > j + 3) then begin
      k := TokenIdx - 1;
      K2 := 0;
      HasInserted := False;

      while (k >= j) and not HasInserted do begin
        if (GetToken(k).ReservedType in [rtThen, rtDo])
          or (GetToken(k).ReservedType = rtElse)
          and (GetToken(k + 1).ReservedType <> rtIf) then begin
          InsertLinefeed(k + 1);
          TokenIdx := j;
        end;

        if (K2 = 0) and (GetToken(k).Space(spAfter)
          or GetToken(k + 1).Space(spBefore)) then
          K2 := k + 1;

        Dec(k);
      end;

      if not HasInserted and (K2 <> 0) and (K2 > j) then begin
        InsertLinefeed(K2);
        TokenIdx := j;
      end;

      LineLen := 0;
    end;
    Inc(TokenIdx);
  end;
end;

end.

{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynMacroRecorder.pas, released 2001-10-17.

Author of this file is Fl�vio Etrusco.
Portions created by Fl�vio Etrusco are Copyright 2001 Fl�vio Etrusco.
Unicode translation by Ma�l H�rz.
All Rights Reserved.

Contributors to the SynEdit project are listed in the Contributors.txt file.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

$Id: SynMacroRecorder.pas,v 1.31.2.3 2008/09/14 16:25:03 maelh Exp $

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net

Known Issues:
-------------------------------------------------------------------------------}

unit SynMacroRecorder;

{$I SynEdit.inc}

interface

uses
  StdCtrls,
  Controls,
  Windows,
  Messages,
  Graphics,
  Menus,
  SynEdit,
  SynEditKeyCmds,
  SynEditPlugins,
  SynEditTypes,
  SynUnicode,
{$IFDEF UNICODE}
  WideStrUtils,
{$ENDIF}
  Classes;

{$IFDEF SYN_COMPILER_3_UP}
resourcestring
{$ELSE}
const
{$ENDIF}
  sCannotRecord = 'Cannot record macro; already recording or playing';
  sCannotPlay = 'Cannot playback macro; already playing or recording';
  sCannotPause = 'Can only pause when recording';
  sCannotResume = 'Can only resume when paused';

type
  TSynMacroState = (msStopped, msRecording, msPlaying, msPaused);
  TSynMacroCommand = (mcRecord, mcPlayback);

  TSynMacroEvent = class(TObject)
  protected
    FRepeatCount: Byte;
    function GetAsString: UnicodeString; virtual; abstract;
    procedure InitEventParameters(aStr: UnicodeString); virtual; abstract;
  public
    constructor Create; virtual;
    procedure Initialize(aCmd: TSynEditorCommand; aChar: WideChar; aData: Pointer);
      virtual; abstract;
    { the CommandID must not be read inside LoadFromStream/SaveToStream. It's read by the
    MacroRecorder component to decide which MacroEvent class to instanciate }
    procedure LoadFromStream(aStream: TStream); virtual; abstract;
    procedure SaveToStream(aStream: TStream); virtual; abstract;
    procedure Playback(aEditor: TCustomSynEdit); virtual; abstract;
    property AsString: UnicodeString read GetAsString;
    property RepeatCount: Byte read FRepeatCount write FRepeatCount;
  end;

  TSynBasicEvent = class(TSynMacroEvent)
  protected
    FCommand: TSynEditorCommand;
    function GetAsString: UnicodeString; override;
    procedure InitEventParameters(aStr: UnicodeString); override;
  public
    procedure Initialize(aCmd: TSynEditorCommand; aChar: WideChar; aData: Pointer);
      override;
    procedure LoadFromStream(aStream: TStream); override;
    procedure SaveToStream(aStream: TStream); override;
    procedure Playback(aEditor: TCustomSynEdit); override;
  public
    property Command: TSynEditorCommand read FCommand write FCommand;
  end;

  TSynCharEvent = class(TSynMacroEvent)
  protected
    FKey: WideChar;
    function GetAsString: UnicodeString; override;
    procedure InitEventParameters(aStr: UnicodeString); override;
  public
    procedure Initialize(aCmd: TSynEditorCommand; aChar: WideChar; aData: Pointer);
      override;
    procedure LoadFromStream(aStream: TStream); override;
    procedure SaveToStream(aStream: TStream); override;
    procedure Playback(aEditor: TCustomSynEdit); override;
  public
    property Key: WideChar read FKey write FKey;
  end;

  TSynStringEvent = class(TSynMacroEvent)
  protected
    FString: UnicodeString;
    function GetAsString: UnicodeString; override;
    procedure InitEventParameters(aStr: UnicodeString); override;
  public
    procedure Initialize(aCmd: TSynEditorCommand; aChar: WideChar; aData: Pointer);
      override;
    procedure LoadFromStream(aStream: TStream); override;
    procedure SaveToStream(aStream: TStream); override;
    procedure Playback(aEditor: TCustomSynEdit); override;
  public
    property Value: UnicodeString read FString write FString;
  end;

  TSynPositionEvent = class(TSynBasicEvent)
  protected
    FPosition: TBufferCoord;
    function GetAsString: UnicodeString; override;
    procedure InitEventParameters(aStr: UnicodeString); override;
  public
    procedure Initialize(aCmd: TSynEditorCommand; aChar: WideChar; aData: Pointer);
      override;
    procedure LoadFromStream(aStream: TStream); override;
    procedure SaveToStream(aStream: TStream); override;
    procedure Playback(aEditor: TCustomSynEdit); override;
  public
    property Position: TBufferCoord read FPosition write FPosition;
  end;

  TSynDataEvent = class(TSynBasicEvent)
  protected
    FData: Pointer;
  public
    procedure Initialize(aCmd: TSynEditorCommand; aChar: WideChar; aData: Pointer);
      override;
    procedure LoadFromStream(aStream: TStream); override;
    procedure SaveToStream(aStream: TStream); override;
    procedure Playback(aEditor: TCustomSynEdit); override;
  end;

  TCustomSynMacroRecorder = class;

  TSynUserCommandEvent = procedure (aSender: TCustomSynMacroRecorder;
    aCmd: TSynEditorCommand; var aEvent: TSynMacroEvent) of object;

  { TCustomSynMacroRecorder
  OnStateChange:
    occurs right after start playing, recording, pausing or stopping
  SaveMarkerPos:
    if true, Bookmark position is recorded in the macro. Otherwise, the Bookmark
    is created in the position the Caret is at the time of playback.
  }

  TCustomSynMacroRecorder = class(TAbstractSynHookerPlugin)
  private
    FShortCuts: array [TSynMacroCommand] of TShortCut;
    FOnStateChange: TNotifyEvent;
    FOnUserCommand: TSynUserCommandEvent;
    FMacroName: string;
    FSaveMarkerPos: boolean;
    function GetEvent(aIndex: Integer): TSynMacroEvent;
    function GetEventCount: Integer;
    function GetAsString: UnicodeString;
    procedure SetAsString(const Value: UnicodeString);
  protected
    FCurrentEditor: TCustomSynEdit;
    FState: TSynMacroState;
    FEvents: TList;
    FCommandIDs: array [TSynMacroCommand] of TSynEditorCommand;
    procedure SetShortCut(const Index: Integer; const Value: TShortCut);
    function GetIsEmpty: boolean;
    procedure StateChanged;
    procedure DoAddEditor(aEditor: TCustomSynEdit); override;
    procedure DoRemoveEditor(aEditor: TCustomSynEdit); override;
    procedure OnCommand(Sender: TObject; AfterProcessing: boolean;
      var Handled: boolean; var Command: TSynEditorCommand; var aChar: WideChar;
      Data, HandlerData: Pointer); override;
    function CreateMacroEvent(aCmd: TSynEditorCommand): TSynMacroEvent;
  protected
    property RecordCommandID: TSynEditorCommand read FCommandIDs[mcRecord];
    property PlaybackCommandID: TSynEditorCommand read FCommandIDs[mcPlayback];
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure Error(const aMsg: String);
    procedure AddEditor(aEditor: TCustomSynEdit);
    procedure RemoveEditor(aEditor: TCustomSynEdit);
    procedure RecordMacro(aEditor: TCustomSynEdit);
    procedure PlaybackMacro(aEditor: TCustomSynEdit);
    procedure Stop;
    procedure Pause;
    procedure Resume;
    property IsEmpty: boolean read GetIsEmpty;
    property State: TSynMacroState read FState;
    procedure Clear;
    procedure AddEvent(aCmd: TSynEditorCommand; aChar: WideChar; aData: Pointer);
    procedure InsertEvent(aIndex: Integer; aCmd: TSynEditorCommand; aChar: WideChar;
      aData: Pointer);
    procedure AddCustomEvent(aEvent: TSynMacroEvent);
    procedure InsertCustomEvent(aIndex: Integer; aEvent: TSynMacroEvent);
    procedure DeleteEvent(aIndex: Integer);
    procedure LoadFromStream(aSrc: TStream);
    procedure LoadFromStreamEx(aSrc: TStream; aClear: boolean);
    procedure SaveToStream(aDest: TStream);
    procedure LoadFromFile(aFilename : string);
    procedure SaveToFile(aFilename : string);
    property EventCount: Integer read GetEventCount;
    property Events[aIndex: Integer]: TSynMacroEvent read GetEvent;
    property RecordShortCut: TShortCut index Ord(mcRecord)
      read FShortCuts[mcRecord] write SetShortCut;
    property PlaybackShortCut: TShortCut index Ord(mcPlayback)
      read FShortCuts[mcPlayback] write SetShortCut;
    property SaveMarkerPos: boolean read FSaveMarkerPos
      write FSaveMarkerPos default False;
    property AsString: UnicodeString read GetAsString write SetAsString;
    property MacroName: string read FMacroName write FMacroName;
    property OnStateChange: TNotifyEvent read FOnStateChange write FOnStateChange;
    property OnUserCommand: TSynUserCommandEvent read FOnUserCommand
      write FOnUserCommand;
  end;

  TSynMacroRecorder = class(TCustomSynMacroRecorder)
  published
    property SaveMarkerPos;
    property RecordShortCut;
    property PlaybackShortCut;
    property OnStateChange;
    property OnUserCommand;
  end;

implementation

uses
  Forms,
  SynEditMiscProcs,
{$IFDEF SYN_COMPILER_6_UP}
  RTLConsts,
{$ENDIF}
  SysUtils;

{ TSynDataEvent }

procedure TSynDataEvent.Initialize(aCmd: TSynEditorCommand; aChar: WideChar;
  aData: Pointer);
begin
  FCommand := aCmd;
  Assert(aChar = #0);
  FData := aData;
end;

procedure TSynDataEvent.LoadFromStream(aStream: TStream);
begin
  aStream.Read(FData, SizeOf(FData));
end;

procedure TSynDataEvent.Playback(aEditor: TCustomSynEdit);
begin
  aEditor.CommandProcessor(Command, #0, FData);
end;

procedure TSynDataEvent.SaveToStream(aStream: TStream);
begin
  inherited;
  aStream.Write(FData, SizeOf(FData));
end;

{ TCustomSynMacroRecorder }

procedure TCustomSynMacroRecorder.AddCustomEvent(aEvent: TSynMacroEvent);
begin
  InsertCustomEvent(EventCount, aEvent);
end;

procedure TCustomSynMacroRecorder.AddEditor(aEditor: TCustomSynEdit);
begin
  inherited AddEditor(aEditor);
end;

procedure TCustomSynMacroRecorder.AddEvent(aCmd: TSynEditorCommand;
  aChar: WideChar; aData: Pointer);
begin
  InsertEvent(EventCount, aCmd, aChar, aData);
end;

procedure TCustomSynMacroRecorder.Clear;
var
  I: Integer;
  Obj: TObject;
begin
  if Assigned(FEvents) then
  begin
    for I := FEvents.Count-1 downto 0 do
    begin
      Obj := FEvents[I];
      FEvents.Delete(I);
      Obj.Free;
    end;
    FreeAndNil(FEvents);
  end;
end;

constructor TCustomSynMacroRecorder.Create(aOwner: TComponent);
begin
  inherited;
  FMacroName := 'unnamed';
  FCommandIDs[mcRecord] := NewPluginCommand;
  FCommandIDs[mcPlayback] := NewPluginCommand;
  FShortCuts[mcRecord] := Menus.ShortCut(Ord('R'), [ssCtrl, ssShift]);
  FShortCuts[mcPlayback] := Menus.ShortCut(Ord('P'), [ssCtrl, ssShift]);
end;

function TCustomSynMacroRecorder.CreateMacroEvent(aCmd: TSynEditorCommand): TSynMacroEvent;

  function WantDefaultEvent(var aEvent: TSynMacroEvent): boolean;
  begin
    if Assigned(OnUserCommand) then
      OnUserCommand(Self, aCmd, aEvent);
    Result := aEvent = nil;
  end;

begin
  case aCmd of
    ecGotoXY, ecSelGotoXY, ecSetMarker0..ecSetMarker9:
      begin
        Result := TSynPositionEvent.Create;
        TSynPositionEvent(Result).Command := aCmd;
      end;
    ecChar:
      Result := TSynCharEvent.Create;
    ecString:
      Result := TSynStringEvent.Create;
    else begin
      Result := nil;
      if (aCmd < ecUserFirst) or WantDefaultEvent(Result) then
      begin
        Result := TSynBasicEvent.Create;
        TSynBasicEvent(Result).Command := aCmd;
      end;
    end;
  end;
end;

procedure TCustomSynMacroRecorder.DeleteEvent(aIndex: Integer);
var
  iObj: Pointer;
begin
  iObj := FEvents[aIndex];
  FEvents.Delete(aIndex);
  TObject(iObj).Free;
end;

destructor TCustomSynMacroRecorder.Destroy;
begin
  Clear;
  inherited;
  ReleasePluginCommand(PlaybackCommandID);
  ReleasePluginCommand(RecordCommandID);
end;

procedure TCustomSynMacroRecorder.DoAddEditor(aEditor: TCustomSynEdit);
begin
  HookEditor(aEditor, RecordCommandID, 0, RecordShortCut);
  HookEditor(aEditor, PlaybackCommandID, 0, PlaybackShortCut);
end;

procedure TCustomSynMacroRecorder.DoRemoveEditor(aEditor: TCustomSynEdit);
begin
  UnHookEditor(aEditor, RecordCommandID, RecordShortCut);
  UnHookEditor(aEditor, PlaybackCommandID, PlaybackShortCut);
end;

procedure TCustomSynMacroRecorder.Error(const aMsg: String);
begin
  raise Exception.Create(aMsg);
end;

function TCustomSynMacroRecorder.GetEvent(aIndex: Integer): TSynMacroEvent;
begin
  Result := TSynMacroEvent(FEvents[aIndex]);
end;

function TCustomSynMacroRecorder.GetEventCount: Integer;
begin
  if FEvents = nil then
    Result := 0
  else
    Result := FEvents.Count;
end;

function TCustomSynMacroRecorder.GetIsEmpty: boolean;
begin
  Result := (FEvents = nil) or (FEvents.Count = 0);
end;

procedure TCustomSynMacroRecorder.InsertCustomEvent(aIndex: Integer;
  aEvent: TSynMacroEvent);
begin
  if FEvents = nil then
    FEvents := TList.Create;
  FEvents.Insert(aIndex, aEvent);
end;

procedure TCustomSynMacroRecorder.InsertEvent(aIndex: Integer;
  aCmd: TSynEditorCommand; aChar: WideChar; aData: Pointer);
var
  iEvent: TSynMacroEvent;
begin
  iEvent := CreateMacroEvent(aCmd);
  try
    iEvent.Initialize(aCmd, aChar, aData);
    InsertCustomEvent(aIndex, iEvent);
  except
    iEvent.Free;
    raise;
  end;
end;

procedure TCustomSynMacroRecorder.LoadFromStream(aSrc: TStream);
begin
  LoadFromStreamEx(aSrc, True);
end;

procedure TCustomSynMacroRecorder.LoadFromStreamEx(aSrc: TStream;
  aClear: boolean);
var
  iCommand: TSynEditorCommand;
  iEvent: TSynMacroEvent;
  cnt, i: Integer;
begin
  Stop;
  if aClear then
    Clear;
  FEvents := TList.Create;
  aSrc.Read(cnt, sizeof(cnt));
  i := 0;
  FEvents.Capacity := aSrc.Size div SizeOf(TSynEditorCommand);
  while (aSrc.Position < aSrc.Size) and (i < cnt) do
  begin
    aSrc.Read(iCommand, SizeOf(TSynEditorCommand));
    iEvent := CreateMacroEvent(iCommand);
    iEvent.Initialize(iCommand, #0, nil);
    iEvent.LoadFromStream(aSrc);
    FEvents.Add(iEvent);
    Inc(i);
  end;
end;

// TODO: Sender could be also something else then a TCustomSynedit(namely a TObject) but the code below assumes it is a TCustomSynedit even if Sender is of type TObject.
procedure TCustomSynMacroRecorder.OnCommand(Sender: TObject;
  AfterProcessing: boolean; var Handled: boolean;
  var Command: TSynEditorCommand; var aChar: WideChar; Data,
  HandlerData: Pointer);
var
  iEvent: TSynMacroEvent;
begin
  if AfterProcessing then
  begin
    if (Sender = FCurrentEditor) and (State = msRecording) and (not Handled) then
    begin
      iEvent := CreateMacroEvent(Command);
      iEvent.Initialize(Command, aChar, Data);
      FEvents.Add(iEvent);
      if SaveMarkerPos and (Command >= ecSetMarker0) and
        (Command <= ecSetMarker9) and (Data = nil) then
      begin
        TSynPositionEvent(iEvent).Position := FCurrentEditor.CaretXY;
      end;
    end;
  end
  else
  begin
    {not AfterProcessing}
    case State of
      msStopped:
        if Command = RecordCommandID then
        begin
          RecordMacro(TCustomSynEdit(Sender));
          Handled := True;
        end
        else if Command = PlaybackCommandID then
        begin
          PlaybackMacro(TCustomSynEdit(Sender));
          Handled := True;
        end;
      msPlaying:
        ;
      msPaused:
        if Command = PlaybackCommandID then
        begin
          Resume;
          Handled := True;
        end;
      msRecording:
        if Command = PlaybackCommandID then
        begin
          Pause;
          Handled := True;
        end
        else if Command = RecordCommandID then
        begin
          Stop;
          Handled := True;
        end;
    end;
  end;
end;

procedure TCustomSynMacroRecorder.Pause;
begin
  if State <> msRecording then
    Error(sCannotPause);
  FState := msPaused;
  StateChanged;
end;

procedure TCustomSynMacroRecorder.PlaybackMacro(aEditor: TCustomSynEdit);
var
  cEvent: Integer;
begin
  if State <> msStopped then
    Error(sCannotPlay);
  FState := msPlaying;
  try
    StateChanged;
    for cEvent := 0 to EventCount -1 do
    begin
      Events[cEvent].Playback(aEditor);
      if State <> msPlaying then
        Break;
    end;
  finally
    if State = msPlaying then
    begin
      FState := msStopped;
      StateChanged;
    end;
  end;
end;

procedure TCustomSynMacroRecorder.RecordMacro(aEditor: TCustomSynEdit);
begin
  if FState <> msStopped then
    Error(sCannotRecord);
  Clear;
  FEvents := TList.Create;
  FEvents.Capacity := 512;
  FState := msRecording;
  FCurrentEditor := aEditor;
  StateChanged;
end;

procedure TCustomSynMacroRecorder.RemoveEditor(aEditor: TCustomSynEdit);
begin
  inherited RemoveEditor(aEditor);
end;

procedure TCustomSynMacroRecorder.Resume;
begin
  if FState <> msPaused then
    Error(sCannotResume);
  FState := msRecording;
  StateChanged;
end;

procedure TCustomSynMacroRecorder.SaveToStream(aDest: TStream);
var
  cEvent, eCnt: Integer;
begin
  eCnt := EventCount;
  aDest.Write(eCnt, sizeof(eCnt));
  for cEvent := 0 to eCnt -1 do
    Events[cEvent].SaveToStream(aDest);
end;

procedure TCustomSynMacroRecorder.SetShortCut(const Index: Integer;
  const Value: TShortCut);
var
  cEditor: Integer;
begin
  if FShortCuts[TSynMacroCommand(Index)] <> Value then
  begin
    if Assigned(fEditors) then
      if Value <> 0 then
      begin
        for cEditor := 0 to fEditors.Count -1 do
          HookEditor(Editors[cEditor], FCommandIDs[TSynMacroCommand(Index)],
            FShortCuts[TSynMacroCommand(Index)], Value);
      end else
      begin
        for cEditor := 0 to fEditors.Count -1 do
          UnHookEditor(Editors[cEditor], FCommandIDs[TSynMacroCommand(Index)],
            FShortCuts[TSynMacroCommand(Index)]);
      end;
    FShortCuts[TSynMacroCommand(Index)] := Value;
  end;
end;

procedure TCustomSynMacroRecorder.StateChanged;
begin
  if Assigned(OnStateChange) then
    OnStateChange(Self);
end;

procedure TCustomSynMacroRecorder.Stop;
begin
  if FState = msStopped then
    Exit;
  FState := msStopped;
  FCurrentEditor := nil;
  if FEvents.Count = 0 then
    FreeAndNil(FEvents);
  StateChanged;
end;

function TCustomSynMacroRecorder.GetAsString: UnicodeString;
var
  i: Integer;
  eStr: UnicodeString;
begin
  Result := 'macro ' + MacroName + #13#10 + 'begin' + #13#10;
  if Assigned(FEvents) then
  begin
    for i := 0 to FEvents.Count -1 do
    begin
      eStr := Events[i].AsString;
      if eStr <> '' then
        Result := Result + '  '  + eStr + #13#10;
    end;
  end;
  Result := Result + 'end';
end;

procedure TCustomSynMacroRecorder.SetAsString(const Value: UnicodeString);
var
  i, p, Cmd: Integer;
  S: TUnicodeStrings;
  cmdStr: UnicodeString;
  iEvent: TSynMacroEvent;
begin
  Stop;
  Clear;
  FEvents := TList.Create;
  // process file line by line and create events
  S := TUnicodeStringList.Create;
  try
    S.Text := Value;
    for i := 0 to S.Count - 1 do
    begin
      cmdStr := WideTrim(S[i]);
      p := Pos(' ', cmdStr);
      if p = 0 then p := Length(cmdStr) + 1;
      Cmd := ecNone;
      if IdentToEditorCommand(Copy(cmdStr, 1, p - 1), Longint(Cmd)) then  // D2 needs type-cast
      begin
        Delete(cmdStr, 1, p);
        iEvent := CreateMacroEvent(Cmd);
        try
          FEvents.Add(iEvent);
          iEvent.InitEventParameters(cmdStr);
        except
          iEvent.Free;
        end;
      end;
    end;
  finally
    S.Free;
  end;
end;

procedure TCustomSynMacroRecorder.LoadFromFile(aFilename: string);
var
  F : TFileStream;
begin
  F := TFileStream.Create(aFilename, fmOpenRead);
  try
    LoadFromStream(F);
    MacroName := ChangeFileExt(ExtractFileName(aFilename), '');
  finally
    F.Free;
  end;
end;

procedure TCustomSynMacroRecorder.SaveToFile(aFilename: string);
var
  F : TFileStream;
begin
  F := TFileStream.Create(aFilename, fmCreate);
  try
    SaveToStream(F);
  finally
    F.Free;
  end;
end;

{ TSynBasicEvent }

function TSynBasicEvent.GetAsString: UnicodeString;
var
  Ident: string;
begin
  EditorCommandToIdent(Command, Ident);
  Result := Ident;
  if RepeatCount > 1 then
    Result := Result + ' ' + IntToStr(RepeatCount);
end;

procedure TSynBasicEvent.InitEventParameters(aStr: UnicodeString);
begin
  // basic events have no parameters but can contain an optional repeat count
  RepeatCount := StrToIntDef(WideTrim(aStr), 1);
end;

procedure TSynBasicEvent.Initialize(aCmd: TSynEditorCommand; aChar: WideChar;
  aData: Pointer);
begin
  Command := aCmd;
{$IFDEF SYN_DEVELOPMENT_CHECKS}
  if (aChar <> #0) or (aData <> nil) then
    raise Exception.Create('TSynBasicEvent cannot handle Char <> #0 or Data <> nil');
{$ENDIF}
end;

procedure TSynBasicEvent.LoadFromStream(aStream: TStream);
begin
  aStream.Read(FRepeatCount, SizeOf(FRepeatCount));
end;

procedure TSynBasicEvent.Playback(aEditor: TCustomSynEdit);
var
  i : Integer;
begin
  for i := 1 to RepeatCount do
    aEditor.CommandProcessor(Command, #0, nil);
end;

procedure TSynBasicEvent.SaveToStream(aStream: TStream);
begin
  aStream.Write(Command, SizeOf(TSynEditorCommand));
  aStream.Write(RepeatCount, SizeOf(RepeatCount));
end;

{ TSynCharEvent }

function TSynCharEvent.GetAsString: UnicodeString;
var
  Ident: string;
begin
  EditorCommandToIdent(ecChar, Ident);
  Result := Ident + ' ' + Key;
  if RepeatCount > 1 then
    Result := Result + ' ' + IntToStr(RepeatCount);
end;

procedure TSynCharEvent.InitEventParameters(aStr: UnicodeString);
begin
  // aStr should be a Key value one character in length
  // with an optional repeat count whitespace separated
  if Length(aStr) >= 1 then
    Key := aStr[1]
  else
    Key := ' ';
  Delete(aStr, 1, 1); // if possible delete the first character
  RepeatCount := StrToIntDef(WideTrim(aStr), 1);
end;

procedure TSynCharEvent.Initialize(aCmd: TSynEditorCommand; aChar: WideChar;
  aData: Pointer);
begin
  Key := aChar;
  Assert(aData = nil);
end;

procedure TSynCharEvent.LoadFromStream(aStream: TStream);
begin
  aStream.Read(FKey, SizeOf(Key));
  aStream.Read(FRepeatCount, SizeOf(FRepeatCount));
end;

procedure TSynCharEvent.Playback(aEditor: TCustomSynEdit);
var
  i: Integer;
begin
  for i := 1 to RepeatCount do
    aEditor.CommandProcessor(ecChar, Key, nil);
end;

procedure TSynCharEvent.SaveToStream(aStream: TStream);
const
  iCharCommand: TSynEditorCommand = ecChar;
begin
  aStream.Write(iCharCommand, SizeOf(TSynEditorCommand));
  aStream.Write(Key, SizeOf(Key));
  aStream.Write(RepeatCount, SizeOf(RepeatCount));
end;

{ TSynPositionEvent }

function TSynPositionEvent.GetAsString: UnicodeString;
begin
  Result := inherited GetAsString;
  // add position data here
  Result := Result + Format(' (%d, %d)', [Position.Char, Position.Line]);
  if RepeatCount > 1 then
    Result := Result + ' ' + IntToStr(RepeatCount);
end;

procedure TSynPositionEvent.InitEventParameters(aStr: UnicodeString);
var
  i, o, c, x, y: Integer;
  valStr: UnicodeString;
begin
  inherited;
  // aStr should be (x, y) with optional repeat count whitespace separated
  aStr := WideTrim(aStr);
  i := Pos(',', aStr);
  o := Pos('(', aStr);
  c := Pos(')', aStr);
  if (not ((i = 0) or (o = 0) or (c = 0))) and
     ((i > o) and (i < c)) then
  begin
    valStr := Copy(aStr, o + 1, i - o - 1);
    x := StrToIntDef(valStr, 1);
    Delete(aStr, 1, i);
    aStr := WideTrim(aStr);
    c := Pos(')', aStr);
    valStr := Copy(aStr, 1, c - 1);
    y := StrToIntDef(valStr, 1);
    Position := BufferCoord(x, y);
    Delete(aStr, 1, c);
    aStr := WideTrim(aStr);
    RepeatCount := StrToIntDef(aStr, 1);
  end;
end;

procedure TSynPositionEvent.Initialize(aCmd: TSynEditorCommand;
  aChar: WideChar; aData: Pointer);
begin
  inherited;
  if aData <> nil then
    Position := TBufferCoord(aData^)
  else
    Position := BufferCoord(0, 0);
end;

procedure TSynPositionEvent.LoadFromStream(aStream: TStream);
begin
  aStream.Read(FPosition, SizeOf(Position));
end;

procedure TSynPositionEvent.Playback(aEditor: TCustomSynEdit);
begin
  if (Position.Char <> 0) or (Position.Line <> 0) then
    aEditor.CommandProcessor(Command, #0, @Position)
  else
    aEditor.CommandProcessor(Command, #0, nil);
end;

procedure TSynPositionEvent.SaveToStream(aStream: TStream);
begin
  inherited;
  aStream.Write(Position, SizeOf(Position));
end;

{ TSynStringEvent }

function TSynStringEvent.GetAsString: UnicodeString;
var
  Ident: string;
begin
  EditorCommandToIdent(ecString, Ident);
  Result := Ident + ' ' + WideQuotedStr(Value, #39);
  if RepeatCount > 1 then
    Result := Result + ' ' + IntToStr(RepeatCount);
end;

procedure TSynStringEvent.InitEventParameters(aStr: UnicodeString);
var
  o, c: Integer;
  valStr: UnicodeString;
begin                      
  // aStr = 'test' with optional whitespace separated repeat count
  o := Pos('''', aStr);
  c := WideLastDelimiter('''', aStr);
  valStr := Copy(aStr, o + 1, c - o - 1);
  Value := UnicodeStringReplace(valStr, '''''', '''', [rfReplaceAll]);
  Delete(aStr, 1, c);
  RepeatCount := StrToIntDef(WideTrim(aStr), 1);
end;

procedure TSynStringEvent.Initialize(aCmd: TSynEditorCommand; aChar: WideChar;
  aData: Pointer);
begin
  Value := UnicodeString(aData);
end;

procedure TSynStringEvent.LoadFromStream(aStream: TStream);
var
  l: Integer;
  Buff: PWideChar;
begin
  aStream.Read(l, sizeof(l));
  GetMem(Buff, l * sizeof(WideChar));
  try
    FillMemory(Buff, l, 0);
    aStream.Read(Buff^, l * sizeof(WideChar));
    FString := Buff;
  finally
    FreeMem(Buff);
  end;
  aStream.Read(FRepeatCount, sizeof(FRepeatCount));
end;

procedure TSynStringEvent.Playback(aEditor: TCustomSynEdit);
var
  i, j: Integer;
begin
  for j := 1 to RepeatCount do
  begin
//    aEditor.CommandProcessor( ecString, #0, Pointer(Value) );
    // SynEdit doesn't actually support the ecString command so we convert
    // it into ecChar commands
    for i := 1 to Length(Value) do
      aEditor.CommandProcessor(ecChar, Value[i], nil);
  end;
end;

procedure TSynStringEvent.SaveToStream(aStream: TStream);
const
  StrCommand: TSynEditorCommand = ecString;
var
  l: Integer;
  Buff: PWideChar;
begin
  aStream.Write(StrCommand, SizeOf(StrCommand));
  l := Length(Value) + 1;
  aStream.Write(l, sizeof(l));
  GetMem(Buff, l * sizeof(WideChar));
  try
    FillMemory(Buff, l, 0);
    WStrCopy(Buff, PWideChar(Value));
    aStream.Write(Buff^, l * sizeof(WideChar));
  finally
    FreeMem(Buff);
  end;
  aStream.Write(RepeatCount, sizeof(RepeatCount));
end;


{ TSynMacroEvent }

constructor TSynMacroEvent.Create;
begin
  inherited Create;
  FRepeatCount := 1;
end;

end.

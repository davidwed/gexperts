{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynEditExport.pas, released 2000-04-16.

The Original Code is partly based on the mwExport.pas file from the
mwEdit component suite by Martin Waldenburg and other developers, the Initial
Author of this file is Michael Hieke.
Portions created by Michael Hieke are Copyright 2000 Michael Hieke.
Portions created by James D. Jacobson are Copyright 1999 Martin Waldenburg.
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

$Id: SynEditExport.pas,v 1.17.2.8 2008/09/17 13:59:12 maelh Exp $

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net

Known Issues:
-------------------------------------------------------------------------------}

{ Base class for exporting a programming language source file or part of it to
  a formatted output like HTML or RTF and copying this to the Windows clipboard
  or saving it to a file. }
{$IFNDEF QSYNEDITEXPORT}
unit SynEditExport;
{$ENDIF}

{$I SynEdit.inc}

interface

uses
  Windows,
  Graphics,
  Clipbrd,
  SynEditHighlighter,
  SynEditTypes,
  SynUnicode,
  Classes,
  SysUtils;

type
  ESynEncoding = class(ESynError);

  { Base exporter class, implements the buffering and the common functionality
    to track the changes of token attributes, to export to the clipboard or to
    save the output to a file. Descendant classes have to implement only the
    actual formatting of tokens. }
  TSynCustomExporter = class(TComponent)
  private
    FBuffer: TMemoryStream;
    FCharSize: Integer;
    FFirstAttribute: Boolean;
    FStreaming: Boolean;
    procedure AssignFont(Value: TFont);
    procedure SetEncoding(const Value: TSynEncoding);
    procedure SetExportAsText(Value: Boolean);
    procedure SetFont(Value: TFont);
    procedure SetHighlighter(Value: TSynCustomHighlighter);
    procedure SetTitle(const Value: UnicodeString);
    procedure SetUseBackground(const Value: Boolean);
    function StringSize(const AText: UnicodeString): Integer;
    procedure WriteString(const AText: UnicodeString);
  protected
    FBackgroundColor: TColor;
    FClipboardFormat: UINT;
    FDefaultFilter: string;
    FEncoding: TSynEncoding;
    FExportAsText: Boolean;
    FFont: TFont;
    FHighlighter: TSynCustomHighlighter;
    FLastBG: TColor;
    FLastFG: TColor;
    FLastStyle: TFontStyles;
    FTitle: UnicodeString;
    FUseBackground: Boolean;
    { Adds a string to the output buffer. }
    procedure AddData(const AText: UnicodeString);
    { Adds a string and a trailing newline to the output buffer. }
    procedure AddDataNewLine(const AText: UnicodeString);
    { Adds a newline to the output buffer. }
    procedure AddNewLine;
    { Copies the data under this format to the clipboard. The clipboard has to
      be opened explicitly when more than one format is to be set. }
    procedure CopyToClipboardFormat(AFormat: UINT);
    procedure DefineProperties(Filer: TFiler); override;
    { Has to be overridden in descendant classes to add the closing format
      strings to the output buffer.  The parameters can be used to track what
      changes are made for the next token. }
    procedure FormatAttributeDone(BackgroundChanged, ForegroundChanged: Boolean;
      FontStylesChanged: TFontStyles); virtual; abstract;
    { Has to be overridden in descendant classes to add the opening format
      strings to the output buffer.  The parameters can be used to track what
      changes have been made in respect to the previous token. }
    procedure FormatAttributeInit(BackgroundChanged, ForegroundChanged: Boolean;
      FontStylesChanged: TFontStyles); virtual; abstract;
    { Has to be overridden in descendant classes to add the closing format
      strings to the output buffer after the last token has been written. }
    procedure FormatAfterLastAttribute; virtual; abstract;
    { Has to be overridden in descendant classes to add the opening format
      strings to the output buffer when the first token is about to be written. }
    procedure FormatBeforeFirstAttribute(BackgroundChanged,
      ForegroundChanged: Boolean; FontStylesChanged: TFontStyles);
      virtual; abstract;
    { Has to be overridden in descendant classes to add the formatted text of
      the actual token text to the output buffer. }
    procedure FormatToken(Token: UnicodeString); virtual;
    { Has to be overridden in descendant classes to add a newline in the output
      format to the output buffer. }
    procedure FormatNewLine; virtual; abstract;
    { Returns the size of the formatted text in the output buffer, to be used
      in the format header or footer. }
    function GetBufferSize: Integer;
    { The clipboard format the exporter creates as native format. }
    function GetClipboardFormat: UINT; virtual;
    { Has to be overridden in descendant classes to return the correct output
      format footer. }
    function GetFooter: UnicodeString; virtual; abstract;
    { Has to be overridden in descendant classes to return the name of the
      output format. }
    function GetFormatName: string; virtual;
    { Has to be overridden in descendant classes to return the correct output
      format header. }
    function GetHeader: UnicodeString; virtual; abstract;
    { Inserts a data block at the given position into the output buffer.  Is
      used to insert the format header after the exporting, since some header
      data may be known only after the conversion is done. }
    procedure InsertData(APos: Integer; const AText: UnicodeString);
    function ReplaceReservedChar(AChar: WideChar): UnicodeString; virtual; abstract;
    { Returns a string that has all the invalid chars of the output format
      replaced with the entries in the replacement array. }
    function ReplaceReservedChars(AToken: UnicodeString): UnicodeString;
    { Sets the token attribute of the next token to determine the changes
      of colors and font styles so the properties of the next token can be
      added to the output buffer. }
    procedure SetTokenAttribute(Attri: TSynHighlighterAttributes); virtual;
    function UseBom: Boolean; virtual; abstract;
  public
    { Creates an instance of the exporter. }
    constructor Create(AOwner: TComponent); override;
    { Destroys an instance of the exporter. }
    destructor Destroy; override;
    { Clears the output buffer and any internal data that relates to the last
      exported text. }
    procedure Clear; virtual;
    { Copies the output buffer contents to the clipboard, as the native format
      or as text depending on the ExportAsText property. }
    procedure CopyToClipboard;
    { Exports everything in the strings parameter to the output buffer. }
    procedure ExportAll(ALines: TUnicodeStrings);
    { Exports the given range of the strings parameter to the output buffer. }
    procedure ExportRange(ALines: TUnicodeStrings; Start, Stop: TBufferCoord);
    { Saves the contents of the output buffer to a file. }
    procedure SaveToFile(const FileName: UnicodeString);
    { Saves the contents of the output buffer to a stream. }
    procedure SaveToStream(Stream: TStream);
    function SupportedEncodings: TSynEncodings; virtual; abstract;
  public
    { Default background color for text that has no token attribute assigned or
      for token attributes that have the background set to default. }
    property Color: TColor read FBackgroundColor write FBackgroundColor;
    { Filter string for the output format for SaveAs file dialogs. }
    property DefaultFilter: string read FDefaultFilter write FDefaultFilter;
    property Encoding: TSynEncoding read FEncoding write SetEncoding default seUTF8;
    property ExportAsText: Boolean read FExportAsText write SetExportAsText;
    { The font to be used for the output format. The font color is used for text
      that has no token attribute assigned or for token attributes that have
      the background set to default. }
    property Font: TFont read FFont write SetFont;
    { The output format of the exporter. }
    property FormatName: string read GetFormatName;
    { The highlighter to use for exporting. }
    property Highlighter: TSynCustomHighlighter
      read FHighlighter write SetHighlighter;
    { The title to embedd into the output header. }
    property Title: UnicodeString read FTitle write SetTitle;
    { Use the token attribute background for the exporting. }
    property UseBackground: Boolean read FUseBackground write SetUseBackground;
  end;

const
  EncodingStrs: array[TSynEncoding] of string =
    ('UTF-8', 'UTF-16 Little Endian', 'UTF-16 Big Endian', 'ANSI');

resourcestring
  SEncodingError = '%s encoding is not supported by %s-exporter';

implementation

uses
{$IFDEF SYN_COMPILER_4_UP}
  Math,
{$ENDIF}
  SynEditMiscProcs,
  SynEditStrConst;

{ TSynCustomExporter }

constructor TSynCustomExporter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBuffer := TMemoryStream.Create;
  FClipboardFormat := CF_TEXT;
  FCharSize := 1;
  FEncoding := seUTF8;
  FFont := TFont.Create;
  FBackgroundColor := clWindow;
  AssignFont(nil);
  Clear;
  FTitle := SYNS_Untitled;
end;

destructor TSynCustomExporter.Destroy;
begin
  FFont.Free;
  FBuffer.Free;
  inherited Destroy;
end;

procedure TSynCustomExporter.AddData(const AText: UnicodeString);
begin
  if AText <> '' then
  begin
    WriteString(AText);
    FBuffer.SetSize(FBuffer.Position);
  end;
end;

procedure TSynCustomExporter.AddDataNewLine(const AText: UnicodeString);
begin
  AddData(AText);
  AddNewLine;
end;

procedure TSynCustomExporter.AddNewLine;
begin
  WriteString(WideCRLF);
  FBuffer.SetSize(FBuffer.Position);
end;

procedure TSynCustomExporter.AssignFont(Value: TFont);
begin
  if Value <> nil then
    FFont.Assign(Value)
  else
  begin
    FFont.Name := 'Courier New';
    FFont.Size := 10;
    FFont.Color := clWindowText;
    FFont.Style := [];
  end;
end;

procedure TSynCustomExporter.Clear;
begin
  FBuffer.Position := 0;
  // Size is ReadOnly in Delphi 2
  FBuffer.SetSize(0);
  FLastStyle := [];
  FLastBG := clWindow;
  FLastFG := clWindowText;
end;

procedure SetClipboardText(Text: UnicodeString);
var
  Mem: HGLOBAL;
  P: PByte;
  SLen: Integer;
begin
  SLen := Length(Text);
  Clipboard.Open;
  try
    Clipboard.Clear;

    // set ANSI text only on Win9X, WinNT automatically creates ANSI from Unicode
    if Win32Platform <> VER_PLATFORM_WIN32_NT then
    begin
      Mem := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, SLen + 1);
      if Mem <> 0 then
      begin
        P := GlobalLock(Mem);
        try
          if P <> nil then
          begin
            Move(PAnsiChar(AnsiString(Text))^, P^, SLen + 1);
            Clipboard.SetAsHandle(CF_TEXT, Mem);
          end;
        finally
          GlobalUnlock(Mem);
        end;
      end;
    end;

    // set unicode text, this also works on Win9X, even if the clipboard-viewer
    // can't show it, Word 2000+ can paste it including the unicode only characters
    Mem := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE,
      (SLen + 1) * sizeof(WideChar));
    if Mem <> 0 then
    begin
      P := GlobalLock(Mem);
      try
        if P <> nil then
        begin
          Move(PWideChar(Text)^, P^, (SLen + 1) * sizeof(WideChar));
          Clipboard.SetAsHandle(CF_UNICODETEXT, Mem);
        end;
      finally
      GlobalUnlock(Mem);
      end;
    end;
    // Don't free Mem!  It belongs to the clipboard now, and it will free it
    // when it is done with it.
  finally
    Clipboard.Close;
  end;
end;

procedure TSynCustomExporter.CopyToClipboard;
const
  Nulls: array[0..1] of Byte = (0, 0);
var
  S: UnicodeString;
begin
  if FExportAsText then
  begin
    FBuffer.Position := FBuffer.Size;
    FBuffer.Write(Nulls, FCharSize);
    case Encoding of
      seUTF16LE:
        S := PWideChar(FBuffer.Memory);
      seUTF16BE:
        begin
          S := PWideChar(FBuffer.Memory);
          StrSwapByteOrder(PWideChar(S));
        end;
      seUTF8:
{$IFDEF UNICODE}
        S := UTF8ToUnicodeString(PAnsiChar(FBuffer.Memory));
{$ELSE}
        S := UTF8Decode(PAnsiChar(FBuffer.Memory));
{$ENDIF}
      seAnsi:
        S := UnicodeString(PAnsiChar(FBuffer.Memory));
    end;
    SetClipboardText(S);
  end
  else
    CopyToClipboardFormat(GetClipboardFormat);
end;

procedure TSynCustomExporter.CopyToClipboardFormat(AFormat: UINT);
var
  hData: THandle;
  hDataSize: UINT;
  PtrData: PByte;
begin
  hDataSize := GetBufferSize + 1;
  hData := GlobalAlloc(GMEM_MOVEABLE or GMEM_ZEROINIT or GMEM_SHARE, hDataSize);
  if hData <> 0 then
  try
    PtrData := GlobalLock(hData);
    if Assigned(PtrData) then
    begin
      try
        FBuffer.Position := 0;
        FBuffer.Read(PtrData^, hDataSize - 1); // trailing #0
      finally
        GlobalUnlock(hData);
      end;
      Clipboard.SetAsHandle(AFormat, hData);
    end
    else
      Abort;
  except
    GlobalFree(hData);
    OutOfMemoryError;
  end;
end;

procedure TSynCustomExporter.DefineProperties(Filer: TFiler);
begin
  inherited;
{$IFNDEF UNICODE}
  UnicodeDefineProperties(Filer, Self);
{$ENDIF}
end;

procedure TSynCustomExporter.ExportAll(ALines: TUnicodeStrings);
begin
  ExportRange(ALines, BufferCoord(1, 1), BufferCoord(MaxInt, MaxInt));
end;

procedure TSynCustomExporter.ExportRange(ALines: TUnicodeStrings; Start, Stop: TBufferCoord);
var
  i: Integer;
  Line, Token: UnicodeString;
  Attri: TSynHighlighterAttributes;
begin
  FStreaming := True;
  try
    // abort if not all necessary conditions are met
    if not Assigned(ALines) or not Assigned(Highlighter) or (ALines.Count = 0)
      or (Start.Line > ALines.Count) or (Start.Line > Stop.Line)
    then
      Abort;

    Stop.Line := Max(1, Min(Stop.Line, ALines.Count));
    Stop.Char := Max(1, Min(Stop.Char, Length(ALines[Stop.Line - 1]) + 1));
    Start.Char := Max(1, Min(Start.Char, Length(ALines[Start.Line - 1]) + 1));
    if (Start.Line = Stop.Line) and (Start.Char >= Stop.Char) then
      Abort;

    // initialization
    FBuffer.Position := 0;
    // Size is ReadOnly in Delphi 2
    FBuffer.SetSize(Max($1000, (Stop.Line - Start.Line) * 128) * FCharSize);
    Highlighter.ResetRange;
    // export all the lines into FBuffer
    FFirstAttribute := True;
    for i := Start.Line to Stop.Line do
    begin
      Line := ALines[i - 1];
      // order is important, since Start.Y might be equal to Stop.Y
      if i = Stop.Line then
        Delete(Line, Stop.Char, MaxInt);
      if (i = Start.Line) and (Start.Char > 1) then
        Delete(Line, 1, Start.Char - 1);
      // export the line
      Highlighter.SetLine(Line, i);
      while not Highlighter.GetEOL do
      begin
        Attri := Highlighter.GetTokenAttribute;
        if Assigned(Attri) then // The .pas highlighter, for example, can return a nil Attri above for a trailing EOF/null that was loaded from a stream
        begin
          Token := ReplaceReservedChars(Highlighter.GetToken);
          SetTokenAttribute(Attri);
          FormatToken(Token);
        end;
        Highlighter.Next;
      end;
      FormatNewLine;
    end;
    if not FFirstAttribute then
      FormatAfterLastAttribute;

    // insert header
    InsertData(0, GetHeader);
    // add footer
    AddData(GetFooter);
  finally
    FStreaming := False
  end
end;

procedure TSynCustomExporter.FormatToken(Token: UnicodeString);
begin
  AddData(Token);
end;

function TSynCustomExporter.GetBufferSize: Integer;
begin
  Result := FBuffer.Size;
end;

function TSynCustomExporter.GetClipboardFormat: UINT;
begin
  Result := FClipboardFormat;
end;

function TSynCustomExporter.GetFormatName: string;
begin
  Result := '';
end;

procedure TSynCustomExporter.InsertData(APos: Integer; const AText: UnicodeString);
var
  Size, ToMove, SizeNeeded: Integer;
  Dest: PByte;
begin
  Size := StringSize(AText);
  if Size > 0 then
  begin
    ToMove := FBuffer.Position;
    SizeNeeded := ToMove + Size;
    if FBuffer.Size < SizeNeeded then
      // Size is ReadOnly in Delphi 2
      FBuffer.SetSize((SizeNeeded + $1800) and not $FFF); // increment in pages
    Dest := FBuffer.Memory;
    Inc(Dest, Size);
    Move(FBuffer.Memory^, Dest^, ToMove);
    FBuffer.Position := 0;
    WriteString(AText);
    FBuffer.Position := ToMove + Size;
    FBuffer.SetSize(FBuffer.Position);
  end;
end;

function TSynCustomExporter.ReplaceReservedChars(AToken: UnicodeString): UnicodeString;
var
  I, ISrc, IDest, SrcLen, DestLen: Integer;
  Replace: UnicodeString;
  c: WideChar;                                                                      //mh 2000-10-10
begin
  if AToken <> '' then
  begin
    SrcLen := Length(AToken);
    ISrc := 1;
    DestLen := SrcLen;
    IDest := 1;
    SetLength(Result, DestLen);
    while ISrc <= SrcLen do
    begin
      c := AToken[ISrc];
      Replace := ReplaceReservedChar(c);
      if Replace <> '' then
        Inc(ISrc)
      else
      begin
        if IDest > DestLen then
        begin
          Inc(DestLen, 32);
          SetLength(Result, DestLen);
        end;
        Result[IDest] := c;
        Inc(ISrc);
        Inc(IDest);
        continue;
      end;
      if IDest + Length(Replace) - 1 > DestLen then
      begin
        Inc(DestLen, Max(32, IDest + Length(Replace) - DestLen));
        SetLength(Result, DestLen);
      end;
      for I := 1 to Length(Replace) do
      begin
        Result[IDest] := Replace[I];
        Inc(IDest);
      end;
    end;
    SetLength(Result, IDest - 1);
  end
  else
    Result := '';
end;

procedure TSynCustomExporter.SaveToFile(const FileName: UnicodeString);
var
  Stream: TStream;
begin
  Stream := TWideFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TSynCustomExporter.SaveToStream(Stream: TStream);
begin
  if UseBOM then
    case Encoding of
      seUTF8:
        Stream.WriteBuffer(UTF8BOM, 3);
      seUTF16LE:
        Stream.WriteBuffer(UTF16BOMLE, 2);
      seUTF16BE:
        Stream.WriteBuffer(UTF16BOMBE, 2);
    end;
  FBuffer.Position := 0;
  FBuffer.SaveToStream(Stream);
end;

procedure TSynCustomExporter.SetEncoding(const Value: TSynEncoding);
begin
  // don't change encoding while streaming as this could corrupt output data
  if FStreaming then Exit;

  if not (Value in SupportedEncodings) then
    raise ESynEncoding.CreateFmt(SEncodingError, [EncodingStrs[Value],
      GetFormatName]);

  FEncoding := Value;
  if Value in [seUTF8, seAnsi] then
    FCharSize := 1
  else if Value in [seUTF16LE, seUTF16BE] then
    FCharSize := 2;
end;

procedure TSynCustomExporter.SetExportAsText(Value: Boolean);
begin
  if FExportAsText <> Value then
  begin
    FExportAsText := Value;
    Clear;
  end;
end;

procedure TSynCustomExporter.SetFont(Value: TFont);
begin
  AssignFont(Value);
end;

procedure TSynCustomExporter.SetHighlighter(Value: TSynCustomHighlighter);
begin
  if FHighlighter <> Value then
  begin
    if FHighlighter <> nil then
      FHighlighter.FreeNotification(Self);
    FHighlighter := Value;
    Clear;
    if Assigned(FHighlighter) and Assigned(FHighlighter.WhitespaceAttribute) and FUseBackground then
      FBackgroundColor := FHighlighter.WhitespaceAttribute.Background;
  end;
end;

procedure TSynCustomExporter.SetTitle(const Value: UnicodeString);
begin
  if FTitle <> Value then
  begin
    if Value <> '' then
      FTitle := Value
    else
      FTitle := SYNS_Untitled;
  end;
end;

procedure TSynCustomExporter.SetTokenAttribute(Attri: TSynHighlighterAttributes);
var
  ChangedBG: Boolean;
  ChangedFG: Boolean;
  ChangedStyles: TFontStyles;

  function ValidatedColor(AColor, ADefColor: TColor): TColor;
  begin
    if AColor = clNone then
      Result := ColorToRGB(ADefColor)
    else
      Result := ColorToRGB(AColor);
  end;

begin
  if FFirstAttribute then
  begin
    FFirstAttribute := False;
    FLastBG := ValidatedColor(Attri.Background, FBackgroundColor);
    FLastFG := ValidatedColor(Attri.Foreground, FFont.Color);
    FLastStyle := Attri.Style;
    FormatBeforeFirstAttribute(UseBackground and (FLastBG <> FBackgroundColor),
      FLastFG <> FFont.Color, Attri.Style);
  end
  else
  begin
    ChangedBG := UseBackground and
      (FLastBG <> ValidatedColor(Attri.Background, FBackgroundColor));
    ChangedFG := (FLastFG <> ValidatedColor(Attri.Foreground, FFont.Color));
    // which font style bits are to be reset?
    ChangedStyles := FLastStyle - Attri.Style;
    if ChangedBG or ChangedFG or (FLastStyle <> Attri.Style) then
    begin
      FormatAttributeDone(ChangedBG, ChangedFG, ChangedStyles);
      // which font style bits are to be set?
      ChangedStyles := Attri.Style - FLastStyle;
      FLastBG := ValidatedColor(Attri.Background, FBackgroundColor);
      FLastFG := ValidatedColor(Attri.Foreground, FFont.Color);
      FLastStyle := Attri.Style;
      FormatAttributeInit(ChangedBG, ChangedFG, ChangedStyles);
    end;
  end;
end;

procedure TSynCustomExporter.SetUseBackground(const Value: Boolean);
begin
  FUseBackground := Value;
  if Assigned(FHighlighter) and Assigned(FHighlighter.WhitespaceAttribute) and FUseBackground then
    FBackgroundColor := FHighlighter.WhitespaceAttribute.Background;
end;

function TSynCustomExporter.StringSize(const AText: UnicodeString): Integer;
begin
  Result := 0;
  case Encoding of
    seUTF8:
      Result := Length(UTF8Encode(AText));
    seUTF16LE, seUTF16BE:
      Result := Length(AText);
    seAnsi:
      Result := Length(AnsiString(PWideChar(AText)));
  end;
  Result := Result * FCharSize;
end;

procedure TSynCustomExporter.WriteString(const AText: UnicodeString);
var
  UTF8Str: UTF8String;
  AnsiStr: AnsiString;
begin
  case Encoding of
    seUTF8:
      begin
        UTF8Str := UTF8Encode(AText);
        FBuffer.WriteBuffer(UTF8Str[1], Length(UTF8Str));
      end;
    seUTF16LE:
      FBuffer.WriteBuffer(AText[1], Length(AText) * sizeof(WideChar));
    seUTF16BE:
      begin
        StrSwapByteOrder(PWideChar(AText));
        FBuffer.WriteBuffer(AText[1], Length(AText) * sizeof(WideChar));
      end;
    seAnsi:
      begin
        AnsiStr := AnsiString(PWideChar(AText));
        FBuffer.WriteBuffer(AnsiStr[1], Length(AnsiStr));
      end;
  end;
end;

end.

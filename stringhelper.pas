//-----------------------------------------------------------------------------------
//  Helpers Package © 2026 by Alexander Tverskoy
//  Licensed under the MIT License
//  You may obtain a copy of the License at https://opensource.org/licenses/MIT
//-----------------------------------------------------------------------------------

unit stringhelper;

{$mode objfpc}{$H+}
{$codepage utf8}
{$modeswitch typehelpers}

interface

uses
  Forms,
  Types,
  Controls,
  StdCtrls,
  SysUtils,
  StrUtils,
  Classes,
  Graphics,
  LCLIntf,
  HTTPDefs,
  RegExpr,
  LazUTF8,
  fpjson;

const
  SpaceChar = ' ';
  TabChar = #9;
  LF = #10;
  CR = #13;
  CRLF = #13#10;
  BrTag = '<br>';

type
  { TStringExHelper }

  TStringHelperEx = type helper(TStringHelper) for string
    /// Converts a hex color string (e.g. '#RRGGBB' or 'RRGGBB') to a TColor value.
    function ToColor: TColor;

    /// Replaces escape sequences like \n, \r, \t, \\, \" and Unicode \uXXXX with their actual characters.
    function UnescapeUnicode: string;

    /// Escapes backslashes, double quotes, line breaks and tabs for safe embedding in JSON or similar text.
    function EscapeText: string;

    /// Encodes the string for use in a URL query parameter or path segment, escaping special characters.
    function EncodeURLElement: string;

    /// Decodes an HTTP/URL encoded string (e.g. %20 → space, + → space).
    function HTTPDecode: string;

    /// Truncates a UTF‑8 string to at most MaxBytes, optionally taking into account later encoding expansion.
    function Utf8Truncate(MaxBytes: integer; Encode: boolean): string;

    /// Truncates a UTF‑8 string by measuring the actual encoded length of each character, then returns the raw UTF‑8 prefix.
    function Utf8TruncateWithEncoding(MaxBytes: integer; Encode: boolean): string;

    /// Returns True if the trimmed string starts with '{' or '[', indicating a possible JSON object or array.
    function IsJson: boolean;

    /// Removes empty string fields from a JSON object (especially inside "params" and "lang") or empty URL parameters.
    function RemoveEmptyParams: string;

    /// Saves the string content to a UTF‑8 text file with the given filename.
    procedure SaveStringToFile(const FileName: string);

    /// Saves the string to a temporary file and opens it with the default text editor.
    procedure OpenStringInTextEditor;

    /// Returns the string without its trailing line break (CRLF, LF or CR), if present.
    function RemoveTrailingLineBreak: string;

    /// Extracts a text sample of at most MaxLen characters, trying to break at a sentence end or space.
    function ExtractTextSample(MaxLen: integer = 500): string;

    /// Tries to parse and pretty‑print the string as JSON; returns True on success and the formatted result in AFormatted.
    function TryFormatJson(out AFormatted: string): boolean;

    /// Tries to parse a string in the form "IP:Port" (e.g. 127.0.0.1:8080) and returns the valid IP and port.
    function TryParseIPPort(out IP: string; out Port: word): boolean;

    /// Loads the string as text into a TStringList; optional trailing empty line when string ends with newline
    function ToStringList(TrimAtEnd: boolean = False): TStringList;

    /// Tries to interpret the string as an ISO 8601 date/time; returns True on success
    function ToDateTimeISOTry(out ADateTime: TDateTime): boolean;

    /// Tries to convert the string to a Double, limiting length to 15 characters and trying multiple decimal separators
    function ToFloatTry(out Value: double; MaxLength: integer = 15): boolean;

    /// Splits the string by spaces, keeping at most Count+1 parts
    function SplitByFirstSpaces(Count: integer = 1): TStringArray;

    /// Checks if the string starts with a comparison operator, returning the operator and the rest
    function StartsWithOperator(out Op, Rest: string): boolean;

    /// Returns True if the string begins with a bracket-surrounded capital letter followed by a space, e.g. "(A) "
    function StartsWithBracketAZ: boolean;

    /// Detects whether the trimmed, lowercased string starts with one of the given "done" markers
    function StartsWithStrings(Strings: array of string): boolean;

    /// Returns True if the string starts with the given character
    function StartsWithChar(const Ch: char = SpaceChar): boolean;

    /// Returns True if the string ends with the given character
    function EndsWithChar(const Ch: char = SpaceChar): boolean;

    /// Returns True if the trimmed string equals one of the given strings
    function IsOneOf(Strings: array of string): boolean;

    /// Removes a leading substring (and a following single space) from the string if present
    function RemoveStrings(Strings: array of string): string;

    /// Replaces all tab characters (#9) with a single space
    function ReplaceTabCharWithSpace: string;

    /// Removes all spaces and trims the result
    function RemoveSpaceChar: string;

    /// Replaces any line breaks with the HTML <br> tag
    function ReplaceLineBreaks(Value: string = BrTag): string;

    /// Removes up to MaxSpaces leading spaces
    function TrimLeadingSpaces(MaxSpaces: integer = 1): string;

    /// Removes up to MaxSpaces trailing spaces
    function TrimTrailingSpaces(MaxSpaces: integer = 1): string;

    /// Percent-encodes all characters not in the safe set
    function AsEncodedUrl: string;

    /// Checks whether a specific UTF-8 character in the string equals FindChar
    function IsUTF8Char(CharIndex: integer; FindChar: string = SpaceChar): boolean;

    /// Returns the UTF-8 lower-case version of the string
    function UTF8Lower: string;

    /// Returns the string repeated Count times
    function RepeatString(Count: integer): string;

    /// Renders the string as a monospace bitmap and converts it to a Unicode block-character representation
    function ToASCIITextArt(const FontName: string = 'Monospace'; FontSize: integer = 12): string;

    /// Validates whether the string is a well-formed email address, ignoring an optional "mailto:" prefix
    function IsEmail: boolean;

    /// Validates whether the string is a URL (http, https, ftp) or contains a path separator
    function IsUrlSimilar: boolean;

    /// Returns True if the string starts with a known scheme (://, mailto:, tel:, sms:)
    function HasUrlScheme: boolean;

    /// Removes any backtick-enclosed blocks from the string, provided they are short enough
    function RemoveBacktickBlocks: string;

    /// Returns the portion of the string before the first colon
    function SubStringBeforeColon: string;

    /// Splits the string into name and hint parts at the first "//"
    procedure SplitStringByComment(out StartPart, EndPart: string);

    /// Replaces each non-empty line with bullet characters matching the original line width, preserving line breaks.
    function MaskTextWithBullets(ACanvas: TCanvas; const ALineEnding: string): string;

    /// Deletes the first character if it equals Ch
    function DeleteFirstChar(const Ch: char): string;

    /// Removes the first occurrence of SubStr (forward or reverse search)
    function RemoveFirstSubstring(const SubStr: string; Reverse: boolean = False): string;

    /// Adds a combining character after every character except newlines
    function ApplyCombiningChar(const ACombiningChar: string = #$0335): string;

    /// Prepends a number of spaces (IndentLevel * Factor) to the string, modifying it in place
    procedure AddIndent(IndentLevel: integer; Factor: integer = 2);

    /// Removes leading space pairs (2 spaces = 1 indent level) and returns the removed level
    function ExtractIndent(out AIndentLevel: integer): string;

  end;

  { TCaptionHelper }

  TCaptionHelper = type helper for TCaption
    function Replace(const Old, New: string): TCaption;
  end;

  { String Ex Methods }

/// Searches backwards for SubStr in S starting at Offset; returns 1‑based position or 0 if not found.
function PosExReverse(const SubStr, S: unicodestring; Offset: SizeInt = -1): SizeInt;

/// Returns the longest string from an array of strings.
function LongestString(const Values: array of string): string;

/// Shows a lightweight modal input dialog with OK/Cancel; returns True and updates AValue on OK.
function InputQueryLite(const ACaption, APrompt: string; var AValue: string): boolean;

/// Converts a TDateTime value to ISO 8601 string (yyyy-mm-dd or yyyy-mm-ddThh:mm:ss), empty string if zero.
function DateTimeToStringISO(Value: TDateTime; ADisplayTime: boolean = True): string;

/// Converts a TDateTime value to a string using system short date and long time format, empty string if zero.
function DateTimeToString(Value: TDateTime; ADisplayTime: boolean = True): string;

/// Converts a floating point value to its string representation using default format settings.
function FloatToString(Value: double): string;

/// Converts a floating point value to its string representation using the provided TFormatSettings.
function FloatToString(Value: double; FS: TFormatSettings): string;

implementation

{%Region -fold String Ex Methods}

function PosExReverse(const SubStr, S: unicodestring; Offset: SizeInt = -1): SizeInt;
var
  i, MaxLen, SubLen: SizeInt;
  // SubFirst: widechar;
  pc: pwidechar;
begin
  Result := 0; // Initialize result to 0 (not found)
  SubLen := Length(SubStr); // Get length of the substring
  if Offset < 0 then Offset := Length(S);

  // Check if the substring is not empty and Offset is valid
  if (SubLen > 0) and (Offset > 0) and (Offset <= Length(S)) then
  begin
    MaxLen := Length(S) - SubLen + 1; // Adjust max starting index to include end of the string
    // SubFirst := SubStr[1]; // Get the first character of the substring

    // Search backwards, starting from Offset
    for i := Offset downto 1 do
    begin
      // Ensure there is enough space left for the substring
      if (i <= MaxLen) then
      begin
        pc := @S[i]; // Pointer to the current position

        // Check for a match with the substring
        if (CompareWord(SubStr[1], pc^, SubLen) = 0) then
        begin
          Result := i; // Return the found position
          Exit; // Exit the function
        end;
      end;
    end;
  end;
end;

function LongestString(const Values: array of string): string;
var
  I: integer;
begin
  Result := string.Empty;
  for I := Low(Values) to High(Values) do
    if Length(Values[I]) > Length(Result) then
      Result := Values[I];
end;

function InputQueryLite(const ACaption, APrompt: string; var AValue: string): boolean;
var
  InputForm: TForm;
  PromptLabel: TLabel;
  InputEdit: TEdit;
  BtnOK, BtnCancel: TButton;
begin
  Result := False;

  // Create the form dynamically
  InputForm := TForm.Create(nil);
  try
    InputForm.Caption := ACaption;
    InputForm.Position := poScreenCenter;
    InputForm.BorderStyle := bsDialog;
    InputForm.Width := 350;
    InputForm.Font.Size := 10; // Make font a bit more modern

    // Create the prompt label
    PromptLabel := TLabel.Create(InputForm);
    PromptLabel.Parent := InputForm;
    PromptLabel.Caption := APrompt;
    PromptLabel.Left := 12;
    PromptLabel.Top := 12;
    PromptLabel.AutoSize := True;

    // Create the input field tightly below the label
    InputEdit := TEdit.Create(InputForm);
    InputEdit.Parent := InputForm;
    InputEdit.Left := 12;
    InputEdit.Top := PromptLabel.Top + PromptLabel.Height + 6;
    InputEdit.Width := InputForm.ClientWidth - 24;
    InputEdit.Text := AValue;

    // Create the OK button tight below the input field
    BtnOK := TButton.Create(InputForm);
    BtnOK.Parent := InputForm;
    BtnOK.Caption := 'OK';
    BtnOK.ModalResult := mrOk;
    BtnOK.Default := True; // Triggers on Enter key
    BtnOK.Width := 75;
    BtnOK.Height := 25;
    BtnOK.Top := InputEdit.Top + InputEdit.Height + 12;
    BtnOK.Left := InputForm.ClientWidth - (BtnOK.Width * 2) - 18;

    // Create the Cancel button next to OK
    BtnCancel := TButton.Create(InputForm);
    BtnCancel.Parent := InputForm;
    BtnCancel.Caption := 'Cancel';
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Cancel := True; // Triggers on Esc key
    BtnCancel.Width := 75;
    BtnCancel.Height := 25;
    BtnCancel.Top := BtnOK.Top;
    BtnCancel.Left := InputForm.ClientWidth - BtnCancel.Width - 12;

    // Dynamically adjust form height to fit controls snugly
    InputForm.ClientHeight := BtnOK.Top + BtnOK.Height + 12;

    // Show the dialog and check the result
    if InputForm.ShowModal = mrOk then
    begin
      AValue := InputEdit.Text;
      Result := True;
    end;
  finally
    InputForm.Free;
  end;
end;

function DateTimeToStringISO(Value: TDateTime; ADisplayTime: boolean = True): string;
var
  FS: TFormatSettings;
const
  MaxDT: TDateTime = 2958465.999988426; // 31.12.9999 23:59:59
begin
  if (Value > MaxDT) then
    Value := 0;

  if (Value <> 0) then
  begin
    FS := DefaultFormatSettings;
    FS.DateSeparator := '-';
    FS.TimeSeparator := ':';
    FS.ShortDateFormat := 'yyyy-mm-dd';
    FS.ShortTimeFormat := 'hh:nn:ss';

    if (Frac(Value) = 0) or (not ADisplayTime) then
      Result := FormatDateTime('yyyy"-"mm"-"dd', Value, FS)
    else
      Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', Value, FS);
  end
  else
    Result := string.Empty;
end;

function DateTimeToString(Value: TDateTime; ADisplayTime: boolean = True): string;
var
  TimeFmt: string;
begin
  if (Value <> 0) then
  begin
    if (not ADisplayTime) then
      Result := FormatDateTime(FormatSettings.ShortDateFormat, Value)
    else
    begin
      TimeFmt := StringReplace(FormatSettings.LongTimeFormat, 'h', 'hh', [rfReplaceAll]);
      Result := FormatDateTime(FormatSettings.ShortDateFormat + ' ' + TimeFmt, Value);
    end;
  end
  else
    Result := string.Empty;
end;

function FloatToString(Value: double): string;
begin
  Result := FloatToStr(Value);
end;

function FloatToString(Value: double; FS: TFormatSettings): string;
begin
  Result := FloatToStr(Value, FS);
end;

{%EndRegion}

{%Region -fold StringExHelper}

function TStringHelperEx.ToColor: TColor;
var
  S: string;
  R, G, B: byte;
begin
  // Remove leading #
  S := Self.Trim;

  if (S.Length = 7) and (S[1] = '#') then
    System.Delete(S, 1, 1);

  // Parse RRGGBB
  R := StrToInt('$' + System.Copy(S, 1, 2));
  G := StrToInt('$' + System.Copy(S, 3, 2));
  B := StrToInt('$' + System.Copy(S, 5, 2));

  // Build TColor
  Result := RGBToColor(R, G, B);
end;

function TStringHelperEx.UnescapeUnicode: string;
var
  i: integer;
  Code: string;
  tmp: integer;
begin
  // Initialize result
  Result := string.Empty;
  i := 1;

  // Loop through the input string
  while i <= Self.Length do
  begin
    // Handle Unicode escape sequence \uXXXX
    if (Self[i] = '\') and (i + 5 <= Self.Length) and (Self[i + 1] = 'u') then
    begin
      Code := System.Copy(Self, i + 2, 4);
      // Convert hexadecimal code to integer
      if TryStrToInt('$' + Code, tmp) and (tmp <= $FFFF) then
        // Explicit conversion to AnsiChar to remove warnings
        Result := Result + string(widechar(tmp))
      else
        Result := Result + '\u' + Code; // Keep original if conversion fails
      Inc(i, 6);
    end
    // Handle standard escape sequences \r, \n, \t, \\, \"
    else if (Self[i] = '\') and (i < Self.Length) then
    begin
      case Self[i + 1] of
        'r': Result := Result + CR;
        'n': Result := Result + LF;
        't': Result := Result + TabChar;
        '\': Result := Result + '\';
        '"': Result := Result + '"';
        else
          Result := Result + '\' + Self[i + 1]; // Keep unknown escapes as-is
      end;
      Inc(i, 2);
    end
    // Append normal character
    else
    begin
      Result := Result + Self[i];
      Inc(i);
    end;
  end;
end;

function TStringHelperEx.EscapeText: string;
begin
  Result := Self;

  // 1. Backslash must be escaped first!
  Result := StringReplace(Result, '\', '\\', [rfReplaceAll]);

  // 2. Double quotes will break the JSON string if not escaped
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);

  // 3. Line breaks (Enter) must be replaced with \n
  Result := StringReplace(Result, CRLF, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, LF, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, CR, '\r', [rfReplaceAll]);

  // 4. Tabs are also problematic
  Result := StringReplace(Result, #9, '\t', [rfReplaceAll]);
end;

function TStringHelperEx.EncodeURLElement: string;
const
  NotAllowed = [';', '/', '?', ':', '@', '=', '&', '#', '+', '_', '<', '>', '"', '%', '{', '}', '|', '\', '^', '~', '[', ']', '`'];
var
  i, o, l: integer;
  h: string[2];
  P: pchar;
  c: ansichar;
begin
  Result := string.Empty;
  l := Self.Length;
  if (l = 0) then Exit;
  SetLength(Result, l * 3);
  P := PChar(Result);
  for I := 1 to L do
  begin
    C := Self[i];
    O := Ord(c);
    if (O <= $20) or (O >= $7F) or (c in NotAllowed) then
    begin
      P^ := '%';
      Inc(P);
      h := IntToHex(Ord(c), 2);
      p^ := h[1];
      Inc(P);
      p^ := h[2];
      Inc(P);
    end
    else
    begin
      P^ := c;
      Inc(p);
    end;
  end;
  SetLength(Result, P - PChar(Result));
end;

function TStringHelperEx.HTTPDecode: string;
var
  S, SS, R: pchar;
  H: string[3];
  L, C: integer;
begin
  L := Self.Length;
  Result := string.Empty;
  SetLength(Result, L);
  if (L = 0) then
    exit;
  S := PChar(Self);
  SS := S;
  R := PChar(Result);
  while (S - SS) < L do
  begin
    case S^ of
      '+': R^ := SpaceChar;
      '%': begin
        Inc(S);
        if ((S - SS) < L) then
        begin
          if (S^ = '%') then
            R^ := '%'
          else
          begin
            H := '$00';
            H[2] := S^;
            Inc(S);
            if (S - SS) < L then
            begin
              H[3] := S^;
              Val(H, pbyte(R)^, C);
              if (C <> 0) then
                R^ := SpaceChar;
            end;
          end;
        end;
      end;
      else
        R^ := S^;
    end;
    Inc(R);
    Inc(S);
  end;
  SetLength(Result, R - PChar(Result));
end;

function TStringHelperEx.Utf8Truncate(MaxBytes: integer; Encode: boolean): string;
var
  p, startPtr: pchar;
  CharLen: integer;
  PredictedSize: integer;
  CurrentTotal: integer;
begin
  Result := string.Empty;
  if (Self = string.Empty) or (MaxBytes <= 0) then Exit;

  p := PChar(Self);
  startPtr := p;
  CurrentTotal := 0;

  while (p^ <> #0) do
  begin
    // 1. Determine UTF-8 character length (1-4 bytes)
    {$NOTES OFF}
    CharLen := UTF8CodepointSize(p);
    {$NOTES ON}

    // 2. Predict the size of the character after encoding/escaping
    if Encode then
    begin
      // URL Encoding logic:
      // Safe chars [A-Z, a-z, 0-9, -, _, ., ~] remain 1 byte.
      // All other bytes are converted to %XX format (3 bytes per 1 input byte).
      if (p^ in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~']) then
        PredictedSize := 1
      else
        PredictedSize := CharLen * 3;
    end
    else
    begin
      // Escaping logic:
      // Control chars \, ", LF, CR, Tab are replaced with 2-byte sequences (e.g. \n).
      // Other UTF-8 characters remain as-is (their original byte length).
      if (p^ in ['\', '"', LF, CR, TabChar]) then
        PredictedSize := 2
      else
        PredictedSize := CharLen;
    end;

    // 3. Check if the encoded character fits within the remaining byte budget
    if CurrentTotal + PredictedSize <= MaxBytes then
    begin
      Inc(CurrentTotal, PredictedSize);
      Inc(p, CharLen); // Move pointer to the start of the next UTF-8 character
    end
    else
      Break; // Limit exceeded, stop processing
  end;

  // 4. Perform a single memory allocation and copy the resulting substring
  if p > startPtr then
    SetString(Result, startPtr, p - startPtr)
  else
    Result := string.Empty;
end;

function TStringHelperEx.Utf8TruncateWithEncoding(MaxBytes: integer; Encode: boolean): string;
var
  p, startPtr: pchar;
  CharLen: integer;
  CurrentChar, EncodedChar: string;
  CurrentTotalBytes: integer;
begin
  Result := string.Empty;
  if (Self = string.Empty) or (MaxBytes <= 0) then Exit;

  p := PChar(Self);
  startPtr := p;
  CurrentTotalBytes := 0;

  while (p^ <> #0) do
  begin
    {$NOTES OFF}
    CharLen := UTF8CodepointSize(p);
    {$NOTES ON}
    SetString(CurrentChar, p, CharLen);

    if Encode then
      EncodedChar := CurrentChar.EncodeURLElement
    else
      EncodedChar := CurrentChar.EscapeText;

    if CurrentTotalBytes + EncodedChar.Length <= MaxBytes then
    begin
      Inc(CurrentTotalBytes, EncodedChar.Length);
      Inc(p, CharLen);
    end
    else
      Break;
  end;

  // Only allocate Result ONCE at the end
  if p > startPtr then
    SetString(Result, startPtr, p - startPtr);
end;

function TStringHelperEx.IsJson: boolean;
var
  Trimmed: string;
begin
  Trimmed := Self.TrimLeft;
  // Check first character – must be object or array
  if (Trimmed = '') or not ((Trimmed[1] = '{') or (Trimmed[1] = '[')) then
    Exit(False);

  // Trim trailing whitespace and verify matching closing bracket
  Trimmed := Trimmed.TrimRight;
  Result := ( (Trimmed[1] = '{') and (Trimmed[System.Length(Trimmed)] = '}') ) or
            ( (Trimmed[1] = '[') and (Trimmed[System.Length(Trimmed)] = ']') );
end;

function TStringHelperEx.RemoveEmptyParams: string;
var
  JsonData: TJSONData;
  JsonObj, ParamsObj, LangObjJson: TJSONObject;
  LangObj: TJSONData;
  I: integer;
  Params: TStringList;
begin
  Result := Self;

  // Check if input looks like JSON
  if (Self.Length > 0) and (Self[1] = '{') then
  begin
    try
      JsonData := GetJSON(Self);
      try
        if JsonData.JSONType = jtObject then
        begin
          JsonObj := TJSONObject(JsonData);

          if JsonObj.FindPath('params') <> nil then
          begin
            ParamsObj := TJSONObject(JsonObj.FindPath('params'));

            // Clean "lang" object
            LangObj := ParamsObj.FindPath('lang');
            if (LangObj <> nil) and (LangObj.JSONType = jtObject) then
            begin
              LangObjJson := TJSONObject(LangObj);
              for I := LangObjJson.Count - 1 downto 0 do
                if LangObjJson.Items[I].AsString = string.Empty then
                  LangObjJson.Delete(I);
            end;

            // Remove other empty string fields in params
            for I := ParamsObj.Count - 1 downto 0 do
              if (ParamsObj.Items[I].JSONType = jtString) and (ParamsObj.Items[I].AsString = string.Empty) then
                ParamsObj.Delete(I);
          end;

          Result := JsonObj.AsJSON;
          Exit;
        end;
      finally
        JsonData.Free;
      end;
    except
      on E: Exception do
        // Invalid JSON, fall through to URL processing
    end;
  end;

  // Treat as URL parameters
  Params := TStringList.Create;
  try
    Params.Delimiter := '&';
    Params.StrictDelimiter := True;
    Params.DelimitedText := Self;

    for I := Params.Count - 1 downto 0 do
      if Pos('=', Params[I]) > 0 then
        if System.Copy(Params[I], Pos('=', Params[I]) + 1, MaxInt) = string.Empty then
          Params.Delete(I);

    // Rebuild URL string with &
    Result := string.Empty;
    for I := 0 to Params.Count - 1 do
      if I = 0 then
        Result := Params[I]
      else
        Result := Result + '&' + Params[I];
  finally
    Params.Free;
  end;
end;

procedure TStringHelperEx.SaveStringToFile(const FileName: string);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Text := Self;
    SL.SaveToFile(FileName, TEncoding.UTF8);
  finally
    SL.Free;
  end;
end;

procedure TStringHelperEx.OpenStringInTextEditor;
var
  SL: TStringList;
  FileName: string;
begin
  FileName := GetTempFileName(GetTempDir, 'txt_') + '.txt';

  SL := TStringList.Create;
  try
    SL.Text := Self;
    SL.SaveToFile(FileName); // save string to temp file
  finally
    SL.Free;
  end;

  // open with associated editor
  OpenDocument(FileName);
end;

function TStringHelperEx.RemoveTrailingLineBreak: string;
begin
  Result := Self;
  if (Result.Length >= 2) and (System.Copy(Result, Result.Length - 1, 2) = sLineBreak) then
    Result := System.Copy(Result, 1, Result.Length - 2)
  else if (Result.Length >= 1) and ((Result[Result.Length] = LF) or (Result[Result.Length] = CR)) then
    Result := System.Copy(Result, 1, Result.Length - 1);
end;

function TStringHelperEx.ExtractTextSample(MaxLen: integer = 500): string;
var
  CutPos, i, L: integer;
begin
  Result := Self.Trim;
  L := Result.Length;

  // 1. If short enough
  if L <= MaxLen then
    Exit;

  // 2. Try cut by sentence end (. ! ?) + space
  CutPos := 0;
  for i := MaxLen downto 1 do
  begin
    if (Result[i] in ['.', '!', '?']) and (i < L) and (Result[i + 1] = SpaceChar) then
    begin
      CutPos := i;
      Break;
    end;
  end;

  // 3. Try cut by space
  if CutPos = 0 then
  begin
    for i := MaxLen downto 1 do
    begin
      if Result[i] = SpaceChar then
      begin
        CutPos := i;
        Break;
      end;
    end;
  end;

  // 4. Fallback
  if CutPos = 0 then
    CutPos := MaxLen;

  Result := System.Copy(Result, 1, CutPos).Trim;
end;

function TStringHelperEx.TryFormatJson(out AFormatted: string): boolean;
var
  JsonData: TJSONData;
begin
  Result := False;
  AFormatted := string.Empty;

  if not Self.IsJson then
    Exit;

  try
    // Try parse JSON
    JsonData := GetJSON(Self);
    try
      // Format with 2 spaces indent
      if Assigned(JsonData) then
        AFormatted := JsonData.FormatJSON([], 2);
      Result := True;
    finally
      JsonData.Free;
    end;
  except
    on E: Exception do
    begin
      // Not valid JSON
      Result := False;
    end;
  end;
end;

function TStringHelperEx.TryParseIPPort(out IP: string; out Port: word): boolean;
var
  Parts, IPParts: TStringList;
  i, Val: integer;
  ok: boolean;
  S: string;
begin
  S := Self.Trim;
  Result := False;
  Parts := TStringList.Create;
  try
    Parts.Delimiter := ':';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := S;
    if Parts.Count <> 2 then
      Exit;

    IP := Parts[0];

    // Validate the IP part (four numbers 0..255 separated by dots)
    IPParts := TStringList.Create;
    try
      IPParts.Delimiter := '.';
      IPParts.StrictDelimiter := True;
      IPParts.DelimitedText := IP;
      if IPParts.Count <> 4 then
        Exit;

      ok := True;
      for i := 0 to 3 do
      begin
        if not TryStrToInt(IPParts[i], Val) or (Val < 0) or (Val > 255) then
        begin
          ok := False;
          Break;
        end;
      end;
      if not ok then
        Exit;
    finally
      IPParts.Free;
    end;

    // Validate the port number (1..65535)
    if not TryStrToInt(Parts[1], Val) or (Val < 1) or (Val > 65535) then
      Exit;

    Port := Val;
    Result := True;
  finally
    Parts.Free;
  end;
end;

function TStringHelperEx.ToStringList(TrimAtEnd: boolean = False): TStringList;
begin
  Result := TStringList.Create;
  try
    Result.Text := Self;
    if (Self <> string.Empty) and (Self[System.Length(Self)] in [LF, CR]) and (not TrimAtEnd) then
      Result.Add(string.Empty);
  except
    Result.Free;
    raise;
  end;
end;

function TStringHelperEx.ToDateTimeISOTry(out ADateTime: TDateTime): boolean;
var
  FS: TFormatSettings;
  SFixed: string;
begin
  ADateTime := 0;
  SFixed := StringReplace(Self, 'T', SpaceChar, [rfReplaceAll]);
  SFixed := StringReplace(SFixed, 'Z', string.Empty, [rfReplaceAll]);
  SFixed := StringReplace(SFixed, '.', '-', [rfReplaceAll]);

  FS := DefaultFormatSettings;
  FS.DateSeparator := '-';
  FS.TimeSeparator := ':';
  FS.ShortDateFormat := 'yyyy-mm-dd';
  FS.ShortTimeFormat := 'hh:nn:ss';

  Result := TryStrToDateTime(SFixed, ADateTime, FS);
  if not Result then
  begin
    FS := DefaultFormatSettings;
    Result := TryStrToDateTime(Self, ADateTime, FS);
  end;
end;

function TStringHelperEx.ToFloatTry(out Value: double; MaxLength: integer = 15): boolean;
var
  FS: TFormatSettings;
begin
  if System.Length(Self) > MaxLength then
    Exit(False);
  Result := TryStrToFloat(Self, Value);
  if (not Result) then
  begin
    FS.DecimalSeparator := '.';
    Result := TryStrToFloat(Self, Value, FS);
    if (not Result) then
    begin
      FS.DecimalSeparator := ',';
      Result := TryStrToFloat(Self, Value, FS);
    end;
  end;
end;

function TStringHelperEx.SplitByFirstSpaces(Count: integer = 1): TStringArray;
var
  SpacePos, i: integer;
  Remaining: string;
begin
  Result := nil;
  if Count < 1 then Count := 1;

  SetLength(Result, 0);
  Remaining := Self;

  for i := 1 to Count do
  begin
    SpacePos := Pos(SpaceChar, Remaining);
    if SpacePos = 0 then
      Break;

    SetLength(Result, System.Length(Result) + 1);
    Result[High(Result)] := System.Copy(Remaining, 1, SpacePos - 1);
    Remaining := System.Copy(Remaining, SpacePos + 1, System.Length(Remaining));
  end;

  // Add whatever is left as the last part
  SetLength(Result, System.Length(Result) + 1);
  Result[High(Result)] := Remaining;
end;

function TStringHelperEx.StartsWithOperator(out Op, Rest: string): boolean;
const
  Ops: array[0..8] of string = ('>=', '<=', '<>', '!=', '=', '>', '<', '!', '#');
var
  i: integer;
begin
  for i := 0 to High(Ops) do
    if StartsText(Ops[i], Self) then
    begin
      Op := Ops[i];
      Rest := SysUtils.Trim(System.Copy(Self, System.Length(Ops[i]) + 1, MaxInt));
      Exit(True);
    end;
  Op := string.Empty;
  Rest := Self;
  Result := False;
end;

function TStringHelperEx.StartsWithBracketAZ: boolean;
var
  C: char;
begin
  Result := False;
  if System.Length(Self) < 4 then
    Exit;
  if Self[1] <> '(' then
    Exit;
  C := Self[2];
  if not (C in ['A'..'Z']) then
    Exit;
  if Self[3] <> ')' then
    Exit;
  if Self[4] <> SpaceChar then
    Exit;
  Result := True;
end;

function TStringHelperEx.StartsWithStrings(Strings: array of string): boolean;
var
  i: integer;
  LowerInput: string;
begin
  Result := False;
  LowerInput := SysUtils.Trim(System.LowerCase(Self));
  for i := 0 to High(Strings) do
  begin
    if LowerInput.StartsWith(LowerCase(Strings[i])) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TStringHelperEx.StartsWithChar(const Ch: char = SpaceChar): boolean;
begin
  Result := (Self <> string.Empty) and (Self[1] = Ch);
end;

function TStringHelperEx.EndsWithChar(const Ch: char = SpaceChar): boolean;
begin
  Result := (Self <> string.Empty) and (Self[System.Length(Self)] = Ch);
end;

function TStringHelperEx.IsOneOf(Strings: array of string): boolean;
var
  TrimmedInput: string;
  I: integer;
begin
  TrimmedInput := SysUtils.Trim(Self);
  Result := False;
  for I := Low(Strings) to High(Strings) do
    if Strings[I] = TrimmedInput then
    begin
      Result := True;
      Break;
    end;
end;

function TStringHelperEx.RemoveStrings(Strings: array of string): string;
var
  I: integer;
begin
  Result := Self;
  for I := Low(Strings) to High(Strings) do
  begin
    if Result.TrimLeft.StartsWith(Strings[I]) then
    begin
      Result := SysUtils.TrimLeft(Result);
      Delete(Result, 1, System.Length(Strings[I]));
      if (System.Length(Result) > 0) and (Result.StartsWith(SpaceChar)) then
        Delete(Result, 1, 1);
      Break;
    end;
  end;
end;

function TStringHelperEx.ReplaceTabCharWithSpace: string;
begin
  Result := Self.Replace(TabChar, SpaceChar);
end;

function TStringHelperEx.RemoveSpaceChar: string;
begin
  Result := Self.Replace(SpaceChar, string.empty).Trim;
end;

function TStringHelperEx.ReplaceLineBreaks(Value: string = BrTag): string;
var
  ResultStr: string;
begin
  ResultStr := StringReplace(Self, sLineBreak, Value, [rfReplaceAll]);
  ResultStr := StringReplace(ResultStr, CR, Value, [rfReplaceAll]);
  ResultStr := StringReplace(ResultStr, LF, Value, [rfReplaceAll]);
  Result := ResultStr;
end;

function TStringHelperEx.TrimLeadingSpaces(MaxSpaces: integer = 1): string;
var
  i, SpaceCount: integer;
begin
  SpaceCount := 0;
  for i := 1 to System.Length(Self) do
  begin
    if (Self[i] = SpaceChar) and (SpaceCount < MaxSpaces) then
      Inc(SpaceCount)
    else
      Break;
  end;
  Result := System.Copy(Self, SpaceCount + 1, System.Length(Self) - SpaceCount);
end;

function TStringHelperEx.TrimTrailingSpaces(MaxSpaces: integer = 1): string;
var
  i, SpaceCount, L: integer;
begin
  SpaceCount := 0;
  L := System.Length(Self);
  for i := L downto 1 do
  begin
    if (Self[i] = SpaceChar) and (SpaceCount < MaxSpaces) then
      Inc(SpaceCount)
    else
      Break;
  end;
  Result := System.Copy(Self, 1, L - SpaceCount);
end;

function TStringHelperEx.AsEncodedUrl: string;
begin
  Result := HTTPEncode(Self);
end;

function TStringHelperEx.IsUTF8Char(CharIndex: integer; FindChar: string = SpaceChar): boolean;
var
  ch: string;
begin
  Result := False;
  if (CharIndex < 1) or (CharIndex > UTF8Length(Self)) then Exit;
  ch := UTF8Copy(Self, CharIndex, 1);
  Result := (ch = FindChar);
end;

function TStringHelperEx.UTF8Lower: string;
begin
  Result := UTF8LowerCase(Self);
end;

function TStringHelperEx.RepeatString(Count: integer): string;
var
  i: integer;
begin
  Result := string.Empty;
  for i := 1 to Count do
    Result := Result + Self;
end;

function TStringHelperEx.ToASCIITextArt(const FontName: string = 'Monospace'; FontSize: integer = 12): string;
var
  bmp: TBitmap;
  x, y: integer;
  line, res: unicodestring;
  col: TColor;
  r, g, b: byte;
  luminance: integer;
  char: boolean;
begin
  if System.Length(Self) > 1024 then exit(Self);

  bmp := TBitmap.Create;
  try
    bmp.Canvas.Font.Name := FontName;
    bmp.Canvas.Font.Size := FontSize;
    bmp.Canvas.Font.Color := clBlack;
    bmp.SetSize(bmp.Canvas.TextWidth(Self), bmp.Canvas.TextHeight(Self));
    bmp.Canvas.Brush.Color := clWhite;
    bmp.Canvas.FillRect(0, 0, bmp.Width, bmp.Height);
    bmp.Canvas.TextRect(Rect(0, 0, bmp.Width, bmp.Height), 0, 0, Self);

    Res := string.Empty;
    for y := 0 to bmp.Height - 1 do
    begin
      line := string.Empty;
      char := False;
      for x := 0 to bmp.Width - 1 do
      begin
        col := bmp.Canvas.Pixels[x, y];
        r := Red(col);
        g := Green(col);
        b := Blue(col);
        luminance := (r + g + b) div 3;

        if luminance < 128 then
        begin
          line := line + #$2593;
          char := True;
        end
        else if luminance < 192 then
        begin
          line := line + #$2592;
          char := True;
        end
        else if luminance < 216 then
        begin
          line := line + #$2591;
          char := True;
        end
        else
        {$IFDEF UNIX}
          line := line + #$2591;
          {$ELSE}
          line := line + #$2003;
        {$ENDIF}
      end;
      if char then
        Res := Res + line + sLineBreak;
    end;
    Result := UTF8Encode(Res);
  finally
    bmp.Free;
  end;
end;

function TStringHelperEx.IsEmail: boolean;
var
  RE: TRegExpr;
  EmailToCheck: string;
begin
  if LowerCase(System.Copy(Self, 1, 7)) = 'mailto:' then
    EmailToCheck := System.Copy(Self, 8, MaxInt)
  else
    EmailToCheck := Self;
  RE := TRegExpr.Create;
  try
    RE.Expression := '^(?i)[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$';
    Result := RE.Exec(EmailToCheck);
  finally
    RE.Free;
  end;
end;

function TStringHelperEx.IsUrlSimilar: boolean;
var
  RE: TRegExpr;
begin
  RE := TRegExpr.Create;
  try
    RE.Expression :=
      '^(?i)' + '(' + '(https?|ftp)://[^\s/$.?#].[^\s]*' + '|' + '.*/.*' + ')$';
    Result := RE.Exec(Self);
  finally
    RE.Free;
  end;
end;

function TStringHelperEx.HasUrlScheme: boolean;
begin
  Result := (Pos('://', Self) > 0) or (Pos('mailto:', LowerCase(Self)) = 1) or (Pos('tel:', LowerCase(Self)) = 1) or
    (Pos('sms:', LowerCase(Self)) = 1);
end;

function TStringHelperEx.RemoveBacktickBlocks: string;
const
  MaxTagLength = 50;
var
  i, Start: integer;
  WordStr: string;
  NewS: string;
  HasRelevantChars: boolean;
begin
  Result := Self;
  HasRelevantChars := Pos('`', Self) > 0;
  if not HasRelevantChars then
    Exit;
  i := 1;
  NewS := string.Empty;
  while i <= System.Length(Self) do
  begin
    if Self[i] = '`' then
    begin
      Start := i;
      Inc(i);
      while (i <= System.Length(Self)) and (Self[i] <> '`') and (i - Start < MaxTagLength) do
      begin
        if Self[i] in [CR, LF] then
          Break;
        Inc(i);
      end;
      if (i <= System.Length(Self)) and (Self[i] = '`') then
      begin
        WordStr := System.Copy(Self, Start, i - Start + 1);
        if (System.Length(WordStr) > 2) and (System.Length(WordStr) <= MaxTagLength) and (Pos(CR, WordStr) = 0) and
          (Pos(LF, WordStr) = 0) then
        begin
          if (System.Length(NewS) > 0) and (NewS[System.Length(NewS)] = SpaceChar) then
            SetLength(NewS, System.Length(NewS) - 1);
          Inc(i);
          Continue;
        end;
      end
      else if i > System.Length(Self) then
      begin
        NewS := NewS + System.Copy(Self, Start, System.Length(Self) - Start + 1);
        Break;
      end;
    end;
    if i <= System.Length(Self) then
      NewS := NewS + Self[i];
    Inc(i);
  end;
  Result := NewS;
end;

function TStringHelperEx.SubStringBeforeColon: string;
var
  p: integer;
begin
  p := Pos(':', Self);
  if p > 0 then
    Result := System.Copy(Self, 1, p - 1)
  else
    Result := Self;
end;

procedure TStringHelperEx.SplitStringByComment(out StartPart, EndPart: string);
var
  PosCommentStart: integer;
begin
  StartPart := string.Empty;
  EndPart := string.Empty;
  PosCommentStart := Pos('//', Self);
  if PosCommentStart > 0 then
  begin
    StartPart := SysUtils.Trim(System.Copy(Self, 1, PosCommentStart - 1));
    EndPart := SysUtils.Trim(System.Copy(Self, PosCommentStart + 2, MaxInt));
  end
  else
    StartPart := SysUtils.Trim(Self);
end;

function TStringHelperEx.MaskTextWithBullets(ACanvas: TCanvas; const ALineEnding: string): string;
var
  Lines: TStringList;
  i, Count: integer;
  Bullet, Line: string;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    // Split text into separate lines
    Lines.Text := Self;
    Bullet := #$2022 + ' '; // Unicode bullet with space

    for i := 0 to Lines.Count - 1 do
    begin
      Line := Lines[i];
      if SysUtils.Trim(Line) <> string.Empty then
      begin
        // Calculate how many bullets fit in the width of this line
        Count := ACanvas.TextWidth(Line) div ACanvas.TextWidth(Bullet);
        if Count < 1 then Count := 1; // always at least one bullet
        Line := Bullet.RepeatString(Count);
      end;
      // Restore line breaks
      if Result = string.Empty then
        Result := Line
      else
        Result := Result + ALineEnding + Line;  // Use string directly
    end;
  finally
    Lines.Free;
  end;
end;

function TStringHelperEx.DeleteFirstChar(const Ch: char): string;
begin
  if (Self <> string.Empty) and (Self[1] = Ch) then
    Result := System.Copy(Self, 2, MaxInt)
  else
    Result := Self;
end;

function TStringHelperEx.RemoveFirstSubstring(const SubStr: string; Reverse: boolean = False): string;
var
  Position, I: integer;
begin
  Result := Self;
  if SubStr = string.Empty then
    Exit;
  if not Reverse then
  begin
    Position := Pos(SubStr, Self);
    if Position > 0 then
      Result := System.Copy(Self, 1, Position - 1) + System.Copy(Self, Position + System.Length(SubStr), MaxInt);
  end
  else
  begin
    Position := 0;
    for I := System.Length(Self) - System.Length(SubStr) + 1 downto 1 do
    begin
      if System.Copy(Self, I, System.Length(SubStr)) = SubStr then
      begin
        Position := I;
        Break;
      end;
    end;
    if Position > 0 then
      Result := System.Copy(Self, 1, Position - 1) + System.Copy(Self, Position + System.Length(SubStr), MaxInt);
  end;
end;

function TStringHelperEx.ApplyCombiningChar(const ACombiningChar: string = #$0335): string;
var
  I, Len: integer;
  Ch: string;
begin
  Result := string.Empty;
  Len := UTF8Length(Self);
  for I := 1 to Len do
  begin
    Ch := UTF8Copy(Self, I, 1);
    Result := Result + Ch;
    if (Ch <> LF) and (Ch <> CR) then
      Result := Result + ACombiningChar;
  end;
end;

procedure TStringHelperEx.AddIndent(IndentLevel: integer; Factor: integer = 2);
begin
  Self := StringOfChar(SpaceChar, IndentLevel * Factor) + Self;
end;

function TStringHelperEx.ExtractIndent(out AIndentLevel: integer): string;
var
  i: integer;
begin
  AIndentLevel := 0;
  i := 1;
  while (i + 1 <= System.Length(Self)) and (Self[i] = SpaceChar) and (Self[i + 1] = SpaceChar) do
  begin
    Inc(AIndentLevel);
    Inc(i, 2);
  end;
  Result := System.Copy(Self, i, System.Length(Self) - i + 1);
end;

{%EndRegion}

{%Region -fold CaptionHelper}

function TCaptionHelper.Replace(const Old, New: string): TCaption;
begin
  Result := TCaption(string(Self).Replace(Old, New));
end;

{%EndRegion}

end.

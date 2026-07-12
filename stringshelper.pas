//-----------------------------------------------------------------------------------
//  Helpers Package © 2026 by Alexander Tverskoy
//  Licensed under the MIT License
//  You may obtain a copy of the License at https://opensource.org/licenses/MIT
//-----------------------------------------------------------------------------------

unit stringshelper;

{$mode ObjFPC}{$H+}
{$codepage utf8}
{$modeswitch typehelpers}

interface

uses
  Classes,
  SysUtils,
  Math,
  LazUTF8;

type
  { TStringsHelper }

  TStringsHelper = class helper for TStrings
  public
    // Searches for the first string containing SubText
    function FindIndex(const AValue: string): integer;

    // Finds a name=value pair by its value part (case‑sensitive by default)
    function FindEqualIndex(const AValue: string; CaseSensitive: boolean = True): integer;

    // Removes all lines where '=' is followed by an empty value
    procedure RemoveEmptyValues;

    // Replaces AFrom with ATo in all strings; optionally replaces only the first occurrence
    procedure Replace(const AFrom, ATo: string; AReplaceAll: boolean = False);

    // Finds a name=value pair by its name (case‑insensitive)
    function IndexOfNameIgnoreCase(const AName: string): integer;

    // Searches for a string that matches AValue by exact name, exact value, or by parts after splitting
    function FindSubstringIndex(const AValue: string; const Seps: TSysCharSet = ['-', '_', ' ', ':', ',', ';']): integer;

    // Returns True if any string in the list contains SubText
    function Any(const SubText: string): boolean;

    // Returns True if the list contains value
    function Contains(const Value: string): boolean;

    /// Removes all lines that are a case-insensitive prefix of S, then adds S to the list.
    procedure AddReplaceStartsWith(const S: string);

    /// Returns a string where each line is wrapped in backticks, optionally preceded by a space.
    function ToBacktickString(LeadingSpace: boolean = True): string;

    /// For every line that contains a colon, adds the prefix (text before the colon) if not already present.
    procedure AddExtractedColonPrefixes;

    /// Compares Self with another TStrings; returns True if they contain identical lines in the same order.
    function Equal(Other: TStrings): boolean;

    /// Scans S for tags (backtick-enclosed or starting with @, #, %, +, $), adds them to the list and removes them from S.
    procedure FillTagsFromString(var S: string; Backtick: boolean = False);

    /// Removes all occurrences of AName from the list.
    procedure RemoveAll(const AName: string);
  end;

  { TStringArrayHelper }

  TStringArrayHelper = type helper for TStringArray
    function JoinArrayText(StartIndex: integer = 0; const Separator: string = ','; EndIndex: integer = -1): string;
  end;

implementation

{%Region -fold StringsHelper}

function TStringsHelper.FindIndex(const AValue: string): integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to Self.Count - 1 do
    if Pos(AValue, Self[i]) > 0 then
    begin
      Result := i;
      Exit;
    end;
end;

function TStringsHelper.FindEqualIndex(const AValue: string; CaseSensitive: boolean): integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to Self.Count - 1 do
    if (CaseSensitive and (Self.ValueFromIndex[i] = AValue)) or (not CaseSensitive and
      (UTF8CompareText(Self.ValueFromIndex[i], AValue) = 0)) then
    begin
      Result := i;
      Exit;
    end;
end;

procedure TStringsHelper.RemoveEmptyValues;
var
  i: integer;
  EqualPos: integer;
begin
  // Traverse the list backwards so that deletions don't affect subsequent indices
  for i := Self.Count - 1 downto 0 do
  begin
    // Locate the position of the '=' character in the current line
    EqualPos := Pos('=', Self[i]);

    // If '=' exists and there is no text after it, remove the line
    if (EqualPos > 0) and (Copy(Self[i], EqualPos + 1, MaxInt) = string.Empty) then
      Self.Delete(i);
  end;
end;

procedure TStringsHelper.Replace(const AFrom, ATo: string; AReplaceAll: boolean);
var
  i: integer;
  Flags: TReplaceFlags;
begin
  if (AFrom = string.Empty) or (Self.Count = 0) then Exit;

  if AReplaceAll then
    Flags := [rfReplaceAll]
  else
    Flags := []; // replace only first occurrence

  for i := 0 to Self.Count - 1 do
  begin
    // Check first to avoid unnecessary StringReplace
    if Pos(AFrom, Self[i]) > 0 then
    begin
      Self[i] := StringReplace(Self[i], AFrom, ATo, Flags);

      // If only one replacement needed — exit after first match
      if not AReplaceAll then
        Exit;
    end;
  end;
end;

function TStringsHelper.IndexOfNameIgnoreCase(const AName: string): integer;
var
  I: integer;
begin
  for I := 0 to Self.Count - 1 do
    if SameText(Self.Names[I], AName) then
      Exit(I);

  Result := -1;
end;

function TStringsHelper.FindSubstringIndex(const AValue: string; const Seps: TSysCharSet = ['-', '_', ' ', ':', ',', ';']): integer;
var
  Parts: TStringArray;
  Part: string;
  CharSet: set of char absolute Seps;
  SepStr: string;
begin
  Result := -1;
  if (Self.Count = 0) or (AValue = string.Empty) then
    Exit;

  // Search by Name (exact, case-sensitive)
  Result := Self.IndexOfName(AValue);
  if Result >= 0 then
    Exit;

  // Search by Value (using our helper method)
  Result := Self.FindEqualIndex(AValue);
  if Result >= 0 then
    Exit;

  SepStr := string.Empty;
  for Part in CharSet do
    SepStr := SepStr + Part;

  // Try to split by common delimiters and search each part
  Parts := AValue.Split(SepStr.ToCharArray);
  for Part in Parts do
  begin
    if Part = string.Empty then
      Continue;

    // Search split part by Name
    Result := Self.IndexOfName(Part);
    if Result >= 0 then
      Exit;

    // Search split part by Value
    Result := Self.FindEqualIndex(Part);
    if Result >= 0 then
      Exit;
  end;

  Result := -1;
end;

function TStringsHelper.Any(const SubText: string): boolean;
begin
  Result := FindIndex(SubText) >= 0;
end;

function TStringsHelper.Contains(const Value: string): boolean;
begin
  Result := Self.IndexOf(Value) >= 0;
end;

procedure TStringsHelper.AddReplaceStartsWith(const S: string);
var
  i: integer;
  LowerS, LowerItem: string;
begin
  LowerS := LowerCase(S);
  // Iterate backwards to safely remove items while looping
  for i := Self.Count - 1 downto 0 do
  begin
    LowerItem := LowerCase(Self[i]);
    // Check if string S starts with the list item (case insensitive)
    if (Length(LowerItem) <= Length(LowerS)) and (Copy(LowerS, 1, Length(LowerItem)) = LowerItem) then
      Self.Delete(i);
  end;

  // Add the string to the list
  Self.Add(S);
end;

function TStringsHelper.ToBacktickString(LeadingSpace: boolean = True): string;
var
  i: integer;
  SB: TStringBuilder;
begin
  if Self.Count = 0 then
  begin
    Result := string.Empty;
    Exit;
  end;

  SB := TStringBuilder.Create;
  try
    for i := 0 to Self.Count - 1 do
    begin
      if LeadingSpace then
        SB.Append(' ');
      SB.Append('`');
      SB.Append(Self[i]);
      SB.Append('`');
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TStringsHelper.AddExtractedColonPrefixes;
var
  i: integer;
  Tag, Prefix: string;
  PrefixesToAdd: TStringList;
begin
  // Create temporary list to store prefixes that need to be added
  PrefixesToAdd := TStringList.Create;
  try
    // First, collect all prefixes that need to be added
    for i := 0 to Self.Count - 1 do
    begin
      Tag := Self[i];
      // Check if tag contains colon (indicates it has a prefix)
      if Pos(':', Tag) > 0 then
      begin
        // Extract prefix (text before the colon)
        Prefix := Copy(Tag, 1, Pos(':', Tag) - 1);
        // Add prefix to temporary list if it doesn't exist in original list
        // and hasn't been already added to the temporary list
        if (Self.IndexOf(Prefix) = -1) and (PrefixesToAdd.IndexOf(Prefix) = -1) then
          PrefixesToAdd.Add(Prefix);
      end;
    end;

    // Add all collected prefixes to the original list at once
    Self.AddStrings(PrefixesToAdd);
  finally
    // Always free the temporary list to avoid memory leaks
    PrefixesToAdd.Free;
  end;
end;

function TStringsHelper.Equal(Other: TStrings): boolean;
var
  i: integer;
begin
  // Compare count first
  if Self.Count <> Other.Count then
    Exit(False);

  // Compare each line
  for i := 0 to Self.Count - 1 do
  begin
    // Compare text values
    if Self[i] <> Other[i] then
      Exit(False);
  end;

  Result := True;
end;

procedure TStringsHelper.FillTagsFromString(var S: string; Backtick: boolean = False);
var
  i, Start: integer;
  WordStr: string;
  HasAlphaNum: boolean;
  Num: double;
  NewS: string; // Used to build modified string when Backtick is True
  HasRelevantChars: boolean; // Optimization flag
const
  MaxTagLength = 500;
begin
  // Initial optimization check: skip processing if string doesn't contain relevant characters
  if Backtick then
    HasRelevantChars := Pos('`', S) > 0
  else
    HasRelevantChars := (Pos('@', S) > 0) or (Pos('#', S) > 0) or (Pos('%', S) > 0) or (Pos('+', S) > 0) or (Pos('$', S) > 0);

  if not HasRelevantChars then
    Exit;

  i := 1;
  NewS := string.Empty; // Initialize new string for Backtick mode

  while i <= Length(S) do
  begin
    // Check for backtick tag first
    if (S[i] = '`') and Backtick then
    begin
      Start := i;
      Inc(i);
      // Scan until closing backtick, line break, or max length
      while (i <= Length(S)) and (S[i] <> '`') and (i - Start < MaxTagLength) do
      begin
        if S[i] in [#13, #10] then
          Break;
        Inc(i);
      end;

      // Analyze scan result
      if (i <= Length(S)) and (S[i] = '`') then
      begin
        // Found a closing backtick
        WordStr := Copy(S, Start, i - Start + 1);
        // Check if it's a valid tag (length, no line breaks)
        if (Length(WordStr) > 2) and (Length(WordStr) <= MaxTagLength) and (Pos(#13, WordStr) = 0) and
          (Pos(#10, WordStr) = 0) then
        begin
          // Valid tag: add to list and remove from output
          Self.Add(StringReplace(WordStr, '`', string.Empty, [rfReplaceAll]));

          // Remove single preceding space from NewS if present
          if (Length(NewS) > 0) and (NewS[Length(NewS)] = ' ') then
            SetLength(NewS, Length(NewS) - 1);

          Inc(i); // Skip closing backtick
          Continue; // Skip adding this block to NewS
        end
        else
        begin
          // Invalid backtick block: add it to NewS as plain text
          NewS := NewS + Copy(S, Start, i - Start + 1);
          Inc(i); // Move past closing backtick
          Continue;
        end;
      end
      else if (i <= Length(S)) and (S[i] in [#13, #10]) then
      begin
        // Encountered a line break before closing backtick: add everything up to the line break
        NewS := NewS + Copy(S, Start, i - Start + 1);
        Inc(i); // Move past the line break
        Continue;
      end
      else
      begin
        // End of string reached without a closing backtick: add the rest from Start
        NewS := NewS + Copy(S, Start, Length(S) - Start + 1);
        i := Length(S) + 1; // Exit the loop
        Continue;
      end;
    end;

    // Process regular prefix tags with Unicode support
    // Rule: Tag starts with prefix and must be preceded by a space or start of string
    if (not Backtick) and (S[i] in ['@', '#', '%', '+', '$']) and ((i = 1) or (S[i - 1] = ' ')) then
    begin
      Start := i;
      Inc(i);
      HasAlphaNum := False;

      // Scan until an invalid character or max length is reached
      while (i <= Length(S)) and (i - Start < MaxTagLength) do
      begin
            { Unicode logic: If the character is within the ASCII range (0..127)
              and is NOT a letter, digit, hyphen, or underscore, it's a delimiter.
              Characters above #127 (Unicode/Cyrillic) are treated as part of the tag. }
        if (S[i] <= #127) and not (S[i] in ['a'..'z', 'A'..'Z', '0'..'9', '-', '_']) then
          Break;

        // Ensure the tag contains at least one alphanumeric character (not just -- or __)
        if not (S[i] in ['-', '_']) then
          HasAlphaNum := True;

        Inc(i);
      end;

      // STRICT VALIDATION OF TAG ENDING
      // Rule: Tag must end at string end, at a space, or at [,;] followed by a space.
      // If stopped by any other character (like @ or .), it's not a valid tag.
      if (i > Start + 1) and HasAlphaNum then
      begin
        if (i > Length(S)) or (S[i] = ' ') or ((S[i] in [',', ';', '.']) and (i < Length(S)) and (S[i + 1] = ' ')) then
        begin
          WordStr := Copy(S, Start, i - Start);
          // Final check to ensure it's not a plain number
          if not TryStrToFloat(WordStr, Num) then
            Self.Add(WordStr);
        end;
      end;
      // Note: We don't use 'Continue' here so the loop naturally moves to the next character
    end
    else
    begin
      // Add current character to NewS when in Backtick mode
      if Backtick then
        NewS := NewS + S[i];
      Inc(i);
    end;
  end;

  // Update original string with modified version when in Backtick mode
  if Backtick then
    S := NewS;
end;

procedure TStringsHelper.RemoveAll(const AName: string);
var
  Index: integer;
begin
  Index := Self.IndexOf(AName);
  while Index <> -1 do
  begin
    Self.Delete(Index);
    Index := Self.IndexOf(AName);
  end;
end;

{%EndRegion}

{%Region -fold StringArrayHelper}

function TStringArrayHelper.JoinArrayText(StartIndex: integer = 0; const Separator: string = ','; EndIndex: integer = -1): string;
var
  i: integer;
begin
  Result := string.Empty;
  if System.Length(Self) = 0 then Exit;

  if StartIndex < 0 then StartIndex := 0;
  if StartIndex > High(Self) then Exit;

  for i := StartIndex to ifthen(EndIndex < 0, High(Self), EndIndex) do
  begin
    Result += Self[i];
    if i < High(Self) then
      Result += Separator;
  end;
end;

{%EndRegion}

end.

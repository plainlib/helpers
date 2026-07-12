unit arrayhelpers;

{$mode objfpc}{$H+}
{$modeswitch typehelpers}

interface

uses
  Classes,
  Math,
  SysUtils;

type
  TIntegerArray = array of integer;

type
  TIntegerArrayHelper = type helper for TIntegerArray
  public
    /// Inserts a value at the specified position, shifting elements by an optional delta
    procedure InsertAtPos(Pos, Value: integer; Delta: integer = 0);

    /// Deletes the element at the given position from the array
    procedure DeleteAtPos(Pos: integer);

    /// Creates and returns an independent copy of the source array
    function CloneArray: TIntegerArray;

    /// Copies all elements from the source array into the destination array
    procedure CopyToArray(const Dest: TIntegerArray);
  end;

implementation

{TIntegerArrayHelper}

procedure TIntegerArrayHelper.InsertAtPos(Pos, Value: integer; Delta: integer = 0);
var
  i, Len: integer;
begin
  Len := Length(Self);
  if (Pos < 0) or (Pos > Len) then
    Exit; // Out of bounds

  // Increase array size
  SetLength(Self, Len + 1);

  // Shift elements to the right
  for i := Len - 1 downto Pos do
    Self[i + 1] := Self[i];

  // Insert new value
  Self[Pos] := Value;

  // Increase all following elements by Delta
  for i := Pos + 1 to High(Self) do
    Self[i] := Self[i] + Delta;
end;

procedure TIntegerArrayHelper.DeleteAtPos(Pos: integer);
var
  i, Len: integer;
begin
  Len := Length(Self);
  if (Pos < 0) or (Pos >= Len) then
    Exit; // Out of bounds

  // Shift left
  for i := Pos to Len - 2 do
    Self[i] := Self[i + 1];

  // Decrease array size
  SetLength(Self, Len - 1);
end;

function TIntegerArrayHelper.CloneArray: TIntegerArray;
begin
  Result := Copy(Self, 0, Length(Self));
end;

procedure TIntegerArrayHelper.CopyToArray(const Dest: TIntegerArray);
var
  CopyCount, i: integer;
begin
  // Determine how many elements to copy: take the smaller of Dest length and Src length
  CopyCount := Min(Length(Dest), Length(Self));
  for i := 0 to CopyCount - 1 do
    Dest[i] := Self[i];
end;

end.

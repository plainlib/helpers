unit ObjectDictionary;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  TObjectDictionary = class
  private
    FList: TStringList;
    function GetItem(const AKey: string): TObject;
    procedure SetItem(const AKey: string; AValue: TObject);
  public
    constructor Create;
    destructor Destroy; override;

    function ContainsKey(const AKey: string): Boolean;
    // Returns True and the stored object when the key exists, otherwise False and nil
    function TryGetValue(const AKey: string; out AValue: TObject): Boolean;
    function Count: Integer;
    // Returns the key at the given index, raises when index is out of range
    function GetKeyAt(AIndex: Integer): string;
    procedure Remove(const AKey: string);
    procedure Clear;

    property Items[const AKey: string]: TObject read GetItem write SetItem; default;
  end;

implementation

constructor TObjectDictionary.Create;
begin
  FList := TStringList.Create;
  FList.Sorted := True;
  FList.Duplicates := dupError;
  FList.OwnsObjects := True;
end;

destructor TObjectDictionary.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;

function TObjectDictionary.GetItem(const AKey: string): TObject;
var
  Index: Integer;
begin
  Index := FList.IndexOf(AKey);
  if Index < 0 then
    Exit(nil);

  Result := FList.Objects[Index];
end;

procedure TObjectDictionary.SetItem(const AKey: string; AValue: TObject);
var
  Index: Integer;
begin
  Index := FList.IndexOf(AKey);

  if Index >= 0 then
  begin
    if FList.Objects[Index] <> AValue then
    begin
      // Free the previously stored object to avoid a memory leak
      FList.Objects[Index].Free;
      FList.Objects[Index] := AValue;
    end;
  end
  else
    FList.AddObject(AKey, AValue);
end;

function TObjectDictionary.ContainsKey(const AKey: string): Boolean;
begin
  Result := FList.IndexOf(AKey) >= 0;
end;

function TObjectDictionary.TryGetValue(const AKey: string; out AValue: TObject): Boolean;
var
  Index: Integer;
begin
  Index := FList.IndexOf(AKey);
  if Index < 0 then
  begin
    AValue := nil;
    Exit(False);
  end;
  AValue := FList.Objects[Index];
  Result := True;
end;

function TObjectDictionary.Count: Integer;
begin
  Result := FList.Count;
end;

function TObjectDictionary.GetKeyAt(AIndex: Integer): string;
begin
  Result := FList[AIndex];
end;

procedure TObjectDictionary.Remove(const AKey: string);
var
  Index: Integer;
begin
  Index := FList.IndexOf(AKey);
  if Index >= 0 then
    FList.Delete(Index);
end;

procedure TObjectDictionary.Clear;
begin
  FList.Clear;
end;

end.

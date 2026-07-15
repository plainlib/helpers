//-----------------------------------------------------------------------------------
//  Helpers Package © 2026 by Alexander Tverskoy
//  Licensed under the MIT License
//  You may obtain a copy of the License at https://opensource.org/licenses/MIT
//-----------------------------------------------------------------------------------

unit pascalutils;

interface

{%Region -fold Inline if overload}

// Boolean version
function iif(ACondition: boolean; const ATrue, AFalse: boolean): boolean; inline; overload;

// Integer types
function iif(ACondition: boolean; const ATrue, AFalse: integer): integer; inline; overload;
function iif(ACondition: boolean; const ATrue, AFalse: int64): int64; inline; overload;
function iif(ACondition: boolean; const ATrue, AFalse: cardinal): cardinal; inline; overload;

// Floating point types
function iif(ACondition: boolean; const ATrue, AFalse: double): double; inline; overload;
function iif(ACondition: boolean; const ATrue, AFalse: single): single; inline; overload;

// String type (UnicodeString, covers both Wide and ANSI contexts)
function iif(ACondition: boolean; const ATrue, AFalse: string): string; inline; overload;

// Pointer
function iif(ACondition: boolean; const ATrue, AFalse: Pointer): Pointer; inline; overload;

{%EndRegion}

implementation

{%Region -fold Inline if overload}

function iif(ACondition: boolean; const ATrue, AFalse: boolean): boolean;
begin
  if ACondition then Result := ATrue
  else
    Result := AFalse;
end;

function iif(ACondition: boolean; const ATrue, AFalse: integer): integer;
begin
  if ACondition then Result := ATrue
  else
    Result := AFalse;
end;

function iif(ACondition: boolean; const ATrue, AFalse: int64): int64;
begin
  if ACondition then Result := ATrue
  else
    Result := AFalse;
end;

function iif(ACondition: boolean; const ATrue, AFalse: cardinal): cardinal;
begin
  if ACondition then Result := ATrue
  else
    Result := AFalse;
end;

function iif(ACondition: boolean; const ATrue, AFalse: double): double;
begin
  if ACondition then Result := ATrue
  else
    Result := AFalse;
end;

function iif(ACondition: boolean; const ATrue, AFalse: single): single;
begin
  if ACondition then Result := ATrue
  else
    Result := AFalse;
end;

function iif(ACondition: boolean; const ATrue, AFalse: string): string;
begin
  if ACondition then Result := ATrue
  else
    Result := AFalse;
end;

function iif(ACondition: boolean; const ATrue, AFalse: Pointer): Pointer;
begin
  if ACondition then
    Result := ATrue
  else
    Result := AFalse;
end;

{%EndRegion}

end.

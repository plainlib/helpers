//-----------------------------------------------------------------------------------
//  Helpers Package © 2026 by Alexander Tverskoy
//  Licensed under the MIT License
//  You may obtain a copy of the License at https://opensource.org/licenses/MIT
//-----------------------------------------------------------------------------------

unit colorhelper;

{$mode objfpc}{$H+}
{$modeswitch typehelpers}

interface

uses
  Types,
  SysUtils,
  Graphics,
  Math,
  LCLIntf;

type
  TColorHelper = type helper for TColor
  public
    // Blend two colors with given intensity (0-100)
    function BlendColor(AColor: TColor; Intensity: integer): TColor;

    // Invert font color against background, with mid-level threshold
    function InvertColor(ABackColor: TColor; MidLevel: integer = 128; AOnlyDarkBackground: boolean = False): TColor;

    // Simple inversion: flip each RGB channel
    function InvertColor: TColor;

    // Convert to web-compatible hex string (#RRGGBB)
    function ToHtml: string;

    // Lighten a dark color for dark themes (blend toward white)
    function ToDarkTheme(Delta: integer = 60): TColor;

    // Lighten or darken a color by an amount, positive lightens, negative darkens
    function AdjustBrightness(Amount: integer): TColor;
  end;

  TCanvasHelper = type helper for TCanvas
  public
    // Draw a filled circle with a subtle vertical gradient for a 3D effect
    procedure CircleFilled(const ARect: Types.TRect; AColor: TColor);

    // Draw a 1-pixel circle outline by detecting boundary pixels with 8-connectivity
    procedure CircleOutline(const ARect: TRect; AColor: TColor);
  end;

implementation

{%Region -fold TColor Helper}

function TColorHelper.BlendColor(AColor: TColor; Intensity: integer): TColor;
var
  R1, G1, B1: byte;
  R2, G2, B2: byte;
  Alpha: double;
begin
  // Return original color if no blending needed
  if Intensity <= 0 then
    Exit(Self);

  // Return full blend color if maximum intensity
  if Intensity >= 100 then
    Exit(AColor);

  // Calculate blend factor (0.0 to 1.0)
  Alpha := Intensity / 100.0;

  // Extract RGB components from first color
  Self := ColorToRGB(Self);
  R1 := GetRValue(Self);
  G1 := GetGValue(Self);
  B1 := GetBValue(Self);

  // Extract RGB components from second color
  AColor := ColorToRGB(AColor);
  R2 := GetRValue(AColor);
  G2 := GetGValue(AColor);
  B2 := GetBValue(AColor);

  // Linear interpolation: result = Self * (1-alpha) + AColor * alpha
  Result := RGBToColor(Round(R1 * (1 - Alpha) + R2 * Alpha), Round(G1 * (1 - Alpha) + G2 * Alpha),
    Round(B1 * (1 - Alpha) + B2 * Alpha));
end;

function TColorHelper.InvertColor(ABackColor: TColor; MidLevel: integer = 128; AOnlyDarkBackground: boolean = False): TColor;
var
  Rb, Gb, Bb: byte;
  Rf, Gf, Bf: byte;
  BrightnessBack, BrightnessFont: double;
begin
  // Clamp MidLevel to valid byte range
  if MidLevel < 0 then MidLevel := 0;
  if MidLevel > 255 then MidLevel := 255;

  // Resolve system colors to actual RGB
  ABackColor := ColorToRGB(ABackColor);
  Self := ColorToRGB(Self);

  Rb := GetRValue(ABackColor);
  Gb := GetGValue(ABackColor);
  Bb := GetBValue(ABackColor);

  Rf := GetRValue(Self);
  Gf := GetGValue(Self);
  Bf := GetBValue(Self);

  // Perceived luminance using ITU-R BT.709 coefficients
  BrightnessBack := 0.299 * Rb + 0.587 * Gb + 0.114 * Bb;
  BrightnessFont := 0.299 * Rf + 0.587 * Gf + 0.114 * Bf;

  // Check if both colors are on the same side of the brightness threshold
  if (BrightnessBack < MidLevel) = (BrightnessFont < MidLevel) then
  begin
    if AOnlyDarkBackground then
    begin
      // Invert only if the background is dark (and thus the font is dark too)
      if BrightnessBack < MidLevel then
        Result := RGBToColor(255 - Rf, 255 - Gf, 255 - Bf)
      else
        Result := Self; // On a light background, leave the font unchanged
    end
    else
      // Default behavior: always invert when both are on the same side
      Result := RGBToColor(255 - Rf, 255 - Gf, 255 - Bf);
  end
  else
    Result := Self; // Already contrasting, keep the original font color
end;

function TColorHelper.InvertColor: TColor;
var
  C: TColor;
begin
  C := ColorToRGB(Self);
  Result := RGB(255 - GetRValue(C), 255 - GetGValue(C), 255 - GetBValue(C));
end;

function TColorHelper.ToHtml: string;
var
  C: TColor;
begin
  C := ColorToRGB(Self);
  Result := Format('#%.2x%.2x%.2x', [GetRValue(C), GetGValue(C), GetBValue(C)]);
end;

function TColorHelper.ToDarkTheme(Delta: integer = 60): TColor;
var
  R, G, B: byte;
  Bright: double;
  Factor: double;
begin
  Self := ColorToRGB(Self);
  R := GetRValue(Self);
  G := GetGValue(Self);
  B := GetBValue(Self);

  // Perceptual brightness (Luma) calculation
  Bright := (0.299 * R + 0.587 * G + 0.114 * B);

  // If already bright enough, return unchanged
  if Bright > 150 then
  begin
    Result := Self;
    Exit;
  end;

  // Delta is 1..100 mapped to 0.0..1.0 factor
  Factor := Delta / 100.0;
  if Factor < 0 then Factor := 0;
  if Factor > 1 then Factor := 1;

  // Linear interpolation towards white
  R := R + Round((255 - R) * Factor);
  G := G + Round((255 - G) * Factor);
  B := B + Round((255 - B) * Factor);

  Result := RGB(R, G, B);
end;

function TColorHelper.AdjustBrightness(Amount: integer): TColor;
var
  R, G, B: integer;
begin
  R := Red(Self) + Amount;
  G := Green(Self) + Amount;
  B := Blue(Self) + Amount;
  if R < 0 then R := 0
  else if R > 255 then R := 255;
  if G < 0 then G := 0
  else if G > 255 then G := 255;
  if B < 0 then B := 0
  else if B > 255 then B := 255;
  Result := RGBToColor(R, G, B);
end;

{%EndRegion}

{%Region -fold TCanvas Helper}

procedure TCanvasHelper.CircleFilled(const ARect: TRect; AColor: TColor);
var
  Cx, Cy, R: double;
  Y: integer;
  Dy, Dx: double;
  XStart, XEnd: integer;
  LineColor: TColor;
  Factor: double;
begin
  // Center is placed between pixels for even dimensions to avoid offset
  Cx := (ARect.Left + ARect.Right - 1) / 2;
  Cy := (ARect.Top + ARect.Bottom - 1) / 2;
  R := (ARect.Right - ARect.Left) / 2;
  Self.Brush.Color := AColor;
  Self.Pen.Style := psClear;
  for Y := ARect.Top to ARect.Bottom - 1 do
  begin
    Dy := Abs(Y - Cy);
    if Dy > R then Continue;
    Dx := Sqrt(R * R - Dy * Dy);
    XStart := Max(ARect.Left, Round(Cx - Dx + 0.5));
    XEnd := Min(ARect.Right - 1, Round(Cx + Dx - 0.5));
    if XStart <= XEnd then
    begin
      // Calculate gradient factor from 1 at top to 0 at bottom
      Factor := 1 - (Y - ARect.Top) / Max(1, ARect.Bottom - ARect.Top - 1);
      // Slight lightening at top and darkening at bottom
      LineColor := AColor.AdjustBrightness(Round((Factor - 0.5) * 100));
      Self.Brush.Color := LineColor;
      Self.FillRect(XStart, Y, XEnd + 1, Y + 1);
    end;
  end;
end;

procedure TCanvasHelper.CircleOutline(const ARect: TRect; AColor: TColor);
var
  Inside: array of array of boolean = nil;
  Cx, Cy, R: double;
  W, H, X, Y: integer;
  AbsX, AbsY: integer;
  HasOutsideNeighbor: boolean;
  DX, DY: integer;
begin
  W := ARect.Right - ARect.Left;
  H := ARect.Bottom - ARect.Top;
  SetLength(Inside, W, H);

  Cx := (ARect.Left + ARect.Right - 1) / 2;
  Cy := (ARect.Top + ARect.Bottom - 1) / 2;
  R := (ARect.Right - ARect.Left) / 2;

  // Build the inside mask using the same formula as CircleFilled
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      AbsX := ARect.Left + X;
      AbsY := ARect.Top + Y;
      Inside[X, Y] := ((AbsX - Cx) * (AbsX - Cx) + (AbsY - Cy) * (AbsY - Cy)) <= R * R;
    end;

  // Draw only boundary pixels: inside but at least one of 8 neighbors is outside
  Self.Pen.Style := psClear;
  Self.Brush.Style := bsSolid;
  Self.Brush.Color := AColor;

  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      if not Inside[X, Y] then Continue;

      HasOutsideNeighbor := False;
      for DY := -1 to 1 do
        for DX := -1 to 1 do
        begin
          if (DX = 0) and (DY = 0) then Continue;
          if (X + DX >= 0) and (X + DX < W) and (Y + DY >= 0) and (Y + DY < H) then
          begin
            if not Inside[X + DX, Y + DY] then
            begin
              HasOutsideNeighbor := True;
              Break;
            end;
          end
          else
          begin
            // Neighbor outside the bitmap is considered outside
            HasOutsideNeighbor := True;
            Break;
          end;
        end;

      if HasOutsideNeighbor then
        Self.FillRect(ARect.Left + X, ARect.Top + Y, ARect.Left + X + 1, ARect.Top + Y + 1);
    end;
end;

{%EndRegion}

end.

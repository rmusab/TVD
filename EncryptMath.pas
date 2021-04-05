/************************************************
* TVD Encryption: Mathematics module            *
* By Ravil Mussabayev                           *
* ravmus@gmail.com                              *
************************************************/
unit EncryptMath;

interface

uses Math;

procedure Switch(var x, y: Int64);
function GCD(a, b: Int64): Int64;
function Prime(n: Int64): Boolean;
function EuclidCoprime(a, b: Int64): Boolean;
function GeneralizedEuclid(a, b, d: Int64; var u, v: Int64): Boolean;

implementation

procedure Switch(var x, y: Int64);
var z: Int64;
begin
  z := x;
  x := y;
  y := z;
end;

function GCD(a, b: Int64): Int64;
begin
  if (b mod a) = 0 then Result := a
  else Result := GCD(b, a mod b);
end;

function Prime(n: Int64): Boolean;
var i: Int64;
begin
  Result := true;
  if (n = 1) or (n = 2) then Exit;
  for i := 2 to n div 2 do
    if n mod i = 0 then begin
      Result := false;
      Exit;
    end;
end;

function EuclidCoprime(a, b: Int64): Boolean;
//var r0, r1, p: Int64;
begin
  {r0 := a mod b;
  p := b;
  if not (r0 = 0) then begin
    repeat
      r1 := p mod r0;
      p := r0;
      r0 := r1;
    until r1 = 0;
  end;
  if p = 1 then Result := True
    else Result := False;}
  if GCD(a, b) = 1 then Result := True
    else Result := False;
end;

function GeneralizedEuclid(a, b, d: Int64; var u, v: Int64): Boolean;
var q1, q2, q: Int64;
    r, r1, r2: array [0..1] of Int64;
    swap: Boolean;
begin
  swap := False;
  if a < b then begin
    Switch(a, b);
    swap := True;
  end;

  q1 := a div b;
  r2[0] := 1; r2[1] := -q1;
  if (r2[0]*a + r2[1]*b) = 0 then begin
    u := 0; v := 1;
    if swap then Switch(u, v);
    Result := True;
    Exit;
  end else
  if (r2[0]*a + r2[1]*b) = d then begin
    u := r2[0]; v := r2[1];
    if swap then Switch(u, v);
    Result := True;
    Exit;
  end;

  q2 := b div (a mod b);
  r1[0] := -q2; r1[1] := 1 + q1 * q2;
  if (r1[0]*a + r1[1]*b) = d then begin
    u := r1[0]; v := r1[1];
    if swap then Switch(u, v);
    Result := True;
    Exit;
  end;

  repeat
    q := (r2[0]*a + r2[1]*b) div (r1[0]*a + r1[1]*b);
    r[0] := r2[0] - r1[0] * q;
    r[1] := r2[1] - r1[1] * q;
    r2 := r1;
    r1 := r;
    if (r[0]*a + r[1]*b) = 0 then begin
      u := 0; v := 0;
      Result := False;
      Exit;
    end;
  until (r[0]*a + r[1]*b) = d;
  u := r[0]; v := r[1];

  if swap then Switch(u, v);
  Result := True;
end;

end.

/************************************************
* TVD Encryption: TEncrypt class module         *
* By Ravil Mussabayev                           *
* ravmus@gmail.com                              *
************************************************/
unit EncryptLib;

interface

uses Math, EncryptMath, Classes, SysUtils, Vcl.ComCtrls,
Vcl.Dialogs;

const //DEFAULT_ALPHABET = 'abcdefghijklmnopqrstuvwxyz1234567890 ';
      MAX_P = 65537; // 65535 + 2
      MAX_LIST_N = 100;
      MAX_RANDOM_FACTOR = 1000000;
      M = 100;
      OFFSET = 2;

type
  PInt64Array = ^TInt64Array;
  TInt64Array = array of Int64;

  PProgressBar = ^TProgressBar;
  PTextFile = ^TextFile;

  TEncrypt = class(TObject)
    private
      //alphabet: array of WideChar;
      //p: array of Integer;
      k: Int64;
      d: TInt64Array;
      s: TInt64Array;
    public
      list_s: TStringList;
      imported: Boolean;
      constructor Create;
      destructor Destroy; override;
      function Initialize(k: Int64): Boolean; overload;
      function Initialize(k: Int64; pd: PInt64Array): Boolean; overload;
      //function GetMaxP: Integer;
      function GetSecretKeyList(Max_N: Integer): TStringList;
      //function Encode(text: WideString): TInt64Array;
      //function Decode(c: PInt64Array): TInt64Array;
      function Encode(InputStream: TMemoryStream; Bar: PProgressBar; f: PTextFile;
                Text: Boolean; var ZeroByte: Boolean): TMemoryStream;
      function Decode(InputStream: TMemoryStream; Bar: PProgressBar; ZeroByte: Boolean): TMemoryStream;
      function AddZeroByte(stream: TMemoryStream): Boolean;
      procedure DeleteZeroByte(stream: TMemoryStream);

  end;

implementation

constructor TEncrypt.Create;
//var i: Integer;
begin
  inherited;

  Self.imported := False;
  {SetLength(alphabet, Length(DEFAULT_ALPHABET));
  SetLength(p, Length(DEFAULT_ALPHABET));
  for i := 1 to Length(DEFAULT_ALPHABET) do begin
      alphabet[i-1] := WideChar(DEFAULT_ALPHABET[i]);
      p[i-1] := ord(DEFAULT_ALPHABET[i]);
    end;}
end;

destructor TEncrypt.Destroy;
begin

end;

function TEncrypt.Initialize(k: Int64): Boolean;
begin
  if k > MAX_P then begin
    Self.k := k;
    Result := True;
  end
  else Result := False;
end;

function TEncrypt.Initialize(k: Int64; pd: PInt64Array): Boolean;
var i: Integer;
begin
  if Initialize(k) then begin
    Self.d := pd^;

    list_s := GetSecretKeyList(M);
    SetLength(s, list_s.Count);
    for i := 0 to list_s.Count - 1 do
      s[i] := StrToInt64(list_s.Strings[i]);
    Self.imported := True;
    Result := True;
  end
  else Result := False;
end;

{function TEncrypt.GetMaxP: Integer;
begin
  Result := MaxIntValue(p);
end;}

function TEncrypt.GetSecretKeyList(Max_N: Integer): TStringList;
var i: Int64;
    n: Integer;
    sign: Byte;
    list: TStringList;
begin
  list := TStringList.Create;

  if MAX_P mod 2 = 0 then
    i := MAX_P + 3
  else i := MAX_P + 4;
  n := 0;
  Randomize;
  repeat
    sign := Random(2);
    if sign = 0 then i := i - 2 * Random((i - MAX_P) div 2)
      else i := i + 2 * Random(MAX_RANDOM_FACTOR);
    if not EuclidCoprime(i, k) then
      Continue
    else begin
      if Prime(i) then begin
        list.Add(IntToStr(i));
        Inc(n);
      end;
    end;
  until n = Max_N;

  Result := list;
end;

{function TEncrypt.Encode(text: WideString): TInt64Array;
var i, s1, d1, s2, u, v, p1, a_p: Int64;
begin
  SetLength(Result, Length(text));
  i := 0;
  repeat
    Inc(i);
    s1 := (i - 1) mod Length(s);
    d1 := (i - 1) mod Length(d);
    s2 := s[s1] * d[d1];
    p1 := Ord(text[i]);
    GeneralizedEuclid(s2, k, 1, u, v);
    if Abs(u) > k then u := u mod k;
    if u < 0 then u := u + k;
    a_p := (p1 * u) mod k;
    Result[i - 1] := a_p * s[s1];
  until i = Length(text);
end;

function TEncrypt.Decode(c: PInt64Array): TInt64Array;
var i, d1: Integer;
begin
  SetLength(Result, Length(c^));
  for i := 0 to High(c^) do begin
    d1 := i mod Length(d);
    Result[i] := (c^[i] * d[d1]) mod k;
  end;
end;}

function TEncrypt.Encode(InputStream: TMemoryStream; Bar: PProgressBar; f: PTextFile;
          Text: Boolean; var ZeroByte: Boolean): TMemoryStream;
var i, s1, d1, s2, u, v, a_p, c: Int64;
    p: Word;
begin
  ZeroByte := AddZeroByte(InputStream);
  Result := TMemoryStream.Create;
  InputStream.Position := 0;
  i := 0;
  repeat
    Inc(i);
    s1 := (i - 1) mod Length(s);
    d1 := (i - 1) mod Length(d);
    s2 := s[s1] * d[d1];
    InputStream.Read(p, SizeOf(Word));
    GeneralizedEuclid(s2, k, 1, u, v);
    if Abs(u) > k then u := u mod k;
    if u < 0 then u := u + k;
    a_p := ((p + OFFSET) * u) mod k;
    c := a_p * s[s1];
    Result.Write(c, SizeOf(Int64));
    if Text then
      WriteLn(f^, IntToStr(c));
    Bar^.position := round((i / (InputStream.Size div SizeOf(Word))) * 100);
  until i = InputStream.Size div SizeOf(Word);
end;

function TEncrypt.Decode(InputStream: TMemoryStream; Bar: PProgressBar; ZeroByte: Boolean): TMemoryStream;
var i, d1: Integer;
    c: Int64;
    p: Word;
begin
  Result := TMemoryStream.Create;
  InputStream.Position := 0;
  for i := 0 to InputStream.Size div SizeOf(Int64) - 1 do begin
    d1 := i mod Length(d);
    InputStream.Read(c, SizeOf(Int64));
    p := (c * d[d1]) mod k - OFFSET;
    Result.Write(p, SizeOf(Word));
    Bar^.position := round(((i + 1) / (InputStream.Size div SizeOf(Int64))) * 100);
  end;
  if ZeroByte then DeleteZeroByte(Result);
end;

function TEncrypt.AddZeroByte(stream: TMemoryStream): Boolean;
var b: Byte;
begin
  if stream.Size mod 2 = 1 then begin
    stream.Position := stream.Size;
    b := 0;
    stream.Write(b, 1);
    Result := True;
  end else Result := False;
end;

procedure TEncrypt.DeleteZeroByte(stream: TMemoryStream);
var b: Byte;
begin
  stream.Position := stream.Size - 1;
  stream.Read(b, 1);
  if b = 0 then stream.Size := stream.Size - 1;
end;

end.

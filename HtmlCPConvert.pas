unit HtmlCPConvert;

interface

{$IFDEF UNICODE}

{$DEFINE SUPPORTS_IMPLICIT_WARNINGS}

{$ELSE}

type
  UnicodeString = WideString;
  RawByteString = AnsiString;

{$UNDEF SUPPORTS_IMPLICIT_WARNINGS}

{$ENDIF}

function CharsetNameToCharset(const ACharsetName: String): Cardinal;
function RawHTMLToHTML(const ARawHTML: RawByteString): UnicodeString;
function HTMLToRawHTML(const AHTML: UnicodeString): RawByteString;

implementation

uses
  Windows, SysUtils, {$IFDEF UNICODE}AnsiStrings, {$ENDIF} MLang, ActiveX, ComObj;

const
  CharSetID               = 'charset=';          // Do Not Localize
  CharsetNameUTF8         = 'utf-8';             // Do Not Localize
  ReplaceChar             = '?';                 // Do Not Localize

function Min(const I1, I2: Integer): Integer;
begin
  if I1 < I2 then
    Result := I1
  else
    Result := I2;
end;

//______________________________________________________________________________

function CharsetNameToCharset(const ACharsetName: String): Cardinal;

  function InternalCharsetNameToCharset(const ACharsetName: String): Cardinal;
  var
    ML: IMultiLanguage;
    ECP: IEnumCodePage;
    CPI: tagMIMECPINFO;
    Fetched: Cardinal;
    Name, S: String;
  begin
    OleCheck(CoCreateInstance(CLSID_CMultiLanguage, nil, CLSCTX_ALL, IID_IMultiLanguage, ML));
    OleCheck(ML.EnumCodePages(MIMECONTF_BROWSER, ECP));

    Name := LowerCase(ACharsetName);

    FillChar(CPI, SizeOf(CPI), 0);
    Fetched := 0;
    while Succeeded(ECP.Next(1, CPI, Fetched)) do
    begin
      if Fetched <= 0 then
        Break;

      S := LowerCase(CPI.wszWebCharset);
      if S = Name then
      begin
        Result := CPI.uiCodePage;
        Exit;
      end;

      S := LowerCase(CPI.wszBodyCharset);
      if S = Name then
      begin
        Result := CPI.uiCodePage;
        Exit;
      end;

      S := LowerCase(CPI.wszHeaderCharset);
      if S = Name then
      begin
        Result := CPI.uiCodePage;
        Exit;
      end;

      FillChar(CPI, SizeOf(CPI), 0);
      Fetched := 0;
    end;

    Result := 0;
  end;

var
  hr: HRESULT;
begin
  hr := CoInitializeEx(nil, 0);
  if hr = RPC_E_CHANGED_MODE then
    Result := InternalCharsetNameToCharset(ACharsetName)
  else
  begin
    OleCheck(hr);
    try
      Result := InternalCharsetNameToCharset(ACharsetName);
    finally
      CoUninitialize;
    end;
  end;
end;

//______________________________________________________________________________

function RawHTMLToHTML(const ARawHTML: RawByteString): UnicodeString;

  function ConvertText(const Text: RawByteString; Charset: Cardinal): UnicodeString;
  var
    CharsetInfo: TCharsetInfo;
    L: Integer;
  begin
    FillChar(CharsetInfo, SizeOf(CharsetInfo), 0);
    if not TranslateCharsetInfo(Charset, CharsetInfo, TCI_SRCCHARSET) then
    begin
      Result := ''; // Do Not Localize
      Exit;
    end;
    L := MultiByteToWideChar(CharsetInfo.ciACP, MB_PRECOMPOSED, PAnsiChar(Text), Length(Text), nil, 0);
    SetLength(Result, L);
    MultiByteToWideChar(CharsetInfo.ciACP, MB_PRECOMPOSED, PAnsiChar(Text), Length(Text), PWideChar(Result), L);
  end;

var
  Tests: Cardinal;
  Enc: RawByteString;
  X: Integer;
  Charset: Cardinal;
begin
  if ARawHTML = '' then // Do Not Localize
  begin
    Result := ''; // Do Not Localize
    Exit;
  end;

  X := Pos(RawByteString(CharSetID), LowerCase(AnsiString(ARawHTML)));
  if X > 0 then
  begin
    Enc := Copy(ARawHTML, X + Length(CharSetID), 255);

    X := Pos(RawByteString('"'), Enc); // Do Not Localize
    if X = 0 then
      X := Pos(RawByteString('>'), Enc) // Do Not Localize
    else
      if Pos(RawByteString('>'), Enc) > 0 then // Do Not Localize
        X := Min(X, Pos(RawByteString('>'), Enc)); // Do Not Localize

    if X <= 0 then
      X := Length(Enc) + 1;
    Enc := Trim(Copy(Enc, 1, X - 1));

    if LowerCase(Enc) = CharsetNameUTF8 then
      Result := UTF8ToUnicodeString(ARawHTML)
    else
    begin
      {$IFDEF SUPPORTS_IMPLICIT_WARNINGS}
      {$WARN IMPLICIT_STRING_CAST OFF} // as designed
      {$ENDIF}
      Charset := CharsetNameToCharset(Enc);
      {$IFDEF SUPPORTS_IMPLICIT_WARNINGS}
      {$WARN IMPLICIT_STRING_CAST ON}
      {$ENDIF}
      if Charset <> 0 then
        Result := ConvertText(ARawHTML, CharSet);

      if Result = '' then // Do Not Localize
        // Unknown charset, suppose default ANSI
        {$IFDEF SUPPORTS_IMPLICIT_WARNINGS}
        {$WARN IMPLICIT_STRING_CAST OFF} // as designed
        {$ENDIF}
        Result := ARawHTML;
        {$IFDEF SUPPORTS_IMPLICIT_WARNINGS}
        {$WARN IMPLICIT_STRING_CAST ON}
        {$ENDIF}
    end;

    Exit;
  end;

  Tests := IS_TEXT_UNICODE_ASCII16 or
           IS_TEXT_UNICODE_REVERSE_ASCII16 or
           IS_TEXT_UNICODE_STATISTICS or
           IS_TEXT_UNICODE_REVERSE_STATISTICS or
           IS_TEXT_UNICODE_CONTROLS or
           IS_TEXT_UNICODE_REVERSE_CONTROLS or
           IS_TEXT_UNICODE_SIGNATURE or
           IS_TEXT_UNICODE_REVERSE_SIGNATURE or
           IS_TEXT_UNICODE_ILLEGAL_CHARS or
           IS_TEXT_UNICODE_ODD_LENGTH or
           IS_TEXT_UNICODE_NULL_BYTES;

  IsTextUnicode(Pointer(ARawHTML), Length(ARawHTML), @Tests);
  if (Tests and IS_TEXT_UNICODE_UNICODE_MASK) <> 0 then
  begin
    SetLength(Result, Length(ARawHTML) div 2);
    Move(Pointer(ARawHTML)^, Pointer(Result)^, Length(Result) * SizeOf(Char));
  end
  else
  if (Tests and IS_TEXT_UNICODE_REVERSE_MASK) <> 0 then
  begin
    SetLength(Result, Length(ARawHTML) div 2);
    Move(Pointer(ARawHTML)^, Pointer(Result)^, Length(Result) * SizeOf(Char));
    for X := 1 to Length(Result) do
    begin
      Result[X] := WideChar(
                             (Ord(Result[X]) shr 8) or
                            ((Ord(Result[X]) and $FF) shl 8)
                           );
    end;
  end
  else
    // No charset, no unicode, suppose Western
    Result := ConvertText(ARawHTML, 1252);
end;

function HTMLToRawHTML(const AHTML: UnicodeString): RawByteString;

  function ConvertText(const Text: UnicodeString; Charset: Cardinal): RawByteString;
  var
    CharsetInfo: TCharsetInfo;
    L: Integer;
    T: Bool;
  begin
    FillChar(CharsetInfo, SizeOf(CharsetInfo), 0);
    if not TranslateCharsetInfo(Charset, CharsetInfo, TCI_SRCCHARSET) then
    begin
      Result := ''; // Do Not Localize
      Exit;
    end;
    T := True;
    L := WideCharToMultiByte(CharsetInfo.ciACP, 0, PWideChar(Text), Length(Text), nil, 0, ReplaceChar, @T);
    SetLength(Result, L);
    T := True;
    WideCharToMultiByte(CharsetInfo.ciACP, 0, PWideChar(Text), Length(Text), PAnsiChar(Result), L, ReplaceChar, @T);
  end;

var
  Enc: String;
  X: Integer;
  {$IFDEF UNICODE}
  Charset: Cardinal;
  {$ENDIF}
begin
  if AHTML = '' then // Do Not Localize
  begin
    Result := ''; // Do Not Localize
    Exit;
  end;

  X := Pos(CharSetID, LowerCase(AHTML));
  if X > 0 then
  begin
    Enc := Copy(AHTML, X + Length(CharSetID), 255);

    X := Pos('"', Enc); // Do Not Localize
    if X = 0 then
      X := Pos('>', Enc) // Do Not Localize
    else
      if Pos('>', Enc) > 0 then // Do Not Localize
        X := Min(X, Pos('>', Enc)); // Do Not Localize

    if X <= 0 then
      X := Length(Enc) + 1;
    Enc := Trim(Copy(Enc, 1, X - 1));

    if LowerCase(Enc) = CharSetNameUTF8 then
      Result := UTF8Encode(AHTML)
    else
    begin
      {$IFDEF UNICODE}
      Charset := CharsetNameToCharset(Enc);
      if Charset <> 0 then
        Result := ConvertText(AHTML, CharSet);

      if Result = '' then // Do Not Localize
        // Unknown charset, suppose default ansi
        {$IFDEF SUPPORTS_IMPLICIT_WARNINGS}
        {$WARN IMPLICIT_STRING_CAST_LOSS OFF} // as designed
        {$ENDIF}
        Result := AHTML;
        {$IFDEF SUPPORTS_IMPLICIT_WARNINGS}
        {$WARN IMPLICIT_STRING_CAST_LOSS ON}
        {$ENDIF}
      {$ELSE UNICODE}
      Result := AHTML; // we have no unicode - so no point in converting
      {$ENDIF}
    end;

    Exit;
  end;

  {$IFDEF UNICODE}
  // No charset, suppose Western
  Result := ConvertText(AHTML, 1252);
  {$ELSE UNICODE}
  Result := AHTML; // we have no unicode - so no point in converting
  {$ENDIF}
end;

end.

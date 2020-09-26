Unit UrlParser;
// Моя версия класса - парсера
Interface

Uses
  Classes ;

Type

 TCSIParser = Class( TComponent )
  Private
   FLocDub : Boolean ; // Удалять ли дубликаты из локальных урл
   FIntDub : Boolean ; // Удалять ли дубликаты из внешних урл
   Procedure Do_Parse( Const What : String ) ;
   Procedure Do_After_Parse ;
  Protected
  Public
   FUrl   : String ; // Полный URL
   FSUrl  : String ; // Урезанный URL (без протокола)
   FSrc   : String ;
   FLocal : TStringList ;
   FInterURL : TStringList ;
   FInterText : TStringList ;
   FCntLocal : LongInt ;
   FCntInter : LongInt ;
   Constructor Create( AOwner: TComponent ) ; Override ;
   Destructor Destroy ; Override ;
   Procedure Execute ;
 End ;

Implementation

Uses
 StrUtils, SysUtils ;
//----------------------------------------------------------------------------//
function LastPos(SubStr, S: string): Integer;
 var
   Found, Len, Pos: integer;
 begin
   Pos := Length(S);
   Len := Length(SubStr);
   Found := 0;
   while (Pos > 0) and (Found = 0) do
   begin
     if Copy(S, Pos, Len) = SubStr then
       Found := Pos;
     Dec(Pos);
   end;
   LastPos := Found;
 end;
//----------------------------------------------------------------------------//
function GetBefore(substr, str:string):string;
begin
 if pos(substr,str)>0 then
   result:=copy(str,1,pos(substr,str)-1)
 else
   result:='';
end;
//----------------------------------------------------------------------------//
function GetAfter(substr, str:string):string;
begin
 if pos(substr,str)>0 then
   result:=copy(str,pos(substr,str)+length(substr),length(str))
 else
   result:='';
end;
//----------------------------------------------------------------------------//


Constructor TCSIParser.Create( AOwner: TComponent ) ;
 Begin
  Inherited Create( AOwner ) ;
  FCntLocal := 0 ;
  FCntInter := 0 ;
  FLocal := TStringList.Create ;
  FInterUrl := TStringList.Create ;
  FInterText := TStringList.Create ;
 End ;
{------------------------------------------------------------------------------}
Destructor TCSIParser.Destroy ;
 Begin
  FLocal.Free ;
  FInterUrl.Free ;
  FInterText.Free ;
  Inherited Destroy ;
 End ;
{------------------------------------------------------------------------------}
Procedure TCSIParser.Do_Parse( Const What : String ) ;
 Var
  tStr, tUrl, tAnchor : String ;                
  lPos : Integer ;
  I, J : Integer ;
 Begin
  tStr := Trim( What ) ;
  tStr := LowerCase( tStr ) ;
  lPos := Pos( 'href', tStr ) ;
  If lPos <> 0
   Then Begin
    // Удаляем из строку всякую хрень
    // Удаляем все, что перед началом URL
    Delete( tStr, 1, lPos + 4 ) ;
    // после href может идти или одинарная кавычка или двойная...
    If tStr[1] = '"'
     Then tUrl := Copy( tStr, 2, PosEx('"', tStr, 2 ) - 2 )
     Else tUrl := Copy( tStr, 2, PosEx('''', tStr, 2 ) - 2 ) ; // предполагается, что одинарная
    // Обработка URL


    If ( tUrl <> '' ) AND ( Pos( 'mailto:', tUrl ) <> 0 )
     Then tUrl := '' ;
    If ( tUrl <> '' ) AND ( Pos( '#', tUrl ) <> 0 )
     Then tUrl := '' ;
    If ( tUrl <> '' ) AND ( Pos( './', tUrl ) <> 0 )
     Then tUrl := '' ;
    If ( tUrl <> '' ) AND ( Pos( './/', tUrl ) <> 0 )
     Then tUrl := '' ;
    If ( tUrl <> '' ) AND ( Pos( '.jpg', tUrl ) <> 0 )
     Then tUrl := '' ;
    If ( tUrl <> '' ) AND ( Pos( '.jpeg', tUrl ) <> 0 )
     Then tUrl := '' ;
    If ( tUrl <> '' ) AND ( Pos( '.png', tUrl ) <> 0 )
     Then tUrl := '' ;
    If ( tUrl <> '' ) AND ( Pos( '.pdf', tUrl ) <> 0 )
     Then tUrl := '' ;
    If ( tUrl <> '' ) AND ( Pos( '.bmp', tUrl ) <> 0 )
     Then tUrl := '' ;
    If ( tUrl <> '' ) AND ( Pos( '.ico', tUrl ) <> 0 )
     Then tUrl := '' ;
    If ( tUrl <> '' ) AND ( Pos( '.gif', tUrl ) <> 0 )
     Then tUrl := '' ;
    If ( tUrl <> '' ) AND ( Pos( '.mp4', tUrl ) <> 0 )
     Then tUrl := '' ;

    If tUrl = '' Then Exit ;

    If Pos( 'http', tUrl ) = 0
     Then tUrl := FUrl + tUrl ;
   // Формируем текст, если он есть
    SetLength( tStr, Length( tStr ) - 4 ) ;
    lPos := LastPos( '>', tStr ) ;
    tAnchor := RightStr( tStr, Length( tStr) - lPos ) ;

    // Если в tUrl будет найден локальный домен, то это локальный адрес
    tStr := Copy( FUrl, 8, Length( FUrl ) - 7 ) ;
    tUrl := Trim( tUrl ) ;
    // Убираем "//"
    lPos := PosEx( '//', tUrl, 8 ) ;
    If lPos <> 0
     Then Begin
      tUrl := Copy( tUrl, 1, lPos ) + Copy( tUrl, lPos + 1, Length( tUrl ) - lPos - 1) ;
     End ;
    If (Pos(tStr,tUrl)<>0) AND (Pos( tStr, tUrl ) < 9)
     Then Begin FLocal.Add( tUrl ) ; Inc( FCntLocal ) ; End
     Else Begin
      FInterURL.Add( tUrl ) ;
      FInterText.Add( tAnchor ) ;
      Inc( FCntInter ) ;
     End ;
   End ;
 End ;
{------------------------------------------------------------------------------}
Procedure TCSIParser.Do_After_Parse ;
 Var
  I : Integer ;
  sTmp : String ;
 Begin
     sTmp := FUrl ;
     If Pos('http', sTmp ) <> 0
      Then Delete( sTmp, 1, 7 ) ;
     sTmp := StringReplace( sTmp, '/', '-', [rfReplaceAll]) ;
     sTmp := StringReplace( sTmp, '.', '-', [rfReplaceAll]) ;
  // Удаляем пустые строки
  While FInterURL.Find( '', I ) Do
   Begin
    FInterURL.Delete( I );
    FInterText.Delete( I ) ;
   End ;
  While FLocal.Find( '', I ) Do
   FLocal.Delete( I );
 End ;
{------------------------------------------------------------------------------}
Procedure TCSIParser.Execute ;
 Var
  I, J : Integer ;
  sDst ,
  sTmp : String ;
 Begin
  If FSrc = '' Then Exit ;
  I := Pos( '<a', FSrc ) ;
  J := PosEx( '</a>', FSrc, I ) ;
  While J <> 0 Do Begin
   sTmp := Copy( FSrc, I, J - I + 4 ) ;
   Delete( FSrc, I, J - I + 4 ) ;
   Do_Parse( sTmp ) ;
   I := Pos( '<a', FSrc ) ;
   J := PosEx( '</a>', FSrc, I ) ;
  End ;
  Do_After_Parse ;
 End ;
//----------------------------------------------------------------------------//

End.

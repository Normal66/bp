Unit LinkWork;
// Задача потока - спарсить все внешние и внутренние урлы с переданного урла
Interface

Uses
 Classes, HttpSend, UrlParser, SyncObjs ;


Type

 TLinkWork = Class(TThread)
   Private
    { Private declarations }
    lwLocalURL : TStringList ;
    lwTotal    : LongInt ;
    sDst       : String ;
    tTemp      : TStringList ;
    Function StreamToString( aStream : TStream ) : String ;
    Procedure Do_Thread_Parsing ;
    Procedure Test ;
   Protected
    Procedure Execute; Override;
   Public
    lwUrl    : String ;
    Constructor Create( CreateSuspend : Boolean ) ;
    Destructor Destroy ; Override ;
  End;

Var
 PLinkWork : TLinkWork ;
 Enable_Count_Thread : Integer ; // Максимально разрешенное кол-во одновременных потоков
 Count_Total : LongInt ; // Типа кол-во спарсенных URL...
 What_Do     : String ;
   lPage ,
   lSite ,
   lDub  ,
   lWord ,
   lText ,
   lInnr ,
   lSave : Boolean ;
   lCntT : Integer ;
   lFile : String ;

List_LocalURL : TStringList ;  // Общий список для результатов локальных урл
List_InterURL : TStringList ;  // Общий список для результатов внешних url

Function CheckListLocal( Const Src : String ) : Boolean ;

Implementation

Uses
 Forms, LinkMain, BPThread, SysUtils, StrUtils;

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


Function CheckListLocal( Const Src : String ) : Boolean ;
 Var
  I : Integer ;
 Begin
  If List_LocalUrl.Find( Src, I )
   Then Result := True
   Else Result := False ;
 End ;

//----------------------------------------------------------------------------//
Procedure TLinkWork.Test ;
 Var
  lPars : TCSIParser ;
  I, J  : Integer ;
  sTmp  : String ;
  tRes  : Boolean ;
  ALink : TLinkWork ;
  F     : TextFile ;
 Begin
     sTmp := lwUrl ;
     If Pos('http', sTmp ) <> 0
      Then Delete( sTmp, 1, 7 ) ;
     sTmp := StringReplace( sTmp, '/', '-', [rfReplaceAll]) ;
     sTmp := StringReplace( sTmp, '.', '-', [rfReplaceAll]) ;

   lwLocalURL.Clear ;
   lPars := TCSIParser.Create( Application );
   lPars.FUrl := lwUrl ;
   lPars.FSrc := sDst ;
   lPars.Execute ;
   lwLocalURL.BeginUpdate ;
   lwLocalURL.AddStrings( lPars.FLocal );
   lwLocalURL.EndUpdate ;
   Try
    CriticalSection.Enter ;
   List_InterURL.BeginUpdate ;
   List_InterURL.AddStrings( lPars.FInterURL ) ;
   List_InterURL.EndUpdate ;
   List_LocalURL.BeginUpdate ;
   List_LocalURL.AddStrings( lwLocalURL );
   List_LocalURL.EndUpdate ;
   Finally
    CriticalSection.Leave ; End ;
   lPars.Free ;
//   lwLocalURL.SaveToFile(GetCurrentDir+'\debug\'+sTmp); // N.B. До сюда - РАБОТАЕТ.
   // Предполагается, что в lwLocalURL список локальнх URL, спарсенных с переданной нам страницы
   // Теперь нужно каждый URL проверить на наличие в общем списке, и, если его там нет,
   // занести его туда и создать новые потоки
   tTemp.BeginUpdate ;
   tTemp.AddStrings( List_LocalURL );
   tTemp.EndUpdate ;
   For I := 0 To tTemp.Count - 1 Do Begin
    sTmp := tTemp.Strings[I] ;
    J := -1 ;
    J := lwLocalURL.IndexOf( sTmp ) ;
    If J = -1
     Then Begin
      ALink := TLinkWork.Create( True );
      ALink.lwUrl := sTmp ;
      ALink.Priority := tpLower;      
     End ;
{    J := List_LocalURL.IndexOf( sTmp ) ;    // Вот ГДЕ-ТО ТУТ ЗАСАДА!!!
    If J = -1
     Then Begin
      List_LocalURL.BeginUpdate ;
      List_LocalURL.Add( sTmp ) ;
      List_LocalURL.EndUpdate ;
      tTemp.BeginUpdate ;
      tTemp.Add( sTmp ) ;
      tTemp.EndUpdate ;
     End ;
   End ;
   For I := 0 To tTemp.Count - 1 Do Begin
    sTmp := tTemp.Strings[I] ;
    ALink := TLinkWork.Create( True );
    ALink.lwUrl := sTmp ;
//    ALink.Priority := tpLower;
    // Вызываем запускатор }
   End ;
  vBPListThread.CheckList ; 
 End ;


Procedure TLinkWork.Do_Thread_Parsing ;
 Begin
 End ;

Function TLinkWork.StreamToString( aStream : TStream ) : String ;
 Var
  SS : TstringStream ;
 Begin
  If aStream <> NIL
   Then Begin
    SS := TStringStream.Create('');
    Try
     aStream.Position := 0 ;
     SS.CopyFrom( aStream, aStream.Size ) ;
     Result := SS.DataString ;
    Finally
     SS.Free ;
    End ;
   End
   Else Result := '' ;
 End ;
{------------------------------------------------------------------------------}
Procedure TLinkWork.Execute ;
 Var
  tRes : Boolean ;
  lHttp : THttpSend ;
  sTmp : String ;
  sCh  : Char ;
  I, J : Integer ;
  tTemp : TStringList ;
  ALink : TLinkWork ;
 Begin
   lwTotal := 0 ; tRes := False ;
   lHttp := THttpSend.Create ;
  lhttp.Document.Clear;
  lhttp.Cookies.Clear;
  lhttp.Headers.Clear;
  lhttp.UserAgent := 'User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.2; ru; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13';
  lhttp.KeepAliveTimeout := 115;
  lhttp.KeepAlive := true;
// ????????? ?????????, ??? ????????. ? ????????? ? ??????? ??? ?????????? ??????
  lhttp.Headers.Add('Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
  lhttp.Headers.Add('Accept-Language: ru-ru,ru;q=0.8,en-us;q=0.5,en;q=0.3');
  lhttp.Headers.Add('Accept-Encoding: text/html');
  lhttp.Headers.Add('Accept-Charset: windows-1251,utf-8;q=0.7,*;q=0.7');
  lhttp.Headers.Add('Keep-Alive: 115');
  lhttp.Headers.Add('Proxy-Connection: keep-alive');
   tRes := lHttp.HTTPMethod( 'GET', lwUrl ) ;
   If tRes AND (lHttp.ResultCode = 200)
    Then Begin
     // Все OK
     sDst := StreamToString( lHttp.Document ) ;
     lHttp.Free ;
     tTemp := TStringList.Create ;
     Test ;
     tTemp.Free ;

    End
    Else Begin // Чота не так...
     If (lHttp.ResultCode = 301) OR (lHttp.ResultCode = 302) OR (lHttp.ResultCode = 307)
      Then Begin
       For I := 0 To lHttp.Headers.Count -1 Do
       If Pos( 'Location:', lHttp.Headers.Strings[I]) <> 0
        Then lwUrl := StringReplace(lHttp.Headers.Strings[I],'Location: ','',[]) ;
       lHttp.Free ;
       lHttp := THttpSend.Create ;
       tRes := lHttp.HTTPMethod( 'GET', lwUrl ) ;
       If tRes AND (lHttp.ResultCode = 200)
        Then Begin
         // Все OK
         sDst := StreamToString( lHttp.Document ) ;
         lHttp.Free ;
         tTemp := TStringList.Create ;
         Test ;
         tTemp.Free ;

        End
        Else Begin
         vBPError.Add( lwUrl, lHttp.ResultString , lHttp.ResultCode ) ; lHttp.Free ; Exit ;
        End ;
      End
      Else Begin
       vBPError.Add( lwUrl, lHttp.ResultString , lHttp.ResultCode ) ; lHttp.Free ; Exit ;
      End ;
    End ;

 End ;
{------------------------------------------------------------------------------}
Constructor TLinkWork.Create( CreateSuspend : Boolean  ) ;
 Begin
  Inherited Create( CreateSuspend ) ;
  FreeOnTerminate := True ;
  lwLocalURL := TStringList.Create ;
//  lwLocalURL.Sorted := True ;
//  lwLocalURL.Duplicates := dupIgnore ;
  lwLocalURL.CaseSensitive := False ;
  vBPListThread.AddThread( Self ) ;
 End ;
{------------------------------------------------------------------------------}
Destructor TLinkWork.Destroy ;
 Begin
  lwLocalURL.Free ;
  vBPListThread.RemoveThread( Self );
  Inherited Destroy ;
 End ;
//----------------------------------------------------------------------------//
End.

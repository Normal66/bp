Unit WorkThread;

Interface

Uses Classes, SysUtils, HttpSend ;

Type

 TWorkThread = Class( TThread )
  Private
   CntUrl : LongInt ;
   Function Extract( Par1, Par2, Par3 : String ) : String;
  Protected
   Procedure Execute; Override;
  Public
   fURL : String ; // URL ��� �������
   fId  : String ; // ������������� ������
   fSrc : String ; // ��� ����� - ����������!!!
   fStatus : Word ; // 1 - ��������, 2 - �������, 3 - ������
 End ;

Implementation

Uses
 Main, GlobVar, Common, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
 IdBaseComponent, Forms, StrUtils, IdCookieManager ;

//----------------------------------------------------------------------------//
Function TWorkThread.Extract( Par1, Par2, Par3 : String ) : String;
 Begin
  Try
    extract:=copy(par1,pos(par2,par1)+length(par2),pos(par3,par1)-pos(par2,par1)-length(par2));
  Except

  End;
 End;
//----------------------------------------------------------------------------//
Procedure TWorkThread.Execute ;
 Var
  lHttp : TidHTTP ;
  lTmp, w  : String ;
  I,J,K,L     : Integer ;
  NewTh : TWorkThread ;
  lUrl : String ;
  B    : Boolean ;
  aHandle : Integer ;
  lBP : TResBP ;
   Src  : String ; // ���� �������� ����� �� ������� �� ������
 Begin
  // ���� ��� �� ������� ������ (Terminate) ��� �� ��� ��������, ������
  While (Not Terminated) or ( fStatus <> 2 ) Do Begin
   // ���� ���� ������ ��� ��������� ��������, �� ���������� �� ���� �������� ����������
   Application.ProcessMessages ;
   If fStatus = 3
    Then Begin
     Try
      CriticalSection.Enter ;
      Dec(gGlobal.gCountErr) ;
     Finally
      CriticalSection.Leave ;
     End ;
    End ;
    // ���� ��� ������ ������, � �� ����� ������...
    // ���������� ����
    If fStatus = 1
     Then Begin
      Try
       CriticalSection.Enter ;
       Inc(gGlobal.gCntCreate) ;
       Inc(gGlobal.gCntCommon) ;
       Inc(gGlobal.gCntRun) ;
       For I := 0 To gGlobal.gListRes.Count - 1 Do Begin
        If TResBP(gGlobal.gListRes.Items[I]).SrcNFile = fSrc
         Then Begin
          lBP := TResBP(gGlobal.gListRes.Items[I]) ;
          Break ;
         End ;
       End ;
      Finally
       CriticalSection.Leave ;
      End ;
     End ;
    Application.ProcessMessages ;
     // ������� ��������� http � ����������� �����
    lHttp := TIdHTTP.Create( NIL ); lHttp.AllowCookies := true;
    lHttp.HandleRedirects := True ; lHttp.Request.Host:= fURL;
    lHttp.Request.UserAgent:='Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)';
    lHttp.Request.Accept:='*/*'; lHttp.Request.AcceptLanguage:='ru';
    lHttp.Request.Pragma := 'no-cache' ; lHttp.Request.ContentType := 'text/html; charset=windows-1251' ;
    lHttp.ReadTimeout := 30000 ;
    // ��������� �� ��� ���, ���� �� �������� ��� ���� ������� � ��������� �������� � � ����������� nextpage

    Repeat
     Application.ProcessMessages ;
     Try
      CriticalSection.Enter ;
       Try
        Src := lHttp.Get( fUrl ) ;
        // ���� ��� ����, ��������� ����������
//        lHttp.Socket.Close ;
        lHttp.Free ;
       Except
       // ������ ��� ���������� �������...
        lHttp.Free ;
        fStatus := 3 ;
        Try
         CriticalSection.Enter ;
         Inc(gGlobal.gCountErr) ;
        Finally CriticalSection.Leave ; End ;
        Sleep( 15000 ) ; // ������� 15 ������ ����� ��������� ��������...
        Exit ;
       End ;
     Finally
      CriticalSection.Leave ;
     End ;
     // ������ ���������� ��������
     Application.ProcessMessages ;
     Repeat
      I := Pos('<url>',Src);
      If I = 0 // ���� ����� ������ ���, ��������� ������
       Then Break;
      Delete(Src,1,I+Length('<url>')-1);
      W := Copy(Src,1,Pos('</url>',Src)-1);
      If (Pos('http://', W) <>0 )
       Then  Delete(W, Pos('http://', W),Length('http://'));
      J := Pos('/',W);
      If J = 0 Then J := Length(W);
       Try
        CriticalSection.Enter ;
        lBP.DstRes.Add( w ) ;
        Inc( gGlobal.gAllParsed ) ;
       Finally CriticalSection.Leave ; End ;
     Until False ;
     // ��������. ������ �������, ���� �� �����������...
     Application.ProcessMessages ;
     If Pos( '<nextpage>', Src ) <> 0
      Then Begin
       lUrl := Extract( Src, '<nextpage><![CDATA[', ']]></nextpage>');
       If lUrl <> ''
        Then Begin
         lUrl := 'http://boss.yahooapis.com' + lUrl ;
         lTmp := Copy( lUrl, Pos('&start=',lUrl)+7, Length(lUrl)-Pos('&start=',lUrl) - 6 );
         J := StrToInt( lTmp ) ;
         If J = 1000 Then B := False Else B := True ;
        End ;
      End ;
     If Not B  // ���� ��� ��������� ��������, ��
      Then Break ; // ��� ������
    Until False ;
    //  ��� ���������, �����������
    Application.ProcessMessages ;
    fStatus := 2 ;
    Terminate ;
  End ; // While
  Try
   CriticalSection.Enter ;
   Inc(gGlobal.gCountDone) ;
   Dec(gGlobal.gCountAll) ;
   Dec(gGlobal.gCntRun);
  Finally
   CriticalSection.Leave ;
  End ;
  Application.ProcessMessages ;

{------------------------------------------------------------------------------}
 End ;
//----------------------------------------------------------------------------//

End.

Unit Thread;
{
����� ������:
 1) ������ �� ��� ���, ���� ������ <> 2 ��� ���� ��� ������� �� �����������
 2) ��� ��������, ������� ����� ����� ������ � ������, ���� ��� ��������� �
 ���������� gRunNewThread �� ������ GlobVar
} 
Interface

Uses
  Classes, SyncObjs, SysUtils ;

Type
  BPThread = Class(TThread)  // ������� �������� ����� ��������
   Private
    { Private declarations }
    fURL : String ; // URL ��� �������
    fId  : String ; // ������������� ������
    fSrc : String ; // ��� ����� - ����������!!!
    Src  : String ; // ���� �������� ����� �� ������� �� ������
    lStatus : Integer ; // ������� ������
    DstRes : TStringList ;
    fF   : TextFile ;
   Protected
    Procedure SetStatus( Status : Integer ) ;
    Procedure Parsing ;
    Procedure Execute; Override;
   Public
    Constructor Create(CreateSuspennded: Boolean; Const URL: String ; Const Id : String; Const Src : String );
  End;

Implementation

uses Common, Main, IdComponent,
     IdTCPConnection, IdTCPClient,
     IdHTTP, IdBaseComponent, StrUtils, GlobVar;


{ Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure BPThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ BPThread }

Procedure BPThread.Parsing ;
 Var
  I, J : Integer ;
  NewTh : BPThread ;
  lUrl : String ;
  lTmp : String ;
 Begin
    I := Pos( '<nextpage>', Src ) ;
    If I <> 0
     Then Begin
      // ��� ��������... ������� ���������...
      J := PosEx( '/', Src, I + 1 ) ;
      I := PosEx( ']', Src, J ) ;
      lUrl := 'http://boss.yahooapis.com' + Copy( Src, J, I - J ) ;
      While gRunNewThread <> True Do
       Sleep(0) ;
      NewTh := BPThread.Create( True, lUrl, fId + '.' + '0', fSrc );
      NewTh.Resume ;
     End ;
     // ��� ������
     I := -1 ;
     While I <> 0 Do Begin
       I := Pos( '<url>', Src ) ;
       J := Pos( '</url', Src ) ;
       lTmp := Copy( Src, I + 5, J - I - 5 ) ;
       Delete( Src, 1, J + 5 ) ;
       DstRes.Add( lTmp ) ;
     End ;
 End ;

Procedure BPThread.SetStatus( Status : Integer );
  // ���� ���� � ������ ����� � ���������� ������
 Var
  I : Integer ;
  P : MyThread ;
 Begin
  For
   I := 0 To ListThread.Count - 1 Do
    Begin
     P := MyThread( ListThread.Items[I] ) ;
     If P.lQuery.IntId = fId
      Then P.lQuery.Status := Status ;
    End ;
 End ;

Constructor BPThread.Create(CreateSuspennded: Boolean; const URL: String ; Const Id : String ; Const Src : String );
 Var
  MyInfo : MyThread ;
 Begin
  Inherited Create(CreateSuspennded); //����� ������
  Try
   CriticalSection.Enter ;
   lStatus := 1 ; // �������� ������
   gCountAll := gCountAll + 1 ;
   gCntCommon := gCntCommon + 1 ;
   fURL := URL ;
   fId  := Id ;
   fSrc := Src ; // ��� ����� - ����������!!!
   MyInfo := MyThread.Create( NIL );
   MyInfo.lQuery.Status := 1 ;
   MyInfo.lQuery.IntId := fId ;
   MyInfo.lQuery.SrcURL := Src ;
   MyInfo.lThread := @Self ;
   ListThread.Add( MyInfo ) ;
   DstRes := TStringList.Create ;
   Resume;
  Finally
   CriticalSection.Leave ;
  End ;
 End ;

Procedure BPThread.Execute;
 Var
  lHttp : TidHTTP ;
  lUrl  : String ;
  lTmp  : String ;
  I     : Integer ;
 Begin
  { Place thread code here }
  While lStatus <> 2 Do
   Begin
    If Terminated Then Exit ; // �������, ���� ������
    If lStatus = 3 Then gCountErr := gCountErr - 1 ;
    Try
     lHttp := TIdHTTP.Create( NIL );
     lHttp.AllowCookies := True ;
     lHttp.HandleRedirects := True ;
     Try
      Src := lHttp.Get( fURL );
      Parsing ;
      lHttp.Free ;
      lStatus := 2 ; // ������ :)
      Try
       CriticalSection.Enter ;
       AssignFile( fF, GetCurrentDir + '\Results\' + fSrc + '.txt' ) ;
       Append( fF ) ;
       For I := 0 To DstRes.Count - 1 Do Begin
        lTmp := DstRes.Strings[I] ;
        WriteLn( fF, lTmp ) ;
       End ;
       Flush( fF ) ;
       CloseFile( fF ) ;
       DstRes.Free ;
       gCountAll := gCountAll - 1 ;
       gCountDone := gCountDone + 1 ;
      Finally
       CriticalSection.Leave ;
      End ;
      SetStatus( 2 ) ;
     Except
      // ������ ��� ���������� �������...
      lHttp.Free ;
      lStatus := 3 ;
      SetStatus( 3 ) ;
      gCountErr := gCountErr + 1 ;
      WriteLn( F, 'Thread : ' + fId + ' error : get ' + fURL );
      Flush( F ) ;
      Sleep( 30000 ) ; // ������� 30 ������ ����� ��������� ��������...
      // P.S. �� ����, ���� �� ���������� �� �� ������...
     End ;
    Except
     // ������ ��� �������� idhttp...
      WriteLn( F, 'Thread : ' + fId + ' error : create' );
      Flush( F ) ;

     lHttp.Free ;
     lStatus := 3 ;
     SetStatus( 3 ) ;
     gCountErr := gCountErr + 1 ;
     Sleep( 30000 ) ; // ������� 30 ������ ����� ��������� ��������...
    End ;
   End ;
 End;

End.

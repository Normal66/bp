Unit Work;

Interface

Uses
  Classes, HttpSend, GlobVar ;

Var
 bCntRun  : LongInt ; // кол-во работающих потоков
 bCntAll  : LongInt ; // кол-во созданных потоков
 bCntDone : LongInt ; // кол-во отработавших потоков
 bCntErr  : LongInt ; // кол-во потоков с ошибками
 bCntPars : LongInt ; // кол-во спарсенных URL
 bCntHits : LongInt ; //
 bPause   : Boolean ; // ≈сли True - то приостанавливаемс€
 bStopped : Boolean ; // ≈сли True - завершаем работу

Type

  TErrRec = Record
   fURL : String ;
   fSrc : String ;
  End ;
  PErrRec = ^TErrRec ;
{------------------------------------------------------------------------------}
//  ласс, в который при ошибке в потоке (кол-во запущенных потоков > разрешенного
// добавл€етс€ url & src дл€ запуска, когда можно будет...
  TErrorBP = Class
   Private
   Protected
   Public
    lList   : TList ;
    Constructor Create ;
    Procedure Free ;
    Procedure Add( lURL, lSRC : String ) ;
  End ;
{------------------------------------------------------------------------------}
  TWork = Class(TThread)
   Private
    { Private declarations }
    lSrc : String ; // –езультат запроса
    fCnt : LongInt ; // —колько спарсили
    fHits : LongInt ;
    lHttp   : THttpSend ;
    fStatus : Word ;
    tUrl : String ;
    Procedure DoPause ;
    Procedure DoStop ;
    Procedure UpdCntHits ;
    Procedure UpdDone ;
    Procedure UpdErrInc  ;
    Procedure UpdErrDec ;
    Procedure UpdAllInc ;
    Procedure UpdAllDec ;
    Procedure UpdRunInc ;
    Procedure UpdRunDec ;
    Procedure UpdCntPar ;
    Function  StreamToString( aStream : TStream ) : String ;
    Procedure UpdSave ;
    Function  Extract( Par1, Par2, Par3 : String ) : String;
//    Procedure Do_Parsing ;
//    Procedure Do_NextPage ;
   Protected
    Procedure Execute; Override;
   Public
    fSrc : String ;
    fUrl : String ;
    fDst : TStringList ;
    fWork : String ;
    Constructor Create( CreateSuspend : Boolean  ) ;
    Destructor Destroy ; Override ;
  End;
{------------------------------------------------------------------------------}
Var
 PWork : TWork ;
 PErrBP : TErrorBP ;
 wErrRec : PErrRec ;

Implementation

Uses
 Common, Forms, SysUtils, StrUtils ;
{ Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TWork.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ TWork }
//----------------------------------------------------------------------------//
Constructor TErrorBP.Create ;
 Begin
  lList := TList.Create ;
 End ;
{------------------------------------------------------------------------------}
Procedure TErrorBP.Free ;
 Var
  I : Integer ;
 Begin
  For I := 0 To Pred( lList.Count ) Do
   Begin
    wErrRec := PErrRec(lList.Items[I]) ;
    Dispose( wErrRec ) ;
   End ;
  lList.Free ;
 End ;
{------------------------------------------------------------------------------}
Procedure TErrorBP.Add( lURL, lSRC : String ) ;
 Begin
  New( wErrRec ) ;
  wErrRec^.fURL := lUrl ;
  wErrRec^.fSrc := lSrc ;
  lList.Add( wErrRec ) ;
 End ;
//----------------------------------------------------------------------------//
Procedure TWork.DoPause ;
 Begin
  If bPause
   Then Suspend ;
 End ;
{------------------------------------------------------------------------------}
Procedure TWork.DoStop ;
 Begin
  If bStopped
   Then Destroy ;
 End ;
{------------------------------------------------------------------------------}
Procedure TWork.UpdCntHits ;
 Begin
  bCntHits := bCntHits + fHits ;
 End ;
//----------------------------------------------------------------------------//
Procedure TWork.UpdCntPar ;
 Begin
  bCntPars := bCntPars + fCnt ;
 End ;
//----------------------------------------------------------------------------//
Procedure TWork.UpdDone ;
 Begin
  Inc( bCntDone ) ;
 End ;
//----------------------------------------------------------------------------//
Procedure TWork.UpdErrInc ;
 Begin
  Inc( bCntErr ) ;
 End ;
//----------------------------------------------------------------------------//
Procedure TWork.UpdErrDec ;
 Begin
  Dec( bCntErr ) ;
 End ;
//----------------------------------------------------------------------------//
Procedure TWork.UpdAllInc ;
 Begin
  Inc( bCntAll ) ;
 End ;
//----------------------------------------------------------------------------//
Procedure TWork.UpdAllDec ;
 Begin
  Dec( bCntAll ) ;
 End ;
//----------------------------------------------------------------------------//
Procedure TWork.UpdRunInc ;
 Begin
  Inc( bCntRun ) ;
 End ;
//----------------------------------------------------------------------------//
Procedure TWork.UpdRunDec ;
 Begin
  Dec( bCntRun ) ;
 End ;
//----------------------------------------------------------------------------//
Function  TWork.StreamToString( aStream : TStream ) : String ;
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
//----------------------------------------------------------------------------//
Procedure TWork.UpdSave ;
 Var
  I : Integer ;
 Begin
  For I := 0 To gGlobal.gListRes.Count - 1 Do Begin
   If TResBP(gGlobal.gListRes.Items[I]).SrcNFile = fSrc
    Then Begin
     TResBP(gGlobal.gListRes.Items[I]).DstRes.AddStrings( fDst ) ;
     Break ;
    End ;
  End ;
 End ;
//----------------------------------------------------------------------------//
Function TWork.Extract( Par1, Par2, Par3 : String ) : String;
 Begin
  Try
    extract:=copy(par1,pos(par2,par1)+length(par2),pos(par3,par1)-pos(par2,par1)-length(par2));
  Except
  End;
 End;
//----------------------------------------------------------------------------//
Procedure TWork.Execute;
 Var
  lRes : Boolean ;
  I, J : Integer ;
  W    : String ;
  NewTH : TWork ;
 Begin
  { Place thread code here }
  Synchronize( DoPause ) ;
  Synchronize( DoStop ) ;

  Synchronize(UpdRunInc) ;
  // –аботаем с одной полученной страницей, дл€ других создаем новые потоки
  lHttp := THttpSend.Create ;
  lRes := lHttp.HTTPMethod( 'GET', fUrl ) ;
  If lRes And (lHttp.ResultCode = 200)
   Then Begin
    lSrc := StreamToString( lHttp.Document ) ;
    lHttp.Free ;
    Synchronize( DoPause ) ;
    Synchronize( DoStop ) ;

    I := Pos( '<nextpage>', lSrc ) ;
    If I <> 0
     Then Begin
      tUrl := Extract( lSrc, '<nextpage><![CDATA[', ']]></nextpage>');
      If tUrl <> ''
       Then Begin
        tUrl := 'http://boss.yahooapis.com' + tUrl ;
        If fUrl <> tUrl // создаем новый поток
         Then Begin
          If bCntRun > GlobalSetting.CurrentMultiThreadingBackLinks
           Then Begin // нельз€ создать поток. ƒобавл€ем в ошибку
            Synchronize(UpdErrInc) ;
            PErrBP.Add( tUrl, fSrc );
           End
           Else Begin // Ok, создаем новый поток
            NewTh := TWork.Create(True);
            NewTh.fURL := tUrl ;
            NewTh.fSrc := fSrc ;
           End ;
         End ;
       End ;
       Synchronize( DoPause ) ;
       Synchronize( DoStop ) ;
     End ;
   End Else
   Begin
    fStatus := 3 ;
    Synchronize(UpdErrInc) ;
    PErrBP.Add( fUrl, fSrc );
   End ;
// ѕарсим ----------------------------------------------------------------------
  Synchronize( DoPause ) ;
  Synchronize( DoStop ) ;
  fCnt := 0 ;
  I := 0 ;
  Repeat
   I := Pos('<url>',lSrc);
   If I = 0 // если урлов больше нет, двихаемс€ дальше
    Then Break;
   J := PosEx('</url>', lSrc ) ;
   W := Copy( lSrc, I+5, J-I-5 ) ;
   Delete( lSrc, I, J-I+6 ) ;
   If W <> '' Then Begin fDst.Add( W ) ; Inc( fCnt ) ; End ;
  Until False ;
  Synchronize( UpdCntPar ) ;
// √отово ----------------------------------------------------------------------
  Synchronize(UpdSave) ;
  fDst.Free ;
  Synchronize(UpdDone) ;
  fStatus := 2 ;
  Synchronize(UpdRunDec) ;
  Terminate ;
 End ;
//----------------------------------------------------------------------------//
Constructor TWork.Create( CreateSuspend : Boolean );
 Begin
  Inherited Create( CreateSuspend ) ;
  fStatus := 1 ;
  fDst    := TStringList.Create ;
  fCnt    := 0 ;
  fHits := 0 ;
  Synchronize(UpdAllInc);
  FreeOnTerminate := True ;
  gGlobal.gListThread.Add( Self ) ;
  Resume ;
 End ;

Destructor TWork.Destroy ;
 Begin
  gGlobal.gListThread.Remove( Self ) ;
  Inherited Destroy ;
 End ;

End.


{
http://boss.yahooapis.com/ysearch/web/v1/www.cnatips.com?appid=qkb4WGvV34FbTeIf97f_c.73L1IAR7FZfqhq_UVqP1.XK3LlAMLC2yXjUfbfwMxgVW.23g--&format=xml&count=50&style=raw&abstract=long&sites=.com
}

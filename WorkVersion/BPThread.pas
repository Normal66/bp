Unit BPThread;
// Общий модуль с классом TBPError и TBPThread
Interface

Uses
  Classes, SyncObjs, SysUtils ;

Type
  TErrRec = Record
   fURL : String ;  // ошибочный урл
   fSrc : String ;  // имя файла - результата
   fErr : Integer ; // Код ошибки
  End ;
  PErrRec = ^TErrRec ;
{------------------------------------------------------------------------------}
// Описание классов
Type

  TBPListThread = Class( TThreadList )
   Private
   Protected
   Public
    FCountAll  : LongInt ;
    FCountRun  : LongInt ;
    FCountDone : LongInt ;
    FCountEnab : LongInt ;
    Constructor Create ;
    Procedure AddThread(Item: Pointer);
    Procedure RemoveThread(Item: Pointer);
    Function CheckList : Boolean ;
  End ;

{------------------------------------------------------------------------------}
  TBPError = Class
   Private
    FCntRec : Integer ;
    Function GetCntRec : Integer ;
   Protected
   Public
    vList   : TList ;
    wErrRec : PErrRec ;
    Property CntRec : Integer Read GetCntRec ;
    Constructor Create ;
    Procedure Free ;
    Procedure Add( lURL, lSRC : String ; lErr : Integer ) ;
    Function GetList : TList ;
    Function GetListItem( Const lItem : Integer ) : PErrRec ;
  End ;
{------------------------------------------------------------------------------}
  TBPThread = Class( TThread )
   Private
   Protected
   Public
  End ;
{------------------------------------------------------------------------------}
// Переменные классов
Var

  vBPError  : TBPError ;
  vBPThread : TBPThread ;
  vBPListThread : TBPListThread ;

Implementation

uses LinkWork, LinkMain;

//----------------------------------------------------------------------------//
Constructor TBPListThread.Create ;
 Begin
  Inherited Create ;
  FCountAll  := 0 ;
  FCountRun  := 0 ;
  FCountDone := 0 ;
 End ;
{------------------------------------------------------------------------------}
Procedure TBPListThread.AddThread( Item : Pointer );
 Begin
  Inc( FCountAll ) ;
  Add( Item ) ;
 End ;
{------------------------------------------------------------------------------}
Procedure TBPListThread.RemoveThread( Item : Pointer );
 Begin
  Remove( Item ) ;
  Inc( FCountDone ) ;
  Dec( FCountRun ) ;
 End ;
{------------------------------------------------------------------------------}
Function TBPListThread.CheckList : Boolean ;
 Var
  I : Integer ;
 Begin
  // Возвращает True, если список потоков закончился. Заодним запускает неотработавшие потоки
  With LockList Do Begin
   Try
    For I := 0 To Count - 1 Do
     Begin
      If TLinkWork( Items[I] ).Suspended
       Then Begin
        If FCountRun < FCountEnab
         Then Begin
          TLinkWork(Items[I]).Resume ;
          Inc( FCountRun ) ;
         End ;
       End ;
     End ;
    If Count <> 0
     Then Result := False
     Else Result := True ;
   Finally
    UnlockList ;
   End ;
  End ;
{  If (FCountDone < FCountAll) AND (FCountRun > 0 )
   Then Result := False
   Else Result := True ; }
 End ;
//----------------------------------------------------------------------------//
Constructor TBPError.Create ;
 Begin
  vList := TList.Create ;
 End ;
{------------------------------------------------------------------------------}
Procedure TBPError.Free ;
 Var
  I : Integer ;
 Begin
  For I := 0 To Pred( vList.Count ) Do
   Begin
    wErrRec := PErrRec(vList.Items[I]) ;
    Dispose( wErrRec ) ;
   End ;
  vList.Free ;
 End ;
{------------------------------------------------------------------------------}
Function TBPError.GetCntRec : Integer ;
 Begin
  Result := vList.Count ;
 End ;
{------------------------------------------------------------------------------}
Procedure TBPError.Add( lURL, lSRC : String ; lErr : Integer ) ;
 Begin
    New( wErrRec ) ;
    wErrRec^.fURL := lUrl ;
    wErrRec^.fSrc := lSrc ;
    wErrRec^.fErr := lErr ;
    vList.Add( wErrRec ) ;
 End ;
{------------------------------------------------------------------------------}
Function TBPError.GetList : TList ;
 Begin
  Result := vList ;
 End ;
{------------------------------------------------------------------------------}
Function TBPError.GetListItem( Const lItem : Integer ) : PErrRec ;
 Begin
  Result := PErrRec( vList.Items[lItem] ) ;
 End ;
//----------------------------------------------------------------------------//
End.

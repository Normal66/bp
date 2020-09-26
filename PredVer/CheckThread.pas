Unit CheckThread;
{
Поток, который отслеживает окончание работы.
Если в списке потоков у всех потоков стоит статус = 2,
значит все потоки отработали
}
Interface

Uses
  Classes, SyncObjs, Common, Main, SysUtils;

Type
  MyCheckThread = Class(TThread)
  Private
    { Private declarations }
  Protected
    Procedure Execute; Override;
    Procedure Update ;
  End;

Var
 NewCh : MyCheckThread ;

Implementation

uses GlobVar, WorkThread, Forms  ;

{ Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure CheckThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ CheckThread }

Procedure MyCheckThread.Update ;
 Var
  I : Integer ;
  lList : TList ;
 Begin
  lList := gGlobal.gListThread.LockList ;
  I := lList.Count ;
  gGlobal.gListThread.UnlockList ;
  gGlobal.gCntRun := I ;
  fmMain.stAllRunning.Caption := IntToStr( I ) ;
  fmMain.stCntDone.Caption := IntToStr( gGlobal.gCountDone ) ;
  fmMain.stCntErr.Caption := IntToStr( gGlobal.gCountErr ) ;
  fmMain.stAllThread.Caption := IntToStr( gGlobal.gCntCreate ) ;
  fmMain.StaticText2.Caption := IntToStr( gGlobal.gAllParsed ) ;
 End ;

Procedure MyCheckThread.Execute;
 Var
  I : Integer ;
  J : Integer ;
  P : TWorkThread ;
  lList : TList ;
 Begin
  { Place thread code here }
  While Not Terminated Do Begin
    lList := gGlobal.gListThread.LockList ;
    For I := 0 To Pred(lList.Count) Do Begin
     If TWorkThread(lList.Items[I]).fStatus = 2
      Then Begin
       lList.Delete(I);
//       Dec(gGlobal.gCntRun) ;
      End ;
    End ;
    gGlobal.gListThread.UnlockList ;
    lList := gGlobal.gListThread.LockList ;
    I := lList.Count ;
    gGlobal.gListThread.UnlockList ;
    If I = 0
     Then Begin
      // Остался только этот поток. Выжидаем 30 секунд и проверяем.
      // Если через 10 секунд мы все еще одни, то ВСЁ. Закончили...
      Sleep( 10000 ) ;
      lList := gGlobal.gListThread.LockList ;
      I := lList.Count ;
      gGlobal.gListThread.UnlockList ;
      If  I = 0
       Then Begin
        Try
         CriticalSection.Enter ;
         gGlobal.gCountAll := gGlobal.gCountAll - 1 ;
         gGlobal.gCountDone := gGlobal.gCountDone + 1 ;
        Finally
         CriticalSection.Leave ;
        End ;
        // Terminate ;
       End ;
     End ;
    Synchronize( update ) ;
    Application.ProcessMessages ;
  End ;
 End;

End.

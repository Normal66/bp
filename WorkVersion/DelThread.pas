unit DelThread;
{
ѕоток, который удал€ет из списка потоков те, которые
закончили свою работу.
}
Interface

Uses
  Classes, SyncObjs, Common, Main, SysUtils;

Type
  MyDelThread = Class(TThread)
  Private
    { Private declarations }
  Protected
    Procedure Execute; Override;
  End;

Var
 NewDel : MyDelThread ;
   
Implementation

Procedure MyDelThread.Execute;
 Var
  aID : TStringList ; // “ут список ID потоков с кодом 2
  I : Integer ;
  P : MyThread ;
  J : Integer ;
 Begin
  { Place thread code here }
  aID := TStringList.Create ;
  For I := 0 To ListThread.Count - 1 Do Begin
   P := MyThread( ListThread.Items[I] ) ;
   If P.lQuery.Status = 2
    Then
     aID.Add( P.lQuery.IntId ) ;
  End ;
  // —формировали массив ID, у которых статус = выполнено
  // –аз выполнено, значит можно удал€ть... ќдновременно
  // уменьша€ текущий счетчик запущенных потоков на единицу.
Try
  CriticalSection.Enter ;
  For I := 0 To aID.Count - 1 Do
   Begin
    J := ListThread.Count - 1 ;
    While J <> 0 Do
     Begin
      P := MyThread( ListThread.Items[J] ) ;
      If P.lQuery.IntId = aID.Strings[I]
       Then Begin
        P.Free ;
        ListThread.Delete(J);
        Dec( GlobThreadR ) ; // уменьшаем счетчик запущенных потоков
       End ;
       J := ListThread.Count - 1 ;
     End ;
   End ;
 If GlobThreadR < GlobalSetting.CurrentMultiThreadingBackLinks
  Then DontCreateThread := True   // ћожно новые потоки
  Else DontCreateThread := False ; // Ќельз€ новые потоки 
Finally
 CriticalSection.Leave ;
End ; 
  If Terminated Then Exit ;

 End;


End.

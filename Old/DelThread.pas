unit DelThread;
{
�����, ������� ������� �� ������ ������� ��, �������
��������� ���� ������.
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
  aID : TStringList ; // ��� ������ ID ������� � ����� 2
  I : Integer ;
  P : MyThread ;
  J : Integer ;
 Begin
  { Place thread code here }
  While Not Terminated Do  Begin
  aID := TStringList.Create ;
  For I := 0 To ListThread.Count - 1 Do Begin
   P := MyThread( ListThread.Items[I] ) ;
   If P.lQuery.Status = 2
    Then
     aID.Add( P.lQuery.IntId ) ;
  End ;
  // ������������ ������ ID, � ������� ������ = ���������
  // ��� ���������, ������ ����� �������... ������������
  // �������� ������� ������� ���������� ������� �� �������.
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
        P.lThread.Terminate ;
        P.Free ;
        ListThread.Delete(J);
//        Dec( GColobThreadR ) ; // ��������� ������� ���������� �������
       End ;
       J := ListThread.Count - 1 ;
     End ;
   End ;
  aID.Free ;
Finally
 CriticalSection.Leave ;
End ;
End ;

 End;


End.

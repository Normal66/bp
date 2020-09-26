Unit RunThread;
// Поток, проверяющий кол-во запущенных потоков и разрешающий
// или запрещающий создание новых потоков
Interface

Uses
  Classes, Main, Common, GlobVar;

Type
  TRunThread = Class(TThread)
  Private
    { Private declarations }
  Protected
    Procedure Execute; Override;
  End;

Var
 thRunThread : TRunThread ;

Implementation

{ Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TRunThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ TRunThread }

Procedure TRunThread.Execute;
 Begin
  { Place thread code here }
  While Not Terminated Do
   Begin
    Try
     CriticalSection.Enter ;
     If gCountAll < GlobalSetting.CurrentMultiThreadingBackLinks
      Then gRunNewThread := True
      Else gRunNewThread := False ;
    Finally
     CriticalSection.Leave ;
    End ;
   End ;
 End;

End.

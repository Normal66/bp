Unit Thread;
{
Общая логика:
 1) Делаем до тех пор, пока статус <> 2 или пока нет команды на Уничтожение
 2) При парсинге, создаем новый поток только в случае, если это разрешено в
 переменной gRunNewThread из модуля GlobVar
} 
Interface

Uses
  Classes, SyncObjs, SysUtils ;

Type
  BPThread = Class(TThread)  // парсинг ИСХОДНОЙ ОДНОЙ страницы
   Private
    { Private declarations }
    fURL : String ; // URL для запроса
    fId  : String ; // идентификатор потока
    fSrc : String ; // имя файла - результата!!!
    Src  : String ; // сюда получаем ответ от сервера на запрос
    lStatus : Integer ; // Текущий статус
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
      // Еще страницы... Создаем подзадачу...
      J := PosEx( '/', Src, I + 1 ) ;
      I := PosEx( ']', Src, J ) ;
      lUrl := 'http://boss.yahooapis.com' + Copy( Src, J, I - J ) ;
      While gRunNewThread <> True Do
       Sleep(0) ;
      NewTh := BPThread.Create( True, lUrl, fId + '.' + '0', fSrc );
      NewTh.Resume ;
     End ;
     // тут парсим
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
  // Ищет себя в списке задач и выставляет статус
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
  Inherited Create(CreateSuspennded); //метод предка
  Try
   CriticalSection.Enter ;
   lStatus := 1 ; // Начинаем работу
   gCountAll := gCountAll + 1 ;
   gCntCommon := gCntCommon + 1 ;
   fURL := URL ;
   fId  := Id ;
   fSrc := Src ; // имя файла - результата!!!
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
    If Terminated Then Exit ; // Выходим, если велено
    If lStatus = 3 Then gCountErr := gCountErr - 1 ;
    Try
     lHttp := TIdHTTP.Create( NIL );
     lHttp.AllowCookies := True ;
     lHttp.HandleRedirects := True ;
     Try
      Src := lHttp.Get( fURL );
      Parsing ;
      lHttp.Free ;
      lStatus := 2 ; // Готово :)
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
      // Ошибка при выполнении запроса...
      lHttp.Free ;
      lStatus := 3 ;
      SetStatus( 3 ) ;
      gCountErr := gCountErr + 1 ;
      WriteLn( F, 'Thread : ' + fId + ' error : get ' + fURL );
      Flush( F ) ;
      Sleep( 30000 ) ; // ожидаем 30 секунд перед следующей попыткой...
      // P.S. По идее, надо бы посмотреть чо за ошибка...
     End ;
    Except
     // Ошибка при создании idhttp...
      WriteLn( F, 'Thread : ' + fId + ' error : create' );
      Flush( F ) ;

     lHttp.Free ;
     lStatus := 3 ;
     SetStatus( 3 ) ;
     gCountErr := gCountErr + 1 ;
     Sleep( 30000 ) ; // ожидаем 30 секунд перед следующей попыткой...
    End ;
   End ;
 End;

End.

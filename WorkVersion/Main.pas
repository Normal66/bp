Unit Main;    // РАБОТАЕТ!!! Осталось почистить лишнее и корректно выходить
// Обработать ситуацию, при которой в qery.txt будут слова разделенные пробелом

Interface

Uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ExtActns, ShellAPI, ComCtrls, RXShell, Menus,
  Buttons, RXCtrls, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP, IdBaseComponent, IdCookieManager,
  IdAntiFreezeBase, IdAntiFreeze, SyncObjs;

Type
  TfmMain = Class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    GroupBox1: TGroupBox;
    edAppID: TEdit;
    stGetID: TStaticText;
    GroupBox2: TGroupBox;
    Image1: TImage;
    StaticText1: TStaticText;
    stQuery: TStaticText;
    stTLDs: TStaticText;
    ComboBox1: TComboBox;
    stOpenResult: TStaticText;
    GroupBox3: TGroupBox;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    RadioGroup2: TRadioGroup;
    stMain: TStatusBar;
    Panel5: TPanel;
    RxTrayIcon1: TRxTrayIcon;
    pmTray: TPopupMenu;
    Restore1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    Panel7: TPanel;
    bbStart: TSpeedButton;
    bbPause: TSpeedButton;
    bbStop: TSpeedButton;
    stStart: TRxLabel;
    stPause: TRxLabel;
    stStop: TRxLabel;
    RxLabel4: TRxLabel;
    pbMain: TProgressBar;
    Label1: TLabel;
    stQueryCnt: TRxLabel;
    Label2: TLabel;
    stTldCnt: TRxLabel;
    mmMain: TMainMenu;
    mmOptions: TMenuItem;
    mmAddons: TMenuItem;
    mmHelp: TMenuItem;
    mmOptionsMulti: TMenuItem;
    mmLinkExtr: TMenuItem;
    mmExit: TMenuItem;
    Label3: TLabel;
    Label4: TLabel;
    edFileName: TEdit;
    IdCookieManager1: TIdCookieManager;
    Label5: TLabel;
    stAllRunning: TStaticText;
    Label6: TLabel;
    Label7: TLabel;
    stCntDone: TStaticText;
    stCntErr: TStaticText;
    Label8: TLabel;
    stAllThread: TStaticText;
    Label9: TLabel;
    stWhatDo: TStaticText;
    Label10: TLabel;
    StaticText2: TStaticText;
    IdAntiFreeze1: TIdAntiFreeze;
    IdHTTP1: TIdHTTP;
    Label11: TLabel;
    StaticText3: TStaticText;
    ProxyChecker1: TMenuItem;
    Procedure stGetIDClick(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure StaticText1Click(Sender: TObject);
    Procedure stQueryClick(Sender: TObject);
    Procedure stOpenResultClick(Sender: TObject);
    Procedure CheckBox2Click(Sender: TObject);
    Procedure Exit1Click(Sender: TObject);
    Procedure mmOptionsMultiClick(Sender: TObject);
    Procedure RadioGroup2Click(Sender: TObject);
    Procedure CheckBox1Click(Sender: TObject);
    Procedure CheckBox3Click(Sender: TObject);
    Procedure bbStartClick(Sender: TObject);
    Procedure RxTrayIcon1DblClick(Sender: TObject);
    Procedure MinimizeClick(Sender: TObject);
    Procedure mmExitClick(Sender: TObject);
    Procedure bbPauseClick(Sender: TObject);
    Procedure bbStopClick(Sender: TObject);
    Procedure OnEmpty( Sender : TObject ) ;
    Procedure edAppIDExit(Sender: TObject);
    procedure ProxyChecker1Click(Sender: TObject);
    procedure mmLinkExtrClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  Private
    { Private declarations }
  Public
    { Public declarations }
   Procedure Show_Result ;
  End;

Var
  fmMain: TfmMain;
  CriticalSection: TCriticalSection;

Implementation

uses QueryEdit, TldEdit, Common, MultiSet, GlobVar, Work;

{$R *.dfm}

Procedure Show_Proxy( AppHandle : THandle ) ; StdCall ; External 'proxy.dll' name 'Show_Proxy' ;
Procedure Show_Link( AppHandle : THandle ) ; StdCall; External 'link.dll' name 'Show_Link';
Procedure Close_Link ; StdCall ; External 'link.dll' name 'Close_Link' ;
Procedure Link_Count_Thread( Const sEnable : Integer ) ; StdCall ; External 'link.dll' name 'Link_Count_Thread' ;

Procedure TfmMain.OnEmpty(Sender : TObject);
// Вызывается, когда все потоки отработали
 Begin
  // Тут очищаем, все, что запускали...
 End ;

//Обработчик кнопки "Свернуть"
Procedure TfmMain.MinimizeClick(Sender: TObject);
 Begin
  //Прячем основное окно
  Hide;
  //Прячем кнопку на таскбаре
  If IsWindowVisible(Application.Handle)
   Then ShowWindow(Application.Handle, SW_HIDE);
 End;

Procedure TfmMain.stGetIDClick(Sender: TObject);
 Begin
  ShellExecute(Application.Handle, 'open', 'http://developer.yahoo.com/search/boss/', '', '', SW_SHOW);
 End;

Procedure TfmMain.FormCreate(Sender: TObject);
 Var
  SR:TSearchRec; // поисковая переменная
  FindRes:Integer; // переменная для записи результата поиска
 Begin
  Application.OnMinimize:= MinimizeClick;
  // Заполняем комбо списком файлов
  GlobalSetting := TGlobalSetting.Create( NIL ) ;
  ComboBox1.Clear ; // очистка компонента перед занесением в него списка файлов
  FindRes:=FindFirst(GetCurrentDir+'\settings\tld*.txt',faAnyFile,SR); // задание условий поиска и начало поиска
  While FindRes=0 do // пока мы находим файлы (каталоги), то выполнять цикл
   Begin
    ComboBox1.Items.Add(SR.Name); // добавление в список название найденного элемента
    FindRes:=FindNext(SR); // продолжение поиска по заданным условиям
   End;
  FindClose(SR); // закрываем поиск
  CriticalSection := TCriticalSection.Create;

  If GlobalSetting.WebSearch
   Then RadioGroup2.ItemIndex := 0
   Else RadioGroup2.ItemIndex := 1 ;
  If GlobalSetting.FilterDublicate
   Then CheckBox1.Checked := True ;
  If GlobalSetting.CompileAll
   Then CheckBox2.Checked := True ;
  If GlobalSetting.DontExtract
   Then CheckBox3.Checked := True ;

 End;

Procedure TfmMain.StaticText1Click(Sender: TObject);
 Begin
  With TfmQueryEdit.Create( NIL ) Do
   Try
    LoadQuery ;
    ShowModal ;
   Finally
    Free ;
   End ;
 End;

Procedure TfmMain.stQueryClick(Sender: TObject);
 Begin
  With TfmTldEdit.Create( NIL ) Do
   Try
    LoadTld ;
    ShowModal ;
   Finally
    Free ;
   End ;
 End;

Procedure TfmMain.stOpenResultClick(Sender: TObject);
 Begin
  ShellExecute(Application.Handle, 'explore', PChar(GetCurrentDir+'\results'), nil, nil, SW_SHOWNORMAL);
 End;

Procedure TfmMain.CheckBox2Click(Sender: TObject);
 Begin
  If Not CheckBox2.Checked
   Then Begin
    edFileName.Text := '' ; edFileName.Enabled := False ;
   End
   Else edFileName.Enabled := True ;
  If CheckBox2.Checked
   Then GlobalSetting.CompileAll := True
   Else GlobalSetting.CompileAll := False ;
 End;

Procedure TfmMain.Exit1Click(Sender: TObject);
 Begin
  GlobalSetting.Free ;
  CriticalSection.Free ;
  Application.Terminate ;
 End;

Procedure TfmMain.mmOptionsMultiClick(Sender: TObject);
 Begin
  With TfmMultiSet.Create( NIL ) Do
   Try
    slBP.Value := GlobalSetting.CurrentMultiThreadingBackLinks ;
    slLE.Value := GlobalSetting.CurrentMultiThreadingLinkExtractor ;
    edBP.Value := GlobalSetting.CurrentMultiThreadingBackLinks ;
    edLE.Value := GlobalSetting.CurrentMultiThreadingLinkExtractor ;
    ShowModal ;
   Finally
    Free ;
   End ;
  Application.ProcessMessages ;
 End;

Procedure TfmMain.RadioGroup2Click(Sender: TObject);
 Begin
  If RadioGroup2.ItemIndex = 0
   Then Begin GlobalSetting.WebSearch := True ; GlobalSetting.SiteExplorer := False ; End
   Else Begin GlobalSetting.SiteExplorer := True ; GlobalSetting.WebSearch := False ; End ;
 End;

Procedure TfmMain.CheckBox1Click(Sender: TObject);
 Begin
  If CheckBox1.Checked
   Then GlobalSetting.FilterDublicate := True
   Else GlobalSetting.FilterDublicate := False ;
 End;

Procedure TfmMain.CheckBox3Click(Sender: TObject);
 Begin
  If CheckBox3.Checked
   Then GlobalSetting.DontExtract := True
   Else GlobalSetting.DontExtract := False ;
 End;

Procedure TfmMain.bbStartClick(Sender: TObject);
 Var
  I , J : Integer ;
  NewTh : TWork ;
  aHandle : Integer ;
  lList : TList ;
  A, B : String ;
  tErrRec : PErrRec ;
 Begin
  GlobalSetting.CheckFirst ;
  If ComboBox1.Text = ''
   Then Begin
    ShowMessage('Select TLD File in dropdown list!');
    ComboBox1.SetFocus ;
   End Else Begin
    bCntRun  := 0 ;
    bCntAll  := 0 ;
    bCntDone := 0 ;
    bCntErr  := 0 ;
    bCntPars := 0 ;
    bCntHits := 0 ;
    bPause   := False ;
    bStopped := False ;
    SetGlobVar ;
    //------------------------------------------------------------------------//
    bbStart.Enabled := False ;
    bbPause.Enabled := True ;
    bbStop.Enabled := True ;
    stStart.Caption := 'IN WORK...' ;
    LoadQuery ;
    LoadTld( ComboBox1.Text ) ;
    stQueryCnt.Caption := IntToStr( mQueryTxt.Count ) ;
    stTldCnt.Caption := IntToStr( mTldTxt.Count ) ;
    stMain.Panels.Items[0].Text := 'Status: Parsing process' ;
    MakeWebSearch ;
    stMain.Panels.Items[1].Text := 'Source URL: '+IntToStr(WebSearchURL.Count);

   For I := 0 To WebSearchURL.Count - 1 Do
     Begin
      If bStopped
       Then
        Break ;
      fmMain.stWhatDo.Caption := 'Creating base thread N : ' + IntToStr( I ) ;
      Show_Result ;
// Тут возникает коллизия
      While bCntRun > GlobalSetting.CurrentMultiThreadingBackLinks Do
       Begin
        Show_Result ;
        If bStopped
         Then Exit ;
       End ;

      NewTh := TWork.Create(True);
      NewTh.fURL := WebSearchURL.Strings[I] ;
      NewTh.fSrc := WebSearchSRC.Strings[I] ;
     End ;
    fmMain.stWhatDo.Caption := 'Parsing in processed...' ;
    While bCntDone <> bCntAll Do
     Begin
      Show_Result ;
      If bStopped
       Then Exit ;
     End ;
    // Обработка ошибочных парсеров
    fmMain.stWhatDo.Caption := 'Обработка ошибок...' ;
    J := PErrBP.lList.Count ;
    While (bCntErr <> 0) Or( bCntRun <> 0 ) Or (J <> 0) Do Begin
     While bCntRun > GlobalSetting.CurrentMultiThreadingBackLinks Do
      Begin
       Show_Result ;
       If bStopped
        Then Exit ;
      End ;
     If (bCntErr <> 0) And (J <> 0) Then Begin
      wErrRec := PErrBP.lList.Items[0] ;
      A := wErrRec^.fURL ; B := wErrRec^.fSrc ;
      Dispose( wErrRec ) ;
      PErrBP.lList.Delete(0);
      Dec(bCntErr) ;
      NewTh := TWork.Create(True);
      NewTh.fURL := A ;
      NewTh.fSrc := B ;
     End ;
     Show_Result ;
     Sleep(50) ;
     J := PErrBP.lList.Count  ;
    End ;
    bbStart.Enabled := True ;
    CloseFile( F ) ;
    stMain.Panels[0].Text := 'Status: Writing results...' ;
    fmMain.stWhatDo.Caption := 'Запись результатов...' ;
    bCntRun  := 0 ;
    bCntAll  := 0 ;
    bCntDone := 0 ;
    bCntErr  := 0 ;
    bCntHits := 0 ;
    Show_Result ;
    If Not bStopped
     Then TestParsing ;
    stStart.Caption := 'Done.' ;
    stMain.Panels[0].Text := 'Status: Done parsing' ;
    fmMain.stWhatDo.Caption := 'Done parsing...' ;
   End ;
 End;

Procedure TfmMain.RxTrayIcon1DblClick(Sender: TObject);
 Begin
  //разворачиваем главное окно
  Application.Restore;
  //сбрасываем признак сворачивания
  if WindowState = wsMinimized then WindowState := wsNormal;
  //Отображаем окно
  visible:=true;
  //Принудительно устанавливаем окно поверх остальных
  SetForegroundWindow(Application.Handle);
 End;

Procedure TfmMain.mmExitClick(Sender: TObject);
 Begin
  GlobalSetting.Free ;
//  ClrGlobVar ;
  Close_Link ;
  Application.Terminate ;
 End;

Procedure TfmMain.bbPauseClick(Sender: TObject);
 Var
  I, J : Integer ;

 Begin
//  vCurrentStatus := 1 ;        List := gThreadManager.ActiveThreadList ;
  If bbPause.Caption = 'PAUSE'
   Then Begin
    fmMain.stWhatDo.Caption := 'Thread paused...' ;
    bPause := True ;
    bbPause.Caption := 'RESUME' ;
    stPause.Caption := 'Paused...' ;
     Try
      CriticalSection.Enter;
      I := 0 ;
      With gGlobal.gListThread.LockList Do
       Try
        J := Count - 1 ;
        While I <> J Do Begin
         PWork := TWork( Items[I] ) ;
         If PWork <> NIL
          Then
           PWork.Suspend ;
         Inc( I ) ;
        End ;
       Finally
        gGlobal.gListThread.UnlockList ;
       End;
     Finally
      CriticalSection.Leave ;
     End ;
   End
   Else Begin
     fmMain.stWhatDo.Caption := 'Thread unpaused...' ;
     bPause := False ;
     bbPause.Caption := 'PAUSE' ;
     stPause.Caption := 'Available...' ;
     fmMain.stWhatDo.Caption := 'Thread unpaused... Wait for 10 sec...' ;
     bbStart.Enabled := False ; bbPause.Enabled := False ; bbStop.Enabled := False ;
     For I := 0 To 9 Do
      Begin
       fmMain.stWhatDo.Caption := 'Thread unpaused... Wait for ' + IntToStr( 9 - I ) + ' sec...' ;
       Sleep(1000) ;
       Application.ProcessMessages ;
      End ;
     Try
      CriticalSection.Enter;
      I := 0 ;
      With gGlobal.gListThread.LockList Do
       Try
        J := Count - 1 ;
        While I <> J Do Begin
         PWork := TWork( Items[I] ) ;
         If PWork <> NIL
          Then
           PWork.Resume ;
         Inc( I ) ;
        End ;   
       Finally
        gGlobal.gListThread.UnlockList ;
       End;
     Finally
      CriticalSection.Leave ;
     End ;  
     bbStart.Enabled := False ; bbPause.Enabled := True ; bbStop.Enabled := True ;
   End ;

 End;

Procedure TfmMain.bbStopClick(Sender: TObject);
 Var
  I, J : Integer ;
 Begin
  fmMain.stWhatDo.Caption := 'Thread stopped...' ;
  bStopped := True ;
//  I := GlobalSetting.CurrentMultiThreadingBackLinks ;
//  GlobalSetting.CurrentMultiThreadingBackLinks := 0 ;
  fmMain.stWhatDo.Caption := 'Wait for all stopped...' ;
Show_Result ;
   Application.ProcessMessages ;

     Try
      CriticalSection.Enter;
      I := 0 ;
      With gGlobal.gListThread.LockList Do
       Try
        J := Count - 1 ;
        While I <> J Do Begin
         PWork := TWork( Items[I] ) ;
         If PWork <> NIL
          Then
           PWork.Terminate ;
         Inc( I ) ;
  Application.ProcessMessages ;
Show_Result ;  
        End ;
       Finally
        gGlobal.gListThread.UnlockList ;
       End;
     Finally
      CriticalSection.Leave ;
     End ;
     bbStart.Enabled := True ; bbPause.Enabled := True ; bbStop.Enabled := True ;
//  Sleep(10000) ;
  bCntRun  := 0 ;
  bCntAll  := 0 ;
  bCntDone := 0 ;
  bCntErr  := 0 ;
  bCntHits := 0 ;
  Show_Result ;
  stStop.Caption := 'Stopped' ;
  bbStop.Enabled := False ;
  bbPause.Enabled := False ;
  bbStart.Enabled := True ;
  stStart.Caption := 'Available' ;
  // Уничтожение запущенных потоков
  Application.ProcessMessages ;
 End;

Procedure TfmMain.edAppIDExit(Sender: TObject);
 Begin
  If edAppID.Text = ''
   Then Begin
    ShowMessage('Enter you ID APP key!');
    edAppID.SetFocus ;
   End
   Else Begin
    GlobalSetting.vAppID := edAppID.Text ;
    GlobalSetting.SaveSettings ;
    GlobalSetting.LoadSettings ;
   End ;
 End;

Procedure TfmMain.Show_Result ;
 Begin
  Application.ProcessMessages ;
//  stAllRunning.Caption := IntToStr( bCntRun ) ;
  stAllRunning.Caption := IntToStr(gGlobal.gListThread.LockList.Count) ;
  gGlobal.gListThread.UnlockList ;
  stCntDone.Caption := IntToStr( bCntDone ) ;
  stCntErr.Caption := IntToStr( bCntErr ) ;
  stAllThread.Caption := IntToStr( bCntAll ) ;
  StaticText2.Caption := IntToStr( bCntPars ) ;
  StaticText3.Caption := IntToStr( bCntHits ) ;
 End ;

Procedure TfmMain.ProxyChecker1Click(Sender: TObject);
 Begin
  Show_Proxy( Application.Handle ) ;
 End;

Procedure TfmMain.mmLinkExtrClick(Sender: TObject);
 Begin
  Link_Count_Thread( GlobalSetting.CurrentMultiThreadingLinkExtractor ) ;
  Show_Link( Application.Handle ) ;
 End;

Procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
 Begin
  Close_Link ;
  GlobalSetting.Free ;  
 End;

End.

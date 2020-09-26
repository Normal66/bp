Unit LinkMain;

Interface

Uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, RXCtrls, HTMLParser, ComCtrls, SyncObjs;

Type
  TfmLinkMain = Class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Panel1: TPanel;
    Label1: TLabel;
    edURL: TEdit;
    cb1: TCheckBox;
    cb2: TCheckBox;
    Memo1: TMemo;
    cb3: TCheckBox;
    Memo2: TMemo;
    cb4: TCheckBox;
    stOpen: TRxLabel;
    bbStart: TButton;
    bbExit: TButton;
    GroupBox3: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    stTotal: TStaticText;
    Label5: TLabel;
    stWhat: TStaticText;
    rgWhere: TRadioGroup;
    Label2: TLabel;
    stRunning: TStaticText;
    cb5: TCheckBox;
    stError: TStaticText;
    Label6: TLabel;
    stAll: TStaticText;
    bbPause: TButton;
    bbStop: TButton;
    Label7: TLabel;
    stDone: TStaticText;
    Procedure FormCreate(Sender: TObject);
    Procedure FormClose(Sender: TObject; var Action: TCloseAction);
    Procedure edURLExit(Sender: TObject);
    Procedure cb4Click(Sender: TObject);
    Procedure bbStartClick(Sender: TObject);
    Procedure bbExitClick(Sender: TObject);
    Procedure cb1Exit(Sender: TObject);
    Procedure cb2Exit(Sender: TObject);
    Procedure cb3Exit(Sender: TObject);
    Procedure cb4Exit(Sender: TObject);
    Procedure rgWhereClick(Sender: TObject);
    Procedure cb5Click(Sender: TObject);
  Private
    { Private declarations }
   Procedure Do_Result ;
   Procedure Do_Parse( sUrl : String ) ;
   Procedure Show_Result ;
  Public
    { Public declarations }
   lDst  : TStringList ;
   LocalURL : TStringList ;
   InterURL : TStringList ;
  End;

Var
  fmLinkMain: TfmLinkMain;
  CriticalSection: TCriticalSection;
   lUrl  : String ;

Implementation

{$R *.dfm}

Uses Registry , LinkWork, HttpSend, StrUtils, BPThread, UrlParser;
//----------------------------------------------------------------------------//
Procedure TfmLinkMain.Show_Result ;
 Begin
   stTotal.Caption := IntToStr( Count_Total ) ;
   stRunning.Caption := IntToStr( vBPListThread.FCountRun ) ;
   stError.Caption := IntToStr( vBPError.CntRec ) ;
   stAll.Caption := IntToStr( vBPListThread.FCountAll ) ;
   stDone.Caption := IntToStr( vBPListThread.FCountDone ) ;
   Application.ProcessMessages ;
 End ;
{------------------------------------------------------------------------------}
Function  StreamToString( aStream : TStream ) : String ;
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
{------------------------------------------------------------------------------}
Procedure TfmLinkMain.Do_Parse( sUrl : String ) ; // Рекурсивная!!!
 Var
  tRes   : Boolean ;
  lHttp  : THttpSend ;
  I      : Integer ;
  ALink  : TLinkWork ;
  S      : String ;
  lPars  : TCSIParser ;
 Begin
   lHttp := THttpSend.Create ;
   tRes  := lHttp.HTTPMethod( 'GET', sUrl ) ;
   If tRes And (lHttp.ResultCode = 200)
    Then Begin
     S := StreamToString( lHttp.Document ) ;
     lHttp.Free ;
     lPars := TCSIParser.Create( Application );
     lPars.FUrl := lUrl ;
     lPars.FSrc := S ;

     lPars.Execute ;
     List_InterURL.AddStrings( lPars.FInterURL );
     List_LocalURL.AddStrings( lPars.FLocal );
     List_LocalURL.SaveToFile(GetCurrentDir+'\debug\prepare.txt');
     lPars.Free ;
     Count_Total := List_InterURL.Count + List_LocalURL.Count ;
     If lSite    // Парсим со всех внутренних страниц
      Then Begin
       Application.ProcessMessages ;
       For I := 0 To List_LocalURL.Count - 1 Do Begin
         // Создаем потоки...
         ALink := TLinkWork.Create( True );
         ALink.lwUrl := List_LocalURL.Strings[I] ;
         ALink.Priority := tpLower; 
//         Show_Result ;
       End ; // For
      End ; // If
    End  ; // If
 End ;
{------------------------------------------------------------------------------}
Procedure TfmLinkMain.Do_Result ;
 Var
  I, J : Integer ;
  lTmp : TStringList ;
  sTmp : String ;
  sRes : String ;
  R    : Boolean ;
 Begin
  // Обработка результатов. Результаты - в lDst
  lTmp := TStringList.Create ;
  If cb1.Checked
   Then Begin // Удаляем ТОЧНЫЕ совпадения!
    lTmp.Sorted := True ;
    lTmp.Duplicates := dupIgnore ;
    For I := 0 To List_InterURL.Count - 1 Do
     Begin
      sTmp := List_InterURL.Strings[I] ;
      lTmp.Add( sTmp ) ;
     End ;
    List_InterURL.Clear ; List_InterURL.AddStrings( lTmp ); lTmp.Clear ;
   End ;

  If cb2.Checked
   Then Begin
    For I := 0 To List_InterURL.Count - 1 Do
     Begin
      sTmp := List_InterURL.Strings[I] ;
      R := False ;
      For J := 0 To Memo1.Lines.Count - 1 Do Begin
       sRes := Memo1.Lines.Strings[J] ;
       If Pos( sRes, sTmp ) <> 0
        Then R := True ;
      End ;
      If Not R
       Then lTmp.Add( sTmp ) ;
     End ;
    List_InterURL.Clear ; List_InterURL.AddStrings( lTmp ); lTmp.Clear ;
   End ;

  If cb5.Checked
   Then Begin
    lTmp.Sorted := True ;
    lTmp.Duplicates := dupAccept ;
    For I := 0 To LocalURL.Count - 1 Do
     Begin
      sTmp := LocalURL.Strings[I] ;
      lTmp.Add( sTmp ) ;
     End ;
    LocalURL.Clear ; LocalURL.AddStrings( lTmp ); lTmp.Clear ;
   End ;
   
  If cb4.Checked
   Then Begin
    List_InterURL.SaveToFile(GetCurrentDir+'\settings\query.txt');
   End ;
  If cb5.Checked
   Then List_LocalURL.SaveToFile(GetCurrentDir+'\Addons\Link Extractor\results\'+lFile)
   Else List_InterURL.SaveToFile(GetCurrentDir+'\Addons\Link Extractor\results\'+lFile);
   Count_Total := List_InterURL.Count ;
   stTotal.Caption := IntToStr( Count_Total ) ;
 End ;
{------------------------------------------------------------------------------}
Procedure TfmLinkMain.edURLExit(Sender: TObject);
 Begin
  If edURL.Text = ''
   Then Begin
    ShowMessage('Enter URL!') ;
    edURL.SetFocus ;
   End
   Else Begin
    lUrl := edURL.Text ;

    If Pos('http://', lUrl) = 0
     Then Begin
      lUrl := 'http://' + lUrl ;
     End ;

    If Pos( 'http://', lUrl ) <> 0
     Then lFile := Copy( lUrl, 8, Length( lUrl ) - 7 )
     Else lFile := lUrl ;
    If Pos('/', lFile ) <> 0
     Then lFile := Copy( lFile, 1, Pos('/', lFile )-1) ;
    lFile := lFile + '.txt' ;

   End ;
 End;
{------------------------------------------------------------------------------}
Procedure TfmLinkMain.cb4Click(Sender: TObject);
 Begin
  lSave := cb4.Checked ;
 End;
{------------------------------------------------------------------------------}
Procedure TfmLinkMain.bbStartClick(Sender: TObject);
 Begin
  List_LocalURL.Clear ; List_InterURL.Clear ;
  stWhat.Caption := 'Start parsing...' ;
  Do_Parse( lUrl ) ;
  stWhat.Caption := 'Parsing in process...' ;
  CheckSynchronize ;
  While Not vBPListThread.CheckList Do Begin
   CheckSynchronize ;
   Show_Result ;
   Application.ProcessMessages ;
  End ;
  stWhat.Caption := 'Write result"s' ;
  Do_Result ;
  stWhat.Caption := 'Done...' ;
 End;
{------------------------------------------------------------------------------}
Procedure TfmLinkMain.bbExitClick(Sender: TObject);
 Begin
  Close ;
 End;
{------------------------------------------------------------------------------}
Procedure TfmLinkMain.cb1Exit(Sender: TObject);
 Begin
  lDub := cb1.Checked ;
 End;
{------------------------------------------------------------------------------}
Procedure TfmLinkMain.cb2Exit(Sender: TObject);
 Begin
  lWord := cb2.Checked ;
 End;
{------------------------------------------------------------------------------}
Procedure TfmLinkMain.cb3Exit(Sender: TObject);
 Begin
  lText := cb3.Checked ;
 End;
{------------------------------------------------------------------------------}
Procedure TfmLinkMain.cb4Exit(Sender: TObject);
 Begin
  lSave := cb4.Checked ;
 End;
{------------------------------------------------------------------------------}
Procedure TfmLinkMain.rgWhereClick(Sender: TObject);
 Begin
  If rgWhere.ItemIndex = 0
   Then Begin lPage := True ; lSite := False ; End
   Else Begin lPage := False ; lSite := True ; End ;
 End;
{------------------------------------------------------------------------------}
Procedure TfmLinkMain.cb5Click(Sender: TObject);
 Begin
  If cb5.Checked
   Then lInnr := True
   Else lInnr := False ;
 End;
{------------------------------------------------------------------------------}
Procedure TfmLinkMain.FormCreate(Sender: TObject);
 Var
  RegFile : TRegIniFile ;
 Begin
  RegFile := TRegIniFile.Create('Software\BPCSI');
  lPage := RegFile.ReadBool('Link', 'Page', True);
  lSite := RegFile.ReadBool('Link', 'Site', False);
  lDub  := RegFile.ReadBool('Link', 'Dub', False);
  lWord := RegFile.ReadBool('Link', 'Word', False);
  lText := RegFile.ReadBool('Link', 'Text', False);
  lSave := RegFile.ReadBool('Link', 'Save', False);
  lInnr := RegFile.ReadBool('Link', 'Innr', False);
  lCntT := RegFile.ReadInteger('Common', 'mtLE', 5) ;
  edURL.Text := RegFile.ReadString('Link','URL', '' ) ;
  RegFile.Free ;
  If lPage
   Then rgWhere.ItemIndex := 0
   Else rgWhere.ItemIndex := 1 ;
  cb1.Checked := lDub ;
  cb2.Checked := lWord ;
  cb3.Checked := lText ;
  cb4.Checked := lSave ;
  cb5.Checked := lInnr ;
  lDst := TStringList.Create ;
  List_LocalURL := TStringList.Create ;
  List_LocalURL.Duplicates := dupIgnore ;
  List_LocalURL.Sorted := True ;
  List_InterURL := TStringList.Create ;
  LocalURL := TStringList.Create ;
  LocalURL.Duplicates := dupIgnore ;
  LocalURL.CaseSensitive := False ;
  LocalURL.Sorted := True ;
  InterURL := TStringList.Create ;
  CriticalSection := TCriticalSection.Create ;
  If FileExists(GetCurrentDir+'\settings\filter-words.txt')
   Then Memo1.Lines.LoadFromFile(GetCurrentDir+'\settings\filter-words.txt');
  vBPError := TBPError.Create ;
  vBPListThread := TBPListThread.Create ;
  vBPListThread.FCountEnab := Enable_Count_Thread ;
 End;
{------------------------------------------------------------------------------}
Procedure TfmLinkMain.FormClose(Sender: TObject; var Action: TCloseAction);
 Var
  RegFile : TRegIniFile ;
 Begin
  RegFile := TRegIniFile.Create('Software\BPCSI');
  RegFile.WriteBool('Link', 'Page', lPage );
  RegFile.WriteBool('Link', 'Site', lSite );
  RegFile.WriteBool('Link', 'Dub', lDub );
  RegFile.WriteBool('Link', 'Word', lWord );
  RegFile.WriteBool('Link', 'Text', lText );
  RegFile.WriteBool('Link', 'Save', lSave );
  RegFile.WriteBool('Link', 'Innr', lInnr );
  RegFile.WriteString('Link', 'URL', edURL.Text );
  RegFile.Free ;
  lDst.Free ;
  List_LocalURL.Free ;
  List_InterURL.Free ;
  LocalURL.Free ;
  InterURL.Free ;
  CriticalSection.Free ;
  Memo1.Lines.SaveToFile(GetCurrentDir+'\settings\filter-words.txt');
  vBPError.Free ;
  vBPListThread.Free ;
 End;

End.

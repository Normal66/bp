////////////////////////////////////////////////////////////////////////////////
// Jazarsoft HTMLParser Component                                             //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// VERSION      : 1.3                                                         //
// AUTHOR       : James Azarja                                                //
// CREATED      : 11 November 2000                                            //
// MODIFIED     : 26 April 2001                                               //
// WEBSITE      : http://www.jazarsoft.com/                                   //
// SUPPORT      : support@jazarsoft.com                                       //
// BUG-REPORT   : bugreport@jazarsoft.com                                     //
// COMMENT      : comment@jazarsoft.com                                       //
// LEGAL        : Copyright (C) 2000-2001 Jazarsoft.                          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// This code may be used and modified by anyone so long as  this header and   //
// copyright  information remains intact.                                     //
//                                                                            //
// The code is provided "as-is" and without warranty of any kind,             //
// expressed, implied or otherwise, including and without limitation, any     //
// warranty of merchantability or fitness for a  particular purpose.          //
//                                                                            //
// In no event shall the author be liable for any special, incidental,        //
// indirect or consequential damages whatsoever (including, without           //
// limitation, damages for loss of profits, business interruption, loss       //
// of information, or any other loss), whether or not advised of the          //
// possibility of damage, and on any theory of liability, arising out of      //
// or in connection with the use or inability to use this software.           //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// HISTORY :                                                                  //
////////////////////////////////////////////////////////////////////////////////
// 1.0, November 2000                                                         //
//      - Initial Development                                                 //
// 1.1, January 2001                                                          //
//      + FoundComment Event                                                  //
//      # Comment not ignored anymore (thanks to M.E.a.H. <MEaH@gmx.de> )     //
// 1.2, March 2001                                                            //
//      + ASP, PHP, PERL hyperlink detection                                  //
// 1.3, April 2001							      //
//      - Fixed ">" bug							      // 
////////////////////////////////////////////////////////////////////////////////

unit HTMLParser;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs;

type
  TOnFoundHyperlink   = procedure(Sender: TObject;Hyperlink:String) of object;
  TOnFoundTag         = procedure(Sender: TObject;Tag:String) of object;
  TOnFoundText        = procedure(Sender: TObject;Text:String) of object;
  TOnFoundComment     = procedure(Sender: TObject;Comment:String) of object;
  TOnParsing          = procedure(Sender: TObject;Lines,Total:Integer) of object;
  
  TLocalRemote  = Class(TPersistent)
  private
    FLocal      : tStrings;
    FRemote     : tStrings;
  protected
  public
   constructor Create;
   destructor Destroy;override;
  published
   property Local     : tStrings Read FLocal  Write FLocal;
   property Remote    : tStrings Read FRemote Write FRemote;
  end;

  TParsed = Class(TPersistent)
  private
    FHyperlinks : tStrings; { All Related Document, Local+Remote }
    FImages     : tStrings; { Document in <IMG SRC=...}
    FEmails     : tStrings; { Anchors <A.. with "mailto:"  }
    FHTTPLinks  : tStrings; { Anchors <A.. with "http:"  }
    FFTPLinks   : tStrings; { Anchors <A.. with "ftp:"  }
    FLocalLinks : tStrings; { Anchors <A.. with no protocol }
    FFramePages : tStrings; { <FRAME SRC=... }

    { .. by extension.. }    
    FHTML       : tLocalRemote;  { *.HTM,*.HTML,*.SHTML,*.DHTML }
    FImage      : tLocalRemote;  { *.JPEG, *.GIF, *.TIF .. }
    FMedia      : tLocalRemote;  { *.AVI, *.MP3, *.MPEG ... }
    FJava       : tLocalRemote;  { *.JAVA, *.CLASS, *.JS }
    FActiveX    : tLocalRemote;  { *.CAB .. }
    FASP        : tLocalRemote;  { *.ASP }
    FPHP        : tLocalRemote;  { *.PHP, *.PHP3 ... }
    FPERL       : tLocalRemote;  { *.PL, *.CGI.. }

    FTitle      : String;        { <TITLE>...</TITLE> }
    FKeyword    : String;        { <META NAME="KEYWORD" ... }
    FDescription: String;        { <META NAME="DESCRIPTION" ... }
  protected
  public
   constructor Create;
   destructor Destroy;override;
  published
   property Title      : String   Read FTitle Write FTitle;
   property Keyword    : String   Read FKeyWord Write FKeyword;
   property Description: String   Read FDescription Write FDescription;
   
   property HTML       : tLocalRemote Read FHTML Write FHTML;
   property Image      : tLocalRemote Read FImage Write FImage;
   property Media      : tLocalRemote Read FMedia Write FMedia;
   property Java       : tLocalRemote Read FJava   Write FJava;
   property ActiveX    : tLocalRemote Read FActiveX Write FActiveX;
   property ASP        : tLocalRemote Read FASP    Write FASP;
   property PHP        : tLocalRemote Read FPHP    Write FPHP;
   property PERL       : tLocalRemote Read FPERL   Write FPERL;

   property Hyperlinks : tStrings Read FHyperlinks Write FHyperlinks;
   property Images     : tStrings Read FImages Write FImages;
   property EMails     : tStrings Read FEmails Write FEmails;
   property HTTPlinks  : tStrings Read FHTTPlinks Write FHTTPlinks;
   property FTPlinks   : tStrings Read FFTPlinks Write FFTPlinks;
   property Locallinks : tStrings Read FLocallinks Write FLocallinks;
   property FramePages : tStrings Read FFramePages Write FFramePages;
  end;

  THTMLParser = class(TComponent)
  private
    FRaw        : tStrings;
    FParsed     : tParsed;

    { Events }
    FOnParsing          : TOnParsing;
    FOnFoundHyperlink   : TOnFoundHyperlink;
    FOnFoundTag         : TOnFoundTag;
    FOnFoundText        : TOnFoundText;
    FOnFoundComment     : TOnFoundComment;

    FParsedLines        : Integer;
    FCurrentLine        : Integer;
    FTotalLines         : Integer;

    Procedure SetRaw(Value:tStrings);
  protected
    Buffering   : Boolean;
    Buffer      : String;
    BufferingTT : String; { Tag }

    Procedure   AddTag(Tag:String);
    Procedure   AddText(Text:String);
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    Procedure   Execute;

    property ParsedLines: Integer  Read FParsedLines;
    property TotalLines : Integer  Read FTotalLines;
    property CurrentLine: Integer  Read FCurrentLine;
  published
    property    HTML   : tStrings Read FRaw Write SetRaw;
    property    Parsed : tParsed  Read FParsed Write FParsed;

    property    OnFoundComment     : tOnFoundComment   Read FOnFoundComment   Write FOnFoundComment;
    property    OnFoundHyperlink   : tOnFoundHyperLink Read FOnFoundHyperLink Write FOnFoundHyperLink;
    property    OnFoundTag         : tOnFoundTag       Read FOnFoundTag       Write FOnFoundTag;
    property    OnFoundText        : tOnFoundText      Read FOnFoundText      Write FOnFoundText;     
    property    OnParsing          : tOnParsing Read FOnParsing Write FOnParsing;
  end;

procedure Register;

implementation


Procedure ParseURL(Const URL:String;var Protocol,Server,Script,Variable:String);
Var S:String;
Begin
 If Url='' then Exit;
 Protocol:='';
 Server:='';

 S:=URL;
 If Pos('://',S)<>0 then
 Begin
  Protocol:=Copy(S,1,Pos('://',S)-1);
  Delete(S,1,Pos('://',S)+2);
 End else
 If Pos('MAILTO:',S)<>0 then 
 Begin
  Protocol:='MAILTO:';
  Delete(S,1,7);
 End else
  Protocol:='http';
 
 While Pos('/',S)<>0 do
 Begin
  Server:=Server+Copy(S,1,Pos('/',S));
  Delete(S,1,Pos('/',S));
 End;

 If Pos('.',S)=0 then
 Begin
  Server:=Server+S;
  If Server[Length(Server)]<>'/' then Server:=Server+'/';
 End else
 Begin
  If Pos('?',S)<>0 then
  begin
   Script:=Copy(S,1,Pos('?',S)-1);
   Delete(S,1,Pos('?',S));
   Variable:=S;
  End else
   Script:=S;
 End;  
End;

Function ExtractQuotedStr(Str:String;Quote:Char):String;
Var StartPos, Index:integer;
Begin
 Result:='';
 StartPos:=Pos(Quote,Str);
 For Index:=StartPos+1 to Length(Str) do
  If Str[Index]<>Quote then
   Result:=Result+Str[Index] else
   Break;
end;

Function GetTagAttribute(Tag,Attribute:String):String;
Var AttrPos, NulPos, Count : Integer;
    UTag, UAttribute : String;
    Quoted : Boolean;
begin
 NulPos:=0;
 Quoted:=False;
 UTag := Uppercase(Tag);
 UAttribute := Uppercase(Attribute);
 AttrPos:=Pos(UAttribute,UTag);
 If AttrPos<>0 then
 Begin
  For Count:=AttrPos to Length(Tag) do
  Begin
   If (Tag[Count]='"') then
   Begin
    If Not Quoted then Quoted:=True else Quoted:=False;
   End;
   If ((Tag[Count]=' ') and Not Quoted) or (Tag[Count]='>') or (Count=Length(tag)) then
    Begin NulPos:=Count; Break; End;
  End;
  Result:=Copy(Tag,AttrPos,NulPos-AttrPos+1);
 End;
End;

Function ExtractValue(Attribute:String):String;
Var Str      : String;
    Count    : Integer;    
    StartPos : Integer;
    Quoted   : Boolean;
Begin
 Result:='';
 Quoted:=False;
 Str:=Attribute;
 StartPos:=Pos('=',Attribute);
 For Count:=StartPos+1 to Length(Attribute) do
 Begin
  If (Attribute[Count]<>'"') or
     (Not Quoted and (Attribute[Count]<>' ')) then
   Result:=Result+Attribute[Count] else
  Begin
   If (Attribute[Count]='"') and not Quoted then
    Quoted:=True else
   Break;
  End;
 End;
 Result:=ExtractQuotedStr(Result,'"');
End;

constructor TLocalRemote.Create;
Begin
  inherited Create;
  FLocal:=tStringList.Create;
  FRemote:=tStringList.Create;
End;

destructor TLocalRemote.Destroy;
Begin
  FLocal.Free;
  FRemote.Free;
  inherited Destroy;
End;


constructor TParsed.Create;
Begin
  inherited Create;
  FHyperlinks:=tStringList.Create;
  FImages:=tStringList.Create;
  FEmails:=tStringList.Create;
  FHTTPLinks:=tStringList.Create;
  FFTPLinks:=tStringList.Create;
  FLocalLinks:=tStringList.Create;
  FFramePages:=tStringList.Create;

  FHTML  := tLocalRemote.Create;
  FImage := tLocalRemote.Create;
  FMedia := tLocalRemote.Create;
  FJava  := tLocalRemote.Create;
  FActiveX := tLocalRemote.Create;
  FPHP   := tLocalRemote.Create;
  FASP   := tLocalRemote.Create;
  FPERL  := tLocalRemote.Create;
End;

destructor TParsed.Destroy;
Begin
  FHTML.Free;
  FImage.Free;
  FMedia.Free;
  FJava.Free;
  FActiveX.Free;
  FPHP.Free;
  FASP.Free;
  FPERL.Free;

  FFramePages.Free;
  FHTTPLinks.Free;
  FFTPLinks.Free;
  FLocalLinks.Free;
  FEmails.Free;
  FHyperlinks.Free;
  FImages.Free;
  inherited Destroy;
End;

Procedure THTMLParser.SetRaw(Value:tStrings);
Begin
 FRaw.Clear;
 FRaw.Assign(Value);
End;

Procedure   THTMLParser.AddTag(Tag:String);
var
 TagName   : String;
 Hyperlink : String;
 UHyperLink: String;
 MetaName,
 MetaContent : String;
 P,S,Sc,Vr:String;
 Ext      : String;
Begin
 If Buffering then
 Begin
  If Pos(Uppercase(BufferingTT),Uppercase(Tag))=0 then
  Begin
   Buffer:=Buffer+'<'+Tag+'>';
   Exit;
  End;
 End;

 { Remove all trailing spaces }
 Trim(Tag);

 If Pos('!--',Tag)=0 then
   If Assigned(FOnFoundTag) then FOnFoundTag(Self,Tag);

 If Pos(' ',Tag)<>0 then
  TagName:=Uppercase(Copy(Tag,1,Pos(' ',Tag)-1)) else
  TagName:=Uppercase(Tag);

 If TagName='A' then { Anchors }
 Begin
  Hyperlink:=ExtractValue(GetTagAttribute(Tag,'href'));
  UHyperlink:=Uppercase(Hyperlink);
  ParseURL(UHyperlink,P,S,Sc,Vr);

  { Extension Check }
  Ext:=ExtractFileExt(SC);
  If Pos('HTM',Ext)<>0 then
  Begin
   If Pos('HTTP://',UHyperlink)<>0 then
    FParsed.FHTML.FRemote.Add(Hyperlink) else
    FParsed.FHTML.FLocal.Add(Hyperlink);
  End else
  if ((Ext='.JPG') or
      (Ext='.JPEG') or
      (Ext='.GIF') or
      (Ext='.TIF') or
      (Ext='.PCX') or
      (Ext='.PNG') or
      (Ext='.ICO') or
      (Ext='.BMP'))
  then
  Begin
   If Pos('HTTP://',UHyperlink)<>0 then
    FParsed.FImage.FRemote.Add(Hyperlink) else
    FParsed.FImage.FLocal.Add(Hyperlink);
  End else
  if ((Ext='.AVI') or
      (Ext='.MP3') or
      (Ext='.AU') or
      (Ext='.MOV') or
      (Ext='.MPG') or
      (Ext='.MPEG'))
  then
  Begin
   If Pos('HTTP://',UHyperlink)<>0 then
    FParsed.FMedia.FRemote.Add(Hyperlink) else
    FParsed.FMedia.FLocal.Add(Hyperlink);
  End else
  if ((Ext='.JS') or
      (Ext='.CLASS') or
      (Ext='.JAVA'))
  then
  Begin
   If Pos('HTTP://',UHyperlink)<>0 then
    FParsed.FJava.FRemote.Add(Hyperlink) else
    FParsed.FJava.FLocal.Add(Hyperlink);
  End else
  if ((Ext='.ASP'))
  then
  Begin
   If Pos('HTTP://',UHyperlink)<>0 then
    FParsed.FASP.FRemote.Add(Hyperlink) else
    FParsed.FASP.FLocal.Add(Hyperlink);
  End else
  if ((Ext='.PL') or
      (Ext='.CGI'))
  then
  Begin
   If Pos('HTTP://',UHyperlink)<>0 then
    FParsed.FPERL.FRemote.Add(Hyperlink) else
    FParsed.FPERL.FLocal.Add(Hyperlink);
  End else
  If Pos('PHP',Ext)<>0
  then
  Begin
   If Pos('HTTP://',UHyperlink)<>0 then
    FParsed.FPHP.FRemote.Add(Hyperlink) else
    FParsed.FPHP.FLocal.Add(Hyperlink);
  End else
  if ((Ext='.CAB'))
  then
  Begin
   If Pos('HTTP://',UHyperlink)<>0 then
    FParsed.FActiveX.FRemote.Add(Hyperlink) else
    FParsed.FActiveX.FLocal.Add(Hyperlink);
  End;

  If Pos('MAILTO:',Uppercase(hyperlink))<>0 then
  begin
   FParsed.FEmails.Add(Copy(Hyperlink,8,Length(Hyperlink)-7));
  end else
  If Pos('FTP://',UHyperlink)<>0 then
  begin
   FParsed.FFTPLinks.Add(Hyperlink);
  end else
  If Pos('HTTP://',UHyperlink)<>0 then
  begin
   FParsed.FHTTPLinks.Add(Hyperlink);
  end else
  If Pos('://',UHyperlink)=0 then
  begin
   FParsed.FLocalLinks.Add(Hyperlink);
  end else

//  If Assigned(FOnFoundHyperlink) then FOnFoundHyperlink(Self,Hyperlink);
  If Assigned(FOnFoundHyperlink) then FOnFoundHyperlink(Self,Tag);
  FParsed.FHyperlinks.Add(Hyperlink);
 End else

 If TagName='IMG' then { Image }
 Begin
  FParsed.FImages.Add(ExtractValue(GetTagAttribute(Tag,'src')));
 End else

 If TagName='FRAME' then { Frame }
 Begin
  FParsed.FFramePages.Add(ExtractValue(GetTagAttribute(Tag,'src')));
 End else

 If TagName='META' then { Meta }
 Begin
  MetaName:=Uppercase(ExtractValue(GetTagAttribute(Tag,'name')));
  MetaContent:=ExtractValue(GetTagAttribute(Tag,'content'));

  If MetaName='KEYWORD' then
   FParsed.FKeyword:=MetaContent else
  if MetaName='DESCRIPTION' then
   FParsed.FDescription:=MetaContent;
 End else

 If TagName='!--' then { Comment }
 Begin
  If Assigned(FOnFoundComment) then FOnFoundComment(Self,Copy(Tag,5,Length(Tag)-3-4));
  { <!-- Comment --> }
 End else
 
 If (TagName='TITLE') then { Title }
 Begin
  Buffering:=True;
  BufferingTT := '/TITLE';
 End else
 If (TagName='/TITLE') then
 Begin
  Buffering:=False;
  BufferingTT:='';
  FParsed.FTitle:=Buffer;
  Buffer:='';
 End;
End;

Procedure   THTMLParser.AddText(Text:String);
Begin
 If Buffering then Buffer:=Text;
 If Not Buffering then
 Begin
   If Assigned(FOnFoundText) then FOnFoundText(Self,Text);
 End;
 Text:='';
End;

Procedure   THTMLParser.Execute;
var LinesIndex : Integer;
    Line       : String;
    CharsIndex : Integer;
    TagDepth   : Integer;
    Tag        : String;
    InTag      : Boolean;
    IgnoreChar : Boolean;
    Text       : String;
    I          : Integer;
Begin
  FParsed.Hyperlinks.Clear;
  FParsed.Images.Clear;
  FParsed.Emails.Clear;
  FParsed.HTTPLinks.Clear;
  FParsed.FTPLinks.Clear;
  FParsed.LocalLinks.Clear;
  FParsed.FramePages.Clear;
  
  TagDepth :=0;
  Tag      :='';
  Text     :='';
  InTag    :=False;
  IgnoreChar := False;
  FTotalLines := FRaw.Count;
  For LinesIndex:=1 to FRaw.Count do
  Begin
    Line:=FRaw[LinesIndex-1];

    FCurrentLine:=LinesIndex;

    If Line='' then Continue;

    For CharsIndex:=1 to Length(Line) do
    Begin
     If IgnoreChar then IgnoreChar:=False;

     If Assigned(FOnParsing) and (TagDepth=0) then
      FOnParsing(Self,LinesIndex,FRaw.Count);

     If (Line[CharsIndex]='<') and Not InTag then
     Begin
      { Save text on buffer }
      If Text<>'' then
      Begin
        AddText(Text);
        Text:='';
      End;

      InTag:=True;
     End else

     If (Line[CharsIndex]='>') and InTag then
     Begin
        Tag:=Tag+'>';
        IgnoreChar:=True;
        For I:=Length(Tag) downto 1 do
        Begin
         If Tag[I]='<' then Break;
        End;
        AddTag(Copy(Tag,I+1,Length(tag)-I));
        InTag:=False;
        Delete(Tag,1,Length(tag)-I+1);

     End; {else }

     If Not IgnoreChar and Not InTag then
     Begin
      { Text }
      Text:=Text+Line[CharsIndex];
     End else

     If Not IgnoreChar and InTag then
     Begin
      { Tag(s) }
      Tag:=Tag+Line[CharsIndex];
     End;

    End;
    FParsedLines:=LinesIndex;

  End;
End;

constructor THTMLParser.Create(AOwner: TComponent);
Begin
  inherited Create(AOwner);
  FParsed:=tParsed.Create;
  FRaw:=tStringList.Create;
End;

destructor THTMLParser.Destroy;
Begin
  FParsed.Free;
  FRaw.Free;
  inherited Destroy;
End;


procedure Register;
begin
  RegisterComponents('Jazarsoft', [THTMLParser]);
end;

end.
 
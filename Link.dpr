library Link;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils,
  Classes,
  Forms,
  LinkMain in 'LinkMain.pas' {fmLinkMain},
  LinkWork in 'LinkWork.pas',
  BPThread in 'BPThread.pas',
  UrlParser in 'UrlParser.pas';

{$R *.res}

Procedure Show_Link( AppHandle : THandle) ; StdCall ; Export ;
 Begin
  Application.Handle := AppHandle ;
  If Assigned( fmLinkMain )
   Then fmLinkMain.Show
   Else Begin
    fmLinkMain := TfmLinkMain.Create( Application ) ;
    fmLinkMain.Show ;
   End ;
 End ;

Procedure Close_Link ; StdCall ; Export ;
 Begin
  If Assigned( fmLinkMain )
   Then Begin
    fmLinkMain.Close ;
    fmLinkMain.Free ;
   End ; 
 End ;

Procedure Link_Count_Thread( Const sEnable : Integer ) ; StdCall ; Export ;
 Begin
  Enable_Count_Thread := sEnable ;
//  vBPListThread.FCountEnab := sEnable ;
 End ;


Exports
 Show_Link ,
 Close_Link ,
 Link_Count_Thread ;
begin
end.

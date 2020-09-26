Unit BPError;
// Модуль, содержащий объект TBPError
Interface

Uses
  Classes ;

Type
//----------------------------------------------------------------------------//
 TBPErrorList = Record
  sURL     ,          // ошибочный URL
  sFName   : String ; // Имя выходного файла
  sErrCode : Integer ;   // Код ошибки
  sIdThr   : LongInt ; // Идентификатор потока
 End ;
 PBPErrorList = ^TBPErrorList ;
//----------------------------------------------------------------------------//
 TBPErrorClass = Class
  Public
   iList   : TList ;
   iErrRec : PBPErrorList ;
   Constructor Create ;
   Procedure Free ;
   Procedure Add( lURL, lSRC : String ; lErr : Integer ) ;
//   Function GetList : TList ;
//   Function GetListItem( Const lItem : Integer ) : PBPErrorList ;
 End ;
//----------------------------------------------------------------------------//
 Var
  cBPError : TBPErrorClass ;


Implementation

//----------------------------------------------------------------------------//
Constructor TBPErrorClass.Create ;
 Begin
  iList := TList.Create ;
 End ;
{------------------------------------------------------------------------------}
Procedure TBPErrorClass.Free ;
 Var
  I : Integer ;
 Begin
  For I := 0 To Pred( iList.Count ) Do
   Begin
    iErrRec := PErrRec(iList.Items[I]) ;
    Dispose( iErrRec ) ;
   End ;
  iList.Free ;
 End ;
{------------------------------------------------------------------------------}
Procedure TBPErrorClass.Add( lURL, lSRC : String ; lErr : Integer ) ;
 Begin
    New( iErrRec ) ;
    iErrRec^.fURL := lUrl ;
    iErrRec^.fSrc := lSrc ;
    iErrRec^.fErr := lErr ;
    iList.Add( iErrRec ) ;
 End ;
{------------------------------------------------------------------------------}
End.

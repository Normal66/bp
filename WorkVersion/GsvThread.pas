unit GsvThread;

{ ��������� �������� ��� ������������ ������� - Windows threads.

  ������ �����. ������, �����. 2005.
  gurin@mail.tomsknet.ru
  http://gurin.tomsknet.ru
}

interface

uses
  Windows, Classes, SysUtils;

type
  TGsvThread = class;

  IGsvThreadList = interface
  ['{2B09399A-07E9-47F5-9CB7-3E34230D37D1}']
    function Count: Integer;
    function GetItem(aIndex: Integer): TGsvThread;

    property Items[aIndex: Integer]: TGsvThread read GetItem; default;
  end;

  TGsvThreadManager = class
  private
    FLatch:     TRTLCriticalSection;
    FHashTable: array of TGsvThread;
    FCurHandle: Integer;
    FCount:     Integer;
    FOnEmpty:   TNotifyEvent;

  public
    constructor Create(aCapacity: Integer = 64);
    destructor  Destroy; override;

    function  Add(aThread: TGsvThread; aStart: Boolean = True): Integer;
    procedure Release(aHandle: Integer);
    function  Lock(aHandle: Integer): TGsvThread;
    function  TerminateAll: Integer;
    function  ActiveThreadList: IGsvThreadList;

    property  OnEmpty: TNotifyEvent read FOnEmpty write FOnEmpty;
  end;

  TGsvThread = class
  public
    constructor Create;
    destructor  Destroy; override;

  private
    // ��� ���� ����� ��� ��������� �������
    FManager:          TGsvThreadManager;
    FGsvHandle:        Integer;
    FRefCount:         Integer;
    FCollision:        TGsvThread;

    // ��� ����������� ������ ������� ������
    FSysHandle:        THandle;
    FTerminated:       Boolean;
    FFinished:         Boolean;
    FTerminationEvent: THandle;

    procedure ThreadExecute;
    procedure Terminate;
    function  GetPriority: Cardinal;
    procedure SetPriority(const Value: Cardinal);

  protected
    procedure Execute; virtual; abstract;
    procedure OnThreadError(const E: Exception); virtual;
    procedure OnFinished; virtual;

    procedure Pause(aTime: Cardinal);

    property  Terminated: Boolean read FTerminated write FTerminated;

  public
    procedure Resume;
    procedure Suspend;

    property  GsvHandle: Integer read FGsvHandle;
    property  SysHandle: THandle read FSysHandle;
    property  Finished: Boolean read FFinished;
    property  Priority: Cardinal read GetPriority write SetPriority;
    property  TerminationEvent: THandle read FTerminationEvent;
  end;

  TGsvLatch = class
  private
    FLatch: TRTLCriticalSection;

  public
    constructor Create;
    destructor  Destroy; override;

    procedure Lock;
    procedure Unlock;
  end;

  TGsvEvent = class
  public
    constructor Create;
    destructor  Destroy; override;

  private
    FHandle: THandle;

    procedure SetState(aState: Boolean);

  public
    function Wait(aThread: TGsvThread; aTimeout: Cardinal = INFINITE): Boolean;

    property Handle: THandle read FHandle;
    property State: Boolean write SetState;
  end;

  TGsvSelectMethod = procedure of object;

  TGsvSelect = class
  private
    FEvents:  array[0..MAXIMUM_WAIT_OBJECTS - 1] of THandle;
    FMethods: array[0..MAXIMUM_WAIT_OBJECTS - 1] of TGsvSelectMethod;
    FCount:   Cardinal;

  public
    constructor Create(aThread: TGsvThread);

    procedure Init;
    procedure Add(aEvent: THandle; aMethod: TGsvSelectMethod);
    function  Wait(aTimeout: Cardinal = INFINITE): Boolean;
  end;

  TGsvQueue = class
  public
    constructor Create(aMaxCount: Integer);
    destructor  Destroy; override;

  private
    FGetEvent: TGsvEvent;
    FPutEvent: TGsvEvent;
    FLatch:    TGsvLatch;
    FList:     TList;
    FMaxCount: Integer;

    function  GetCount: Integer;
    procedure SetEvents;

  public
    function  Get(aThread: TGsvThread; aTimeout: Cardinal = INFINITE): TObject;
    function  Put(aThread: TGsvThread; aMessage: TObject;
              aTimeout: Cardinal = INFINITE): Boolean;
    procedure PutOutOfTurn(aMessage: TObject);

    property  GetEvent: TGsvEvent read FGetEvent;
    property  PutEvent: TGsvEvent read FPutEvent;
    property  Count: Integer read GetCount;
    property  MaxCount: Integer read FMaxCount;
  end;

  TGsvChannelMethod = procedure(aThread: TGsvThread) of object;

  TGsvChannel = class
  private
    FSendEvent:     TGsvEvent;
    FReceiveEvent:  TGsvEvent;
    FReceiveThread: TGsvThread;
    FLatch:         TGsvLatch;
    FResult:        Boolean;

  public
    constructor Create;
    destructor  Destroy; override;

    function Send(aThread: TGsvThread; aMethod: TGsvChannelMethod;
             aTimeout: Cardinal = INFINITE): Boolean;
    function Receive(aThread: TGsvThread; aTimeout: Cardinal = INFINITE):
             Boolean;
  end;

implementation

type
  TGsvThreadList = class(TInterfacedObject, IGsvThreadList)
  private
    FManager: TGsvThreadManager;
    FItems:   TList;

  public
    constructor Create(aManager: TGsvThreadManager);
    destructor  Destroy; override;

    function    Count: Integer;
    function    GetItem(aIndex: Integer): TGsvThread;
  end;

{ TGsvThreadList }

constructor TGsvThreadList.Create(aManager: TGsvThreadManager);
var
  hash: Integer;
  th:   TGsvThread;
begin
  inherited Create;
  FManager := aManager;
  FItems   := TList.Create;
  // ������� � ������ ��� �������� ������ �� ���-�������
  with FManager do
    for hash := Low(FManager.FHashTable) to High(FHashTable) do begin
      th := FHashTable[hash];
      while Assigned(th) do begin
        if not th.FTerminated then begin
          // ����������� ������� ������ ������, ��� ��� ������ �� ������������ �������
          Inc(th.FRefCount);
          FItems.Add(th);
        end;
        // �������� �� ������� ��������
        th := th.FCollision;
      end;
    end;
end;

destructor TGsvThreadList.Destroy;
var
  i: Integer;
begin
  // ����������� ��� ������� �������
  for i := 0 to Pred(FItems.Count) do
    FManager.Release(TGsvThread(FItems[i]).FGsvHandle);
  inherited Destroy;
end;

function TGsvThreadList.Count: Integer;
begin
  Result := FItems.Count;
end;

function TGsvThreadList.GetItem(aIndex: Integer): TGsvThread;
begin
  Result := TGsvThread(FItems[aIndex]);
end;

{ TGsvThreadManager }

constructor TGsvThreadManager.Create(aCapacity: Integer);
var
  i: Integer;
begin
  if aCapacity < 1 then
    aCapacity := 1;
  InitializeCriticalSection(FLatch);
  SetLength(FHashTable, aCapacity);
  // ���� �������������� ���-�������
  for i := Low(FHashTable) to High(FHashTable) do
    FHashTable[i] := nil;
  FCurHandle := 0; // ����� �������������, ������� ����� ���� �� �� ������
  FCount     := 0;
end;

destructor TGsvThreadManager.Destroy;
begin
  // ����������� ������ - ����������� ���������� ��������, ���� �������
  // ������������� ������, ��� ��� ��� ����� ���������� ��� ����� ����������
  // � ���������
  Assert(FCount = 0);
  DeleteCriticalSection(FLatch);
  inherited Destroy;
end;

function TGsvThreadManager.Add(aThread: TGsvThread; aStart: Boolean): Integer;
var
  hash: Integer; // ���-��� �����������: ������ � ���-�������
begin
  // ������ ��� �������� ������ ����������� ������ ����� ���������
  // ��������� ������������ �������
  EnterCriticalSection(FLatch);
  try
    Inc(FCurHandle);   // ������� ��������� ����������
    hash               := FCurHandle mod Length(FHashTable);
    aThread.FManager   := Self;
    aThread.FGsvHandle := FCurHandle;
    aThread.FRefCount  := 1;
    // �������� ������ � ������ ������� �������� (���� ��� ����) �
    // ������ ������ � ���-�������
    aThread.FCollision := FHashTable[hash];
    FHashTable[hash]   := aThread;
    Inc(FCount);
    Result := FCurHandle;
  finally
    LeaveCriticalSection(FLatch);
  end;
  // ������������ ������������ ���������� ������
  if aStart then
    aThread.Resume;
end;

procedure TGsvThreadManager.Release(aHandle: Integer);
var
  hash: Integer;
  th:   TGsvThread; // �����, ��������� � ������������
  prev: TGsvThread; // ���������� ����� � ������� ��������
begin
  EnterCriticalSection(FLatch);
  try
    // ����� �������, ���������� � ������������ � ����������� ������� �
    // ������� ��������. ���������� ������ ����� ��-�� ����, ���
    // ������� �������� ������������ ����� ����������� ������, � ��� �����
    // ������������� �������� ������� �� �������� ��� ����� ������
    hash := aHandle mod Length(FHashTable);
    prev := nil;
    th   := FHashTable[hash];
    while Assigned(th) do begin
      if th.FGsvHandle = aHandle then
        Break;
      // �������� �� ������� ��������
      prev := th;
      th   := th.FCollision;
    end;
    if Assigned(th) then begin
      // ������ ������ ��� ����������, ��������� ��� ������� ������
      Dec(th.FRefCount);
      // ���������� ��������� ( <= 0) ��� ������ �� ������ ���������� �����������
      if th.FRefCount <= 0 then begin
        // ������ ������ ������ ������ �� �����
        if not th.FFinished then begin
          // ������ ������ ��� �� ��������. ��������� ���
          th.Terminate;
          // ����� ������ ���������� ����� �������������� ������� Release,
          // ������� �������� ����������� ��� ������� ������ ��� �����������
          // ������� (�� ��������� �������������� �������� �������� ������)
          Inc(th.FRefCount);
        end
        else begin
          // ������ ������ ��������,
          // ������� ������ �� ���-������� � �� ������� ��������
          if Assigned(prev) then
            prev.FCollision := th.FCollision   // ������ � �������� ��� � �����
          else
            FHashTable[hash] := th.FCollision; // ������ � ������ �������
          Dec(FCount);
          // ���������� ������ ������
          th.Free;
        end;
      end;
    end;
    // else - ������� � ����� ������������ �� ����������, ������ �� ������
    // ���� ������ ������� ����, �� �������� ������� OnEmpty
    if (FCount = 0) and Assigned(FOnEmpty) then
      FOnEmpty(Self);
  finally
    LeaveCriticalSection(FLatch);
  end;
end;

function TGsvThreadManager.Lock(aHandle: Integer): TGsvThread;
var
  hash: Integer;
begin
  EnterCriticalSection(FLatch);
  try
    hash := aHandle mod Length(FHashTable);
    // ����� ������� ������ �� ��� �����������
    Result := FHashTable[hash];
    while Assigned(Result) do begin
      if Result.FGsvHandle = aHandle then
        Break;
      Result := Result.FCollision;
    end;
    // ������ ����������, ����������� ��� ������� ������, ��� ��� � �������
    // �������� ��� ���� "������������"
    if Assigned(Result) then
      Inc(Result.FRefCount);
  finally
    LeaveCriticalSection(FLatch);
  end;
end;

// ������� ��������� ��� �������� ������ � ���������� ���������� �������,
// ������� ��� �� �������� ���� ������� ����������
function TGsvThreadManager.TerminateAll: Integer;
var
  hash: Integer;
  th:   TGsvThread;
begin
  Result := 0;
  EnterCriticalSection(FLatch);
  try
    // ������� ��� ���-�������
    for hash := Low(FHashTable) to High(FHashTable) do begin
      th := FHashTable[hash];
      while Assigned(th) do begin
        // ��������� �����. ���� �� ��� ��������, �� Terminate �� ��������
        // �������� ��������
        th.Terminate;
        if not th.FFinished then
          Inc(Result);
        // �������� �� ������� ��������
        th := th.FCollision;
      end;
    end;
  finally
    LeaveCriticalSection(FLatch);
  end;
end;

function TGsvThreadManager.ActiveThreadList: IGsvThreadList;
begin
  EnterCriticalSection(FLatch);
  try
    Result := TGsvThreadList.Create(Self);
  finally
    LeaveCriticalSection(FLatch);
  end;
end;

{ TGsvThread }

function ThreadProc(p: TGsvThread): Integer;
begin
  // ���������, ������� �������� ������������ ������� ��� ������ �������������
  // ������
  Result := 0;
  with p do begin
    // ��������� ���� ������
    ThreadExecute;
    // �������������� ������
    if Assigned(FManager) then
      FManager.Release(FGsvHandle);
  end;
  EndThread(0);
end;

constructor TGsvThread.Create;
var
  id: Cardinal;
begin
  inherited Create;
  // ����������� ������� ��������� � ������ ������ ������������� (True),
  // ��������� ��������� ������� - ����������������� (False)
  FTerminationEvent := CreateEvent(nil, True, False, nil);
  if FTerminationEvent = 0 then
    RaiseLastOSError;
  // ������������ ����� ��������� � ���������������� ���������. Delphi-�������
  // BeginThread ������������ ������ Windows-������� CreateThread ��� ����,
  // ����� ��������� ���������� ��������� ��������������� Delphi-����������.
  FSysHandle := BeginThread(nil, 0, @ThreadProc, Self, CREATE_SUSPENDED, id);
  if FSysHandle = 0 then
    RaiseLastOSError;
end;

destructor TGsvThread.Destroy;
begin
  if FTerminationEvent <> 0 then begin
    CloseHandle(FTerminationEvent);
    FTerminationEvent := 0;
  end;
  inherited Destroy;
end;

procedure TGsvThread.ThreadExecute;
begin
  try
    Execute;
  except
    on E: Exception do begin
      try
        OnThreadError(E);
      except
      end;
    end;
  end;
  FTerminated := True;
  if FSysHandle <> 0 then begin
    CloseHandle(FSysHandle);
    FSysHandle := 0;
  end;
  FFinished := True;
  try
    OnFinished;
  except
  end;
end;

procedure TGsvThread.Terminate;
begin
  if not FTerminated then begin
    FTerminated := True;
    SetEvent(FTerminationEvent);
    Resume;
  end;
end;

function TGsvThread.GetPriority: Cardinal;
begin
  if FSysHandle <> 0 then
    Result := GetThreadPriority(FSysHandle)
  else
    Result := THREAD_PRIORITY_NORMAL;
end;

procedure TGsvThread.SetPriority(const Value: Cardinal);
begin
  if FSysHandle <> 0 then
    SetThreadPriority(FSysHandle, Value);
end;

// ����� ���������� � ��������� ������������� ������ ��� �������������
// �������������� �������� � Execute
procedure TGsvThread.OnThreadError(const E: Exception);
begin
end;

// ��� ��������� �����, ������� ���������� � ��������� ������������� ������.
// ����� ���������� ���������� �� ����, �� ����� ������� ��������� ����������
// ������. ����� ������ ����� ������ ������������ ����� ���������� ���� ������,
// �� ������ ������ ����� ��� ������������ �� ��� ���, ���� �� ���� ��������
// ������
procedure TGsvThread.OnFinished;
begin
end;

// ����� � ��������� �������� ���������� ������. ����� 0 ������������
// ��� ����, ����� ������� ��������� ������������ ������� Windows �
// �������� ���������� ������� ������������� ������
procedure TGsvThread.Pause(aTime: Cardinal);
begin
  if not FTerminated then begin
    if aTime = 0 then
      Sleep(0)
    else
      WaitForSingleObject(FTerminationEvent, aTime);
  end;
end;

procedure TGsvThread.Resume;
begin
  if FSysHandle <> 0 then
    ResumeThread(FSysHandle);
end;

procedure TGsvThread.Suspend;
begin
  if FSysHandle <> 0 then
    SuspendThread(FSysHandle);
end;

{ TGsvLatch }

constructor TGsvLatch.Create;
begin
  inherited Create;
  InitializeCriticalSection(FLatch);
end;

destructor TGsvLatch.Destroy;
begin
  DeleteCriticalSection(FLatch);
  inherited Destroy;
end;

procedure TGsvLatch.Lock;
begin
  EnterCriticalSection(FLatch);
end;

procedure TGsvLatch.Unlock;
begin
  LeaveCriticalSection(FLatch);
end;

{ TGsvEvent }

constructor TGsvEvent.Create;
begin
  inherited Create;
  FHandle := CreateEvent(nil, False, False, nil);
  if FHandle = 0 then
    RaiseLastOSError;
end;

destructor TGsvEvent.Destroy;
begin
  if FHandle <> 0 then
    CloseHandle(FHandle);
  inherited Destroy;
end;

procedure TGsvEvent.SetState(aState: Boolean);
begin
  if aState then
    SetEvent(FHandle)
  else
    ResetEvent(FHandle);
end;

function TGsvEvent.Wait(aThread: TGsvThread; aTimeout: Cardinal): Boolean;
var
  objs: array[0..1] of THandle;
  cnt:  Integer;
begin
  objs[0] := FHandle;
  cnt     := 1;
  if Assigned(aThread) then begin
    objs[1] := aThread.FTerminationEvent;
    cnt     := 2;
  end;
  Result := WaitForMultipleObjects(cnt, @objs[0], False, aTimeout) =
            WAIT_OBJECT_0;
end;

{ TGsvSelect }

constructor TGsvSelect.Create(aThread: TGsvThread);
begin
  inherited Create;
  FEvents[0]  := aThread.FTerminationEvent;
  FMethods[0] := nil;
  FCount      := 1;
end;

procedure TGsvSelect.Init;
begin
  FCount := 1;
end;

procedure TGsvSelect.Add(aEvent: THandle; aMethod: TGsvSelectMethod);
begin
  Assert(FCount <= High(FEvents));
  FEvents[FCount]  := aEvent;
  FMethods[FCount] := aMethod;
  Inc(FCount);
end;

function TGsvSelect.Wait(aTimeout: Cardinal): Boolean;
var
  res, i: Cardinal;
begin
  Result := False;
  res    := WaitForMultipleObjects(FCount, @FEvents[0], False, aTimeout);
  if res < (WAIT_OBJECT_0 + FCount) then begin
    Result := res > WAIT_OBJECT_0;
    if Result then begin
      i := res - WAIT_OBJECT_0;
      if Assigned(FMethods[i]) then
        FMethods[i]();
    end;
  end;
end;

{ TGsvQueue }

constructor TGsvQueue.Create(aMaxCount: Integer);
begin
  inherited Create;
  FGetEvent      := TGsvEvent.Create;
  FPutEvent      := TGsvEvent.Create;
  FLatch         := TGsvLatch.Create;
  FList          := TList.Create;
  FMaxCount      := aMaxCount;
  FList.Capacity := FMaxCount;
end;

destructor TGsvQueue.Destroy;
var
  i: Integer;
begin
  for i := 0 to Pred(FList.Count) do
    TObject(FList.Items[i]).Free;
  FList.Free;
  FLatch.Free;
  FPutEvent.Free;
  FGetEvent.Free;
  inherited Destroy;
end;

function TGsvQueue.GetCount: Integer;
begin
  FLatch.Lock;
  Result := FList.Count;
  FLatch.Unlock;
end;

procedure TGsvQueue.SetEvents;
begin
  FGetEvent.State := FList.Count <> 0;
  FPutEvent.State := FList.Count < FMaxCount;
end;

function TGsvQueue.Get(aThread: TGsvThread; aTimeout: Cardinal): TObject;
begin
  Result := nil;
  if not FGetEvent.Wait(aThread, aTimeout) then
    Exit;
  FLatch.Lock;
  try
    if FList.Count <> 0 then begin
      Result := TObject(FList.Items[0]);
      FList.Delete(0);
      SetEvents;
    end;
  finally
    FLatch.Unlock;
  end;
end;

function TGsvQueue.Put(aThread: TGsvThread; aMessage: TObject;
  aTimeout: Cardinal): Boolean;
begin
  Result := False;
  if not FPutEvent.Wait(aThread, aTimeout) then
    Exit;
  FLatch.Lock;
  try
    FList.Add(aMessage);
    SetEvents;
    Result := True;
  finally
    FLatch.Unlock;
  end;
end;

procedure TGsvQueue.PutOutOfTurn(aMessage: TObject);
begin
  FLatch.Lock;
  try
    FList.Add(aMessage);
    SetEvents;
  finally
    FLatch.Unlock;
  end;
end;

{ TGsvChannel }

constructor TGsvChannel.Create;
begin
  inherited Create;
  FSendEvent    := TGsvEvent.Create;
  FReceiveEvent := TGsvEvent.Create;
  FLatch        := TGsvLatch.Create;
  FResult       := False;
end;

destructor TGsvChannel.Destroy;
begin
  FLatch.Free;
  FReceiveEvent.Free;
  FSendEvent.Free;
  inherited Destroy;
end;

function TGsvChannel.Send(aThread: TGsvThread; aMethod: TGsvChannelMethod;
  aTimeout: Cardinal): Boolean;
begin
  Result  := False;
  FResult := False;
  if not FSendEvent.Wait(aThread, aTimeout) then
    Exit;
  FLatch.Lock;
  try
    if Assigned(FReceiveThread) then begin
      aMethod(FReceiveThread);     // ����� �������
      FReceiveEvent.State := True; // ����������� ����������
      Result              := True; // �������� �������
      FResult             := True;
    end;
  finally
    FLatch.Unlock;
  end;
end;

function TGsvChannel.Receive(aThread: TGsvThread;
  aTimeout: Cardinal): Boolean;
begin
  FLatch.Lock;
  try
    FReceiveThread      := aThread;
    FReceiveEvent.State := False;   // ����� ���������� �������
    FSendEvent.State    := True;    // ����������� �����������
  finally
    FLatch.Unlock;
  end;
  FReceiveEvent.Wait(aThread, aTimeout);
  FLatch.Lock;
  try
    Result           := FResult;
    FResult          := False;      // ���������� ������ � �������� ���������
    FSendEvent.State := False;
    FReceiveThread   := nil;
  finally
    FLatch.Unlock;
  end;
end;

end.

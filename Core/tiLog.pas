unit tiLog;

{$I tiDefines.inc}

interface
uses
  tiBaseObject,
  tiThread,
  tiObject,
  Classes,
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF MSWINDOWS}
  SyncObjs,   // This unit must always appear after the Windows unit!
  Contnrs,
  SysUtils,
  types;

const
  crsSeverityNotFound = 'Severity <%s> not found';
  cErrorCanNotCreateLogDirectory = 'Can not create directory for log files <%s>';
  // Command line parameters
  csLog         = 'l'; // Command line parameter to turn logging on (default log to file)
  csLogVisual   = 'lv'; // Command line parameter to turn visual logging on
  csLogConsole  = 'lc'; // Command line parameter to turn console logging on

type

  // I use this set to provide additional log severity types
  // If you change the set of log event types, then remember to change the
  // strings in caLogSeverityStrings (below) too.
  TtiLogSeverity = (
                    lsNormal
                   ,lsUserInfo
                   ,lsObjCreation
                   ,lsVisitor
                   ,lsConnectionPool
                   ,lsAcceptVisitor
                   ,lsQueryTiming
                   ,lsDebug
                   ,lsWarning
                   ,lsError
                   ,lsSQL
               );

const

  ctiLogSeverityStrings: array[ TtiLogSeverity ] of String = (
                    'Norm'
                   ,'Info'
                   ,'Obj'
                   ,'Vis'
                   ,'DBCon'
                   ,'AVis'
                   ,'Query'
                   ,'Debug'
                   ,'Warn'
                   ,'Error'
                   ,'SQL'
               );


type
  TtiLogLevel = (llMinimal, llMedium, llVerbose, llCustom);

  { Forward declaration of the main logging class }
  TtiLog = class;


  { It is possible to filter for a group of log events }
  TtiSevToLog = set of TtiLogSeverity;


  { A class to hold a logged event while in the cache }
  TtiLogEvent = class(TtiBaseObject)
  private
    FLogMessage : String;
    FDateTime : String;
    FSeverity  : TtiLogSeverity;
    FThreadID : string;
    function  GetSeverityAsString: string;
    procedure SetSeverityAsString(const AValue: string);
    function  GetShortLogMessage: string;
    function  GetFormattedMessageTimeStamp: string;
  public
    property DateTime  : string       read FDateTime  write FDateTime;
    property LogMessage : String       read FLogMessage write FLogMessage;
    property ShortLogMessage : string  read GetShortLogMessage;
    property Severity  : TtiLogSeverity read FSeverity   write FSeverity;
    property ThreadID  : string       read FThreadID  write FThreadID;
    property SeverityAsString : string read GetSeverityAsString write SetSeverityAsString;
    function AsString  : string;
    function AsStringStripCrLf : string;
    function AsLeftPaddedString: string;
  end;


  { Holds a list of TtiLogEvent objects }
  TtiLogEvents = class(TtiBaseObject)
  private
    FList: TObjectList;
    function GetItems(AIndex: Integer): TtiLogEvent;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure   Add(AItem: TtiLogEvent);
    property    Items[AIndex: Integer]: TtiLogEvent Read GetItems;
    function    Count: Integer;
    procedure   Clear;
  end;


  { Abstract base class to manage logging to anything }
  TtiLogToAbs = class(TtiBaseObject)
  private
    FSevToLog: TtiSevToLog; // ToDo: Is FSevToLog required here. Isn't it managed in TtiLog?
    FTerminated: Boolean;
  protected
    function  AcceptEvent(const ADateTime : string;
                           const AMessage : string;
                           ASeverity : TtiLogSeverity): boolean; virtual;
    { Only used by decendant classes that use caching and threading while logging }
    procedure WriteToOutputSynchronized; virtual;
    procedure WriteToOutput; virtual; abstract;
    procedure SetSevToLog(const AValue: TtiSevToLog); virtual;
  public
    constructor Create; virtual;
    procedure   Log(const ADateTime : string;
                     const AThreadID : string;
                     const AMessage : string;
                     ASeverity : TtiLogSeverity); virtual; abstract;
    property    SevToLog : TtiSevToLog read FSevToLog Write SetSevToLog;
    { Placeholder method for any terminating code you might require. }
    procedure   Terminate; virtual;
    procedure   Purge;
    property    Terminated : boolean read FTerminated;
  end;


  TtiLogToClass = class of TtiLogToAbs;
  TtiLogToCacheAbs = class;


  // A thread class to manage the writing out of events when the
  // system has some free time
  TtiThrdLog = class(TtiSleepThread)
  private
    FLogTo : TtiLogToCacheAbs;
    procedure   SetLogTo(const AValue: TtiLogToCacheAbs);
    procedure   WriteToOutput;
  public
    constructor CreateExt(ALogTo : TtiLogToCacheAbs);
    procedure   Execute; override;
    property    Terminated;  // surfaced from protected
    procedure   tiSynchronize(AMethod: TThreadMethod); // surfaced Synchronize from protected
    property    LogTo : TtiLogToCacheAbs  read FLogTo write SetLogTo;
  end;


  // Abstract base class to manage cached logging
  TtiLogToCacheAbs = class(TtiLogToAbs)
  private
    FList: TList;
    FListWorking: TtiLogEvents;
    FCritSect: TCriticalSection;
    FThrdLog: TtiThrdLog;
    FSynchronized: Boolean;
    FEnableCaching: boolean;
    procedure Init(const ASynchronized: Boolean);  // Called by all constructors.
    procedure SetEnableCaching(const AValue: boolean);
  protected
    property  ThrdLog: TtiThrdLog read FThrdLog;
    property  ListWorking: TtiLogEvents read FListWorking;
    procedure WriteToOutputSynchronized; override;
    procedure WriteToOutput; override;
  public
    // NOTE: Descendants need to call one of the following inherited constructors
    // depending on whether they need log output synchronized with the main thread.
    // This is typically only when logging to a GUI.
    // Log output not synchronized to the main thread
    constructor Create; override;
    // Log output synchronized to the main thread
    constructor CreateSynchronized; virtual;
    destructor  Destroy; override;
    procedure   Log(const ADateTime : string;
                    const AThreadID : string;
                    const AMessage : string;
                    ASeverity: TtiLogSeverity); override;
    procedure   Terminate; override;
    property    Synchronized: Boolean read FSynchronized;
    property    EnableCaching: boolean read FEnableCaching write SetEnableCaching;
  end;


  // The main logging class
  TtiLog = class(TtiBaseObject)
  private
    FLogToList : TList;
    FSevToLog: TtiSevToLog;
    FCritSect: TCriticalSection;
    FLogLevel: TtiLogLevel;
    procedure SetSevToLog(const AValue: TtiSevToLog);
    function  IsRegistered(const ALogToClass : TtiLogToClass): boolean;
    procedure SetLogLevel(const Value: TtiLogLevel);
    function  GetSevToLogAsString: string;
    procedure SetSevToLogAsString(const AValue: string);
  public
    constructor Create;
    destructor  Destroy; override;
    procedure   RegisterLog(ALogTo : TtiLogToAbs); overload;
    procedure   RegisterLog(ALogTo : TtiLogToClass); overload;
    function    FindByLogClass(ALogToClass : TtiLogToClass): TtiLogToAbs;
    procedure   Log(const AMessage : string;
                     const ASeverity : TtiLogSeverity = lsNormal);
    property    SevToLog : TtiSevToLog read FSevToLog write SetSevToLog;
    property    SevToLogAsString: string read GetSevToLogAsString write SetSevToLogAsString;
    property    LogLevel: TtiLogLevel read FLogLevel write SetLogLevel;
    function    LogToFileName: string;
    procedure   Purge;
  end;


// The log object is a singleton
function  GLog : TtiLog;
procedure ReleaseLog; //Allow testing to fully close then re-open Log; Peterm

// Some global procedures to make logging easier
procedure Log(const AMessage : string; ASeverity : TtiLogSeverity = lsNormal); overload;
procedure Log(const AMessage : integer; ASeverity : TtiLogSeverity = lsNormal); overload;
procedure Log(const AMessage : Extended; ASeverity : TtiLogSeverity = lsNormal); overload;
procedure Log(const AMessage : boolean; ASeverity : TtiLogSeverity = lsNormal); overload;
procedure Log(const AMessages : TStrings; ASeverity : TtiLogSeverity = lsNormal); overload;
procedure Log(const AArray : Array of Const; ASeverity : TtiLogSeverity = lsNormal); overload;
procedure Log(const AMessage : string; const AArray : Array of Const; ASeverity : TtiLogSeverity = lsNormal); overload;
procedure Log(const AObject : TtiObject; const ASeverity : TtiLogSeverity = lsNormal); overload;

procedure LogWarning(const AMessage : string); overload;
procedure LogError(const AMessage : string; ARaiseException : boolean = true); overload;
procedure LogError(const AException : Exception; ARaiseException : boolean = true); overload;
procedure LogError(const AMessage : string; const AArray : Array of Const); overload;

// helper procedures to debug values
procedure LogValue(const AIdentifier: string; const AValue: Integer); overload;
procedure LogValue(const AIdentifier: string; const AValue: Cardinal); overload;
procedure LogValue(const AIdentifier: string; const AValue: Extended); overload;
procedure LogValue(const AIdentifier: string; const AValue: Boolean); overload;
procedure LogValue(const AIdentifier: string; const AValue: String); overload;
procedure LogValue(const AIdentifier: string; const ARect: TRect); overload;
procedure LogValue(const AIdentifier: string; const APoint: TPoint); overload;
procedure LogValue(const AIdentifier: string; const AValue: TDateTime); overload;
procedure LogValue(const AIdentifier: string; const AValue: Currency); overload;

function LogSeverityToString(const ALogSeverity: TtiLogSeverity): string;
function StringToLogSeverity(const AValue: string; out ALogSeverity: TtiLogSeverity): boolean;


const
  // Constants for formatting the error log
  cuiWidthDate         = 19;
  cuiWidthThread       =  4;
  cuiWidthSeverity     =  5;
  cuiWidthShortMessage = 60;


implementation
uses
   tiConstants
  ,tiUtils
  ,tiLogToFile
  ,tiExcept
  {$IFDEF DELPHI6ORABOVE}
  ,Variants
  {$ELSE}
  ,FileCtrl
  {$ENDIF}
 ;


var
  ULog : TtiLog;
  UFinalization : boolean;


const
  // Default set of log events to write out. Any events not in this set will
  // be ignored.
  CSevToLogMinimal = [
                    lsUserInfo
                   ,lsWarning
                   ,lsError
              ];

  CSevToLogMedium = [
                    lsNormal
                   ,lsUserInfo
                   ,lsWarning
                   ,lsError
              ];

  CSevToLogVerbose = [
                    lsNormal
                   ,lsUserInfo
                   ,lsObjCreation
                   ,lsVisitor
                   ,lsConnectionPool
                   ,lsAcceptVisitor
                   ,lsQueryTiming
                   ,lsDebug
                   ,lsWarning
                   ,lsError
                   ,lsSQL
              ];


// The log is a singleton
function GLog : TtiLog;
begin
  if UFinalization then
  begin
    result := nil;
    Exit; //==>
  end;
  if ULog = nil then
    ULog := TtiLog.Create;
  result := ULog;
end;

procedure ReleaseLog;
begin
  if ULog <> nil then
  try
    UFinalization := True;
    FreeAndNil(ULog);
  finally
    UFinalization := False;
  end;
end;

function _IsParam(const AParam: string): boolean;
  //------------
  function _IsThisParam(const AParam, psDelim, psCommandLineParams: string): boolean;
  begin
    result := (pos(psDelim + UpperCase(AParam) + ' ',
                     psCommandLineParams) <> 0)
  end;

  //------------
  function _ReadCommandLineParams : string;
  var
    i : integer;
  begin
    result := '';
    for i := 1 to ParamCount do begin
      result :=
        result +
        upperCase(ParamStr(i)) + ' ';
    end;
  end;
var
  lsCommandLineParams : string;
begin
  lsCommandLineParams := _ReadCommandLineParams;
  result := _IsThisParam(AParam, '-', lsCommandLineParams) or
            _IsThisParam(AParam, '/', lsCommandLineParams) or
            _IsThisParam(AParam, '\', lsCommandLineParams);
end;

function RectToStr(const ARect: TRect): String;
begin
  with ARect do
    Result := Format('(Left: %d; Top: %d; Right: %d; Bottom: %d)', [Left, Top, Right, Bottom]);
end;

function PointToStr(const APoint: TPoint): String;
begin
  with APoint do
    Result := Format('(X: %d; Y: %d)', [X, Y]);
end;

procedure Log(const AMessage : string; ASeverity : TtiLogSeverity = lsNormal);
begin
  if UFinalization then
    Exit; //==>
  GLog.Log(AMessage, ASeverity);
end;


procedure Log(const AMessage : integer; ASeverity : TtiLogSeverity = lsNormal);
begin
  Log(IntToStr(AMessage), ASeverity);
end;


procedure Log(const AMessage: Extended; ASeverity : TtiLogSeverity = lsNormal); overload;
begin
  Log(FloatToStr(AMessage), ASeverity);
end;


procedure Log(const AMessage : boolean; ASeverity : TtiLogSeverity = lsNormal); overload;
begin
  Log(tiBoolToStr(AMessage), ASeverity);
end;

procedure Log(const AMessages : TStrings; ASeverity : TtiLogSeverity = lsNormal); overload;
var
  i: integer;
begin
  for i := 0 to AMessages.Count - 1 do
    Log(AMessages.Strings[i]);    
end;

procedure LogError(const AMessage : string; ARaiseException : boolean = true);
begin
  if UFinalization then
    Exit; //==>
  GLog.Log(AMessage, lsError);
  {$IFDEF ThirdPartyExceptionHandling}
    if ARaiseException then
      raise exception.Create(AMessage);
  {$ENDIF}
end;


procedure LogError(const AException : Exception; ARaiseException : boolean = true);
begin
  if UFinalization then
    Exit; //==>
  GLog.Log(AException.Message, lsError);
  {$IFDEF ThirdPartyExceptionHandling}
    if ARaiseException then
      raise Exception(AException.ClassType).Create(AException.Message);
  {$ENDIF}
end;


procedure LogError(const AMessage : string; const AArray : Array of Const);
var
  ls : string;
begin
  if UFinalization then
    Exit; //==>
  try
    ls := Format(AMessage, AArray);
  except
    on e:exception do
      ls := 'Unable to evaluate log message <' + AMessage + '> reason: ' + e.Message;
  end;
  GLog.Log(ls, lsError);
end;


procedure LogWarning(const AMessage : string);
begin
  if UFinalization then
    Exit; //==>
  GLog.Log(AMessage, lsWarning);
end;


procedure Log(const AArray : Array of Const; ASeverity : TtiLogSeverity = lsNormal);
const
  BoolChars: array[Boolean] of Char = ('F', 'T');
var
  i: Integer;
  lsLine : string;
begin
  lsLine := '';
  for I := 0 to High(AArray) do begin
    if lsLine <> '' then
      lsLine := lsLine + ', ';
    with AArray[i] do
      case VType of
        vtInteger:    lsLine := lsLine + IntToStr(VInteger);
        vtBoolean:    lsLine := lsLine + BoolChars[VBoolean];
        vtChar:       lsLine := lsLine + VChar;
        vtExtended:   lsLine := lsLine + FloatToStr(VExtended^);
        vtString:     lsLine := lsLine + VString^;
        vtPChar:      lsLine := lsLine + VPChar;
        vtObject:     lsLine := lsLine + VObject.ClassName;
        vtClass:      lsLine := lsLine + VClass.ClassName;
        vtAnsiString: lsLine := lsLine + string(VAnsiString);
        vtCurrency:   lsLine := lsLine + CurrToStr(VCurrency^);
        vtVariant:
        begin
          if not VarIsNull(VVariant^) then
            lsLine := lsLine + string(VVariant^);
        end;
        vtInt64:      lsLine := lsLine + IntToStr(VInt64^);
      else
        raise exception.Create('Invalid variant type passed to LogArray');
    end;
  end;
  Log(lsLine, ASeverity);
end;


procedure Log(const AMessage : string; const AArray : Array of Const; ASeverity : TtiLogSeverity = lsNormal);
var
  lMessage : string;
begin
  try
    lMessage := Format(AMessage, AArray);
  except
    on e:exception do
      LogError('Unable to evaluate log message <' + AMessage + '> reason: ' + e.Message);
  end;
  Log(lMessage, ASeverity);
end;

procedure Log(const AObject : TtiObject; const ASeverity : TtiLogSeverity = lsNormal);
begin
  Log(AObject.AsDebugString, ASeverity);
end;

procedure LogValue(const AIdentifier: string; const AValue: Integer);
begin
  Log(AIdentifier + ' = ' + IntToStr(AValue), lsDebug);
end;

procedure LogValue(const AIdentifier: string; const AValue: Cardinal);
begin
  Log(AIdentifier + ' = ' + IntToStr(AValue), lsDebug);
end;

procedure LogValue(const AIdentifier: string; const AValue: Extended);
begin
  Log(AIdentifier + ' = ' + FloatToStr(AValue), lsDebug);
end;

procedure LogValue(const AIdentifier: string; const AValue: Boolean);
begin
  Log(AIdentifier + ' = ' + tiBooleanToStr(AValue), lsDebug);
end;

procedure LogValue(const AIdentifier: string; const AValue: String);
begin
  Log(AIdentifier + ' = ' + AValue, lsDebug);
end;

procedure LogValue(const AIdentifier: string; const ARect: TRect);
begin
  Log(AIdentifier + ' = ' + RectToStr(ARect), lsDebug);
end;

procedure LogValue(const AIdentifier: string; const APoint: TPoint);
begin
  Log(AIdentifier + ' = ' + PointToStr(APoint), lsDebug);
end;

procedure LogValue(const AIdentifier: string; const AValue: TDateTime);
begin
  Log(AIdentifier + ' = ' + tiDateTimeAsIntlDateDisp(AValue), lsDebug);
end;

procedure LogValue(const AIdentifier: string; const AValue: Currency);
begin
//  Log(AIdentifier + ' = ' + CurrToStrF(AValue, ffCurrency, 4), lsDebug);
  Log(AIdentifier + ' = ' + FormatFloat('� #,##0.0000', AValue), lsDebug);
end;

function LogSeverityToString(const ALogSeverity: TtiLogSeverity): string;
begin
  result := ctiLogSeverityStrings[ALogSeverity];
end;

function StringToLogSeverity(const AValue: string;
  out ALogSeverity: TtiLogSeverity): boolean;
var
  LLogSeverity: TtiLogSeverity;
begin
  result := false;
  for LLogSeverity := Low(TtiLogSeverity) to High(TtiLogSeverity) do
    if SameText(AValue, LogSeverityToString(LLogSeverity)) then
    begin
      result := true;
      ALogSeverity := LLogSeverity;
      break;
    end;
end;


function _StrTran(AValue, ADel, AIns : string): string;
var i : integer;
    sToChange : string;
begin
  result := '';
  sToChange := AValue;
  i := pos(ADel, sToChange);
  while i <> 0 do begin
    result := result + copy(sToChange, 1, i-1) + AIns;
    delete(sToChange, 1, i+length(ADel)-1);
    i := pos(ADel, sToChange);
  end;
  result := result + sToChange;
end;


function _PadR(AValue : string; ALen : integer): string;
begin
  if length(AValue) < ALen then begin
    while length(AValue) < ALen do begin
      AValue := AValue + ' ';
    end;
  end
  else if length(AValue) > ALen then
    AValue := copy(AValue, 1, ALen);
  result := AValue;
end;


function _PadL(AValue : string; ALen : integer): string;
begin
  if length(AValue) < ALen then begin
    while length(AValue) < ALen do begin
      AValue := ' ' + AValue;
    end;
  end
  else if length(AValue) > ALen then
    AValue := copy(AValue, length(AValue)-ALen, ALen);
  result := AValue;
end;


  { TtiLog }

constructor TtiLog.Create;
begin
  inherited;
  FCritSect := TCriticalSection.Create;
  FLogToList := TList.Create;
  FSevToLog := CSevToLogMedium;
end;


destructor TtiLog.Destroy;
var
  i : integer;
  lLog : TtiLogToAbs;
begin
  // Probably over the top to add thread safety here but better to be safe than sorry.
  FCritSect.Enter;
  try
    for i := FLogToList.Count - 1 downto 0 do
    begin
      lLog := TtiLogToAbs(FLogToList.Items[i]);
      FLogToList.Delete(i);
      lLog.Free;
    end;
  finally
    FCritSect.Leave;
  end;
  FLogToList.Free;
  FCritSect.Free;
  inherited;
end;


function TtiLog.FindByLogClass(ALogToClass: TtiLogToClass): TtiLogToAbs;
var
  i : integer;
begin
  result := nil;
  FCritSect.Enter;
  try
    for i := 0 to FLogToList.Count - 1 do
      if TObject(FLogToList.Items[i]) is ALogToClass then
      begin
        result := TtiLogToAbs(FLogToList.Items[i]);
        break; //==>
      end;
  finally
    FCritSect.Leave;
  end;
end;


function TtiLog.IsRegistered(const ALogToClass: TtiLogToClass): boolean;
begin
  result := FindByLogClass(ALogToClass) <> nil;
end;


procedure TtiLog.Log(const AMessage: string; const ASeverity: TtiLogSeverity = lsNormal);
var
  lsNow     : string;
  i         : integer;
  lsMessage : string;
  lsThreadID : string;
begin
  if UFinalization then
    Exit; //==>

  lsNow := _PadR(FormatDateTime(cIntlDateTimeDisp, Now), Length(cIntlDateTimeDisp));
  lsMessage := AMessage;

  lsThreadID := IntToStr(PtrUInt(GetCurrentThreadID));   // So it's compatible with MacOSX
  lsThreadID := _PadL(lsThreadID, cuiWidthThread);

  FCritSect.Enter;
  try
    for i := 0 to FLogToList.Count - 1 do
      TtiLogToAbs(FLogToList.Items[i]).Log(lsNow,
                                           lsThreadID,
                                           lsMessage,
                                           ASeverity);
  finally
    FCritSect.Leave;
  end;
end;


constructor TtiLogToAbs.Create;
begin
  inherited Create;
  FSevToLog := GLog.SevToLog;
  FTerminated := False;
end;


procedure TtiLogToAbs.Purge;
begin
  WriteToOutputSynchronized;
end;

function TtiLogToAbs.AcceptEvent(const ADateTime : string;
                                const AMessage : string;
                                ASeverity : TtiLogSeverity): boolean;
begin
  result := (ASeverity in FSevToLog);
end;


constructor TtiLogToCacheAbs.Create;
const
  CSynchronized = false;
begin
  inherited Create;
  FEnableCaching:= true;
  Init(CSynchronized);
end;


constructor TtiLogToCacheAbs.CreateSynchronized;
const
  CSynchronized = true;
begin
  inherited Create;
  Init(CSynchronized);
end;


// Call from all constructors.
procedure TtiLogToCacheAbs.Init(const ASynchronized: Boolean);
begin
  FList        := TList.Create;
  FListWorking := TtiLogEvents.Create;
  FCritSect    := TCriticalSection.Create;
  FThrdLog     := TtiThrdLog.CreateExt(self); // Must call FThrdLog.Resume in the descandant classes
  FSynchronized := ASynchronized;
end;


destructor TtiLogToCacheAbs.Destroy;
var
  i: integer;
begin
  Terminate;
  for i := FList.Count - 1 downto 0 do
    TObject(FList.Items[i]).Free;
  FThrdLog.Free;  // <== Add this, round about line 597 of tiLog.pas
  FList.Free;
  FListWorking.Free;
  FCritSect.Free;
  inherited;
end;


procedure TtiLogToCacheAbs.Log(const ADateTime : string;
                              const AThreadID : string;
                              const AMessage : string;
                              ASeverity : TtiLogSeverity);
var
  lLogEvent: TtiLogEvent;
begin
  if not AcceptEvent(ADateTime, AMessage, ASeverity) then
    Exit; //==>
  FCritSect.Enter;
  try
    lLogEvent := TtiLogEvent.Create;
    lLogEvent.DateTime  := ADateTime;
    lLogEvent.LogMessage := AMessage;
    lLogEvent.Severity  := ASeverity;
    lLogEvent.ThreadID  := AThreadID;
    FList.Add(lLogEvent);
  finally
    FCritSect.Leave;
  end;
  if Not FEnableCaching then
    WriteToOutput;
end;


procedure TtiLogToCacheAbs.SetEnableCaching(const AValue: boolean);
begin
  Assert(not AValue, 'Once turned off, caching can not be turned back on');
  Terminate;
  FEnableCaching := AValue;
end;

procedure TtiLogToCacheAbs.Terminate;
begin
  FThrdLog.Terminate;
  {$IFDEF FPC}
  { graemeg: 2009-05-04
    FPC handles WaitFor slightly different under Unix enviroments, so I rather
    do the following which seems safer. Delphi could probably also use this
    method. }
  while not FThrdLog.Terminated do sleep(100);
  {$ELSE}
  FThrdLog.WaitFor;
  {$ENDIF}
end;


procedure TtiLogToCacheAbs.WriteToOutput;
var
  i : integer;
begin
  for i := 0 to FList.Count - 1 do
    FListWorking.Add(TtiLogEvent(FList.Items[i]));
  FList.Clear;
end;


procedure TtiLogToCacheAbs.WriteToOutputSynchronized;
begin
  FCritSect.Enter;
  try
    WriteToOutput;
  finally
    FCritSect.Leave;
  end;
end;

function TtiLogEvent.AsLeftPaddedString: string;
var
  LMessagePrefix: string;
  LMessagePrefixLen: integer;
  LMessage: string;
  i: Integer;
begin
  // ToDo: This will need a going over for possible combinations of CrLf, Cr, LF, etc
  if Pos(Cr, LogMessage) = 0 then
    Result := GetFormattedMessageTimeStamp + LogMessage
  else
  begin
    LMessagePrefix:= GetFormattedMessageTimeStamp;
    LMessagePrefixLen:= Length(LMessagePrefix);
    Result := LMessagePrefix;
    LMessage := tiStrTran(LogMessage, CrLf, Cr);
    LMessage := tiStrTran(LMessage, Lf, Cr);
    for i:= 1 to tiNumToken(LMessage, Cr) do
    begin
      if i > 1 then
      begin
        Result := Result + CrLf + tiSpace(LMessagePrefixLen) + tiToken(LMessage, Cr, i);
      end else
        Result := Result + tiToken(LMessage, Cr, i);
    end;
  end;
end;


function TtiLogEvent.AsString: string;
begin
  result := GetFormattedMessageTimestamp +
            tiStrTran(LogMessage, Lf, '');
end;


function TtiLogEvent.AsStringStripCrLf: string;
begin
  result := _StrTran(AsString, Cr, ' ');
end;


function TtiLogEvent.GetFormattedMessageTimeStamp: string;
begin
  Result :=
    DateTime   + ' ' +
              FThreadID + ' ' +
              _PadR(cTILogSeverityStrings[ Severity ], cuiWidthSeverity) + ' ';
end;


function TtiLogEvent.GetSeverityAsString: string;
begin
  result := cTILogSeverityStrings[ Severity ];
end;


function TtiLogEvent.GetShortLogMessage: string;
var
  ls : string;
begin
  ls := LogMessage;
  if Length(ls) + 3 > cuiWidthShortMessage then
    result := Copy(ls, 1, cuiWidthShortMessage - 3) + '...'
  else
    result := ls;
end;


procedure TtiLogEvent.SetSeverityAsString(const AValue: string);
var
  i : TtiLogSeverity;
  lsSeverity : string;
begin
  lsSeverity := Trim(AValue);
  for i := Low(TtiLogSeverity) to High(TtiLogSeverity) do
  begin
    if lsSeverity = cTILogSeverityStrings[ i ] then
    begin
      Severity := i;
      Exit; //==>
    end;
  end;
  Assert(false, 'Severity <' + AValue + '> unknown');
end;


constructor TtiThrdLog.CreateExt(ALogTo : TtiLogToCacheAbs);
begin
  Create(true);
  Priority := tpLower;
  FLogTo   := ALogTo;
end;


procedure TtiThrdLog.Execute;
begin
  while SleepAndCheckTerminated(200) do
    if FLogTo.Synchronized then
      Synchronize(WriteToOutput)
    else
      WriteToOutput;
end;

procedure TtiThrdLog.SetLogTo(const AValue: TtiLogToCacheAbs);
begin
  FLogTo := AValue;
end;

function TtiLog.LogToFileName: string;
var
  LLogTo: TtiLogToFile;
begin
  LLogTo:= FindByLogClass(TtiLogToFile) as TtiLogToFile;
  if LLogTo <> nil then
    Result:= LLogTo.FileName
  else
    Result := '';
end;


procedure TtiLog.Purge;
var
  i: integer;
begin
  FCritSect.Enter;
  try
    for i := 0 to FLogToList.Count - 1 do
      TtiLogToAbs(FLogToList.Items[i]).Purge;
  finally
    FCritSect.Leave;
  end;
end;

procedure TtiLog.RegisterLog(ALogTo : TtiLogToAbs);
begin
  Assert(ALogTo.TestValid, CTIErrorInvalidObject);
  // It would be nice to be able to have multiple instances of the same LogTo
  // class, such as two TtiLogToFile, one main one logging to some admin
  // area for critical errors and another temporarily used for debugging such
  // that you can add the second without disturbing the first.
  // What to do with TtiLog.LogToFileName?
  if IsRegistered(TtiLogToClass(ALogTo.ClassType)) then
  begin
    ALogTo.Free;
    Exit; //==>
  end;
  FCritSect.Enter;
  try
    FLogToList.Add(ALogTo);
  finally
    FCritSect.Leave;
  end;
end;


procedure TtiLog.RegisterLog(ALogTo : TtiLogToClass);
begin
  Assert(ALogTo <> nil, 'ALogTo not assigned');
  RegisterLog(ALogTo.Create);
end;


procedure TtiThrdLog.tiSynchronize(AMethod: TThreadMethod);
begin
{ I just wanted to surface this from protected for tiLogErrorForm
  (in another unit). Brain went to sleep on correct syntax.
  (OK with property, but not with procedure.) }
  Synchronize(AMethod);
end;


procedure TtiThrdLog.WriteToOutput;
begin
  FLogTo.WriteToOutputSynchronized;
end;


procedure TtiLogToAbs.SetSevToLog(const AValue: TtiSevToLog);
begin
  FSevToLog := AValue;
end;


procedure TtiLogToAbs.Terminate;
begin
  // Do nothing, implement if required in the concrete
end;


procedure TtiLogToAbs.WriteToOutputSynchronized;
begin
  WriteToOutput;
end;

procedure TtiLogEvents.Add(AItem: TtiLogEvent);
begin
  FList.Add(AItem);
end;


procedure TtiLogEvents.Clear;
begin
  FList.Clear;
end;


function TtiLogEvents.Count: Integer;
begin
  Result := FList.Count;
end;


constructor TtiLogEvents.Create;
begin
  inherited;
  FList:= TObjectList.Create(True);
end;


destructor TtiLogEvents.Destroy;
begin
  FList.Free;
  inherited;
end;


function TtiLogEvents.GetItems(AIndex: Integer): TtiLogEvent;
begin
  Result := FList.Items[AIndex] as TtiLogEvent;
end;


procedure TtiLog.SetLogLevel(const Value: TtiLogLevel);
begin
  case Value of
  llMinimal: SevToLog:= CSevToLogMinimal;
  llMedium:  SevToLog:= CSevToLogMedium;
  llVerbose: SevToLog:= CSevToLogVerbose;
  llCustom: ;// Do nothing
  else
    Raise EtiOPFProgrammerException.Create('Unknown TtiLogLevel');
  end;
  FLogLevel := Value;
end;

procedure TtiLog.SetSevToLog(const AValue: TtiSevToLog);
var
  i : integer;
begin
  FCritSect.Enter;
  try
    if AValue = CSevToLogMinimal then
      FLogLevel:= llMinimal
    else if AValue = CSevToLogMedium then
      FLogLevel:= llMedium
    else if AValue = CSevToLogVerbose then
      FLogLevel:= llVerbose
    else
      FLogLevel:= llCustom;
    FSevToLog := AValue;
    for i := 0 to FLogToList.Count - 1 do
      TtiLogToAbs(FLogToList.Items[i]).SevToLog := AValue;
  finally
    FCritSect.Leave;
  end;
end;


function TtiLog.GetSevToLogAsString: string;
var
  LLogSeverity: TtiLogSeverity;
begin
  result := '';
  for LLogSeverity := Low(TtiLogSeverity) to High(TtiLogSeverity) do
    if LLogSeverity in FSevToLog then
    begin
      if result <> '' then
        result := result + ',';
      result := result + LogSeverityToString(LLogSeverity);
    end;
end;


procedure TtiLog.SetSevToLogAsString(const AValue: string);
var
  LSevToLog: TtiSevToLog;
  LLogSeverityList: TStringList;
  i: Integer;
  LLogSeverity: TtiLogSeverity;
begin
  LSevToLog := [];
  LLogSeverityList := TStringList.Create;
  try
    LLogSeverityList.CommaText := AValue;
    for i := 0 to LLogSeverityList.Count - 1 do
      if StringToLogSeverity(LLogSeverityList.Strings[i], LLogSeverity) then
        LSevToLog := LSevToLog + [LLogSeverity];
  finally
    LLogSeverityList.Free;
  end;
  SevToLog := LSevToLog;
end;


initialization
  UFinalization := false;

finalization
  UFinalization := true;
  FreeAndNil(ULog);

end.

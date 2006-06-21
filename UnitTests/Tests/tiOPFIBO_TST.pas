unit tiOPFIBO_TST;

{$I tiDefines.inc}

interface
uses
   tiQuery_TST
  ,tiQuerySQL_TST
  ,tiOPFTestManager
  ,tiTestFramework
  ,tiClassToDBMap_TST
  ,tiOID_tst
  ;

type

  TtiOPFTestSetupDataIBO = class( TtiOPFTestSetupData )
  public
    constructor Create ; override ;
  end ;

  TTestTIPersistenceLayersIBO = class( TTestTIPersistenceLayers )
  protected
    procedure Setup; override;
  end;

  TTestTIDatabaseIBO = class( TTestTIDatabase )
  protected
    procedure Setup; override;
  published
    procedure DatabaseExists ; override ;
    procedure CreateDatabase ; override ;
  end ;

  TTestTIQueryIBO = class( TTestTIQuerySQL )
  protected
    procedure   Setup; override;
  end;

  TTestTIClassToDBMapOperationIBO = class(TTestTIClassToDBMapOperation)
  protected
    procedure   Setup; override;
  end;

  TTestTIOIDManagerIBO = class(TTestTIOIDManager)
  protected
    procedure   Setup; override;
  end;

procedure RegisterTests;

implementation
uses
   tiConstants
  ,TestFramework
  ,SysUtils
  ,tiUtils
  ,tiDUnitDependencies
  ;

procedure RegisterTests ;
begin
  if gTIOPFTestManager.ToRun(cTIQueryTestName) then
  begin
    RegisterTest( cTIQueryTestName, TTestTIPersistenceLayersIBO.Suite);
    RegisterTest( cTIQueryTestName, TTestTIDatabaseIBO.Suite);
    RegisterTest( cTIQueryTestName, TTestTIQueryIBO.Suite);
    RegisterTest( cTIQueryTestName, TTestTIOIDManagerIBO.Suite);
    RegisterTest( cTIQueryTestName, TTestTIClassToDBMapOperationIBO.Suite);
  end;
end ;

{ TtiOPFTestSetupDataIBO }

constructor TtiOPFTestSetupDataIBO.Create;
begin
  inherited;
  {$IFNDEF STATIC_PERLAYER_LINKING}
    FEnabled := True;
  {$ELSE}
    {$IFDEF LINK_IBO}
      FEnabled := True;
    {$ELSE}
      FEnabled := False;
    {$ENDIF}
  {$ENDIF}
  FSelected:= FEnabled;
  FPerLayerName := cTIPersistIBO ;
  FDBName   := ReadFromReg( cTIPersistIBO, 'DBName', gTestDataRoot + '.ib' ) ;
  FUserName := ReadFromReg( cTIPersistIBO, 'UserName', 'SYSDBA') ;
  FPassword := ReadFromReg( cTIPersistIBO, 'Password', 'masterkey') ;
  FCanCreateDatabase := false ;
end;

{ TTestTIDatabaseIBO }

procedure TTestTIDatabaseIBO.CreateDatabase;
var
  lDB : string ;
  lDBExists : boolean ;
begin
  lDB := ExpandFileName( PerFrameworkSetup.DBName ) ;
  lDB := tiSwapExt( lDB, 'tmp' ) ;
  if FileExists( lDB ) then
  begin
    SysUtils.DeleteFile( lDB ) ;
    if FileExists( lDB ) then
      Fail( 'Can not remove old database file' ) ;
  end ;

  Check( not FileExists( lDB ), 'Database exists when it should not' ) ;
  FDatabaseClass.CreateDatabase(
    lDB,
    PerFrameworkSetup.Username,
    PerFrameworkSetup.Password ) ;
  Check( FileExists( lDB ), 'Database not created' ) ;

  lDBExists :=
    FDatabaseClass.DatabaseExists(
      lDB,
      PerFrameworkSetup.Username,
      PerFrameworkSetup.Password ) ;

  Check( lDBExists, 'Database does not exist when it should do' ) ;
  SysUtils.DeleteFile( lDB ) ;
end;

procedure TTestTIDatabaseIBO.DatabaseExists;
var
  lDB : string ;
  lDBExists : boolean ;
begin
  lDB := PerFrameworkSetup.DBName ;
  Check( FileExists( lDB ), 'Database file not found so test can not be performed' ) ;
  lDBExists :=
    FDatabaseClass.DatabaseExists(
      PerFrameworkSetup.DBName,
      PerFrameworkSetup.Username,
      PerFrameworkSetup.Password ) ;
  Check( lDBExists, 'DBExists returned false when it should return true' ) ;
  Check( not FileExists( lDB + 'Tmp' ), 'Database file found so test can not be performed' ) ;
  lDBExists :=
    FDatabaseClass.DatabaseExists(
      PerFrameworkSetup.DBName + 'Tmp',
      PerFrameworkSetup.Username,
      PerFrameworkSetup.Password ) ;
  Check( not lDBExists, 'DBExists returned true when it should return false' ) ;
end;

{ TtiOPFTestSetupDecoratorIBO }

procedure TTestTIDatabaseIBO.Setup;
begin
  PerFrameworkSetup:= gTIOPFTestManager.FindByPerLayerName(cTIPersistIBO);
  inherited;
end;

{ TTestTIPersistenceLayersIBO }

procedure TTestTIPersistenceLayersIBO.Setup;
begin
  PerFrameworkSetup:= gTIOPFTestManager.FindByPerLayerName(cTIPersistIBO);
  inherited;
end;

{ TTestTIQueryIBO }

procedure TTestTIQueryIBO.Setup;
begin
  PerFrameworkSetup:= gTIOPFTestManager.FindByPerLayerName(cTIPersistIBO);
  inherited;
end;

procedure TTestTIClassToDBMapOperationIBO.Setup;
begin
  PerFrameworkSetup:= gTIOPFTestManager.FindByPerLayerName(cTIPersistIBO);
  inherited;
end;

{ TTestTIOIDManagerXMLLight }

procedure TTestTIOIDManagerIBO.Setup;
begin
  PerFrameworkSetup:= gTIOPFTestManager.FindByPerLayerName(cTIPersistIBO);
  inherited;
end;

end.

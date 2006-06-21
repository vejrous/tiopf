program fpcUnitTIOPFText;

{$mode objfpc}{$H+}

uses
  custapp, classes, sysutils, fpcunit,
  testreport, testregistry, tiDUnitDependencies;


const
  ShortOpts = 'alh';
  Longopts: Array[1..5] of String = (
      'all', 'list', 'format:', 'suite:', 'help');
  Version = 'Version 0.1';


type
  TTestRunner = class(TCustomApplication)
  private
    FXMLResultsWriter: TXMLResultsWriter;
  protected
    procedure DoRun ; override;
    procedure doTestRun(aTest: TTest); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;


constructor TTestRunner.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FXMLResultsWriter := TXMLResultsWriter.Create;
end;


destructor TTestRunner.Destroy;
begin
  FXMLResultsWriter.Free;
end;


procedure TTestRunner.doTestRun(aTest: TTest);
var
  testResult: TTestResult;
begin
  testResult := TTestResult.Create;
  try
    testResult.AddListener(FXMLResultsWriter);
    FXMLResultsWriter.WriteHeader;
    aTest.Run(testResult);
    FXMLResultsWriter.WriteResult(testResult);
  finally
    testResult.Free;
  end;
end;


procedure TTestRunner.DoRun;
var
  I : Integer;
  S : String;
begin
  S:=CheckOptions(ShortOpts,LongOpts);
  If (S<>'') then
    Writeln(S);
  if HasOption('h', 'help') or (ParamCount = 0) then
  begin
    writeln(Title);
    writeln(Version);
    writeln('Usage: ');
    writeln('-l or --list to show a list of registered tests');
    writeln('default format is xml, add --format=latex to output the list as latex source');
    writeln('-a or --all to run all the tests and show the results in xml format');
    writeln('The results can be redirected to an xml file,');
    writeln('for example: ./testrunner --all > results.xml');
    writeln('use --suite=MyTestSuiteName to run only the tests in a single test suite class');
  end;
  if HasOption('l', 'list') then
  begin
    if HasOption('format') then
    begin
      if GetOptionValue('format') = 'latex' then
        writeln(GetSuiteAsLatex(GetTestRegistry))
      else
        writeln(GetSuiteAsXML(GetTestRegistry));
    end
    else
      writeln(GetSuiteAsXML(GetTestRegistry));
  end;
  if HasOption('a', 'all') then
  begin
    doTestRun(GetTestRegistry)
  end
  else
    if HasOption('suite') then
    begin
      S := '';
      S:=GetOptionValue('suite');
      if S = '' then
        for I := 0 to GetTestRegistry.Tests.count - 1 do
          writeln(GetTestRegistry[i].TestName)
      else
        for I := 0 to GetTestRegistry.Tests.count - 1 do
          if GetTestRegistry[i].TestName = S then
          begin
            doTestRun(GetTestRegistry[i]);
          end;
    end;
  Terminate;
end;


var
  App : TTestRunner;


begin
  App:=TTestRunner.Create(Nil);
  App.Initialize;
  App.Title := 'FPCUnit Console Test Case runner.';
  
  tiDUnitDependencies.RegisterTests;
  
  App.Run;
  App.Free;
end.


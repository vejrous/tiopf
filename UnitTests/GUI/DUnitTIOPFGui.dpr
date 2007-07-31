program DUnitTIOPFGui;

uses
  FastMM4,
  madExcept,
  madLinkDisAsm,
  tiBaseObject,
  tiLog,
  Forms,
  TestFramework,
  GUITestRunner,
  tiLogToGUI,
  tiDUnitDependencies in '..\Common\tiDUnitDependencies.pas',
  tiPromptWhichPersistenceLayersToTest in '..\Common\tiPromptWhichPersistenceLayersToTest.pas',
  tiGUIUtils_TST in '..\Tests\tiGUIUtils_TST.pas';

{$R *.RES}

begin
  RegisterExpectedTIOPFMemoryLeaks;
  if not TtiPromptWhichPersistenceLayersToTest.Execute then
    Halt;
  Application.Initialize;
  tiDUnitDependencies.RegisterTests;
  GUITestRunner.RunRegisteredTests;
end.


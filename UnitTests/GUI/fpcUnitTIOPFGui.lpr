program fpcUnitTIOPFGui;

{$I tiDefines.inc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces
  ,Forms
  ,GuiTestRunner
  ,tiDUnitINI
  ,tiPromptWhichPersistenceLayersToTest
  ,tiDUnitDependencies
  , tiRTTI_TST;
  

begin
  Application.Title:='fpcUnit TIOPF Gui';
  Application.Initialize;
  
  if not TtiPromptWhichPersistenceLayersToTest.Execute then
    Halt;

  tiDUnitDependencies.RegisterTests;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.


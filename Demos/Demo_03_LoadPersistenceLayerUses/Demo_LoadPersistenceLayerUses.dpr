program Demo_LoadPersistenceLayerUses;

{$I tiDefines.inc}

// Adding a tiQueryXXX unit to your project will force that
// persistence layer to be loaded.
// When you run this demo, a dialog will show listing
// the loaded persistence layers. (Note, the dialog will
// say the database is not connected - which is correct.)
uses
  DemoDBUtils in '..\Common\DemoDBUtils.pas'
  {$IFDEF FPC}
  ,tiQuerySqldbIB
  {$ELSE}
  ,tiQueryIBX
  {$ENDIF}
  ,tiQueryXMLLight
  ,tiQueryCSV
  {$IFDEF MSWINDOWS}
  ,tiQueryXML
  ,tiQueryADOAccess
  {$ENDIF}
  ;

{$R *.res}

begin
  ShowConnectedDatabases;
end.


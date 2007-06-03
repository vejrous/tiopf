inherited FormMainConnectToDBCode: TFormMainConnectToDBCode
  Left = 384
  Top = 198
  Caption = 'FormMainConnectToDBCode'
  ClientHeight = 251
  ClientWidth = 524
  OldCreateOrder = True
  ExplicitWidth = 530
  ExplicitHeight = 283
  PixelsPerInch = 96
  TextHeight = 13
  inherited GroupBox1: TGroupBox
    Left = 8
    Width = 508
    ExplicitLeft = 8
    ExplicitWidth = 508
    inherited sbDefaultToPresetValues: TtiSpeedButton
      Left = 347
      ExplicitLeft = 347
    end
    inherited paePersistenceLayer: TtiPerAwareEdit
      Width = 332
      ExplicitWidth = 332
    end
    inherited paeDatabaseName: TtiPerAwareEdit
      Width = 332
      ExplicitWidth = 332
    end
    inherited paeUserName: TtiPerAwareEdit
      Width = 332
      ExplicitWidth = 332
    end
    inherited paePassword: TtiPerAwareEdit
      Width = 332
      ExplicitWidth = 332
    end
  end
  object btnConnectToDatabase: TButton [1]
    Left = 8
    Top = 187
    Width = 241
    Height = 25
    Caption = 'Connect to the database show above'
    TabOrder = 3
    OnClick = btnConnectToDatabaseClick
  end
  object btnDisconnectFromDatabase: TButton [2]
    Left = 8
    Top = 218
    Width = 241
    Height = 25
    Caption = 'Disconnect from the database shown above'
    TabOrder = 1
    OnClick = btnDisconnectFromDatabaseClick
  end
  object btnShowWhatsConnected: TButton [3]
    Left = 8
    Top = 156
    Width = 241
    Height = 25
    Caption = 'Show what'#39's connected'
    TabOrder = 2
    OnClick = btnShowWhatsConnectedClick
  end
end

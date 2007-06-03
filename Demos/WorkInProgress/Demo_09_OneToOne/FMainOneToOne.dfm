object FormMainInheritance: TFormMainInheritance
  Left = 297
  Top = 107
  Caption = 'FormMainInheritance'
  ClientHeight = 350
  ClientWidth = 540
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    540
    350)
  PixelsPerInch = 96
  TextHeight = 13
  object Button2: TButton
    Left = 429
    Top = 246
    Width = 101
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Show Objects'
    TabOrder = 0
    OnClick = Button2Click
    ExplicitLeft = 420
    ExplicitTop = 240
  end
  object Button1: TButton
    Left = 429
    Top = 278
    Width = 101
    Height = 25
    Action = aSave
    Anchors = [akRight, akBottom]
    TabOrder = 1
    ExplicitLeft = 420
    ExplicitTop = 272
  end
  object btnRead: TButton
    Left = 429
    Top = 310
    Width = 101
    Height = 25
    Action = aRead
    Anchors = [akRight, akBottom]
    TabOrder = 2
    ExplicitLeft = 420
    ExplicitTop = 304
  end
  object lvClient: TtiVTListView
    Left = 8
    Top = 8
    Width = 410
    Height = 327
    Anchors = [akLeft, akTop, akRight, akBottom]
    Header.AutoSizeIndex = 0
    Header.Font.Charset = DEFAULT_CHARSET
    Header.Font.Color = clWindowText
    Header.Font.Height = -11
    Header.Font.Name = 'Tahoma'
    Header.Font.Style = []
    Header.MainColumn = -1
    Header.Options = [hoColumnResize, hoDrag, hoVisible]
    Header.Style = hsXPStyle
    ShowAlternateRowColor = False
    SortOrders.GroupColumnCount = 0
    SortOrders = <>
    VisibleButtons = [tiLVBtnVisEdit, tiLVBtnVisNew, tiLVBtnVisDelete]
    VT.Left = 2
    VT.Top = 26
    VT.Width = 406
    VT.Height = 299
    VT.Align = alClient
    VT.Header.AutoSizeIndex = 0
    VT.Header.Font.Charset = DEFAULT_CHARSET
    VT.Header.Font.Color = clWindowText
    VT.Header.Font.Height = -11
    VT.Header.Font.Name = 'Tahoma'
    VT.Header.Font.Style = []
    VT.Header.MainColumn = -1
    VT.Header.Options = [hoColumnResize, hoDrag, hoVisible]
    VT.Header.Style = hsXPStyle
    VT.NodeDataSize = 4
    VT.TabOrder = 0
    VT.TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowRoot, toShowVertGridLines, toThemeAware, toUseBlendedImages]
    VT.TreeOptions.SelectionOptions = [toFullRowSelect]
    VT.ExplicitTop = 2
    VT.ExplicitWidth = 181
    VT.ExplicitHeight = 37
    VT.Columns = <>
    OnFilterData = lvClientFilterData
    OnItemDelete = lvClientItemDelete
    OnItemEdit = lvClientItemEdit
    OnItemInsert = lvClientItemInsert
    ExplicitWidth = 401
    ExplicitHeight = 321
  end
  object ActionList1: TActionList
    OnUpdate = ActionList1Update
    Left = 420
    Top = 204
    object aSave: TAction
      Caption = 'Save'
      OnExecute = aSaveExecute
    end
    object aRead: TAction
      Caption = 'Read'
      OnExecute = aReadExecute
    end
  end
end

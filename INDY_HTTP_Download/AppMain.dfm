object FormMain: TFormMain
  Left = 220
  Top = 134
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'INDY HTTP Download'
  ClientHeight = 249
  ClientWidth = 481
  Color = clBtnFace
  Font.Charset = RUSSIAN_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 120
  TextHeight = 16
  object LblCurLine: TLabel
    Left = 8
    Top = 176
    Width = 65
    Height = 16
    Caption = 'Current file:'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object LblTotLine: TLabel
    Left = 8
    Top = 200
    Width = 69
    Height = 16
    Caption = 'Total count:'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object LblFicNull: TLabel
    Left = 8
    Top = 224
    Width = 89
    Height = 16
    Caption = 'Files not found:'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 70
    Height = 16
    Caption = 'Destination:'
  end
  object LblCurrent: TLabel
    Left = 176
    Top = 104
    Width = 45
    Height = 16
    Caption = 'Current:'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object LblTemps: TLabel
    Left = 8
    Top = 128
    Width = 62
    Height = 16
    Caption = 'Time total:'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object LblTot: TLabel
    Left = 8
    Top = 104
    Width = 74
    Height = 16
    Caption = 'Downloads: '
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Max: TLabel
    Left = 312
    Top = 104
    Width = 28
    Height = 16
    Caption = 'Max:'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Bevel1: TBevel
    Left = 8
    Top = 160
    Width = 465
    Height = 9
    Shape = bsTopLine
  end
  object BtnBrowseDest: TButton
    Left = 440
    Top = 31
    Width = 33
    Height = 26
    Caption = '...'
    TabOrder = 0
    OnClick = BtnBrowseDestClick
  end
  object BtnOpenTxt: TButton
    Left = 7
    Top = 64
    Width = 162
    Height = 25
    Caption = 'Open CSV'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = BtnOpenTxtClick
  end
  object BtnOpenVar: TButton
    Left = 312
    Top = 64
    Width = 161
    Height = 25
    Caption = 'Open TXT'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = BtnOpenVarClick
  end
  object BtnPause: TButton
    Left = 176
    Top = 64
    Width = 129
    Height = 25
    Caption = 'Pause'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnClick = BtnPauseClick
  end
  object EdtDest: TEdit
    Left = 8
    Top = 31
    Width = 425
    Height = 26
    TabOrder = 4
  end
  object EdtNumMax: TEdit
    Left = 392
    Top = 96
    Width = 81
    Height = 24
    TabOrder = 5
    Text = '5'
  end
  object OpnDlg: TOpenDialog
    Filter = 'Fichier CSV|*.csv'
    Left = 248
    Top = 118
  end
end

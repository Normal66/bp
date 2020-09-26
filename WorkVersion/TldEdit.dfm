object fmTldEdit: TfmTldEdit
  Left = 192
  Top = 107
  BorderStyle = bsDialog
  Caption = 'Edit tld* File'
  ClientHeight = 453
  ClientWidth = 688
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 412
    Width = 688
    Height = 41
    Align = alBottom
    TabOrder = 0
    object BitBtn1: TBitBtn
      Left = 472
      Top = 3
      Width = 100
      Height = 34
      TabOrder = 0
      Kind = bkCancel
    end
    object BitBtn2: TBitBtn
      Left = 584
      Top = 3
      Width = 100
      Height = 34
      TabOrder = 1
      OnClick = BitBtn2Click
      Kind = bkYes
    end
  end
  object edTld: TMemo
    Left = 0
    Top = 0
    Width = 688
    Height = 412
    Align = alClient
    TabOrder = 1
  end
  object odTLD: TOpenDialog
    DefaultExt = '*.txt'
    Left = 32
    Top = 16
  end
end

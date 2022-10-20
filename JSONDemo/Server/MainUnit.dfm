object RestServerForm: TRestServerForm
  Left = 0
  Top = 0
  Caption = 'REST Server Demo'
  ClientHeight = 855
  ClientWidth = 1511
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 15
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1511
    Height = 57
    Align = alTop
    BevelOuter = bvNone
    Caption = 'Panel1'
    ShowCaption = False
    TabOrder = 0
    ExplicitWidth = 1573
    DesignSize = (
      1511
      57)
    object Label1: TLabel
      Left = 16
      Top = 21
      Width = 73
      Height = 15
      Caption = 'Listening port'
    end
    object Edit1: TEdit
      Left = 104
      Top = 18
      Width = 65
      Height = 23
      TabOrder = 0
      Text = '80'
    end
    object Button1: TButton
      Left = 192
      Top = 17
      Width = 75
      Height = 25
      Action = AStartServer
      TabOrder = 1
    end
    object Button2: TButton
      Left = 273
      Top = 17
      Width = 75
      Height = 25
      Action = AStopServer
      TabOrder = 2
    end
    object Button3: TButton
      Left = 1421
      Top = 17
      Width = 75
      Height = 25
      Action = AClearLog
      Anchors = [akTop, akRight]
      TabOrder = 3
      ExplicitLeft = 1483
    end
  end
  object Memo1: TMemo
    Left = 0
    Top = 57
    Width = 1511
    Height = 798
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Consolas'
    Font.Style = []
    Lines.Strings = (
      '')
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 1
    ExplicitWidth = 1573
    ExplicitHeight = 1287
  end
  object ActionList1: TActionList
    Left = 400
    Top = 16
    object AStartServer: TAction
      Caption = 'Start'
      OnExecute = AStartServerExecute
    end
    object AStopServer: TAction
      Caption = 'Stop'
      OnExecute = AStopServerExecute
    end
    object AClearLog: TAction
      Caption = 'Clear log'
      OnExecute = AClearLogExecute
    end
  end
  object IdHTTPServer1: TIdHTTPServer
    OnStatus = IdHTTPServer1Status
    Bindings = <>
    OnConnect = IdHTTPServer1Connect
    OnDisconnect = IdHTTPServer1Disconnect
    OnException = IdHTTPServer1Exception
    OnListenException = IdHTTPServer1ListenException
    AutoStartSession = True
    ServerSoftware = 'Demo'
    OnCommandGet = IdHTTPServer1CommandGet
    Left = 448
    Top = 184
  end
  object IdServerIOHandlerSSLOpenSSL1: TIdServerIOHandlerSSLOpenSSL
    SSLOptions.Method = sslvTLSv1_2
    SSLOptions.SSLVersions = [sslvTLSv1_2]
    SSLOptions.Mode = sslmUnassigned
    SSLOptions.VerifyMode = []
    SSLOptions.VerifyDepth = 0
    Left = 552
    Top = 16
  end
end

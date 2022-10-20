unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  IdBaseComponent, IdComponent, IdCustomTCPServer, IdCustomHTTPServer,
  IdHTTPServer, Vcl.StdCtrls, Vcl.ExtCtrls, IdContext, IdServerIOHandler, IdSSL,
  IdSSLOpenSSL, CustomerClass,
  System.Generics.Collections,
  IdHeaderList,
  System.NetEncoding,
  System.JSON,
  System.JSON.Types,
  System.JSON.BSON,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Builders;

type
  TRestServerForm = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    ActionList1: TActionList;
    Memo1: TMemo;
    IdHTTPServer1: TIdHTTPServer;
    AStartServer: TAction;
    AStopServer: TAction;
    AClearLog: TAction;
    Button3: TButton;
    IdServerIOHandlerSSLOpenSSL1: TIdServerIOHandlerSSLOpenSSL;
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    procedure AStartServerExecute(Sender: TObject);
    procedure AStopServerExecute(Sender: TObject);
    procedure IdHTTPServer1Status(ASender: TObject; const AStatus: TIdStatus;
      const AStatusText: string);
    procedure IdHTTPServer1ListenException(AThread: TIdListenerThread;
      AException: Exception);
    procedure IdHTTPServer1Exception(AContext: TIdContext;
      AException: Exception);
    procedure IdHTTPServer1Disconnect(AContext: TIdContext);
    procedure IdHTTPServer1Connect(AContext: TIdContext);
    procedure IdHTTPServer1CommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure AClearLogExecute(Sender: TObject);
  private
    { Private declarations }
    FMsgHandle : THandle;
    procedure ReportDebugText(aText : string);
    procedure MessageHandler(var WMS: TMessage);
    function HandleRequest(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo) : boolean;
    procedure EventHTTPCreatePostStream(AContext: TIdContext; AHeaders: TIdHeaderList; var VPostStream: TStream);
    procedure EventHTTPDoneWithPostStream(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var VCanFree: Boolean);
  public
    { Public declarations }
    function ProcessMessages : Cardinal;
    procedure Log(aText : string);
  end;

var
  RestServerForm: TRestServerForm;

implementation

{$R *.dfm}

const

     // Windows messages
     CM_RESTSRV_BASE        = $B000 + $E0;
     CM_RESTSRV_STATUS      = CM_RESTSRV_BASE + 1;
     CM_RESTSRV_DEBUGTEXT   = CM_RESTSRV_BASE + 2;


constructor TRestServerForm.Create(AOwner : TComponent);
begin
 inherited Create(AOwner);
 FMsgHandle := AllocateHWnd(MessageHandler);
 IdHTTPServer1.DefaultPort := 80;
 IdHTTPServer1.OnCreatePostStream := EventHTTPCreatePostStream;
 IdHTTPServer1.OnDoneWithPostStream := EventHTTPDoneWithPostStream;
end;

destructor TRestServerForm.Destroy;
begin
 IdHTTPServer1.Active := false;
 ProcessMessages;
 DeallocateHWnd(FMsgHandle);
 inherited Destroy;
end;

procedure TRestServerForm.EventHTTPCreatePostStream(AContext: TIdContext; AHeaders: TIdHeaderList; var VPostStream: TStream);
begin
 VPostStream := TBytesStream.Create;
end;

procedure TRestServerForm.EventHTTPDoneWithPostStream(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var VCanFree: Boolean);
begin
 VCanFree := false;
end;


function TryPostStreamToString(const aRequestInfo: TIdHTTPRequestInfo; var aOut : string) : boolean;
var aBytes : TBytes;
begin
 result := false;
 aOut := '';
 if Assigned(aRequestInfo) then begin
  try
   if ARequestInfo.CommandType = hcPOST then begin
    if (ARequestInfo.PostStream is TBytesStream) then begin
     aBytes := TBytesStream(ARequestInfo.PostStream).Bytes;
     SetLength(aBytes,ARequestInfo.PostStream.Size);
     if SameText(ARequestInfo.CharSet,'utf-8') then begin
      aOut := Trim(TEncoding.UTF8.GetString(aBytes));
      result := true;
     end else if SameText(ARequestInfo.CharSet,'utf-16') then begin
      aOut := Trim(TEncoding.Unicode.GetString(aBytes));
      result := true;
     end else if SameText(ARequestInfo.CharSet,'utf-7') then begin
      aOut := Trim(TEncoding.UTF7.GetString(aBytes));
      result := true;
     end else begin
      aOut := Trim(TEncoding.UTF8.GetString(aBytes));
      result := true;
     end;
    end;
   end;
  except
   result := false;
  end;
 end;
end;

function TRestServerForm.HandleRequest(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo) : boolean;
var aJr : TJsonTextReader;
    aSr : TStringReader;

    aCustomer : TCustomer;
    aWriter: TJsonTextWriter;
    aStringWriter: TStringWriter;
    aBuilder: TJSONObjectBuilder;
    aJSON,aJsCur : TJSONCollectionBuilder.TPairs;
    aStr : string;
begin
 result := false;
 if (ARequestInfo.CommandType in [hcPOST]) then begin
  if TryPostStreamToString(ARequestInfo,aStr) then begin
   ReportDebugText(aStr);

   aCustomer := TCustomer.Create;
   try
    {$REGION 'Read request'}
     aSr := TStringReader.Create(aStr);
     aJr := TJsonTextReader.Create(aSr);
     try
      aCustomer.ReadFromJSON(aJr);
     finally
      aJr.Free;
      aSr.Free;
     end;
    {$ENDREGION}

    {$REGION 'Change some data'}
    aCustomer.Name := 'Hello ' + aCustomer.Name;
    {$ENDREGION}

    {$REGION 'Create response'}
    aStringWriter := TStringWriter.Create;
    aWriter := TJsonTextWriter.Create(aStringWriter);
    aWriter.Formatting := TJsonFormatting.Indented;
    aBuilder := TJSONObjectBuilder.Create(aWriter);
    try
     aJSON := aBuilder.BeginObject;
     aCustomer.AddToJSON(aJSON);
     aJSON.EndObject;
     AResponseInfo.ResponseNo := 200;
     AResponseInfo.ContentType := 'application/json; charset=utf-8';
     AResponseInfo.ContentText := aStringWriter.ToString;
    finally
     aBuilder.Free;
     aWriter.Free;
     aStringWriter.Free;
    end;
    {$ENDREGION}

   finally
    aCustomer.Free;
   end;

   result := true;
  end;

 end else begin
  AResponseInfo.ResponseNo := 405;
  AResponseInfo.CustomHeaders.Values['Allow'] := 'POST';
  AResponseInfo.ContentType := 'application/json; charset=utf-8';
  AResponseInfo.ContentText := Format('{"Result": false, "ResponseNo": %u}',[AResponseInfo.ResponseNo]);
  result := true;
 end;
end;


procedure TRestServerForm.IdHTTPServer1CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
 if (AContext is TIdServerContext) then begin
  if Assigned(TIdServerContext(AContext).Connection) then begin
   ReportDebugText('['+ARequestInfo.Command+'] - '+ARequestInfo.URI);
   AResponseInfo.ResponseNo := 200;
   try
    HandleRequest(AContext,ARequestInfo,AResponseInfo);
   except
    on E:Exception do begin
     AResponseInfo.ResponseNo := 500;
     AResponseInfo.ContentType := 'application/json; charset=utf-8';
     AResponseInfo.ContentText := Format('{"responseno": %u}',[AResponseInfo.ResponseNo]);
     ReportDebugText('API_CALL: '+ARequestInfo.URI+' ('+inttostr(AResponseInfo.ResponseNo)+') Exception: '+E.Message);
    end;
   end;
  end;
 end;
end;

procedure TRestServerForm.IdHTTPServer1Connect(AContext: TIdContext);
begin
 if (AContext <> nil) and (AContext.Connection <> nil) and (AContext.Connection.Socket <> nil) then begin
  ReportDebugText('Connect - '+AContext.Connection.Socket.Binding.PeerIP);
 end;
end;

procedure TRestServerForm.IdHTTPServer1Disconnect(AContext: TIdContext);
begin
 if (AContext <> nil) and (AContext.Connection <> nil) and (AContext.Connection.Socket <> nil) then begin
  ReportDebugText('Disconnect - '+AContext.Connection.Socket.Binding.PeerIP);
 end;
end;

procedure TRestServerForm.IdHTTPServer1Exception(AContext: TIdContext;
  AException: Exception);
begin
 if (AException <> nil) then begin
  ReportDebugText(AException.ToString);
 end;
end;

procedure TRestServerForm.IdHTTPServer1ListenException(AThread: TIdListenerThread;
  AException: Exception);
begin
 if (AException <> nil) then begin
  ReportDebugText(AException.ToString);
 end;
end;

procedure TRestServerForm.IdHTTPServer1Status(ASender: TObject; const AStatus: TIdStatus;
  const AStatusText: string);
begin
 ReportDebugText(AStatusText);
end;

procedure TRestServerForm.Log(aText : string);
begin
 Memo1.Lines.Add(aText);
end;

procedure TRestServerForm.MessageHandler(var WMS: TMessage);
var AData : pointer;
    ADataSize : integer;
    aText : string;
begin
 try
  case WMS.Msg of
   CM_RESTSRV_DEBUGTEXT: begin
    ADataSize := WMS.LParam;
    AData := Ptr(WMS.WParam);
    if (ADataSize > 0) then begin
     SetLength(aText,(ADataSize div SizeOf(Char)));
     Move(AData^,aText[1],ADataSize);
     Log(Trim(aText));
     FreeMem(AData,ADataSize);
    end;
   end;
  else
   WMS.Result := DefWindowProc(FMsgHandle,WMS.Msg,WMS.wParam,WMS.lParam);
  end;
 except
  on E:Exception do begin
   Log('Exception in MessageHandler: '+E.Message);
  end;
 end;
end;

function TRestServerForm.ProcessMessages : Cardinal;
var Msg : TMsg;
    ConvMsg : TMessage;
begin
 result := 0;
 if (FMsgHandle <> 0) then begin
  while PeekMessage(Msg,FMsgHandle,0,$FFFFFFFF,PM_REMOVE) do begin
   ConvMsg.Msg := Msg.message;
   ConvMsg.Result := 0;
   ConvMsg.WParam := Msg.wParam;
   ConvMsg.LParam := Msg.lParam;
   MessageHandler(ConvMsg);
   inc(result);
   if ((result mod 10) = 0) then begin
    //TThread.Yield;
    Sleep(10);
   end;
  end;
 end;
end;

procedure TRestServerForm.ReportDebugText(aText : string);
var aData : pointer;
    aSize : integer;
begin
 aText := aText + ' ('+inttostr(GetCurrentThreadId)+')';
 aSize := Length(aText)*SizeOf(Char);
 if (aSize > 0) then begin
  GetMem(aData,aSize);
  Move(aText[1],aData^,aSize);
  PostMessage(FMsgHandle,CM_RESTSRV_DEBUGTEXT,WPARAM(aData),LPARAM(aSize));
 end;
end;

procedure TRestServerForm.AClearLogExecute(Sender: TObject);
begin
 Memo1.Clear;
end;

procedure TRestServerForm.AStartServerExecute(Sender: TObject);
begin
 if IdHTTPServer1.Active then IdHTTPServer1.Active := false;
 IdHTTPServer1.DefaultPort := StrToIntDef(Edit1.Text,IdHTTPServer1.DefaultPort);
 IdHTTPServer1.Active := true;
end;

procedure TRestServerForm.AStopServerExecute(Sender: TObject);
begin
 IdHTTPServer1.Active := false;
end;

end.

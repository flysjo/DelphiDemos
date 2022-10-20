unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, JSON.Serializers, Vcl.StdCtrls,
  Vcl.ExtCtrls, REST.Client, System.ImageList, Vcl.ImgList,
  Vcl.VirtualImageList, Vcl.BaseImageCollection, Vcl.ImageCollection,
  System.Actions, Vcl.ActnList, Data.Bind.Components, Data.Bind.ObjectScope,
  REST.Types, REST.Json.Types, REST.Json, CustomerClass, Vcl.ComCtrls,
  System.Generics.Collections,
  System.NetEncoding,
  System.JSON,
  System.JSON.Types,
  System.JSON.BSON,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Builders;

type
  TMainForm = class(TForm)
    Memo1: TMemo;
    GridPanel1: TGridPanel;
    Splitter1: TSplitter;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Shape1: TShape;
    Shape2: TShape;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Button1: TButton;
    ActionList1: TActionList;
    ImageCollection1: TImageCollection;
    VirtualImageList1: TVirtualImageList;
    AObjectToJSON: TAction;
    AJSONToObject: TAction;
    AMakeRESTCall: TAction;
    Button2: TButton;
    Button3: TButton;
    Label4: TLabel;
    Edit1: TEdit;
    Label5: TLabel;
    Edit2: TEdit;
    RESTRequest1: TRESTRequest;
    RESTResponse1: TRESTResponse;
    RESTClient1: TRESTClient;
    memJSON: TMemo;
    cbActive: TCheckBox;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    edtName: TEdit;
    edtPhone: TEdit;
    edtEmail: TEdit;
    EdtZip: TEdit;
    edtCity: TEdit;
    edtCredits: TEdit;
    dtpBirthdate: TDateTimePicker;
    Shape3: TShape;
    ComboBox1: TComboBox;
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    procedure AMakeRESTCallExecute(Sender: TObject);
    procedure AObjectToJSONExecute(Sender: TObject);
    procedure AJSONToObjectExecute(Sender: TObject);
    procedure RESTRequest1AfterExecute(Sender: TCustomRESTRequest);
  private
    { Private declarations }
    FRestCli : TRESTClient;
    procedure InitRestClient;

    procedure CustomerToUI(aObj : TCustomer);
    procedure UIToCustomer(aObj : TCustomer);

  public
    { Public declarations }
    procedure Log(aText : string);

    procedure UpdateJSONByRTTI;
    procedure UpdateJSONByBuilder;

    procedure JSONToObjectByRTTI;
    procedure JSONToObjectByBuilder;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

// https://docwiki.embarcadero.com/RADStudio/Sydney/en/REST_Client_Library

{ TForm1 }

constructor TMainForm.Create(AOwner: TComponent);
begin
 inherited Create(AOwner);
 FRestCli := TRESTClient.Create(nil);
 CustomerToUI(nil);
end;

destructor TMainForm.Destroy;
begin
 FRestCli.Free;
 inherited Destroy;
end;

procedure TMainForm.InitRestClient;
begin
 FRestCli.BaseURL := 'http://127.0.0.1'; //'http://www.songsterr.com/a/ra/';
end;

procedure TMainForm.Log(aText : string);
begin
 Memo1.Lines.Add(aText);
end;

procedure TMainForm.CustomerToUI(aObj : TCustomer);
begin
 if Assigned(aObj) then begin
  cbActive.Checked := aObj.Active;
  edtName.Text := aObj.Name;
  edtPhone.Text := aObj.Phone;
  edtEmail.Text := aObj.Email;
  EdtZip.Text := inttostr(aObj.Zip);
  edtCity.Text := aObj.City;
  edtCredits.Text := CurrToStr(aObj.Credits);
  dtpBirthdate.Date := aObj.Birthdate;
 end else begin
  cbActive.Checked := false;
  edtName.Text := '';
  edtPhone.Text := '';
  edtEmail.Text := '';
  EdtZip.Text := '';
  edtCity.Text := '';
  edtCredits.Text := '';
  dtpBirthdate.Date := now;
 end;
end;

procedure TMainForm.UIToCustomer(aObj : TCustomer);
begin
 if Assigned(aObj) then begin
  aObj.Active := cbActive.Checked;
  aObj.Name := edtName.Text;
  aObj.Phone := edtPhone.Text;
  aObj.Email := edtEmail.Text;
  aObj.Zip := StrToIntDef(EdtZip.Text,aObj.Zip);
  aObj.City := edtCity.Text;
  aObj.Credits := StrToCurrDef(edtCredits.Text,aObj.Credits);
  aObj.Birthdate := dtpBirthdate.Date;
 end;
end;

procedure TMainForm.UpdateJSONByRTTI;
var aObj : TCustomer;
begin
 aObj := TCustomer.Create;
 try
  UIToCustomer(aObj);
  memJSON.Text := TJson.ObjectToJsonString(aObj,[joIndentCaseCamel]);
 finally
  aObj.Free;
 end;
end;

procedure TMainForm.UpdateJSONByBuilder;
var aObj : TCustomer;
    aSw : TStringWriter;
    aJw : TJsonTextWriter;
    aSb: TStringBuilder;
    aBuilder: TJSONObjectBuilder;
    aNode : TJSONCollectionBuilder.TPairs;
begin
 aObj := TCustomer.Create;
 aSb := TStringBuilder.Create;
 aSw := TStringWriter.Create(aSb);
 aJw := TJsonTextWriter.Create(aSw);
 aBuilder := TJSONObjectBuilder.Create(aJw);
 try
  UIToCustomer(aObj);
  aJw.Formatting := TJsonFormatting.Indented;
  aNode := aBuilder.BeginObject;
  aObj.AddToJSON(aNode);
  aNode.EndObject;
  memJSON.Text := aSb.ToString;
 finally
  aObj.Free;
  aBuilder.Free;
  aJw.Free;
  aSw.Free;
  aSb.Free;
 end;
end;

procedure TMainForm.JSONToObjectByRTTI;
var aObj : TCustomer;
begin
 aObj := TJSON.JsonToObject<TCustomer>(memJSON.Text);
 if (aObj <> nil) then begin
  CustomerToUI(aObj);
  aObj.Free;
 end;
end;

procedure TMainForm.RESTRequest1AfterExecute(Sender: TCustomRESTRequest);
begin
 Log('http response = '+inttostr(Sender.Response.StatusCode));
 Log('content length = '+inttostr(Sender.Response.ContentLength));
 Log('content encoding = '+Sender.Response.ContentEncoding);
 //Log('content  = '+Sender.Response.Content);
 Log(Sender.Response.JSONText);
end;

procedure TMainForm.JSONToObjectByBuilder;
var aObj : TCustomer;
    aSr : TStringReader;
    aJr : TJsonTextReader;
begin
 aObj := TCustomer.Create;
 aSr := TStringReader.Create(memJSON.Text);
 aJr := TJsonTextReader.Create(aSr);
 try
  aObj.ReadFromJSON(aJr);
  CustomerToUI(aObj);
 finally
  aJr.Free;
  aSr.Free;
  aObj.Free;
 end;
end;

procedure TMainForm.AJSONToObjectExecute(Sender: TObject);
begin
 case Combobox1.ItemIndex of
  0: JSONToObjectByRTTI;
  1: JSONToObjectByBuilder;
 end;
end;

procedure TMainForm.AObjectToJSONExecute(Sender: TObject);
begin
 case Combobox1.ItemIndex of
  0: UpdateJSONByRTTI;
  1: UpdateJSONByBuilder;
 end;
end;

procedure TMainForm.AMakeRESTCallExecute(Sender: TObject);
var aObj : TCustomer;
begin
 aObj := TCustomer.Create;
 try
  UIToCustomer(aObj);

  RESTClient1.BaseURL := Edit1.Text+Edit2.Text;
  RESTClient1.ContentType := 'application/json';
  RESTRequest1.Client := RESTClient1;
  RESTRequest1.AutoCreateParams := true;

  RESTRequest1.Accept := 'application/json';



  RESTRequest1.Params.AddBody(memJSON.Text,'application/json');
//  RESTRequest1.Params.AddObject(aObj);
//  RESTRequest1.Params.AddBody(aObj,ooCopy);

//  RESTRequest1.Params.AddItem('Active',aObj.Active);
//  RESTRequest1.Params.AddItem('Name',aObj.Name);
//  RESTRequest1.Params.AddItem('Phone',aObj.Phone);
//  RESTRequest1.Params.AddItem('Email',aObj.Email);
//  RESTRequest1.Params.AddItem('Zip',aObj.Zip);
//  RESTRequest1.Params.AddItem('City',aObj.City);
//  RESTRequest1.Params.AddItem('Credits',aObj.Credits);
//  RESTRequest1.Params.AddItem('Birthdate',aObj.Birthdate);

  RESTRequest1.Method := rmPOST;
  RESTRequest1.Execute;

 finally
  aObj.Free;
 end;
end;



end.

unit CustomerClass;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Types,
  {$IFDEF MSWINDOWS}
  WinApi.Windows,
  {$ENDIF}
  System.Generics.Collections,
  System.NetEncoding,
  System.JSON,
  System.JSON.Types,
  System.JSON.BSON,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Builders,
  REST.Json,
  REST.Json.Types;

type


 TCustomer = class(TObject)
  constructor Create;
  destructor Destroy; override;
 private
  [JSONMarshalled(True)] [JSonName('Magnus')]
  FActive : boolean;
  //[JSONMarshalled(False)] [JSonName('RecField')]
  FName : string;
  //[JSONMarshalled(False)] [JSonName('RecField')]
  FPhone : string;
  //[JSONMarshalled(False)] [JSonName('RecField')]
  FEmail : string;
  FZip : integer;
  FCity : string;
  FCredits : Currency;
  FBirthdate : TDateTime;
 public
  procedure AddToJSON(aJSON : TJSONCollectionBuilder.TPairs);
  function ReadFromJSON(aReader : TJsonTextReader) : boolean;
  property Active : boolean read FActive write FActive;
  property Name : string read FName write FName;
  property Phone : string read FPhone write FPhone;
  property Email : string read FEmail write FEmail;
  property Zip : integer read FZip write FZip;
  property City : string read FCity write FCity;
  property Credits : Currency read FCredits write FCredits;
  property Birthdate : TDateTime read FBirthdate write FBirthdate;
 end;


implementation

{ TCustomer }

constructor TCustomer.Create;
begin
 inherited Create;
 FActive := false;
 FName := 'Magnus';
 FPhone := '';
 FEmail := '';
 FZip := 0;
 FCity := '';
 FCredits := 0;
 FBirthdate := EncodeDate(1978,10,13);
end;

destructor TCustomer.Destroy;
begin
 inherited Destroy;
end;

procedure TCustomer.AddToJSON(aJSON : TJSONCollectionBuilder.TPairs);
begin
 if Assigned(aJSON) then begin
  aJSON.Add('Active',FActive);
  aJSON.Add('Name',FName);
  aJSON.Add('Phone',FPhone);
  aJSON.Add('Email',FEmail);
  aJSON.Add('Zip',FZip);
  aJSON.Add('City',FCity);
  aJSON.Add('Credits',FCredits);
  aJSON.Add('Birthdate',FBirthdate);
 end;
end;

function TCustomer.ReadFromJSON(aReader : TJsonTextReader) : boolean;
var aKeyname : string;
begin
 result := false;
 if Assigned(aReader) then begin

  while aReader.Read do begin
   case aReader.TokenType of
    TJsonToken.StartObject: ;
    TJsonToken.StartArray: ;
    TJsonToken.PropertyName: begin
     try
      aKeyname := aReader.Value.ToString;
      if SameText(aKeyname,'Active') then begin
       if aReader.Read then begin
        case aReader.TokenType of
         TJsonToken.String: FActive := StrToBoolDef(aReader.Value.ToString,FActive);
         TJsonToken.Boolean: FActive := aReader.Value.AsBoolean;
         TJsonToken.Integer: FActive := (aReader.Value.AsInteger <> 0);
        end;
       end;
      end else if SameText(aKeyname,'Name') then begin
       FName := aReader.ReadAsString;
      end else if SameText(aKeyname,'Phone') then begin
       FPhone := aReader.ReadAsString;
      end else if SameText(aKeyname,'Email') then begin
       FEmail := aReader.ReadAsString;
      end else if SameText(aKeyname,'Zip') then begin
       if aReader.Read then begin
        case aReader.TokenType of
         TJsonToken.String: FZip := StrToIntDef(aReader.Value.ToString,FZip);
         TJsonToken.Integer: FZip := aReader.Value.AsInteger;
        end;
       end;
      end else if SameText(aKeyname,'City') then begin
       FCity := aReader.ReadAsString;
      end else if SameText(aKeyname,'Credits') then begin
       FCredits := aReader.ReadAsDouble;
      end else if SameText(aKeyname,'Birthdate') then begin
       FBirthdate := aReader.ReadAsDateTime;
      end;
     except
     end;
    end;
    TJsonToken.EndObject: ;
    TJsonToken.EndArray: ;
   end;
  end;
 end;
end;


end.

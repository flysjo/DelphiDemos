unit CommonUtils;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Types,
  System.Math,
  {$IFDEF MSWINDOWS}
  WinApi.Windows,
  {$ENDIF}
  System.Generics.Collections;


type

     TStreamHead = packed record
      ID    : word;
      Ver   : word;
      Size  : integer;
      Count : integer;
     end;

     TELSDataHeader = packed record
      ID : word;
      DataType : word;
      Size : integer;
     end;

     TELSDataStreamWriterWithProt = procedure(aProtVer : word; AStream : TStream) of object;
     TELSDataStreamWriter = procedure(AStream : TStream) of object;
     TELSDataStreamWriteEncryptMethod = procedure(AStream : TStream; aStr : string; aKeyIdx : integer = -1) of object;
     TELSDataStreamReader = function(AStream : TStream) : boolean of object;
     TELSDataStreamReaderString = function(AStream : TStream) : string of object;

     TELSDataHeaderHelper = record helper for TELSDataHeader
      function IsEmpty : boolean;
      class function Empty : TELSDataHeader; static;
      class function NextHeaderFromStream(const AStream : TStream) : TELSDataHeader; static;

      class function StreamSize(const aDataSize : integer) : integer; overload; static;
      class function StreamSize(const aData : string) : integer; overload; static;
      class function StreamSize(const aData : TStream) : integer; overload; static;

      class procedure WriteHeaderToStream(const AStream : TStream; aID : word; aSize : integer; aDataType : word = 0); overload; static;

      class procedure WriteToStream(const AStream : TStream; aID : word; var aData; aSize : integer); overload; static;
      class procedure WriteToStream(const AStream : TStream; aID : word; const aData : byte); overload; static;
      class procedure WriteToStream(const AStream : TStream; aID : word; const aData : boolean); overload; static;
      class procedure WriteToStream(const AStream : TStream; aID : word; const aData : word); overload; static;
      class procedure WriteToStream(const AStream : TStream; aID : word; const aData : integer); overload; static;
      class procedure WriteToStream(const AStream : TStream; aID : word; const aData : cardinal); overload; static;
      class procedure WriteToStream(const AStream : TStream; aID : word; const aData : int64); overload; static;
      class procedure WriteToStream(const AStream : TStream; aID : word; const aData : TDateTime); overload; static;
      class procedure WriteToStream(const AStream : TStream; aID : word; const aData : real); overload; static;
      class procedure WriteToStream(const AStream : TStream; aID : word; const aData : double); overload; static;
      class procedure WriteToStream(const AStream : TStream; aID : word; const aData : string); overload; static;
      class procedure WriteToStream(const AStream : TStream; aID : word; const aData : TStream); overload; static;
      class procedure WriteToStream(const AStream : TStream; aID : word; aSize : integer; aWriter : TELSDataStreamWriterWithProt; aProtVer : word); overload; static;
      class procedure WriteToStream(const AStream : TStream; aID : word; aSize : integer; aWriter : TELSDataStreamWriter); overload; static;
      class procedure WriteToStream(const AStream : TStream; aID : word; const aData : string; aWriter : TELSDataStreamWriteEncryptMethod); overload; static;

      class function ReadHeaderFromStream(const AStream : TStream; var aHeader : TELSDataHeader) : boolean; overload; static;

      class function ReadFromStream(const AStream : TStream; var aData; aSize : integer) : boolean; overload; static;
      class function ReadFromStream(const AStream : TStream; var aData : byte) : boolean; overload; static;
      class function ReadFromStream(const AStream : TStream; var aData : boolean) : boolean; overload; static;
      class function ReadFromStream(const AStream : TStream; var aData : word) : boolean; overload; static;
      class function ReadFromStream(const AStream : TStream; var aData : integer) : boolean; overload; static;
      class function ReadFromStream(const AStream : TStream; var aData : cardinal) : boolean; overload; static;
      class function ReadFromStream(const AStream : TStream; var aData : int64) : boolean; overload; static;
      class function ReadFromStream(const AStream : TStream; var aData : TDateTime) : boolean; overload; static;
      class function ReadFromStream(const AStream : TStream; var aData : real) : boolean; overload; static;
      class function ReadFromStream(const AStream : TStream; var aData : double) : boolean; overload; static;
      class function ReadFromStream(const AStream : TStream; var aData : string) : boolean; overload; static;
      class function ReadFromStream(const AStream : TStream; var aData : TStream; aClearBefore : boolean) : boolean; overload; static;
      class function ReadFromStream(const AStream : TStream; aReader : TELSDataStreamReader) : boolean; overload; static;
      class function ReadFromStream(const AStream : TStream; var aData : string; aReader : TELSDataStreamReaderString) : boolean; overload; static;

     end;


function DateTimeToAPSTicks(aDateTime : TDateTime) : Int64;
function APSTicksToDateTime(aAPSTicks : Int64) : TDateTime;

implementation


// APS Date is the same as C# ticks, but in seconds instead of 100 nanoseconds steps
function DateTimeToAPSTicks(aDateTime : TDateTime) : Int64;
begin
 result := Round((DateDelta + aDateTime - 1) * MSecsPerDay) div 1000;
end;

function APSTicksToDateTime(aAPSTicks : Int64) : TDateTime;
begin
 result := ((aAPSTicks*1000) / Int64(MSecsPerDay)) - DateDelta + 1;
end;


{ TELSDataHeaderHelper }

function TELSDataHeaderHelper.IsEmpty : boolean;
begin
 result := (ID = 0) and (DataType = 0) and (Size = 0);
end;

class function TELSDataHeaderHelper.Empty : TELSDataHeader;
begin
 result.ID := 0;
 result.DataType := 0;
 result.Size := 0;
end;

class function TELSDataHeaderHelper.NextHeaderFromStream(const AStream : TStream) : TELSDataHeader;
var aPos : Int64;
begin
 result := TELSDataHeader.Empty;
 if Assigned(AStream) then begin
  aPos := AStream.Position;
  try
   AStream.Read(result,SizeOf(TELSDataHeader));
  finally
   AStream.Seek(aPos,soFromBeginning);
  end;
 end;
end;

// Size helpers
class function TELSDataHeaderHelper.StreamSize(const aDataSize : integer) : integer;
begin
 result := SizeOf(TELSDataHeader) + aDataSize;
end;

class function TELSDataHeaderHelper.StreamSize(const aData : string) : integer;
begin
 result := SizeOf(TELSDataHeader) + Min((Length(aData)*2),MaxInt);
end;

class function TELSDataHeaderHelper.StreamSize(const aData : TStream) : integer;
begin
 result := SizeOf(TELSDataHeader);
 if Assigned(aData) then begin
  inc(result,Min(aData.Size,MaxInt));
 end;
end;

// Write helpers

class procedure TELSDataHeaderHelper.WriteHeaderToStream(const AStream : TStream; aID : word; aSize : integer; aDataType : word = 0);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) then begin
  aHead.ID := aID;
  aHead.DataType := aDataType;
  aHead.Size := aSize;
  AStream.Write(aHead,SizeOf(TELSDataHeader));
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; var aData; aSize : integer);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) then begin
  aHead.ID := aID;
  aHead.DataType := 0; // unknown
  aHead.Size := aSize;
  AStream.Write(aHead,SizeOf(TELSDataHeader));
  AStream.WriteBuffer(aData,aHead.Size);
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; const aData : byte);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) then begin
  aHead.ID := aID;
  aHead.DataType := 1; // Byte
  aHead.Size := 1;
  AStream.Write(aHead,SizeOf(TELSDataHeader));
  AStream.Write(aData,1);
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; const aData : boolean);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) then begin
  aHead.ID := aID;
  aHead.DataType := 2; // Bool
  aHead.Size := 1;
  AStream.Write(aHead,SizeOf(TELSDataHeader));
  AStream.Write(aData,1);
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; const aData : word);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) then begin
  aHead.ID := aID;
  aHead.DataType := 3; // Word
  aHead.Size := 2;
  AStream.Write(aHead,SizeOf(TELSDataHeader));
  AStream.Write(aData,2);
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; const aData : integer);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) then begin
  aHead.ID := aID;
  aHead.DataType := 4; // Integer/Cardinal
  aHead.Size := 4;
  AStream.Write(aHead,SizeOf(TELSDataHeader));
  AStream.Write(aData,4);
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; const aData : cardinal);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) then begin
  aHead.ID := aID;
  aHead.DataType := 4; // Integer/Cardinal
  aHead.Size := 4;
  AStream.Write(aHead,SizeOf(TELSDataHeader));
  AStream.Write(aData,4);
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; const aData : int64);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) then begin
  aHead.ID := aID;
  aHead.DataType := 5; // Int64
  aHead.Size := 8;
  AStream.Write(aHead,SizeOf(TELSDataHeader));
  AStream.Write(aData,8);
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; const aData : TDateTime);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) then begin
  aHead.ID := aID;
  aHead.DataType := 6; // DateTime
  aHead.Size := 8;
  AStream.Write(aHead,SizeOf(TELSDataHeader));
  AStream.Write(aData,8);
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; const aData : real);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) then begin
  aHead.ID := aID;
  aHead.DataType := 7; // real
  aHead.Size := SizeOf(real);
  AStream.Write(aHead,SizeOf(TELSDataHeader));
  AStream.Write(aData,SizeOf(real));
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; const aData : double);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) then begin
  aHead.ID := aID;
  aHead.DataType := 8; // double
  aHead.Size := SizeOf(double);
  AStream.Write(aHead,SizeOf(TELSDataHeader));
  AStream.Write(aData,SizeOf(double));
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; const aData : string);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) then begin
  aHead.ID := aID;
  aHead.DataType := 9; // string
  aHead.Size := Min(Length(aData)*2,MaxInt);
  AStream.Write(aHead,SizeOf(TELSDataHeader));
  if (aHead.Size > 0) then begin
   {$IFDEF NEXTGEN}
   AStream.WriteBuffer(aData[0],aHead.Size);
   {$ELSE}
   AStream.WriteBuffer(aData[1],aHead.Size);
   {$ENDIF}
  end;
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; const aData : TStream);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) then begin
  aHead.ID := aID;
  aHead.DataType := 10; // stream
  if Assigned(aData) then aHead.Size := Min(aData.Size,MaxInt) else aHead.Size := 0;
  AStream.Write(aHead,SizeOf(TELSDataHeader));
  if Assigned(aData) and (aHead.Size > 0) then begin
   aData.Position := 0;
   AStream.CopyFrom(aData,aHead.Size);
  end;
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; aSize : integer; aWriter : TELSDataStreamWriterWithProt; aProtVer : word);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) and Assigned(aWriter) then begin
  aHead.ID := aID;
  aHead.DataType := 0;
  aHead.Size := aSize;
  AStream.Write(aHead,SizeOf(TELSDataHeader));
  aWriter(aProtVer,AStream);
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; aSize : integer; aWriter : TELSDataStreamWriter);
var aHead : TELSDataHeader;
begin
 if Assigned(AStream) and Assigned(aWriter) then begin
  aHead.ID := aID;
  aHead.DataType := 0;
  aHead.Size := aSize;
  AStream.Write(aHead,SizeOf(TELSDataHeader));
  aWriter(AStream);
 end;
end;

class procedure TELSDataHeaderHelper.WriteToStream(const AStream : TStream; aID : word; const aData : string; aWriter : TELSDataStreamWriteEncryptMethod);
var aHead : TELSDataHeader;
    aTmpStream : TMemoryStream;
begin
 if Assigned(AStream) and Assigned(aWriter) then begin
  aTmpStream := TMemoryStream.Create;
  try
   aWriter(aTmpStream,aData,-1);
   aHead.ID := aID;
   aHead.DataType := 0;
   aHead.Size := aTmpStream.Size;
   AStream.Write(aHead,SizeOf(TELSDataHeader));
//   aWriter(AStream);
   aTmpStream.Position := 0;
   AStream.CopyFrom(aTmpStream,aTmpStream.Size);
  finally
   aTmpStream.Free;
  end;

 end;
end;


// Read helpers

class function TELSDataHeaderHelper.ReadHeaderFromStream(const AStream : TStream; var aHeader : TELSDataHeader) : boolean;
var aPos : Int64;
begin
 result := false;
 if Assigned(AStream) then begin
  try
   if (AStream.Position+SizeOf(TELSDataHeader) <= AStream.Size) then begin
    AStream.Read(aHeader,SizeOf(TELSDataHeader));
    result := true;
   end;
  except
   result := false;
  end;
 end;
end;


class function TELSDataHeaderHelper.ReadFromStream(const AStream : TStream; var aData; aSize : integer) : boolean;
var aHead : TELSDataHeader;
    aPos : Int64;
begin
 result := false;
 if Assigned(AStream) then begin
  try
   AStream.Read(aHead,SizeOf(TELSDataHeader));
   aPos := AStream.Position;
   AStream.Read(aData,Min(aSize,aHead.Size));
   AStream.Seek(aPos+aHead.Size,soFromBeginning);
   result := true;
  except
   result := false;
  end;
 end;
end;

class function TELSDataHeaderHelper.ReadFromStream(const AStream : TStream; var aData : byte) : boolean;
var aHead : TELSDataHeader;
begin
 result := false;
 if Assigned(AStream) then begin
  try
   AStream.Read(aHead,SizeOf(TELSDataHeader));
   if (aHead.DataType = 1) and (aHead.Size = 1) then begin
    AStream.Read(aData,1);
    result := true;
   end;
  except
   result := false;
  end;
 end;
end;

class function TELSDataHeaderHelper.ReadFromStream(const AStream : TStream; var aData : boolean) : boolean;
var aHead : TELSDataHeader;
begin
 result := false;
 if Assigned(AStream) then begin
  try
   AStream.Read(aHead,SizeOf(TELSDataHeader));
   if (aHead.DataType = 2) and (aHead.Size = 1) then begin
    AStream.Read(aData,1);
    result := true;
   end;
  except
   result := false;
  end;
 end;
end;

class function TELSDataHeaderHelper.ReadFromStream(const AStream : TStream; var aData : word) : boolean;
var aHead : TELSDataHeader;
begin
 result := false;
 if Assigned(AStream) then begin
  try
   AStream.Read(aHead,SizeOf(TELSDataHeader));
   if (aHead.DataType = 3) and (aHead.Size = 2) then begin
    AStream.Read(aData,2);
    result := true;
   end;
  except
   result := false;
  end;
 end;
end;

class function TELSDataHeaderHelper.ReadFromStream(const AStream : TStream; var aData : integer) : boolean;
var aHead : TELSDataHeader;
begin
 result := false;
 if Assigned(AStream) then begin
  try
   AStream.Read(aHead,SizeOf(TELSDataHeader));
   if (aHead.DataType = 4) and (aHead.Size = 4) then begin
    AStream.Read(aData,4);
    result := true;
   end;
  except
   result := false;
  end;
 end;
end;

class function TELSDataHeaderHelper.ReadFromStream(const AStream : TStream; var aData : cardinal) : boolean;
var aHead : TELSDataHeader;
begin
 result := false;
 if Assigned(AStream) then begin
  try
   AStream.Read(aHead,SizeOf(TELSDataHeader));
   if (aHead.DataType = 4) and (aHead.Size = 4) then begin
    AStream.Read(aData,4);
    result := true;
   end;
  except
   result := false;
  end;
 end;
end;

class function TELSDataHeaderHelper.ReadFromStream(const AStream : TStream; var aData : int64) : boolean;
var aHead : TELSDataHeader;
begin
 result := false;
 if Assigned(AStream) then begin
  try
   AStream.Read(aHead,SizeOf(TELSDataHeader));
   if (aHead.DataType = 5) and (aHead.Size = 8) then begin
    AStream.Read(aData,8);
    result := true;
   end;
  except
   result := false;
  end;
 end;
end;

class function TELSDataHeaderHelper.ReadFromStream(const AStream : TStream; var aData : TDateTime) : boolean;
var aHead : TELSDataHeader;
begin
 result := false;
 if Assigned(AStream) then begin
  try
   AStream.Read(aHead,SizeOf(TELSDataHeader));
   if (aHead.DataType = 6) and (aHead.Size = 8) then begin
    AStream.Read(aData,8);
    result := true;
   end;
  except
   result := false;
  end;
 end;
end;

class function TELSDataHeaderHelper.ReadFromStream(const AStream : TStream; var aData : real) : boolean;
var aHead : TELSDataHeader;
begin
 result := false;
 if Assigned(AStream) then begin
  try
   AStream.Read(aHead,SizeOf(TELSDataHeader));
   if (aHead.DataType = 7) and (aHead.Size = SizeOf(real)) then begin
    AStream.Read(aData,SizeOf(real));
    result := true;
   end;
  except
   result := false;
  end;
 end;
end;

class function TELSDataHeaderHelper.ReadFromStream(const AStream : TStream; var aData : double) : boolean;
var aHead : TELSDataHeader;
begin
 result := false;
 if Assigned(AStream) then begin
  try
   AStream.Read(aHead,SizeOf(TELSDataHeader));
   if (aHead.DataType = 8) and (aHead.Size = SizeOf(double)) then begin
    AStream.Read(aData,SizeOf(double));
    result := true;
   end;
  except
   result := false;
  end;
 end;
end;

class function TELSDataHeaderHelper.ReadFromStream(const AStream : TStream; var aData : string) : boolean;
var aHead : TELSDataHeader;
begin
 result := false;
 if Assigned(AStream) then begin
  try
   AStream.Read(aHead,SizeOf(TELSDataHeader));
   if (aHead.DataType = 9) then begin
    if (aHead.Size > 0) then begin
     SetLength(aData,aHead.Size shr 1);
     {$IFDEF NEXTGEN}
     Fillchar(aData[0],aHead.Size,0);
     AStream.ReadBuffer(aData[0],aHead.Size);
     {$ELSE}
     Fillchar(aData[1],aHead.Size,0);
     AStream.ReadBuffer(aData[1],aHead.Size);
     {$ENDIF}
    end else aData := '';
    result := true;
   end;
  except
   result := false;
  end;
 end;
end;

class function TELSDataHeaderHelper.ReadFromStream(const AStream : TStream; var aData : TStream; aClearBefore : boolean) : boolean;
var aHead : TELSDataHeader;
begin
 result := false;
 if Assigned(AStream) then begin
  try
   AStream.Read(aHead,SizeOf(TELSDataHeader));
   if (aHead.DataType = 10) and Assigned(aData) then begin
    if aClearBefore then aData.Size := 0;
    if (aHead.Size > 0) then begin
     aData.CopyFrom(AStream,aHead.Size);
    end;
    result := true;
   end;
  except
   result := false;
  end;
 end;
end;

class function TELSDataHeaderHelper.ReadFromStream(const AStream : TStream; aReader : TELSDataStreamReader) : boolean;
var aHead : TELSDataHeader;
    aPos : Int64;
begin
 result := false;
 if Assigned(AStream) and Assigned(aReader) then begin
  try
   AStream.Read(aHead,SizeOf(TELSDataHeader));
   aPos := AStream.Position;
   result := aReader(AStream);
   AStream.Position := aPos+aHead.Size;
  except
   result := false;
  end;
 end;
end;

class function TELSDataHeaderHelper.ReadFromStream(const AStream : TStream; var aData : string; aReader : TELSDataStreamReaderString) : boolean;
var aHead : TELSDataHeader;
    aPos : Int64;
begin
 result := false;
 if Assigned(AStream) and Assigned(aReader) then begin
  try
   AStream.Read(aHead,SizeOf(TELSDataHeader));
   aPos := AStream.Position;
   aData := aReader(AStream);
   AStream.Position := aPos+aHead.Size;
   result := true;
  except
   result := false;
  end;
 end;
end;



end.

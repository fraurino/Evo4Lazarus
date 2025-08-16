{
  Projeto: EvolutionAPI Lazarus
  Autor: Francisco Aurino
  Licença: Open Source

  Descrição:
  Funções para integração com a Evolution API via Lazarus/Delphi, incluindo
  envio de mensagens, status de digitação, download de imagens, verificação
  de números comerciais, etc.

  Direitos Autorais:
  Todo e qualquer aprimoramento, correção, modificação ou evolução deste
  projeto deve manter intactos os dados do criador original.
  É permitido uso, redistribuição e adaptação, contanto que seja mantido
  o crédito do autor.

  Referência da documentação oficial:
  https://doc.apicomponente.com.br/introduction

  Observações:
  - Para suporte ou reportar problemas, siga as instruções na documentação.
  - Este projeto é distribuído "como está" sem garantias expressas.
}


unit EvolutionAPI;

{$mode ObjFPC}{$H+}

interface

uses
  Dialogs, Classes, SysUtils, fphttpclient, opensslsockets, fpjson, jsonparser,
  base64, laz2_XMLRead,RegExpr, DateUtils, Forms;

type
  // Enumerações para status
  TInstanceStatus  = (isOffline, isConnecting , isConnected, isDisconnected);
  TMessageStatus   = (msPending, msSent, msDelivered, msRead, msFailed);
  TIntegrationType = (itWhatsappBaileys, itWhatsappBusiness);

  // Record para resposta de mensagem
  TMessageResponse = record
    MessageId: string;
    RemoteJid: string;
    Status: TMessageStatus;
    Timestamp: TDateTime;
    Success: Boolean;
    ErrorMessage: string;
  end;

 // Definir tipos para mapeamento
type
  TMimeTypeMap = record
    Extension: string;
    MimeType: string;
  end;

  TFileTypeMap = record
    Extension: string;
    FileType: string;
  end;

  // Record para informações da instância
  TInstanceInfo = record
    Name: string;
    Status: TInstanceStatus;
    ProfileName: string;
    ProfilePictureUrl: string;
    PhoneNumber: string;
    IsConnected: Boolean;
    Icon: string;
    Version: string;              // versão da API/sessão
    PushName: string;             // nome do dispositivo
    Platforms: string;            // plataforma usada (Android, iOS, etc)
  end;

  // Record para QR Code
  TQRCodeInfo = record
    QRCode: string;
    Base64: string;
    Success: Boolean;
    ErrorMessage: string;
  end;

  // Classe principal da Evolution API

  { TEvolutionAPI }

  TEvolutionAPI = class
  private
    FServerURL: string;
    FApiKey: string;
    FInstanceName: string;
    FHttpClient: TFPHttpClient;
    FLastError: string;

    function DoHttpRequest(const AMethod, AEndpoint: string; const AData: string = ''): string;
    function ParseMessageStatus(const AStatus: string): TMessageStatus;
    function ParseInstanceStatus(const AStatus: string): TInstanceStatus;
    function FormatPhoneNumber(const ANumber: string): string;
    function JsonToMessageResponse(const AJson: string): TMessageResponse;
    function JsonToInstanceInfo(const AJson: string): TInstanceInfo;

  public
    constructor Create(const AServerURL, AApiKey: string);
    destructor Destroy; override;

    // Propriedades
    property ServerURL: string read FServerURL write FServerURL;
    property ApiKey: string read FApiKey write FApiKey;
    property InstanceName: string read FInstanceName write FInstanceName;
    property LastError: string read FLastError;

    // Métodos principais
    function CreateInstance(const AInstanceName: string; Const Qrcode : boolean = True; const AWebhookUrl: string=''): Boolean;
    function DeleteInstance(const AInstanceName: string): Boolean;
    function GetInstanceStatus(const AInstanceName: string): TInstanceInfo;
    function StartInstance(const AInstanceName: string): Boolean;
    function ConnectInstance(const AInstanceName: string): Boolean;
    function GetQRCode(const AInstanceName: string): TQRCodeInfo;
    function ConnectWithPairingCode(const AInstanceName, APhoneNumber: string): string;
    function GetMimeTypeByExtension(const FileExt: string): string;
    function GetMediaTypeByExtension(const FileExt: string): string;
    function ExtractFileExt(const FileName: string): string;
    function ExtractFileName(const FilePath: string): string;
    function ChangeFileExt(const FileName, NewExt: string): string;
    function DownloadImage(const Url, numero: string): string;

    // Função para converter arquivo para Base64 (equivalente à FileToBase64)
    function FileToBase64(const Arquivo: string): string;


    // Envio de mensagens
    function SendTextMessage(const AInstanceName, APhoneNumber, AMessage: string;  const ADelay: Integer = 0): TMessageResponse;
    function SendImageMessage(const AInstanceName, APhoneNumber, ACaption: string; const AImagePath: string; const ADelay: Integer = 0): TMessageResponse;
    function SendFileMessage(const AInstanceName, APhoneNumber, AFileName: string; const AFilePath: string; const ADelay: Integer = 0): TMessageResponse;
    // Status de mensagens
    function GetMessageStatus(const AInstanceName, AMessageId: string): TMessageStatus;
    function FindStatusMessage(const AInstanceName, MsgID: string): TMessageResponse;
    function SimulateTyping(const AInstanceName, APhoneNumber: string;  ADurationSeconds: Integer = 3; AIsGroup: Boolean = False): TMessageResponse;
    function SetTypingStatus(const AInstanceName, APhoneNumber: string; ATyping: Boolean; AIsGroup: Boolean = False): TMessageResponse;
    function UnblockContact(const AInstanceName, APhoneNumber: string;  AIsGroup: Boolean = False): TMessageResponse;

    // Utilitários
    function IsInstanceActive(const AInstanceName: string): Boolean;
    function GetAllInstances: TStringList;
  end;

implementation

{ TEvolutionAPI }


// Adicione essas funções auxiliares na sua classe TEvolutionAPI

function TEvolutionAPI.GetMimeTypeByExtension(const FileExt: string): string;
const
  MimeTypes: array[0..20] of TMimeTypeMap = (
    (Extension: '.html'; MimeType: 'text/html'),
    (Extension: '.htm'; MimeType: 'text/html'),
    (Extension: '.txt'; MimeType: 'text/plain'),
    (Extension: '.jpg'; MimeType: 'image/jpeg'),
    (Extension: '.jpeg'; MimeType: 'image/jpeg'),
    (Extension: '.png'; MimeType: 'image/png'),
    (Extension: '.gif'; MimeType: 'image/gif'),
    (Extension: '.bmp'; MimeType: 'image/bmp'),
    (Extension: '.webp'; MimeType: 'image/webp'),
    (Extension: '.pdf'; MimeType: 'application/pdf'),
    (Extension: '.zip'; MimeType: 'application/zip'),
    (Extension: '.rar'; MimeType: 'application/x-rar-compressed'),
    (Extension: '.doc'; MimeType: 'application/msword'),
    (Extension: '.docx'; MimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'),
    (Extension: '.xls'; MimeType: 'application/vnd.ms-excel'),
    (Extension: '.xlsx'; MimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
    (Extension: '.ppt'; MimeType: 'application/vnd.ms-powerpoint'),
    (Extension: '.pptx'; MimeType: 'application/vnd.openxmlformats-officedocument.presentationml.presentation'),
    (Extension: '.mp3'; MimeType: 'audio/mpeg'),
    (Extension: '.mp4'; MimeType: 'video/mp4'),
    (Extension: '.avi'; MimeType: 'video/x-msvideo')
  );
var
  Ext: string;
  I: Integer;
begin
  Result := 'application/octet-stream';
  Ext := LowerCase(ExtractFileExt(FileExt));

  if Ext <> '' then
  begin
    if not (Ext[1] = '.') then
      Ext := '.' + Ext;

    for I := 0 to High(MimeTypes) do
    begin
      if MimeTypes[I].Extension = Ext then
      begin
        Result := MimeTypes[I].MimeType;
        Break;
      end;
    end;
  end;
end;


function TEvolutionAPI.GetMediaTypeByExtension(const FileExt: string): string;
const
  FileTypes: array[0..15] of TFileTypeMap = (
    (Extension: '.pdf'; FileType: 'document'),
    (Extension: '.doc'; FileType: 'document'),
    (Extension: '.docx'; FileType: 'document'),
    (Extension: '.txt'; FileType: 'document'),
    (Extension: '.xls'; FileType: 'document'),
    (Extension: '.xlsx'; FileType: 'document'),
    (Extension: '.zip'; FileType: 'document'),
    (Extension: '.rar'; FileType: 'document'),
    (Extension: '.jpg'; FileType: 'image'),
    (Extension: '.jpeg'; FileType: 'image'),
    (Extension: '.png'; FileType: 'image'),
    (Extension: '.webp'; FileType: 'image'),
    (Extension: '.gif'; FileType: 'image'),
    (Extension: '.bmp'; FileType: 'image'),
    (Extension: '.mp3'; FileType: 'audio'),
    (Extension: '.wav'; FileType: 'audio')
  );
var
  Ext: string;
  I: Integer;
begin
  Result := 'document';
  Ext := LowerCase(ExtractFileExt(FileExt));

  for I := 0 to High(FileTypes) do
  begin
    if FileTypes[I].Extension = Ext then
    begin
      Result := FileTypes[I].FileType;
      Break;
    end;
  end;
end;


// Função auxiliar para extrair extensão (se não tiver)
function TEvolutionAPI.ExtractFileExt(const FileName: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := Length(FileName) downto 1 do
  begin
    if FileName[i] = '.' then
    begin
      Result := Copy(FileName, i, Length(FileName) - i + 1);
      Break;
    end;
    if FileName[i] = '\' then Break; // Para no diretório
  end;
end;

// Função auxiliar para extrair nome do arquivo (se não tiver)
function TEvolutionAPI.ExtractFileName(const FilePath: string): string;
var
  i: Integer;
begin
  Result := FilePath;
  for i := Length(FilePath) downto 1 do
  begin
    if (FilePath[i] = '\') or (FilePath[i] = '/') then
    begin
      Result := Copy(FilePath, i + 1, Length(FilePath) - i);
      Break;
    end;
  end;
end;



// Função auxiliar para trocar extensão (se não tiver)
function TEvolutionAPI.ChangeFileExt(const FileName, NewExt: string): string;
var
  DotPos, i: Integer;
  FoundDot: Boolean;
begin
  Result := FileName;
  DotPos := 0;
  FoundDot := False;

  // Procura o último ponto
  for i := Length(FileName) downto 1 do
  begin
    if FileName[i] = '.' then
    begin
      DotPos := i;
      FoundDot := True;
      Break;
    end;
    if (FileName[i] = '\') or (FileName[i] = '/') then
      Break; // Não encontrou ponto antes do diretório
  end;

  if FoundDot and (DotPos > 0) then
    Result := Copy(FileName, 1, DotPos - 1) + NewExt
  else
    Result := FileName + NewExt;
end;

function TEvolutionAPI.DownloadImage(const Url, numero: string): string;
var
  HttpClient: TFPHTTPClient;
  FileStream: TFileStream;
  FileName: string;
  retorno : TInstanceInfo;
begin
  Result := '';
  HttpClient := TFPHTTPClient.Create(nil);
  try
    FileName := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'imgs\' + numero + '.jpg';
    if FileExists(FileName) then
      DeleteFile(FileName);

    FileStream := TFileStream.Create(FileName, fmCreate);
    try
      try
        // Faz o download
        HttpClient.Get(Url, FileStream);

        // Se chegou aqui, o arquivo foi baixado com sucesso
        Result := FileName;
        retorno.icon := FileName;
      except
        on E: Exception do
          raise Exception.Create('Erro ao baixar a imagem: ' + E.Message);
      end;
    finally
      FileStream.Free;
    end;
  finally
    HttpClient.Free;
  end;
end;
function TEvolutionAPI.FileToBase64(const Arquivo: string): string;
var
  FileStream: TFileStream;
  FileContent: AnsiString;
  Base64: string;

  function ValidBase64(const Base64ToStr: string): string;
  var
    I: Integer;
    C: Char;
  begin
    Result := '';
    for I := 1 to Length(Base64ToStr) do
    begin
      C := Base64ToStr[I];
      if C in ['A'..'Z', 'a'..'z', '0'..'9', '+', '/', '='] then
        Result := Result + C;
    end;
  end;

begin
  Result := '';
  if not FileExists(Arquivo) then
    Exit;

  try
    FileStream := TFileStream.Create(Arquivo, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(FileContent, FileStream.Size);
      if FileStream.Size > 0 then
        FileStream.ReadBuffer(FileContent[1], FileStream.Size);

      Base64 := EncodeStringBase64(FileContent);
      Result := ValidBase64(Base64);
    finally
      FileStream.Free;
    end;
  except
    Result := '';
  end;
end;



constructor TEvolutionAPI.Create(const AServerURL, AApiKey: string);
begin
  inherited Create;
  FServerURL := AServerURL;
  FApiKey := AApiKey;
  FHttpClient := TFPHttpClient.Create(nil);
  FHttpClient.AddHeader('Content-Type', 'application/json');
  FHttpClient.AddHeader('apikey', FApiKey);
  FLastError := '';
end;


function TEvolutionAPI.CreateInstance(const AInstanceName: string;
		  const Qrcode: boolean; const AWebhookUrl: string): Boolean;
var
  JsonData: TJSONObject;
  JsonStr: string;
begin
  Result := False;
  FInstanceName := AInstanceName;

  JsonData := TJSONObject.Create;
  try
    JsonData.Add('instanceName', AInstanceName);
    JsonData.Add('integration', 'WHATSAPP-BAILEYS');
    JsonData.Add('qrcode', Qrcode); // true literal, sem aspas
    JsonStr := JsonData.AsJSON;
  finally
    JsonData.Free;
  end;

  // envia POST
  Result := DoHttpRequest('POST', '/instance/create', JsonStr) <> '';
end;

function TEvolutionAPI.DeleteInstance(const AInstanceName: string): Boolean;
var
  Response: string;
begin
  Response := DoHttpRequest('DELETE', '/instance/delete/' + AInstanceName);
  Result := (Response <> '') and (FLastError = '');
end;

destructor TEvolutionAPI.Destroy;
begin
  FHttpClient.Free;
  inherited Destroy;
end;

function TEvolutionAPI.DoHttpRequest(const AMethod, AEndpoint: string; const AData: string): string;
var
  URL: string;
  PostStream: TStringStream;
begin
  Result := '';
  FLastError := '';
  URL := FServerURL + AEndpoint;

  try
    if AMethod = 'POST' then
    begin
      PostStream := TStringStream.Create(AData, TEncoding.UTF8);
      try
        FHttpClient.RequestBody := PostStream;
        Result := FHttpClient.Post(URL);
      finally
        PostStream.Free;
      end;
    end
    else if AMethod = 'GET' then
      Result := FHttpClient.Get(URL)
    else if AMethod = 'DELETE' then
      Result := FHttpClient.Delete(URL);
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      Result := '';
    end;
  end;
end;



function TEvolutionAPI.ParseMessageStatus(const AStatus: string): TMessageStatus;
begin
  case LowerCase(AStatus) of
    'pending': Result := msPending;
    'sent': Result := msSent;
    'delivered': Result := msDelivered;
    'read': Result := msRead;
    'failed', 'error': Result := msFailed;
    else Result := msPending;
  end;
end;

function TEvolutionAPI.ParseInstanceStatus(const AStatus: string): TInstanceStatus;
begin
  case LowerCase(AStatus) of
    'open', 'connected': Result := isConnected;
    'connecting': Result := isConnecting;
    'close', 'closed', 'disconnected': Result := isDisconnected;
    else Result := isOffline;
  end;
end;

function TEvolutionAPI.FormatPhoneNumber(const ANumber: string): string;
var
  fone, ddd, resto: string;
  dddInt: Integer;
  c: Char;  // Corrigido para Char
begin
  // Remove tudo que não for dígito
  fone := '';
  for c in ANumber do
    if c in ['0'..'9'] then
      fone := fone + c;

  case Length(fone) of
    8: Result := fone; // telefone sem DDD
    9: begin
      dddInt := StrToIntDef(Copy(fone, 1, 2), 0);
      if dddInt <= 35 then
        Result := fone
      else
        Result := Copy(fone, 2, 8); // remove o primeiro dígito
    end;
    10: begin
      ddd := Copy(fone, 1, 2);
      resto := Copy(fone, 3, 8);
      dddInt := StrToIntDef(ddd, 0);
      if dddInt >= 35 then
        Result := ddd + resto
      else
        Result := ddd + '9' + Copy(resto, 2, 7);
    end;
    11: begin
      ddd := Copy(fone, 1, 2);
      resto := Copy(fone, 3, 9);
      Result := ddd + resto;
    end;
    12: begin
      ddd := Copy(fone, 1, 4);
      resto := Copy(fone, 5, 8);
      dddInt := StrToIntDef(Copy(fone, 3, 2), 0);
      if dddInt >= 35 then
        Result := ddd + resto
      else
        Result := ddd + '9' + Copy(resto, 2, 7);
    end;
    13: begin
      ddd := Copy(fone, 1, 4);
      resto := Copy(fone, 5, 9);
      Result := ddd + resto;
    end;
  else
    Result := fone; // qualquer outro tamanho, retorna como está
  end;
end;


function TEvolutionAPI.JsonToMessageResponse(const AJson: string): TMessageResponse;
var
  JsonData: TJSONData;
  JsonObj: TJSONObject;
  KeyObj: TJSONObject;
begin
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.Status := msPending;

  try
    JsonData := GetJSON(AJson);
    try
      if JsonData is TJSONObject then
      begin
        JsonObj := TJSONObject(JsonData);

        // Verifica se há chave key
        if JsonObj.Find('key') <> nil then
        begin
          KeyObj := JsonObj.Get('key', TJSONObject(nil));
          if Assigned(KeyObj) then
          begin
            Result.MessageId := KeyObj.Get('id', '');
            Result.RemoteJid := KeyObj.Get('remoteJid', '');
          end;
        end;

        // Status da mensagem
        Result.Status := ParseMessageStatus(JsonObj.Get('status', 'pending'));

        // Timestamp
        if JsonObj.Find('messageTimestamp') <> nil then
          Result.Timestamp := UnixToDateTime(JsonObj.Get('messageTimestamp', 0));

        Result.Success := True;
      end;
    finally
      JsonData.Free;
    end;
  except
    on E: Exception do
    begin
      Result.ErrorMessage := E.Message;
      Result.Success := False;
    end;
  end;
end;

function TEvolutionAPI.JsonToInstanceInfo(const AJson: string): TInstanceInfo;
var
  JsonData: TJSONData;
  JsonObj: TJSONObject;
begin
  // Inicializa record
  Result.Name := '';
  Result.Status := isOffline;
  Result.IsConnected := False;
  Result.ProfileName := '';
  Result.ProfilePictureUrl := '';
  Result.PhoneNumber := '';

  try
    JsonData := GetJSON(AJson);
    try
      if JsonData is TJSONObject then
      begin
        JsonObj := TJSONObject(JsonData);

        // Campos correspondentes ao JSON da API
        Result.Name := JsonObj.Get('instanceName', '');
        Result.Status := ParseInstanceStatus(JsonObj.Get('status', 'offline'));
        Result.IsConnected := JsonObj.Get('isConnected', False);
        Result.ProfileName := JsonObj.Get('profileName', '');
        Result.ProfilePictureUrl := JsonObj.Get('profilePicture', '');
        Result.PhoneNumber := JsonObj.Get('phoneNumber', '');
      end;
    finally
      JsonData.Free;
    end;
  except
    on E: Exception do
      FLastError := 'Error parsing JSON: ' + E.Message;
  end;
end;



function TEvolutionAPI.GetInstanceStatus(const AInstanceName: string): TInstanceInfo;
var
  Response: string;
  JsonData, InstanceData: TJSONData;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Name := AInstanceName;
  Result.Status := isOffline;
  Result.IsConnected := False;

  try
    // Faz requisição GET
    Response := DoHttpRequest('GET', '/instance/connectionState/' + AInstanceName, '');

    if (Response <> '') and (FLastError = '') then
    begin
      JsonData := GetJSON(Response);
      try
        if (JsonData is TJSONObject) then
        begin
          // Pega o campo 'instance' do JSON
          InstanceData := TJSONObject(JsonData).Find('instance');
          if (InstanceData <> nil) and (InstanceData is TJSONObject) then
          begin
            Result.Name := TJSONObject(InstanceData).Get('instanceName', AInstanceName);
            Result.Status := ParseInstanceStatus(TJSONObject(InstanceData).Get('state', 'offline'));
            Result.IsConnected := (Result.Status = isConnected) or (Result.Status = isConnecting);
          end;
        end;
      finally
        JsonData.Free;
      end;
    end;

  except
    on E: Exception do
      FLastError := 'Error getting instance status: ' + E.Message;
  end;
end;



function TEvolutionAPI.StartInstance(const AInstanceName: string): Boolean;
var
  Response: string;
begin
  Response := DoHttpRequest('POST', '/instance/connect/' + AInstanceName);
  Result := (Response <> '') and (FLastError = '');
end;

function TEvolutionAPI.ConnectInstance(const AInstanceName: string): Boolean;
var
  Response: string;
begin
  Response := DoHttpRequest('POST', '/instance/connect/' + AInstanceName);
  Result := (Response <> '') and (FLastError = '');
end;

function TEvolutionAPI.GetQRCode(const AInstanceName: string): TQRCodeInfo;
var
  Response: string;
  JsonData: TJSONData;
  JsonObj: TJSONObject;
begin
  Result.Success := False;
  Result.QRCode := '';
  Result.Base64 := '';
  Result.ErrorMessage := '';

  Response := DoHttpRequest('GET', '/instance/connect/' + AInstanceName);
  if (Response <> '') and (FLastError = '') then
  begin
    try
      JsonData := GetJSON(Response);
      try
        if JsonData is TJSONObject then
        begin
          JsonObj := TJSONObject(JsonData);
          Result.QRCode := JsonObj.Get('code', '');      // Ajuste aqui
          Result.Base64 := JsonObj.Get('base64', '');
          Result.Success := Result.QRCode <> '';
        end;
      finally
        JsonData.Free;
      end;
    except
      on E: Exception do
      begin
        Result.ErrorMessage := E.Message;
        Result.Success := False;
      end;
    end;
  end
  else
    Result.ErrorMessage := FLastError;
end;

function TEvolutionAPI.ConnectWithPairingCode(const AInstanceName, APhoneNumber: string): string;
var
  Response: string;
  ResponseJson: TJSONData;
  ResponseObj: TJSONObject;
begin
  Result := '';

  // GET no endpoint passando o número
  Response := DoHttpRequest('GET', '/instance/connect/' + AInstanceName + '?number=' + APhoneNumber);

  if (Response <> '') and (FLastError = '') then
  begin
    try
      ResponseJson := GetJSON(Response);
      try
        if ResponseJson is TJSONObject then
        begin
          ResponseObj := TJSONObject(ResponseJson);

          // Para retornar o código completo do telefone:
          Result := ResponseObj.Get('code', '');

          // Se quiser retornar o código de pareamento em vez disso:
           Result := ResponseObj.Get('pairingCode', '');
        end;
      finally
        ResponseJson.Free;
      end;
    except
      on E: Exception do
        FLastError := E.Message;
    end;
  end;
end;



function TEvolutionAPI.SendTextMessage(const AInstanceName, APhoneNumber, AMessage: string; const ADelay: Integer): TMessageResponse;
var
  JsonData: TJSONObject;
  JsonStr: string;
  Response: string;
begin
  JsonData := TJSONObject.Create;
  try
    JsonData.Add('number', FormatPhoneNumber(APhoneNumber));
    JsonData.Add('text', AMessage);
    if ADelay > 0 then
      JsonData.Add('delay', ADelay);

    JsonStr := JsonData.AsJSON;
  finally
    JsonData.Free;
  end;

  Response := DoHttpRequest('POST', '/message/sendText/' + AInstanceName, JsonStr);

  if (Response <> '') and (FLastError = '') then
  begin
   Result := JsonToMessageResponse(Response);
   // verifica o status da mensagem
   FindStatusMessage(AInstanceName, APhoneNumber);
  end
  else
  begin
    Result.Success := False;
    Result.ErrorMessage := FLastError;
    Result.Status := msFailed;
  end;
end;

function TEvolutionAPI.SendImageMessage(const AInstanceName, APhoneNumber,
		  ACaption: string; const AImagePath: string; const ADelay: Integer
		  ): TMessageResponse;
var
  JsonData: TJSONObject;
  JsonStr: string;
  Response: string;
  FileStream: TFileStream;
  Base64String: string;
begin
  Result.Success := False;

  if not FileExists(AImagePath) then
  begin
    Result.ErrorMessage := 'Arquivo não encontrado: ' + AImagePath;
    Result.Status := msFailed;
    Exit;
  end;

  try
    FileStream := TFileStream.Create(AImagePath, fmOpenRead);
    try
      Base64String := EncodeStringBase64(FileStream.ReadAnsiString);
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      Result.ErrorMessage := 'Erro ao ler arquivo: ' + E.Message;
      Result.Status := msFailed;
      Exit;
    end;
  end;

  JsonData := TJSONObject.Create;
  try
    JsonData.Add('number', FormatPhoneNumber(APhoneNumber));
    JsonData.Add('mediaMessage', True);
    JsonData.Add('media', Base64String);
    JsonData.Add('fileName', ExtractFileName(AImagePath));
    if ACaption <> '' then
      JsonData.Add('caption', ACaption);
    if ADelay > 0 then
      JsonData.Add('delay', ADelay);

    JsonStr := JsonData.AsJSON;
  finally
    JsonData.Free;
  end;

  Response := DoHttpRequest('POST', '/message/sendMedia/' + AInstanceName, JsonStr);

  if (Response <> '') and (FLastError = '') then
    Result := JsonToMessageResponse(Response)
  else
  begin
    Result.Success := False;
    Result.ErrorMessage := FLastError;
    Result.Status := msFailed;
  end;
end;
       function TEvolutionAPI.SendFileMessage(const AInstanceName, APhoneNumber,
  AFileName: string; const AFilePath: string; const ADelay: Integer
  ): TMessageResponse;
var
  JsonData: TJSONObject;
  JsonStr: string;
  Response: string;
  Base64String: string;
  MimeType, MediaType: string;
begin
  Result.Success := False;
  if not FileExists(AFilePath) then
  begin
    Result.ErrorMessage := 'Arquivo não encontrado: ' + AFilePath;
    Result.Status := msFailed;
    Exit;
  end;

  try
    // Converte arquivo para Base64
    Base64String := FileToBase64(AFilePath);
    if Base64String = '' then
    begin
      Result.ErrorMessage := 'Erro ao converter arquivo para Base64';
      Result.Status := msFailed;
      Exit;
    end;

    // Determina MimeType e MediaType baseado no arquivo
    MimeType := GetMimeTypeByExtension(AFilePath);
    MediaType := GetMediaTypeByExtension(AFilePath);

  except
    on E: Exception do
    begin
      Result.ErrorMessage := 'Erro ao processar arquivo: ' + E.Message;
      Result.Status := msFailed;
      Exit;
    end;
  end;

  JsonData := TJSONObject.Create;
  try
    // Monta o JSON seguindo o padrão da Evolution API
    JsonData.Add('number', FormatPhoneNumber(APhoneNumber));
    JsonData.Add('mediatype', MediaType);
    JsonData.Add('mimetype', MimeType);
    JsonData.Add('caption', ChangeFileExt(ExtractFileName(AFileName), ''));
    JsonData.Add('fileName', AFileName);
    JsonData.Add('media', Base64String);

    if ADelay > 0 then
      JsonData.Add('delay', ADelay);

    JsonStr := JsonData.AsJSON;
  finally
    JsonData.Free;
  end;

  Response := DoHttpRequest('POST', '/message/sendMedia/' + AInstanceName, JsonStr);
  if (Response <> '') and (FLastError = '') then
    Result := JsonToMessageResponse(Response)
  else
  begin
    Result.Success := False;
    Result.ErrorMessage := FLastError;
    Result.Status := msFailed;
  end;
end;


function TEvolutionAPI.GetMessageStatus(const AInstanceName, AMessageId: string): TMessageStatus;
var
  Response: string;
  JsonData: TJSONData;
  JsonObj: TJSONObject;
begin
  Result := msPending;

  Response := DoHttpRequest('GET', '/chat/fetchMessages/' + AInstanceName + '?messageId=' + AMessageId);

  if (Response <> '') and (FLastError = '') then
  begin
    try
      JsonData := GetJSON(Response);
      try
        if JsonData is TJSONObject then
        begin
          JsonObj := TJSONObject(JsonData);
          Result := ParseMessageStatus(JsonObj.Get('status', 'pending'));
        end;
      finally
        JsonData.Free;
      end;
    except
      on E: Exception do
        FLastError := E.Message;
    end;
  end;
end;

function TEvolutionAPI.FindStatusMessage(const AInstanceName, MsgID: string  ): TMessageResponse;
var
  JsonData, WhereObj: TJSONObject;
  JsonStr, Response: string;
  ResponseJson: TJSONData;
  JsonArray: TJSONArray;
  Item: TJSONObject;
  StatusStr: string;
begin
  // Inicializa valores padrão
  Result.MessageId   := MsgID;
  Result.RemoteJid   := '';
  Result.Status      := msPending;
  Result.Timestamp   := Now;
  Result.Success     := False;
  Result.ErrorMessage:= '';

  // Monta JSON do filtro
  JsonData := TJSONObject.Create;
  try
    WhereObj := TJSONObject.Create;
    WhereObj.Add('_id', MsgID);
    JsonData.Add('where', WhereObj);
    JsonStr := JsonData.AsJSON;
  finally
    JsonData.Free;
  end;

  // Faz o POST
  Response := DoHttpRequest('POST', '/chat/findStatusMessage/' + AInstanceName, JsonStr);

  if (Response <> '') and (FLastError = '') then
  begin
    try
      ResponseJson := GetJSON(Response);
      try
        if ResponseJson is TJSONArray then
        begin
          JsonArray := TJSONArray(ResponseJson);
          if JsonArray.Count > 0 then
          begin
            // Último item = status mais recente
            Item := TJSONObject(JsonArray.Items[JsonArray.Count - 1]);

            Result.MessageId := Item.Get('messageId', MsgID);
            Result.RemoteJid := Item.Get('remoteJid', '');
            StatusStr        := Item.Get('status', '');

            // Mapear string para enum
            if StatusStr = 'SERVER_ACK' then
              Result.Status := msSent
            else if StatusStr = 'DELIVERY_ACK' then
              Result.Status := msDelivered
            else if StatusStr = 'READ' then
              Result.Status := msRead
            else if StatusStr = 'FAILED' then
              Result.Status := msFailed
            else
              Result.Status := msPending;

            // Marca como sucesso
            Result.Success := True;
          end
          else
            Result.ErrorMessage := 'Nenhum status encontrado';
        end
        else
          Result.ErrorMessage := 'Resposta inválida (esperado JSONArray)';
      finally
        ResponseJson.Free;
      end;
    except
      on E: Exception do
        Result.ErrorMessage := E.Message;
    end;
  end
  else
    Result.ErrorMessage := FLastError;
end;

function TEvolutionAPI.SimulateTyping(const AInstanceName,
		  APhoneNumber: string; ADurationSeconds: Integer; AIsGroup: Boolean
		  ): TMessageResponse;
var
  StartResult, StopResult: TMessageResponse;
begin
  // Inicia a digitação
  StartResult := SetTypingStatus(AInstanceName, APhoneNumber, True, AIsGroup);

  if StartResult.Success then
  begin
    // Aguarda o tempo especificado
    Sleep(ADurationSeconds * 1000);

    // Para a digitação
    StopResult := SetTypingStatus(AInstanceName, APhoneNumber, False, AIsGroup);
    Result := StopResult;
  end
  else
    Result := StartResult;
end;


function TEvolutionAPI.SetTypingStatus(const AInstanceName, APhoneNumber: string;
  ATyping: Boolean; AIsGroup: Boolean = False): TMessageResponse;
var
  JsonData: TJSONObject;
  JsonStr: string;
  Response: string;
  IsGroupStr, TypingStr: string;
begin
  // Inicializa o resultado
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.Status := msFailed;

  // Validações de entrada
  if Trim(AInstanceName) = '' then
  begin
    Result.ErrorMessage := 'Nome da instância não pode estar vazio';
    Exit;
  end;

  if Trim(APhoneNumber) = '' then
  begin
    Result.ErrorMessage := 'Número do telefone não pode estar vazio';
    Exit;
  end;

  try
    // Converte booleanos para strings minúsculas

    IsGroupStr := LowerCase(BoolToStr(AIsGroup, True));
    TypingStr  := LowerCase(BoolToStr(ATyping, True));
    JsonData := TJSONObject.Create;
    try
      JsonData.Add('phone', FormatPhoneNumber(APhoneNumber));
      JsonData.Add('isGroup', AIsGroup);
      JsonData.Add('value', ATyping);
      JsonStr := JsonData.AsJSON;
    finally
      JsonData.Free;
    end;
    // Faz a requisição HTTP
    Response := DoHttpRequest('POST', '/' + AInstanceName + '/typing', JsonStr);

    // Processa a resposta
    if (Trim(Response) <> '') and (FLastError = '') then
    begin
      Result := JsonToMessageResponse(Response);
      if not Result.Success then
      begin
        // Se JsonToMessageResponse não detectou sucesso, mas chegou aqui, considera sucesso
        Result.Success := True;
        Result.Status := msDelivered;
        Result.ErrorMessage := '';
      end;
    end
    else
    begin
      Result.Success := False;
      if FLastError <> '' then
        Result.ErrorMessage := FLastError
      else
        Result.ErrorMessage := 'Resposta vazia do servidor';
      Result.Status := msFailed;
    end;

  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := 'Erro ao enviar status de digitação: ' + E.Message;
      Result.Status := msFailed;
    end;
  end;
end;

function TEvolutionAPI.UnblockContact(const AInstanceName,
		  APhoneNumber: string; AIsGroup: Boolean): TMessageResponse;
var
  JsonData: TJSONObject;
  JsonStr: string;
  Response: string;
begin
  // Inicializa retorno
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.Status := msFailed;

  // Validações
  if Trim(AInstanceName) = '' then
  begin
    Result.ErrorMessage := 'Nome da instância não pode estar vazio';
    Exit;
  end;

  if Trim(APhoneNumber) = '' then
  begin
    Result.ErrorMessage := 'Número do telefone não pode estar vazio';
    Exit;
  end;

  try
    // Monta JSON da requisição
    JsonData := TJSONObject.Create;
    try
      JsonData.Add('phone', FormatPhoneNumber(APhoneNumber));
      JsonData.Add('isGroup', AIsGroup);
      JsonStr := JsonData.AsJSON;
    finally
      JsonData.Free;
    end;

    // Faz POST
    Response := DoHttpRequest('POST', '/' + AInstanceName + '/unblock-contact', JsonStr);

    // Processa resposta
    if (Trim(Response) <> '') and (FLastError = '') then
    begin
      Result := JsonToMessageResponse(Response);

      if not Result.Success then
      begin
        // Se o JSON não retornou sucesso, mas chegou resposta, trata como sucesso parcial
        Result.Success := True;
        Result.Status := msDelivered;
        Result.ErrorMessage := '';
      end;
    end
    else
    begin
      Result.Success := False;
      if FLastError <> '' then
        Result.ErrorMessage := FLastError
      else
        Result.ErrorMessage := 'Resposta vazia do servidor';
      Result.Status := msFailed;
    end;

  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := 'Erro ao desbloquear contato: ' + E.Message;
      Result.Status := msFailed;
    end;
  end;
end;



function TEvolutionAPI.IsInstanceActive(const AInstanceName: string): Boolean;
var
  InstanceInfo: TInstanceInfo;
begin
  InstanceInfo := GetInstanceStatus(AInstanceName);

  // Retorna True se o status indicar que a instância está conectada ou conectando
  Result := (InstanceInfo.Status = isConnected) or (InstanceInfo.Status = isConnecting);
end;

function TEvolutionAPI.GetAllInstances: TStringList;
var
  Response: string;
  JsonData, InstanceData: TJSONData;
  JsonObj: TJSONObject;
  i: Integer;
begin
  Result := TStringList.Create;

  Response := DoHttpRequest('GET', '/instance/fetchInstances', '');

  if (Response <> '') and (FLastError = '') then
  begin
    try
      JsonData := GetJSON(Response);
      try
        if JsonData.JSONType = jtArray then
        begin
          for i := 0 to TJSONArray(JsonData).Count - 1 do
          begin
            InstanceData := TJSONArray(JsonData)[i];
            if (InstanceData <> nil) and (InstanceData.JSONType = jtObject) then
            begin
              JsonObj := TJSONObject(InstanceData);
              Result.Add(JsonObj.Get('name', '')); // 'name' contém o nome da instância
            end;
          end;
        end;
      finally
        JsonData.Free;
      end;
    except
      on E: Exception do
        FLastError := 'Error parsing JSON: ' + E.Message;
    end;
  end;
end;


end.

unit uEvo4Lazarus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,TypInfo,
  FPImgCanv, FPImage, FPReadPNG, Base64, LCLIntf, ExtCtrls, EvolutionAPI;

type

  { TfrmEvo4Lazarus }

  TfrmEvo4Lazarus = class(TForm)
		    Bevel1: TBevel;
		    Bevel2: TBevel;
		    Bevel3: TBevel;
		    btnQrcodeCode: TSpeedButton;
    deleteinstance: TSpeedButton;
    documentacao: TLabel;
    GroupBox1: TGroupBox;
    iddamensagem: TEdit;
    gbqrcode: TGroupBox;
    imgQrcode: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    meunumero: TEdit;
    imglist2: TImageList;
    imglist1: TImageList;
    Mensagem: TMemo;
    edtPairingCode: TEdit;
    rgqrcode: TRadioGroup;
    ScrollBox1: TScrollBox;
    CreateInstance: TSpeedButton;
    btnGetStatusInstance: TSpeedButton;
    btnstateinstance: TSpeedButton;
    btnGetAllInstances: TSpeedButton;
    ScrollBox2: TScrollBox;
    btnQrcode: TSpeedButton;
    btnSendMessage: TSpeedButton;
    btnGetStatusMessageID: TSpeedButton;
    btnSendFile: TSpeedButton;
    status: TMemo;
    telefone: TEdit;
    edtFile: TEdit;
    telefone1: TEdit;
    Token: TEdit;
    Instancia: TEdit;
    urlapi: TEdit;
    offline: TImage;
    online: TImage;

    procedure btnGetAllInstancesClick(Sender: TObject);
    procedure btnGetStatusInstanceClick(Sender: TObject);
    procedure btnGetStatusMessageIDClick(Sender: TObject);
    procedure btnQrcodeClick(Sender: TObject);
    procedure btnQrcodeCodeClick(Sender: TObject);
    procedure btnSendFileClick(Sender: TObject);
    procedure btnSendMessageClick(Sender: TObject);
    procedure btnstateinstanceClick(Sender: TObject);
    procedure CreateInstanceClick(Sender: TObject);
    procedure deleteinstanceClick(Sender: TObject);
    procedure documentacaoClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure rgqrcodeClick(Sender: TObject);
  private
    procedure statusform (value : string );
  public

  end;

var
  frmEvo4Lazarus: TfrmEvo4Lazarus;
  API: TEvolutionAPI;
  InstanceInfo: TInstanceInfo;
  QRInfo: TQRCodeInfo;
  MessageResponse: TMessageResponse;
  PairingCode: string;
  Instances: TStringList;
  i: Integer;
implementation

{$R *.lfm}

{ TfrmEvo4Lazarus }



procedure TfrmEvo4Lazarus.statusform(value: string);
begin
  status.Lines.Add(value);
end;

procedure TfrmEvo4Lazarus.btnGetAllInstancesClick(Sender: TObject);
begin
    // 9. Listar todas as instâncias
      statusform('=== Evolution API - Exemplo de Uso ===');
      API := TEvolutionAPI.Create(urlapi.text, token.text);
        statusform( 'Listando todas as instâncias...');
       Instances := API.GetAllInstances;
        try
          if Instances.Count > 0 then
          begin
            statusform('   Instâncias encontradas:');
            for i := 0 to Instances.Count - 1 do
            begin
              statusform('   - '+ Instances[i]);
              InstanceInfo := API.GetInstanceStatus(Instances[i]);
              statusform('       Status: '+ Ord(InstanceInfo.Status).tostring + ' | Conectada: '+ BoolToStr(InstanceInfo.IsConnected, True));
            end;
          end
          else
            statusform('   Nenhuma instância encontrada.');
        finally
          Instances.Free;
        end;
         API.Free;
end;

procedure TfrmEvo4Lazarus.btnGetStatusInstanceClick(Sender: TObject);
  var
    StatusStr: string;
  begin
      statusform('=== Evolution API - Exemplo de Uso ===');
      API := TEvolutionAPI.Create(urlapi.text, token.text);
      // 2. Verificar status da instância
      statusform('Verificando status da instância...');
      InstanceInfo := API.GetInstanceStatus(Instancia.text);
      statusform('   Instancia: ' +InstanceInfo.Name);
      case InstanceInfo.Status of
          isOffline       : StatusStr := 'Offline';
          isConnecting    : StatusStr := 'Connecting';
          isConnected     : StatusStr := 'Connected';
          isDisconnected  : StatusStr := 'Disconnected';
       else
         StatusStr := 'Unknown';
      end;

       //ocultar qrcode caso esteja conectado
       gbqrcode.Visible := InstanceInfo.status in [ isOffline, isConnecting , isDisconnected ];
       imgqrcode.Picture :=  nil;

       offline.Visible  := InstanceInfo.status in [ isOffline, isConnecting , isDisconnected ];
       online.Visible   := InstanceInfo.status in [ isConnected];

       btnSendMessage.Enabled         :=InstanceInfo.status in [ isConnected];
       btnGetStatusMessageID.Enabled  :=InstanceInfo.status in [ isConnected];
       btnSendFile.Enabled            :=InstanceInfo.status in [ isConnected];

        statusform('   Situação: ' + StatusStr);

      statusform('   Conectada: '+ BoolToStr(InstanceInfo.IsConnected, True));
      if InstanceInfo.ProfileName <> '' then
        statusform('   Perfil: '+ InstanceInfo.ProfileName);
      statusform('');
      API.Free;
  end;

procedure TfrmEvo4Lazarus.btnGetStatusMessageIDClick(Sender: TObject);
  var
    MsgResp: TMessageResponse;
  begin
    statusform('=== Evolution API - Exemplo de Uso ===');
    API := TEvolutionAPI.Create(urlapi.text, token.text);
    try
      statusform('Verificando status da mensagem...');

      MsgResp := API.FindStatusMessage(instancia.text, iddamensagem.text);

      case MsgResp.Status of
        msPending   : statusform('⏳ Pendente');
        msSent      : statusform('✅ Enviado');
        msDelivered : statusform('📬 Recebido');
        msRead      : statusform('👁️ Lido');
        msFailed    : statusform('❌ Falha');
      end;

      if MsgResp.Success then
        statusform(Format('MessageId %s '+sLineBreak+
                          'RemoteJid %s '+sLineBreak+
                          'status: %s',
                          [MsgResp.MessageId,
                          MsgResp.RemoteJid,
                          GetEnumName(TypeInfo(TMessageStatus), Ord(MsgResp.Status))]))
      else
        statusform('✗ Erro: ' + MsgResp.ErrorMessage);

    finally
      API.Free;
    end;
  end;



procedure TfrmEvo4Lazarus.btnQrcodeClick(Sender: TObject);
var
    QRInfo: TQRCodeInfo;
    Base64Data: string;
    ImageStream: TMemoryStream;
    FPImg: TFPMemoryImage;
    Reader: TFPReaderPNG;
  begin
    statusform('=== Evolution API - Exemplo de Uso ===');
    API := TEvolutionAPI.Create(urlapi.text, token.text);
    try
      statusform('Obtendo QR Code para conexão...');
      QRInfo := API.GetQRCode(instancia.text);

      if QRInfo.Success then
      begin
        statusform('   ✓ QR Code obtido com sucesso!');
        statusform('   QR Code: ' + Copy(QRInfo.QRCode, 1, 50) + '...');
        statusform('   Base64 disponível: ' + BoolToStr(QRInfo.Base64 <> '', True));

        if QRInfo.Base64 <> '' then
        begin
          // Remove prefixo "data:image/png;base64,"
          Base64Data := QRInfo.Base64;
          if Pos('base64,', Base64Data) > 0 then
            Base64Data := Copy(Base64Data, Pos('base64,', Base64Data) + 7, MaxInt);

          // Decodifica Base64 para bytes
          ImageStream := TMemoryStream.Create;
          try
            ImageStream.Write(DecodeStringBase64(Base64Data)[1], Length(DecodeStringBase64(Base64Data)));
            ImageStream.Position := 0;

            // Carrega PNG no TFPMemoryImage
            FPImg := TFPMemoryImage.Create(0,0);
            try
              Reader := TFPReaderPNG.Create;
              try
                FPImg.LoadFromStream(ImageStream, Reader);

                // Mostra no TImage
                imgQrcode.Picture.Assign(FPImg);
              finally
                Reader.Free;
              end;
            finally
              FPImg.Free;
            end;
          finally
            ImageStream.Free;
          end;
        end;
      end
      else
        statusform('   ✗ Erro ao obter QR Code: ' + QRInfo.ErrorMessage);

      statusform('');
    finally
      API.Free;
    end;
  end;

procedure TfrmEvo4Lazarus.btnQrcodeCodeClick(Sender: TObject);
var
  PhoneCode: string;
begin
  statusform('=== Evolution API - Conectar via Número ===');
  API := TEvolutionAPI.Create(urlapi.text, token.text);
  try
    PhoneCode := API.ConnectWithPairingCode(instancia.text, meunumero.text);
    edtPairingCode.clear;
    if PhoneCode <> '' then
      begin
       statusform('   ✓ Código obtido para número: ' + PhoneCode);
       edtPairingCode.text :=  PhoneCode;
      end
    else
      statusform('   ✗ Erro ao conectar: ' + API.LastError);
  finally
    API.Free;
  end;
end;

procedure TfrmEvo4Lazarus.btnSendFileClick(Sender: TObject);
begin
  API := TEvolutionAPI.Create(urlapi.text, token.text);
  statusform('=== Evolution API - Exemplo de Uso ===');
  statusform('Enviando documento...');
  if FileExists(edtFile.text) then
  begin

    // Simula digitação por 5 segundos
    api.SimulateTyping(instancia.text, telefone.text, 5);
    // enviando mensagem
    MessageResponse := API.SendFileMessage(Instancia.text, telefone.text, mensagem.text, edtFile.text);

    if MessageResponse.Success then
    begin
      statusform('   ✓ Documento enviado com sucesso!');
      statusform('   ID da mensagem: '+ MessageResponse.MessageId);
    end
    else
    statusform('   ✗ Erro ao enviar documento: '+ MessageResponse.ErrorMessage);

  end
  else
  statusform('   Arquivo '+edtFile.text+' não encontrado');
  API.Free;
end;

procedure TfrmEvo4Lazarus.btnSendMessageClick(Sender: TObject);
begin
  // 5. Verificar se está conectado antes de enviar mensagens


   API := TEvolutionAPI.Create(urlapi.text, token.text);
   try
     statusform('=== Evolution API - Exemplo de Uso ===');
          if API.IsInstanceActive(Instancia.text) then
          begin
            statusform('Enviando mensagem de texto...');
            // Simula digitação por 5 segundos
            api.SimulateTyping(instancia.text, telefone.text, 5);
            // enviando mensagem
            MessageResponse := API.SendTextMessage(Instancia.text, telefone.text, mensagem.text);

            if MessageResponse.Success then
            begin
              statusform('   ✓ Mensagem enviada com sucesso!');
              statusform('   ID da mensagem: '+ MessageResponse.MessageId);
              iddamensagem.text := MessageResponse.MessageId;
              statusform('   Status: '+ Ord(MessageResponse.Status).tostring);
              case MessageResponse.Status of
                  msPending   : statusform('Pendente ');
                  msSent      : statusform('Enviado');
                  msDelivered : statusform('Recebido ');
                  msRead      : statusform('Lido');
                  msFailed    : statusform('Falha');
              end;
     	    end;
     	 statusform('   Para: '+ MessageResponse.RemoteJid);
            end
            else
              begin
                statusform('   ✗ Erro ao enviar mensagem: '+ MessageResponse.ErrorMessage);
     	 end;
         statusform('');
   finally
     Api.free;
   end;

end;


procedure TfrmEvo4Lazarus.btnstateinstanceClick(Sender: TObject);
begin
    // 3. Iniciar instância se não estiver ativa
        API := TEvolutionAPI.Create(urlapi.Text, token.Text);
        try
          statusform('=== Evolution API - Exemplo de Uso ===');

          if not API.IsInstanceActive(Instancia.Text) then
          begin
            statusform('Iniciando instância...');

            if API.StartInstance(Instancia.Text) then
              statusform('   ✓ Instância iniciada com sucesso!')
            else
              statusform('   ✗ Erro ao iniciar instância: ' + API.LastError);

            statusform('');

            // Aguardar um pouco para a instância se conectar
            statusform('   Aguardando conexão...');
            Sleep(3000);

            // Opcional: checar novamente o status
            if API.IsInstanceActive(Instancia.Text) then
              statusform('   Instância agora está conectada!')
            else
              statusform('   Instância ainda não conectada.');
          end
          else
            statusform('   Instância já está ativa.');
        finally
          API.Free;
        end;
end;

procedure TfrmEvo4Lazarus.CreateInstanceClick(Sender: TObject);
begin
  // 1. Criar uma nova instância
  API := TEvolutionAPI.Create(urlapi.text, token.text);
  statusform('=== Evolution API - Exemplo de Uso ===');
  statusform('Criando instância...');
  if API.CreateInstance(Instancia.text, rgqrcode.ItemIndex.ToBoolean) then
  statusform('   ✓ Instância criada com sucesso!')
  else
  statusform('   ✗ Erro ao criar instância: ' +  API.LastError);
  statusform('');
  API.Free;
end;

procedure TfrmEvo4Lazarus.deleteinstanceClick(Sender: TObject);
var
 result : boolean;
begin
  statusform('=== Evolution API - Exemplo de Uso ===');
  API := TEvolutionAPI.Create(urlapi.text, token.text);
  statusform('Deletando instância...');
  result := API.DeleteInstance(instancia.text);
  if result then
  begin
   statusform('   ✓ Instância deletada com sucesso!') ;
   offline.Visible                :=  result;
   online.Visible                 := not result;
   btnSendMessage.Enabled         := not result;
   btnGetStatusMessageID.Enabled  := not result;
   btnSendFile.Enabled            := not result;
  end;

  if not result then
  statusform('   ✗ Erro ao deletar instância: ' +  API.LastError);

  statusform('');
  API.Free;
end;

procedure TfrmEvo4Lazarus.documentacaoClick(Sender: TObject);
begin
 OpenURL(documentacao.caption);
end;

procedure TfrmEvo4Lazarus.FormShow(Sender: TObject);
begin
 rgqrcode.OnClick(self);
end;


procedure TfrmEvo4Lazarus.rgqrcodeClick(Sender: TObject);
begin
  btnQrcode.Enabled    := not rgqrcode.ItemIndex.ToBoolean;
  btnQrcodeCode.Enabled:= rgqrcode.ItemIndex.ToBoolean;
end;


end.


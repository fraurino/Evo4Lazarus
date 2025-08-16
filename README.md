<p>
  <img width="90" height="90" alt="evo4lazarus" src="https://github.com/user-attachments/assets/15f5565a-b825-4cf7-a2c7-915df8638843" />
  <b><strong>EvolutionAPI Lazarus/Delphi</strong></b>
</p>


**Projeto Open Source para integração com a Evolution API usando Lazarus**  

Este projeto utiliza uma API chamada por **Evolution API** , https://github.com/EvolutionAPI/evolution-api, permitindo funcionalidades como envio de mensagens via WhatsApp, simulação de digitação, verificação de número comercial, download de imagens e consulta de status de mensagens e entre outras funcionalidades;

O projeto é **open source**, e todo aprimoramento, correção ou evolução deve manter os créditos do autor.

---
<img width="797" height="750" alt="image" src="https://github.com/user-attachments/assets/2cd2b9e0-a687-4279-87f9-4bf9c117c7c8" /> <p>

## 🔗 Grupo Evo4Lazarus<p>
https://chat.whatsapp.com/FBzDEpa4d3dBJVjOVxyXDE

## 📌 Funcionalidades

- Conexão com a Evolution API via instância e número de telefone  
- Obtenção de **pairing code** e **QrCODE** para autenticação; 
- Envio de mensagens de texto e mídia  
- Simulação de digitação (`typing`)
- Bloquear e Desbloquear contato;
- Download de imagens de perfil de contatos  
- Consulta de **status de mensagens**  
- Estrutura de tipos e records para **status de instância e mensagens**  
- Código preparado para Lazarus 4.0 com tratamento de exceções  
---
## ⚡ Exemplo de Uso

```pascal
var
  API: TEvolutionAPI;
  MsgResp: TMessageResponse;
begin
  API := TEvolutionAPI.Create('https://demo2.apieuatendo.com.br', 'SUA_APIKEY');
  try 
   // Simula digitação por 5 segundos
   api.SimulateTyping(instancia.text, telefone.text, 5);

   //Enviando mensagem
   API.SendTextMessage(Instancia.text, telefone.text, mensagem.text);

   // retorno do status do envio da mensagem
    if MessageResponse.Success then
    begin
      statusform('   ✓ Mensagem enviada com sucesso!');
      statusform('   ID da mensagem: '+ MessageResponse.MessageId);
      iddamensagem.text := MessageResponse.MessageId;
      statusform('   Status: '+ Ord(MessageResponse.Status).tostring);

      // situação da leitura da mensagem pelo destinatário
      case MessageResponse.Status of
          msPending   : statusform('Pendente ');
          msSent      : statusform('Enviado');
          msDelivered : statusform('Recebido ');
          msRead      : statusform('Lido');
          msFailed    : statusform('Falha');
      end;
  end

  finally
    API.Free;
  end;
end;

git clone [https://github.com/fraurino/Evo4Lazarus/EvolutionAPI_Lazarus.git](https://github.com/fraurino/Evo4Lazarus.git)
```
---
## 📂 Instalação

Baixe ou clone este repositório:

git clone [https://github.com/fraurino/Evo4Lazarus/EvolutionAPI_Lazarus.git](https://github.com/fraurino/Evo4Lazarus.git)


Abra o projeto .lpi no Lazarus.

Adicione a unit EvolutionAPI.pas ao seu projeto.

## 📖 Documentação

A documentação oficial da API está disponível em:
https://doc.apicomponente.com.br/introduction


## 📝 Licença

Open Source – Direitos Autorais do Criador Mantidos

Todo e qualquer aprimoramento, correção ou evolução deste projeto deve manter os dados do criador original.
Uso, redistribuição e adaptação são permitidos, contanto que seja mantido o crédito do autor.
<center><img width="50" height="50" alt="evo4lazarus-removebg-preview" src="https://github.com/user-attachments/assets/15f5565a-b825-4cf7-a2c7-915df8638843" /></center>

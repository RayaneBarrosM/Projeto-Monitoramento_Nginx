# Projeto de Monitoramento de Erros

**🎯 Objetivos do projeto:**<br>

♦ Monitorar erros<br>
♦ Redirecionar erros para Discord
<br>

# 🧩Para fazer este projeto foi utilizado:
Maquina Virtual VirtualBox
Distribuição Linux Mint Mate

# 📌 Passo a Passo <br> 
**1. Instalação do Nginx**  <br>
Atualize a lista de pacotes disponíveis para evitar trabalhar com pacotes desatualizados e instale o Nginx com os seguintes comandos. <br>
```bash
sudo apt update
sudo apt install nginx
```
-Para verificar o status do pacote execute: `systemctl status nginx` <br>
-Caso ele esteja inativo, inicie-o com:  `systemctl start nginx`.<br>

**2.Criação de uma página html**<br>
Crie uma pasta em `/var/www/` aqui chamarei de discord-webhook, e dentro dela um arquivo `índex.html`
```html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8"/>
<title>Página Nginx</title>
</head>
<body>
<H1>Página Nginx</H1>
</body>
</html>
```
<br>

**3. Configuração o servidor** <br>
Configure o servidor acessando o arquivo default por meio do comando: `sudo nano /etc/nginx/sites-enabled/default` 

```nginx
server{
  listen 80 default_server; #Porta padrão
  listen [::]:80 default_server;

  #Caminho para o site
  root /var/www/discord-webhook; #pasta criada no passo anterior;
  index pagina.html;
  
  server_name 0.0.0.0; #colocar ip da sua maquina ou _

  location /webhook{
    proxy_pass http://localhost:3000/webhook; #Porta utilizada;
    proxy_set_header Content_Type; "application/json"

    #Restrição de ip
    allow 0.0.0.0; #colocar ip da sua máquina
    deny all; #bloqueia de utilizarem outro ip para acessarem
  }
}
```
**4.Criação de webhook**<br>
Para a criação do webhook será utilizado um canal no Discord, para isso siga os seguintes passos:<br>
• Criar um servidor no discord<br>
• Acessar as configurações do canal onde será lançado as mensagens<br>
• Selecionar a aba Integrações<br>
• Clicar em criar webhook<br>
• Clique em copiar url para adiciona-lo ao script 


**5.Criação do Script**

```bash
#Variaveis e permições
LOG_DIR="var/log/nginx/pasta-logs" #Caminho para o diretório onde serão armazenados os arquivo de logs
LOG_FILE="$LOG_DIR/monitoramento-logs" #Caso o caminho não esteja funcionando tente desta forma
WEBHOOK_URL="HTTPS://discord.com/api/webhooks/..." #Aqui voce ira adicionar a url do Webhook
SERVICE="nginx"

sudo mkdir -p "$LOG_DIR" || { echo "Erro ao criar diretorio" >&2; exit1; } # Cria diretório de logs 
sudo touch "LOG_FILE" || { echo "Erro ao criar arquivo de logs" >&2; exit1; } # Cria o arquivo de logs vazio
sudo chmod 664 "LOG_FILE" #Permição do de dono e grupos

#Função de registro de logs
log(){
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a "$LOG_FILE" # Formata com hora e grava no arquivo de log
}

#Registra a criação do registro de log
log "Arquivo de log criado"

#Função para enviar  alertas ao Discord
discord_alert() {
   local message="$1" # Armazena o primeiro argumento passado na variável
   # Envia uma mensagem JSON para o webhook do Discord via curl
   curl  -s -X POST "$WEBHOOK_URL" -H "Content-type: application/json" -d "{\"content\" :\"$message\"}"
}

#Loop de verificao a cada 1 minuto
while true; do
       # Verifica se o serviço Nginx está inativo
        if ! systemctl is-active --quiet "$SERVICE"; then
          log "$SERVICE está inativo"
          discord_alert "Servidor inativo"

        #Tentativas de reiniciar serviço
             if sudo systemctl restart "$SERVICE"; then
                 log "$SERVICE reiniciado com sucesso."
                 discord_alert "Servidor reiniciado"

            # Se o restart falhar, tenta um start
             else
                  if sudo systemctl start "$SERVICE"; then
                     log "$SERVICE reiniciado com sucesso."
                     discord_alert "Reiniciado com sucesso"

                  # Se ambas as tentativas falharem
                  else
                     log "Falha ao reiniciar $SERVICE!"
                     discord_alert
                     exit 1
                  fi 
             fi
        fi
        # Intervalo 
        sleep 60
done
```

**6.Teste**

Para testar se o script funciona digite os seguintes comandos:

```bash
sudo systemctl stop nginx
sudo bash seu_script.sh
```
<img width="514" height="125" alt="image" align="center" src="https://github.com/user-attachments/assets/ab5c9f38-13af-4393-8b9d-cdc3b807c49d" />

*Forma de como devem aparecer logs no terminal*

<img width="514" height="105" alt="image" align="center" src="https://github.com/user-attachments/assets/20a7e9a1-9b68-4c7c-9b4c-11dd6ac62765" />

*Forma como deve aparecer no Discord* <br>
Para parar utilize `Ctrl+C`


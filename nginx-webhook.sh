#!/bin/bash

LOG_DIR="/var/log/nginx/monitoramento"
LOG_FILE="$LOG_DIR/monitoramento.log"
WEBHOOK_URL="https://discord.com/api/webhooks/1404915160254124162/t4KtrCNhhWGwD-xSvvo3ivkYq12OfMQWTilkqz0tR_hq7Zcje3ifVJZZ2uureTDYeyu_"
SERVICE="nginx"

#Redirecionamento dos Logs para arquivo e permição
sudo mkdir -p "$LOG_DIR" ||{ echo "Erro: Tentativa falha de criar $LOG_DIR!" >&2; exit 1; }
sudo touch "$LOG_FILE" || { echo "Erro: Tentativa falha de criar arquivo de log" >&2; exit 1; }
sudo chown $(whoami):$(id -gn) "$LOG_FILE"
sudo chmod 644 "$LOG_FILE"

#Função de registro de logs
log(){
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a "$LOG_FILE"
} 

log "Arquivo de log criado"

discord_alert() {
   local message="$1"
   curl  -s -X POST "$WEBHOOK_URL" -H "Content-type: application/json" -d "{\"content\" :\"$message\"}"
}

#Loop de verificao a cada 1 minuto
while true; do
        if ! systemctl is-active --quiet "$SERVICE"; then
          log "$SERVICE está inativo"
          discord_alert "Servidor inativo"
	#Tentativas de reiniciar serviço
             if sudo systemctl restart "$SERVICE"; then
                 log "$SERVICE reiniciado com sucesso."
                 discord_alert "Servidor reiniciado"

             else
                  if sudo systemctl start "$SERVICE"; then
                     log "$SERVICE reiniciado com sucesso."
                     discord_alert "Reiniciado com sucesso"

                  else
                     log "Falha ao reiniciar $SERVICE!"
                     discord_alert
                     exit 1
                  fi 
             fi
        fi
 
        sleep 60
done

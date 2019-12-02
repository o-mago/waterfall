#include <Arduino.h>
#include <Wire.h>

#include <Arduino_FreeRTOS.h>
#include <semphr.h>

#include <SoftwareSerial.h>

//Pinos para comunicação Arduino - Bluetooth
SoftwareSerial bluetooth(7, 8); //(rx, tx)

//Variável que indica se o app enviou o comando para parar o sistema
bool on = true;

//Potência da bomba
int speed = 255;

//Variável para evitar dados extras vindos pela comunicação bluetooth
bool speedAlready = true;

//Pinos PWM da ponte h
int IN1 = 10;
int IN2 = 11;

//Pino sensor nível baixo de fluido
int sensorBaixo = 2;

//Pino sensor nível alto de fluido
int sensorAlto = 3;

//Semaforo binário para ligar a bomba
SemaphoreHandle_t ligaBombaSemaforo;

//Semaforo binário para desligar a bomba
SemaphoreHandle_t desligaBombaSemaforo;

void setup(void)
{
  //Serial para debug
  Serial.begin(9600);

  //Inicia comunicação com módulo Bluetooth
  bluetooth.begin(9600);
  
  //Pinos ponte h como output
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);

  //Pinos sensores como input
  pinMode(sensorBaixo, INPUT);
  pinMode(sensorAlto, INPUT);

  //Cria as tasks
  xTaskCreate(TaskLigaBomba,
              "Liga Bomba",
              128,
              NULL,
              1,
              NULL);

  xTaskCreate(TaskDesligaBomba,
              "Desliga Bomba",
              128,
              NULL,
              1,
              NULL);

  xTaskCreate(TaskBluetooth,
              "Bluetooth",
              128,
              NULL,
              0,
              NULL);

  //Inicializa os semaforos como binários
  ligaBombaSemaforo = xSemaphoreCreateBinary();
  desligaBombaSemaforo = xSemaphoreCreateBinary();

  //Verifica o nível inicial do fluido
  verificaEstadoAtual();

  //Interrupções para leitura dos sensores de nível
  if (ligaBombaSemaforo != NULL)
  {
    attachInterrupt(digitalPinToInterrupt(sensorBaixo), ligaBombaHandler, RISING); //Rising: LOW -> HIGH
  }

  if (desligaBombaSemaforo != NULL)
  {
    attachInterrupt(digitalPinToInterrupt(sensorAlto), desligaBombaHandler, FALLING); //Falling: HIGH -> LOW
  }
}

//=============== Rotinas para tratar as interrupções ================
void ligaBombaHandler()
{
  xSemaphoreGiveFromISR(ligaBombaSemaforo, NULL);
}

void desligaBombaHandler()
{
  xSemaphoreGiveFromISR(desligaBombaSemaforo, NULL);
}
//====================================================================

//================ Funções para controle da ponte h ==================
void ligaBomba() {
  Serial.println("Ligada");
  digitalWrite(IN1, speed);
  digitalWrite(IN2, 0);
}

void desligaBomba() {
  Serial.println("Desligada");
  digitalWrite(IN1, 255);
  digitalWrite(IN2, 255);
}
//====================================================================

void verificaEstadoAtual() {
  if(!digitalRead(sensorAlto)) {
    Serial.println("ALTO");
    xSemaphoreGive(desligaBombaSemaforo);
    bluetooth.write(static_cast<byte>(1));
  } else {
    Serial.println("BAIXO");
    xSemaphoreGive(ligaBombaSemaforo);
    bluetooth.write(static_cast<byte>(0));
  }
}

void TaskLigaBomba(void *pvParameters)
{
  (void)pvParameters;

  for (;;)
  {
    //Com o reservatório vazio, pega o semáforo para ligar a bomba e enviar a informação para o app
    xSemaphoreTake(ligaBombaSemaforo, portMAX_DELAY);
    Serial.println("Liga Bomba");
    ligaBomba();
    bluetooth.write(static_cast<byte>(0));
  }
}

void TaskDesligaBomba(void *pvParameters) {
  
  (void)pvParameters;

  for (;;)
  {
    //Com o reservatório cheio (após a interrupção) pega o semáforo para desligar a bomba e enviar a informação para o app
    xSemaphoreTake(desligaBombaSemaforo, portMAX_DELAY);
    Serial.println("Desliga Bomba");
    desligaBomba();
    //Só muda o nível de fluido no app se o sistema estiver ligado (evita mudar se clicar em desligar o sistema)
    if(on) {
      bluetooth.write(static_cast<byte>(1));
    }
  }
}

//Task para receber informações da aplicação mobile
void TaskBluetooth(void *pvParameters)
{
  (void)pvParameters;

  for (;;)
  {
    while (bluetooth.available())
    {
      int msg = bluetooth.read();
      if (msg >= 32 && msg <= 126)
      {
        Serial.println(msg);
        switch (msg)
        {
        //ON
        case 'a':
          on = true;
          verificaEstadoAtual();
          break;
        //OFF
        case 'b':
          on = false;
          xSemaphoreGive(desligaBombaSemaforo);
          break;
        //Muda SPEED
        default:
          if (!speedAlready)
          {
            int speedReceived = 0;
            if (msg >= 48 && msg <= 57)
            {
              speedReceived = msg - '0';
            }
            speedAlready = true;
            speed = map(speedReceived, 0, 5, 0, 255);
            verificaEstadoAtual();
            Serial.print("speed: ");
            Serial.println(speed);
            break;
          }
        }
      }
    }
    speedAlready = false;
  }
}

void loop()
{
}
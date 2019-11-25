#include <Arduino.h>
#include <Wire.h>

#include <Arduino_FreeRTOS.h>
#include <semphr.h>

#include <SoftwareSerial.h>

SoftwareSerial bluetooth(7, 8);

bool on = true;

int speed = 255;

bool speedAlready = true;

int IN1 = 10;
int IN2 = 11;

int sensorBaixo = 2;
int sensorAlto = 3;

SemaphoreHandle_t ligaBombaSemaforo;
SemaphoreHandle_t desligaBombaSemaforo;

void setup(void)
{
  Serial.begin(9600);

  bluetooth.begin(9600);

  pinMode(13, OUTPUT);
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(sensorBaixo, INPUT);
  pinMode(sensorAlto, INPUT);

  digitalWrite(13, LOW);

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

  ligaBombaSemaforo = xSemaphoreCreateBinary();
  desligaBombaSemaforo = xSemaphoreCreateBinary();
  xSemaphoreGive(ligaBombaSemaforo);

  //Interrupções para leitura dos sensores de nível
  if (ligaBombaSemaforo != NULL)
  {
    attachInterrupt(digitalPinToInterrupt(sensorBaixo), ligaBombaHandler, FALLING); //Falling: HIGH -> LOW
  }

  if (desligaBombaSemaforo != NULL)
  {
    attachInterrupt(digitalPinToInterrupt(sensorAlto), desligaBombaHandler, RISING); //Rising: LOW -> HIGH
  }
}

//=============== Rotinas para tratar as interrupções ================
void ligaBombaHandler()
{
  Serial.println("LIGA");
  xSemaphoreGiveFromISR(ligaBombaSemaforo, NULL);
}

void desligaBombaHandler()
{
  Serial.println("Desliga");
  xSemaphoreGiveFromISR(desligaBombaSemaforo, NULL);
}
//====================================================================

//================ Funções para controle da ponte h ==================
void ligaBomba() {
  digitalWrite(IN1, speed);
  digitalWrite(IN2, LOW);
}

void desligaBomba() {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, HIGH);
}
//====================================================================

void TaskLigaBomba(void *pvParameters)
{
  (void)pvParameters;

  for (;;)
  {
    //Com o reservatório vazio, pega o semáforo para ligar a bomba e enviar a informação para o app
    if ((xSemaphoreTake(ligaBombaSemaforo, portMAX_DELAY) == pdPASS) && on)
    {
      Serial.println("LOW");
      ligaBomba();
      bluetooth.write(static_cast<byte>(0));
    }
  }
}

void TaskDesligaBomba(void *pvParameters) {
  
  (void)pvParameters;

  for (;;)
  {
    //Com o reservatório cheio (após a interrupção) pega o semáforo para desligar a bomba e enviar a informação para o app
    if (xSemaphoreTake(desligaBombaSemaforo, portMAX_DELAY) == pdPASS)
    {
      Serial.println("HIGH");
      desligaBomba();
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
          break;
        //OFF
        case 'b':
          on = false;
          xSemaphoreGive(desligaBombaSemaforo);
          break;
        //CHANGE SPEED
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
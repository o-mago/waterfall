#include <Arduino.h>
#include <Wire.h>

#define DEBUG 1

#include <SoftwareSerial.h>

SoftwareSerial bluetooth(7, 8);

bool doUpdateStatus = false;

int speed = 0;

bool speedAlready = true;

void loop(void)
{
  delay(1);
  while (bluetooth.available()) {
    int msg = bluetooth.read();
    if(msg >= 32 && msg <= 126) {
      Serial.println(msg);
      switch (msg) {
        //ON
        case 'a':
          doUpdateStatus = true;
          digitalWrite(13, HIGH);
          break;
        //OFF
        case 'b':
          doUpdateStatus = false;
          digitalWrite(13, LOW);
          break;
        //CHANGE SPEED
        // case 's':
        //   char mensagem[3];
        //   int cont = 0;
        //   while (bluetooth.available())
        //   {
        //     int byte = bluetooth.read();
        //     if(byte >= 48 && byte <= 57) {
        //       mensagem[cont] = byte;
        //       cont++;
        //     }
        //   }
        //   speed = atoi(mensagem);
        //   Serial.print("speed: ");
        //   Serial.println(speed);
        //   doUpdateStatus = false;
        //   break;
        default :
          if(!speedAlready) {
            if(msg >= 48 && msg <= 57) {
              speed = msg-'0';
            }
            speedAlready = true;
            Serial.print("speed: ");
            Serial.println(speed);
            doUpdateStatus = false;
            break;
          }
      }
    }
  }

  speedAlready = false;
  
  // static unsigned long lastRefreshTime = 0;
  // if (millis() - lastRefreshTime >= 1000) {
  //   lastRefreshTime += 1000;
    
  //   if (doUpdateStatus) {
      
  //     bluetooth.write('t');
  //     for (byte i = 0; i < 2; i++) {
  //       bluetooth.write(static_cast<byte>(static_cast<int>(DS18B20_value[i])));
  //       bluetooth.write(static_cast<byte>(static_cast<int>((DS18B20_value[i] - static_cast<int>(DS18B20_value[i])) * 100)));
  //     }
      
  //     bluetooth.write('w');
  //     bluetooth.write(static_cast<byte>(static_cast<int>(phSensors[0].value)));
  //     bluetooth.write(static_cast<byte>(static_cast<int>((phSensors[0].value - static_cast<int>(phSensors[0].value)) * 100)));
  //   }
  // }
}

void setup(void)
{
  Serial.begin(9600);
  
  bluetooth.begin(9600);
  
  pinMode(13, OUTPUT);
  digitalWrite(13, LOW);
}
//import necessary libraries to calibrate ADC readings from ESP32 pins
#include "Arduino.h"
#include <ESP32AnalogRead.h>

//import necessary libraries for the BLE capabilities
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

//import necessary libraries to use OLED display.
//TFT display communicates via SPI communication: include the SPI library on your code. 
//We also use the TFT library to write and draw on the display.
#include <SPI.h>
#include <TFT_eSPI.h>       // Hardware-specific library

#include <Wire.h>//library to use I2C
//libraries to interface with BME280
#include <Adafruit_Sensor.h>
#include <Adafruit_BME280.h>

TFT_eSPI tft = TFT_eSPI();  // Invoke custom library

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

//define UUID (Universally Unique Identifier) for the Service and Characteristic
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

Adafruit_BME280 bme; // I2C protocol, create object called bme

//callback that handles the bluetooth connection status
//sets the "deviceConnected" flag true or false when you connect or discconect from the ESP32
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      BLEDevice::startAdvertising();
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

//declare pins
ESP32AnalogRead vmeas1adc;
ESP32AnalogRead vmeas2adc;
ESP32AnalogRead imeas1adc;
ESP32AnalogRead imeas2adc;
const int s1Pin=27;
const int s2Pin=2;
const int s3Pin=15;
const int readButtonPress=37;

//variables
// adc pin values
float v1meas=0;
float i1meas=0;
float v2meas=0;
float i2meas=0;
//desired values
float vmeas1=0;
float imeas1=0;
float vmeas2=0;
float imeas2=0;
int takeRead=0;
float temperature=0;

//constants     
#define        resolution12bit                 4095           
#define        REF_VOLTAGE                     3.3         
float sensitivity=0.1;  
float Voc=37;//48.2
float Isc=8.66;//9.72
float v_offset1 = 2.54;
float v_offset2 = 2.54;



void setup() {
 //import necessary libraries to calibrate ADC readings from ESP32 pins
#include "Arduino.h"
#include <ESP32AnalogRead.h>

//import necessary libraries for the BLE capabilities
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

//import necessary libraries to use OLED display.
//TFT display communicates via SPI communication: include the SPI library on your code. 
//We also use the TFT library to write and draw on the display.
#include <SPI.h>
#include <TFT_eSPI.h>       // Hardware-specific library

#include <Wire.h>//library to use I2C
//libraries to interface with BME280
#include <Adafruit_Sensor.h>
#include <Adafruit_BME280.h>

TFT_eSPI tft = TFT_eSPI();  // Invoke custom library

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

//define UUID (Universally Unique Identifier) for the Service and Characteristic
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

Adafruit_BME280 bme; // I2C protocol, create object called bme

//callback that handles the bluetooth connection status
//sets the "deviceConnected" flag true or false when you connect or discconect from the ESP32
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      BLEDevice::startAdvertising();
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

//declare pins
ESP32AnalogRead vmeas1adc;
ESP32AnalogRead vmeas2adc;
ESP32AnalogRead imeas1adc;
ESP32AnalogRead imeas2adc;
const int s1Pin=27;
const int s2Pin=2;
const int s3Pin=15;
const int readButtonPress=37;

//variables
// adc pin values
float v1meas=0;
float i1meas=0;
float v2meas=0;
float i2meas=0;
//desired values
float vmeas1=0;
float imeas1=0;
float vmeas2=0;
float imeas2=0;
int takeRead=0;
float temperature=0;

//constants     
#define        resolution12bit                 4095           
#define        REF_VOLTAGE                     3.3         
float sensitivity=0.1;  
float Voc=37;//48.2
float Isc=8.66;//9.72
float v_offset1 = 2.54;
float v_offset2 = 2.54;


void setup() {
  //starts serial communication
  Serial.begin(115200);
  analogReadResolution(12);
  
  //configure pins as INPUTs/OUTPUTs
  vmeas1adc.attach(32);
  vmeas2adc.attach(33);
  imeas1adc.attach(39);
  imeas2adc.attach(36);
  pinMode(s1Pin,OUTPUT);
  pinMode(s2Pin,OUTPUT);
  pinMode(s3Pin,OUTPUT);
  pinMode(readButtonPress,INPUT);  
 
  // Create the BLE Device
  BLEDevice::init("ESP32");

  // Create the BLE Server and set the BLE devvice as a server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service using service UUID
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create a BLE Characteristic, need to pass as properties the characteristic's properties
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );

  // https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.descriptor.gatt.client_characteristic_configuration.xml
  // Create a BLE Descriptor
  //BLE2902 desciptor makes it so that the esp32 wont notify the clients unless the client wants to 
  //read values 
  pCharacteristic->addDescriptor(new BLE2902());

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);  // set value to 0x00 to not advertise this parameter
  BLEDevice::startAdvertising();
  Serial.println("Waiting a client connection to notify...");

  //initialise OLED display
    tft.init();
    tft.setRotation(1);
    tft.fillScreen(TFT_WHITE);
    // Set "cursor" at top left corner of display (0,0) and select font 4
    tft.setCursor(37, 50, 4);
    // Set the font colour to be white with a black background
    tft.setTextColor(TFT_BLACK, TFT_WHITE);
    // We can now plot text on screen using the "print" class
    tft.println("Starting Device");
    

  //initialise bme280 sensor
   bool status;
  status = bme.begin(0x76); 
  if (!status) {
   Serial.println("Could not find a valid BME280 sensor, check wiring!");
  while (1);
  }
  delay(1500);
}

void loop() {
    //if "take meaurement" button is pressed take readings, otherwise dont take readings and open switch 3
    if(digitalRead(readButtonPress)==HIGH){
      takeRead=1;
      }
      else{
        takeRead=0;
        s3on();
        }


  //if "take measurements" button is pressed:
  if(takeRead==1 ){
    //read voltage level from adc pin and calibrate pin voltage
    v1meas=(vmeas1adc.readVoltage())*1.1977-0.0671;
    v2meas=(vmeas2adc.readVoltage())*1.1938-0.0645;
    i1meas=(imeas1adc.readVoltage());
    i2meas=(imeas2adc.readVoltage());
    
    //calibrate values as seen before their respective voltage dividers 
    vmeas1=(v1meas*((556000+38200)/38200))*1.0363+0.019;
    vmeas2=(v2meas*((556000+38200)/38200))*1.0487-0.0426;
    imeas1=(i1meas*(323000+564000)/564000)*v_offset1/1.85;
    imeas2=(i2meas*(325400+560000)/560000)*v_offset2/1.88;

    imeas1=((imeas1-v_offset1)/0.1)*5;
    imeas2=((imeas2-v_offset2)/0.1)*5;
    
    //read temerpature in Celsius of BME280
    temperature=bme.readTemperature();

    if(vmeas1<2){
      s1on();
    }
    else if(vmeas1>Voc){
      s3on();
    }
    else{
      s2on();
    }

    displayMeasurements();
    //check if device is connectedor not (handled by callback function)
    //if ESP is connected, save measurements and temperature to char array "str"
    //so that the app can process it, set the value to send and notify the client
    if (deviceConnected && vmeas1>0.69) {
      String str = "";
        str += vmeas1;
        str += ",";
        str += imeas1;
        str += ",";
        str += temperature;
        
        pCharacteristic->setValue((char*)str.c_str());
        pCharacteristic->notify();

    }
    else if (deviceConnected && vmeas1<0.69){
      String strn = "";
        
        pCharacteristic->setValue((char*)strn.c_str());
        pCharacteristic->notify();
      }
    // disconnecting
    if (!deviceConnected && oldDeviceConnected) {
        delay(500); // give the bluetooth stack the chance to get things ready
        pServer->startAdvertising(); // restart advertising
        Serial.println("start advertising");
        oldDeviceConnected = deviceConnected;
    }
    // connecting
    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
    }

   }
   if(takeRead==0){
    display_when_not_measuring();
    s3on();
    }

  delay(0.01);
}

void display_when_not_measuring(){
    tft.fillScreen(TFT_WHITE);
    tft.setRotation(1);
    tft.setCursor(0, 45, 4);
    tft.setTextColor(TFT_BLACK, TFT_WHITE);
    tft.println("Press button to start meseauring");
  }
  
  void s1on(){
    digitalWrite(s1Pin,HIGH);
    digitalWrite(s2Pin,LOW);
    digitalWrite(s3Pin, LOW); 
    }

  void s2on(){
    digitalWrite(s1Pin,LOW);
    digitalWrite(s2Pin,HIGH);
    digitalWrite(s3Pin, LOW); 
    }

  void s3on(){
    digitalWrite(s1Pin,LOW);
    digitalWrite(s2Pin,LOW);
    digitalWrite(s3Pin,HIGH);
    } 

  void displayMeasurements(){
    tft.fillScreen(TFT_WHITE);
        tft.setRotation(1);
        tft.setCursor(0, 0, 4);
        tft.setTextColor(TFT_BLACK, TFT_WHITE);
        tft.print("   Live Measurements\n");
        tft.print("V1: ");
        tft.print(vmeas1);
        tft.print("      I1: ");
        tft.print(imeas1);
        tft.print("\nV2: ");
        tft.print(vmeas2);
        tft.print("      I2: ");
        tft.println(imeas2);
        tft.print("Temperature: ");
        tft.print(temperature);
        tft.setCursor(60,120, 2);
        tft.setTextColor(TFT_BLUE, TFT_WHITE);
        tft.print("Press button to stop");
    }  

    
    

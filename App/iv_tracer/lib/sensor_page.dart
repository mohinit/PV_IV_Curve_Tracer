//https://github.com/cph-cachet/flutter-plugins/blob/master/packages/light/example/lib/main.dart
import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iv_tracer/VCChart.dart';
import 'package:iv_tracer/CurrentChart.dart';
import 'package:iv_tracer/VoltageChart.dart';
import 'package:iv_tracer/stc_iv.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:light/light.dart';
import 'package:path_provider/path_provider.dart';

import 'DataModel.dart';
import 'gallery_scaffold.dart';
//import 'package:flutter_android/android_hardware.dart' show Sensor, SensorEvent, SensorManager;

class SensorPage extends StatefulWidget {
  const SensorPage({Key key, this.device}): super(key: key);
  final BluetoothDevice device;


  @override
  _SensorPageState createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  List<DataModel> associateList = new List<DataModel>() ;
  bool csvUpdating = false;
  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final int listSize = 100 ;// set size for all graph values and excel file
  bool isReady;
  Stream<List<int>> stream;
  Light _light = new Light();
  StreamSubscription _subscription;
  String _lux = 'Unknown';
  final double voc = 37.0;

  List<double> traceVoltage = List();
  List<double> traceCurrent =List();
  List<double> traceTemp = List();
  List<double> traceLight =List();
  List<double> scaledVoltage = List();
  List<double> scaledCurrent =List();
  bool reading=true;

  void onData(int luxValue) async {
    print("Lux value: $luxValue");
    setState(() {
      _lux = "$luxValue";
    });
  }

  void stopListening() {
    _subscription.cancel();
  }

  void startListening() {
    _light = new Light();
    try {
      _subscription = _light.lightSensorStream.listen(onData);
    }
    on LightException catch (exception) {
      print(exception);
    }
  }

  @override
  void initState() {
    debugPrint("init rns");
    super.initState();
    isReady = false;
    connectToDevice();
    getLight();
  }

  Future<void> getLight() async {
    startListening();
  }

  getCsv() async {//function created with help from https://icircuit.net/create-csv-file-flutter-app/2614
    //create an element rows of type list of list. All the above data set are stored in associate list
    //Let associate be a model class with attributes name,gender and age and associateList be a list of associate model class.

    List<List<dynamic>> rows = List<List<dynamic>>();
    for (int i = 0; i <associateList.length;i++) {

    //row refer to each column of a row in csv file and rows refer to each row in a file
      List<dynamic> row = List();
      row.add(associateList[i].voltage);
      row.add(associateList[i].current);
      row.add(associateList[i].temperatureK);
      row.add(associateList[i].irradianceL);
      row.add(associateList[i].scaledV);
      row.add(associateList[i].scaledI);
      rows.add(row);
    }


    bool checkPermission= true;
    if(checkPermission) {

    //store file in documents folder
      String dir = await ExtStorage.getExternalStoragePublicDirectory(ExtStorage.DIRECTORY_DOCUMENTS) ;
      if(File(dir+"/measurements.csv").existsSync()){
        final myData = await rootBundle.loadString(dir+"/measurements.csv");
        List<List<dynamic>> csvTable = CsvToListConverter().convert(myData);
        rows.addAll(csvTable);
      }
      File f = new File(dir+"/measurements.csv");

// convert rows to String and write as csv file
      String csv =  ListToCsvConverter().convert(rows);
      f.writeAsString(csv);
      associateList.removeRange(0, listSize);
      csvUpdating = false;
      print("saved"+dir);
    }

  }

  connectToDevice() async {
    if (widget.device == null) {
      _Pop();
      return;
    }

    new Timer(const Duration(seconds: 5), () {//changed from 15 to 5
      if (!isReady) {
        disconnectFromDevice();
        _Pop();
      }
    });

    await widget.device.connect();
    discoverServices();
  }
  disconnectFromDevice() {
    if (widget.device == null) {
      _Pop();
      return;
    }

    widget.device.disconnect();
  }

  discoverServices() async{
    if(widget.device == null){
      _Pop();
      return;
    }

    List<BluetoothService> services = await widget.device.discoverServices();
    services.forEach((service){
      if(service.uuid.toString()==SERVICE_UUID){
        service.characteristics.forEach((characteristic){
          if(characteristic.uuid.toString() == CHARACTERISTIC_UUID){
            characteristic.setNotifyValue(!characteristic.isNotifying);
            stream = characteristic.value;

            setState(() {
              isReady = true;
            });
          }
        });
      }
    });
    if(!isReady){
      _Pop();
    }
  }


  Future<bool> _onWillPop(){
    return showDialog(
        context: context,
        builder: (context)=>
        new AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you want to disconnect device and go back?'),
          actions: <Widget>[
            new FlatButton(onPressed: ()=> Navigator.of(context).pop(false), child: new Text("No")),
            new FlatButton(onPressed: (){disconnectFromDevice();Navigator.of(context).pop(true);}, child: new Text('Yes')),
          ],
        )??
            false);
  }

  _Pop(){
    Navigator.of(context).pop(true);
  }

  String _dataParser(List<int> dataFromDevice){
    return utf8.decode(dataFromDevice);
  }


  @override
  Widget build(BuildContext context) {


    return WillPopScope(
      onWillPop: _onWillPop,
      child:Scaffold(appBar: AppBar(title: Text("Measurements"),
      ),
        body: Container(child: !isReady ? Center(child:Text("Waiting...", style: TextStyle(fontSize: 24, color: Colors.blueAccent),),)
            :Container(child: StreamBuilder<List<int>>(
          stream: stream,
          builder: (BuildContext context,
              AsyncSnapshot<List<int>> snapshot){
            if(snapshot.hasError)
              return Text("Error: ${snapshot.error}");
            if(snapshot.connectionState == ConnectionState.active){
              var measValue = _dataParser(snapshot.data);
              var voltageValue = measValue.split(",")[0];
              var currentValue = measValue.split(",")[1];
              var tempValue = measValue.split(",")[2];
              double irradiance = double.parse((int.tryParse(_lux)/120).toStringAsFixed(2));
              var tempcell = double.tryParse(tempValue)+((45-20)/0.8)*(irradiance/1000);
              var stcvoltage=(double.tryParse(voltageValue))/(1-0.003*(tempcell-25));
              var stccurrent=((double.tryParse(currentValue)*1000/irradiance)*(1+0.006*(tempcell-25)));


              traceVoltage.add(double.tryParse(voltageValue) ?? 0);
              traceCurrent.add(double.tryParse(currentValue) ?? 0);
              traceTemp.add(double.tryParse(tempValue) ?? 0);
              traceLight.add(double.tryParse(irradiance.toStringAsFixed(2)) ?? 0);

              scaledCurrent.add(double.tryParse(stccurrent.toStringAsFixed(2)) ?? 0);
              scaledVoltage.add(double.tryParse(stcvoltage.toStringAsFixed(2)) ?? 0);


              if(associateList.length >= listSize && !csvUpdating){
                csvUpdating = true;
                getCsv();
                reading=false;
              }
              else {
                associateList.add(new DataModel(
                  double.tryParse(voltageValue) ?? 0,
                  double.tryParse(currentValue) ?? 0,
                  double.tryParse(tempValue) ?? 0,
                  double.tryParse(irradiance.toStringAsFixed(2)) ?? 0,
                  (double.tryParse(stcvoltage.toStringAsFixed(2)) ?? 0),
                  (double.tryParse(stccurrent.toStringAsFixed(2)) ?? 0),
                ));
              }

              String notification = 'Measuring Data';
              if(reading==false){
                notification ='Measurements Ready: Access Data from Internal Storage -> Documents -> measurements.csv';
              }

              return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(flex:1,child: Column(mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text("Live measurement", style: TextStyle(fontSize: 24)),
                            Text("Voltage: $voltageValue V", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                            Text("Current: $currentValue A", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                            Text("Light: $irradiance W/m^2", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                            Text("Temperature: $tempValue deg C", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
                            ]
                      ),
                      ),
                      Expanded(flex:1,
                          child: new ListView(
                              children : [
                                Text(notification, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 12)),
                                new GalleryScaffold(
                                  listTileIcon: new Icon(Icons.show_chart),
                                  title: 'Voltage Line Chart',
                                  subtitle: 'Voltage measurements',
                                  childBuilder: () => new VoltageLineChart.withSensorData(traceVoltage),
                                ).buildGalleryListTile(context),
                                new GalleryScaffold(
                                  listTileIcon: new Icon(Icons.show_chart),
                                  title: 'Current Line Chart',
                                  subtitle: 'Current measurements',
                                  childBuilder: () => new CurrentLineChart.withSensorData(traceCurrent),
                                ).buildGalleryListTile(context),
                                new GalleryScaffold(
                                  listTileIcon: new Icon(Icons.show_chart),
                                  title: 'IV Line Chart',
                                  subtitle: 'Current-Voltage measurements',
                                  childBuilder: () => new VCChart.withSensorData(traceVoltage,traceCurrent),
                                ).buildGalleryListTile(context),
                                new GalleryScaffold(
                                  listTileIcon: new Icon(Icons.show_chart),
                                  title: 'STC IV Line Chart',
                                  subtitle: 'Current-Voltage measurements scaled back to STC',
                                  childBuilder: () => new stc_iv.withSensorData(scaledVoltage,scaledCurrent),
                                ).buildGalleryListTile(context),
                                ]
                          )
                      ),
                    ],)
              );
            }else{
              return Text("Check the stream");
            }
          },
        ),
        )),
      ),
    );
  }
}


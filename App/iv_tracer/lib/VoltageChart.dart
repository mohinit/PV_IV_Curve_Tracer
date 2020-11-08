// Copyright 2018 the Charts project authors. Please see the AUTHORS file
// for details.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Example of a simple line chart.
// EXCLUDE_FROM_GALLERY_DOCS_START
import 'dart:math';
// EXCLUDE_FROM_GALLERY_DOCS_END
import 'package:charts_flutter/flutter.dart' as charts ;
import 'package:flutter/material.dart' ;

class VoltageLineChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  VoltageLineChart(this.seriesList, {this.animate});



  factory VoltageLineChart.withSensorData(List<double> voltageData) {
    return new VoltageLineChart(
        _createSensorData(voltageData)

    );
  }




  static List<charts.Series<LinearSales, num>> _createSensorData(List<double> voltageData) {

    List<LinearSales> data = new List<LinearSales>();
    int counter = 0;
    for(double vals in voltageData){
      data.add(new LinearSales(counter.toDouble(), vals));
      counter++;
    }
    return [
      new charts.Series<LinearSales, double>(
        id: 'Sales',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (LinearSales sales, _) => sales.year,
        measureFn: (LinearSales sales, _) => sales.sales,

        data: data,
      )
    ];
  }

  // EXCLUDE_FROM_GALLERY_DOCS_END

  @override
  Widget build(BuildContext context) {
    return new charts.LineChart(
      seriesList,
      animate: animate,
      behaviors: [
        new charts.ChartTitle('values',
            behaviorPosition: charts.BehaviorPosition.bottom,
            titleOutsideJustification:
            charts.OutsideJustification.middleDrawArea),
        new charts.ChartTitle('Voltage(v)',
            behaviorPosition: charts.BehaviorPosition.start,
            titleOutsideJustification:
            charts.OutsideJustification.middleDrawArea)
      ],
    );
  }

}

/// Sample linear data type.
class LinearSales {
  final double year;
  final double sales;

  LinearSales(this.year, this.sales);
}
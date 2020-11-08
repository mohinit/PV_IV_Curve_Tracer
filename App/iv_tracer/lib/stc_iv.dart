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

class stc_iv extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  stc_iv(this.seriesList, {this.animate});



  factory stc_iv.withSensorData(List<double> vData,List<double> cData) {
    return new stc_iv(
        _createSensorData(vData,cData)

    );
  }




  static List<charts.Series<LinearSales, num>> _createSensorData(List<double> voltageData,List<double> currentData) {

    List<LinearSales> data = new List<LinearSales>();
    int counter = 0;
    for(int i =0 ;i < voltageData.length ; i++){
      data.add(new LinearSales(voltageData[i], currentData[i]));
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

//    final simpleCurrencyFormatter =
//    new charts.BasicNumericTickFormatterSpec.);
    List<charts.TickSpec<num>> _createTickSpec() {
      List<charts.TickSpec<num>> _tickProvidSpecs = new List<charts.TickSpec<num>>();
      double d = 0;
      while (d <= 250) {
        _tickProvidSpecs.add(new charts.TickSpec(d,
            label: '$d%', style: charts.TextStyleSpec(fontSize: 14)));
        d += 0.1;
      }
    }
    return new charts.LineChart(
      seriesList,
      animate: animate,
      behaviors: [
        new charts.ChartTitle('Voltage(V)',
            behaviorPosition: charts.BehaviorPosition.bottom,
            titleOutsideJustification:
            charts.OutsideJustification.middleDrawArea),
        new charts.ChartTitle('Current(A)',
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
class DataModel {
  double voltage;
  double current;
  double temperatureK;
  double irradianceL;
  double scaledV;
  double scaledI;

  DataModel(double v , double i, double t, double l, double sv, double si){
    voltage = v ;
    current = i ;
    temperatureK=t;
    irradianceL=l;
    scaledV=sv;
    scaledI=si;

  }



}
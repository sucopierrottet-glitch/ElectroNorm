import '../models/conductor.dart';

class ConductorCatalog {
  ConductorCatalog._();

  static const List<String> standardAwgGauges = [
    '14 AWG',
    '12 AWG',
    '10 AWG',
    '8 AWG',
    '6 AWG',
    '4 AWG',
    '3 AWG',
    '2 AWG',
    '1 AWG',
    '1/0 AWG',
    '2/0 AWG',
    '3/0 AWG',
    '4/0 AWG',
    '250 kcmil',
    '300 kcmil',
    '350 kcmil',
    '400 kcmil',
    '500 kcmil',
  ];

  static const List<String> standardMetricGauges = [
    '1.5 mm²',
    '2.5 mm²',
    '4.0 mm²',
    '6.0 mm²',
    '10.0 mm²',
    '16.0 mm²',
    '25.0 mm²',
    '35.0 mm²',
    '50.0 mm²',
    '70.0 mm²',
    '95.0 mm²',
    '120.0 mm²',
    '150.0 mm²',
    '185.0 mm²',
    '240.0 mm²',
  ];

  // Helper dimensions by gauge and insulation
  static const Map<String, Map<ConductorInsulation, Map<String, double>>>
      _awgDimensions = {
    '14 AWG': {
      ConductorInsulation.thhn: {'od': 0.111, 'area': 0.0097, 'odMm': 2.82, 'areaMm': 6.26},
      ConductorInsulation.thwn: {'od': 0.111, 'area': 0.0097, 'odMm': 2.82, 'areaMm': 6.26},
      ConductorInsulation.xhhw: {'od': 0.133, 'area': 0.0139, 'odMm': 3.38, 'areaMm': 8.97},
      ConductorInsulation.use2: {'od': 0.163, 'area': 0.0209, 'odMm': 4.14, 'areaMm': 13.48},
    },
    '12 AWG': {
      ConductorInsulation.thhn: {'od': 0.130, 'area': 0.0133, 'odMm': 3.30, 'areaMm': 8.58},
      ConductorInsulation.thwn: {'od': 0.130, 'area': 0.0133, 'odMm': 3.30, 'areaMm': 8.58},
      ConductorInsulation.xhhw: {'od': 0.152, 'area': 0.0181, 'odMm': 3.86, 'areaMm': 11.68},
      ConductorInsulation.use2: {'od': 0.182, 'area': 0.0260, 'odMm': 4.62, 'areaMm': 16.77},
    },
    '10 AWG': {
      ConductorInsulation.thhn: {'od': 0.164, 'area': 0.0211, 'odMm': 4.17, 'areaMm': 13.61},
      ConductorInsulation.thwn: {'od': 0.164, 'area': 0.0211, 'odMm': 4.17, 'areaMm': 13.61},
      ConductorInsulation.xhhw: {'od': 0.176, 'area': 0.0243, 'odMm': 4.47, 'areaMm': 15.68},
      ConductorInsulation.use2: {'od': 0.206, 'area': 0.0333, 'odMm': 5.23, 'areaMm': 21.48},
    },
    '8 AWG': {
      ConductorInsulation.thhn: {'od': 0.216, 'area': 0.0366, 'odMm': 5.49, 'areaMm': 23.61},
      ConductorInsulation.thwn: {'od': 0.216, 'area': 0.0366, 'odMm': 5.49, 'areaMm': 23.61},
      ConductorInsulation.xhhw: {'od': 0.236, 'area': 0.0437, 'odMm': 5.99, 'areaMm': 28.19},
      ConductorInsulation.use2: {'od': 0.286, 'area': 0.0642, 'odMm': 7.26, 'areaMm': 41.42},
    },
    '6 AWG': {
      ConductorInsulation.thhn: {'od': 0.254, 'area': 0.0507, 'odMm': 6.45, 'areaMm': 32.71},
      ConductorInsulation.thwn: {'od': 0.254, 'area': 0.0507, 'odMm': 6.45, 'areaMm': 32.71},
      ConductorInsulation.xhhw: {'od': 0.274, 'area': 0.0590, 'odMm': 6.96, 'areaMm': 38.06},
      ConductorInsulation.use2: {'od': 0.324, 'area': 0.0824, 'odMm': 8.23, 'areaMm': 53.16},
    },
    '4 AWG': {
      ConductorInsulation.thhn: {'od': 0.324, 'area': 0.0824, 'odMm': 8.23, 'areaMm': 53.16},
      ConductorInsulation.thwn: {'od': 0.324, 'area': 0.0824, 'odMm': 8.23, 'areaMm': 53.16},
      ConductorInsulation.xhhw: {'od': 0.322, 'area': 0.0814, 'odMm': 8.18, 'areaMm': 52.52},
      ConductorInsulation.use2: {'od': 0.372, 'area': 0.1087, 'odMm': 9.45, 'areaMm': 70.13},
    },
    '3 AWG': {
      ConductorInsulation.thhn: {'od': 0.352, 'area': 0.0973, 'odMm': 8.94, 'areaMm': 62.77},
      ConductorInsulation.thwn: {'od': 0.352, 'area': 0.0973, 'odMm': 8.94, 'areaMm': 62.77},
      ConductorInsulation.xhhw: {'od': 0.350, 'area': 0.0962, 'odMm': 8.89, 'areaMm': 62.06},
      ConductorInsulation.use2: {'od': 0.400, 'area': 0.1257, 'odMm': 10.16, 'areaMm': 81.10},
    },
    '2 AWG': {
      ConductorInsulation.thhn: {'od': 0.384, 'area': 0.1158, 'odMm': 9.75, 'areaMm': 74.71},
      ConductorInsulation.thwn: {'od': 0.384, 'area': 0.1158, 'odMm': 9.75, 'areaMm': 74.71},
      ConductorInsulation.xhhw: {'od': 0.382, 'area': 0.1146, 'odMm': 9.70, 'areaMm': 73.94},
      ConductorInsulation.use2: {'od': 0.432, 'area': 0.1466, 'odMm': 10.97, 'areaMm': 94.58},
    },
    '1 AWG': {
      ConductorInsulation.thhn: {'od': 0.446, 'area': 0.1562, 'odMm': 11.33, 'areaMm': 100.77},
      ConductorInsulation.thwn: {'od': 0.446, 'area': 0.1562, 'odMm': 11.33, 'areaMm': 100.77},
      ConductorInsulation.xhhw: {'od': 0.442, 'area': 0.1534, 'odMm': 11.23, 'areaMm': 98.97},
      ConductorInsulation.use2: {'od': 0.512, 'area': 0.2059, 'odMm': 13.00, 'areaMm': 132.84},
    },
    '1/0 AWG': {
      ConductorInsulation.thhn: {'od': 0.486, 'area': 0.1855, 'odMm': 12.34, 'areaMm': 119.68},
      ConductorInsulation.thwn: {'od': 0.486, 'area': 0.1855, 'odMm': 12.34, 'areaMm': 119.68},
      ConductorInsulation.xhhw: {'od': 0.482, 'area': 0.1825, 'odMm': 12.24, 'areaMm': 117.74},
      ConductorInsulation.use2: {'od': 0.552, 'area': 0.2393, 'odMm': 14.02, 'areaMm': 154.39},
    },
    '2/0 AWG': {
      ConductorInsulation.thhn: {'od': 0.532, 'area': 0.2223, 'odMm': 13.51, 'areaMm': 143.42},
      ConductorInsulation.thwn: {'od': 0.532, 'area': 0.2223, 'odMm': 13.51, 'areaMm': 143.42},
      ConductorInsulation.xhhw: {'od': 0.528, 'area': 0.2190, 'odMm': 13.41, 'areaMm': 141.29},
      ConductorInsulation.use2: {'od': 0.598, 'area': 0.2809, 'odMm': 15.19, 'areaMm': 181.23},
    },
    '3/0 AWG': {
      ConductorInsulation.thhn: {'od': 0.584, 'area': 0.2679, 'odMm': 14.83, 'areaMm': 172.84},
      ConductorInsulation.thwn: {'od': 0.584, 'area': 0.2679, 'odMm': 14.83, 'areaMm': 172.84},
      ConductorInsulation.xhhw: {'od': 0.580, 'area': 0.2642, 'odMm': 14.73, 'areaMm': 170.45},
      ConductorInsulation.use2: {'od': 0.650, 'area': 0.3318, 'odMm': 16.51, 'areaMm': 214.06},
    },
    '4/0 AWG': {
      ConductorInsulation.thhn: {'od': 0.642, 'area': 0.3237, 'odMm': 16.31, 'areaMm': 208.84},
      ConductorInsulation.thwn: {'od': 0.642, 'area': 0.3237, 'odMm': 16.31, 'areaMm': 208.84},
      ConductorInsulation.xhhw: {'od': 0.638, 'area': 0.3197, 'odMm': 16.21, 'areaMm': 206.26},
      ConductorInsulation.use2: {'od': 0.708, 'area': 0.3937, 'odMm': 17.98, 'areaMm': 254.00},
    },
    '250 kcmil': {
      ConductorInsulation.thhn: {'od': 0.711, 'area': 0.3970, 'odMm': 18.06, 'areaMm': 256.13},
      ConductorInsulation.thwn: {'od': 0.711, 'area': 0.3970, 'odMm': 18.06, 'areaMm': 256.13},
      ConductorInsulation.xhhw: {'od': 0.707, 'area': 0.3926, 'odMm': 17.96, 'areaMm': 253.29},
      ConductorInsulation.use2: {'od': 0.787, 'area': 0.4865, 'odMm': 19.99, 'areaMm': 313.87},
    },
    '300 kcmil': {
      ConductorInsulation.thhn: {'od': 0.766, 'area': 0.4608, 'odMm': 19.46, 'areaMm': 297.29},
      ConductorInsulation.thwn: {'od': 0.766, 'area': 0.4608, 'odMm': 19.46, 'areaMm': 297.29},
      ConductorInsulation.xhhw: {'od': 0.762, 'area': 0.4560, 'odMm': 19.35, 'areaMm': 294.19},
      ConductorInsulation.use2: {'od': 0.842, 'area': 0.5568, 'odMm': 21.39, 'areaMm': 359.23},
    },
    '350 kcmil': {
      ConductorInsulation.thhn: {'od': 0.817, 'area': 0.5242, 'odMm': 20.75, 'areaMm': 338.19},
      ConductorInsulation.thwn: {'od': 0.817, 'area': 0.5242, 'odMm': 20.75, 'areaMm': 338.19},
      ConductorInsulation.xhhw: {'od': 0.813, 'area': 0.5191, 'odMm': 20.65, 'areaMm': 334.90},
      ConductorInsulation.use2: {'od': 0.893, 'area': 0.6263, 'odMm': 22.68, 'areaMm': 404.06},
    },
    '400 kcmil': {
      ConductorInsulation.thhn: {'od': 0.864, 'area': 0.5863, 'odMm': 21.95, 'areaMm': 378.26},
      ConductorInsulation.thwn: {'od': 0.864, 'area': 0.5863, 'odMm': 21.95, 'areaMm': 378.26},
      ConductorInsulation.xhhw: {'od': 0.860, 'area': 0.5809, 'odMm': 21.84, 'areaMm': 374.77},
      ConductorInsulation.use2: {'od': 0.940, 'area': 0.6940, 'odMm': 23.88, 'areaMm': 447.74},
    },
    '500 kcmil': {
      ConductorInsulation.thhn: {'od': 0.949, 'area': 0.7073, 'odMm': 24.10, 'areaMm': 456.32},
      ConductorInsulation.thwn: {'od': 0.949, 'area': 0.7073, 'odMm': 24.10, 'areaMm': 456.32},
      ConductorInsulation.xhhw: {'od': 0.945, 'area': 0.7014, 'odMm': 24.00, 'areaMm': 452.51},
      ConductorInsulation.use2: {'od': 1.025, 'area': 0.8252, 'odMm': 26.04, 'areaMm': 532.39},
    },
  };

  // Ampacity table (NEC Table 310.16)
  static const Map<String, Map<String, double>> _awgAmpacities = {
    '14 AWG': {'cu60': 15, 'cu75': 20, 'cu90': 25, 'al60': 0, 'al75': 0, 'al90': 0, 'ocpdCu': 15, 'ocpdAl': 0},
    '12 AWG': {'cu60': 20, 'cu75': 25, 'cu90': 30, 'al60': 15, 'al75': 20, 'al90': 25, 'ocpdCu': 20, 'ocpdAl': 15},
    '10 AWG': {'cu60': 30, 'cu75': 35, 'cu90': 40, 'al60': 25, 'al75': 30, 'al90': 35, 'ocpdCu': 30, 'ocpdAl': 25},
    '8 AWG': {'cu60': 40, 'cu75': 50, 'cu90': 55, 'al60': 35, 'al75': 40, 'al90': 45, 'ocpdCu': 0, 'ocpdAl': 0},
    '6 AWG': {'cu60': 55, 'cu75': 65, 'cu90': 75, 'al60': 40, 'al75': 50, 'al90': 60, 'ocpdCu': 0, 'ocpdAl': 0},
    '4 AWG': {'cu60': 70, 'cu75': 85, 'cu90': 95, 'al60': 55, 'al75': 65, 'al90': 75, 'ocpdCu': 0, 'ocpdAl': 0},
    '3 AWG': {'cu60': 85, 'cu75': 100, 'cu90': 115, 'al60': 65, 'al75': 75, 'al90': 85, 'ocpdCu': 0, 'ocpdAl': 0},
    '2 AWG': {'cu60': 95, 'cu75': 115, 'cu90': 130, 'al60': 75, 'al75': 90, 'al90': 100, 'ocpdCu': 0, 'ocpdAl': 0},
    '1 AWG': {'cu60': 110, 'cu75': 130, 'cu90': 145, 'al60': 85, 'al75': 100, 'al90': 115, 'ocpdCu': 0, 'ocpdAl': 0},
    '1/0 AWG': {'cu60': 125, 'cu75': 150, 'cu90': 170, 'al60': 100, 'al75': 120, 'al90': 135, 'ocpdCu': 0, 'ocpdAl': 0},
    '2/0 AWG': {'cu60': 145, 'cu75': 175, 'cu90': 195, 'al60': 115, 'al75': 135, 'al90': 150, 'ocpdCu': 0, 'ocpdAl': 0},
    '3/0 AWG': {'cu60': 165, 'cu75': 200, 'cu90': 225, 'al60': 130, 'al75': 155, 'al90': 175, 'ocpdCu': 0, 'ocpdAl': 0},
    '4/0 AWG': {'cu60': 195, 'cu75': 230, 'cu90': 260, 'al60': 150, 'al75': 180, 'al90': 205, 'ocpdCu': 0, 'ocpdAl': 0},
    '250 kcmil': {'cu60': 215, 'cu75': 255, 'cu90': 290, 'al60': 170, 'al75': 205, 'al90': 230, 'ocpdCu': 0, 'ocpdAl': 0},
    '300 kcmil': {'cu60': 240, 'cu75': 285, 'cu90': 320, 'al60': 195, 'al75': 230, 'al90': 260, 'ocpdCu': 0, 'ocpdAl': 0},
    '350 kcmil': {'cu60': 260, 'cu75': 310, 'cu90': 350, 'al60': 210, 'al75': 250, 'al90': 280, 'ocpdCu': 0, 'ocpdAl': 0},
    '400 kcmil': {'cu60': 280, 'cu75': 335, 'cu90': 380, 'al60': 225, 'al75': 270, 'al90': 305, 'ocpdCu': 0, 'ocpdAl': 0},
    '500 kcmil': {'cu60': 320, 'cu75': 380, 'cu90': 430, 'al60': 260, 'al75': 310, 'al90': 350, 'ocpdCu': 0, 'ocpdAl': 0},
  };

  // Electrical properties (Table 8 & Table 9)
  static const Map<String, Map<String, double>> _awgElectrical = {
    '14 AWG': {'cm': 4110, 'dcCu': 3.07, 'dcAl': 0.0, 'acCuSteel': 3.10, 'acCuPvc': 3.10, 'acAlSteel': 0.0, 'acAlPvc': 0.0, 'xl': 0.058},
    '12 AWG': {'cm': 6530, 'dcCu': 1.93, 'dcAl': 3.18, 'acCuSteel': 1.98, 'acCuPvc': 1.98, 'acAlSteel': 3.25, 'acAlPvc': 3.25, 'xl': 0.054},
    '10 AWG': {'cm': 10380, 'dcCu': 1.21, 'dcAl': 2.00, 'acCuSteel': 1.24, 'acCuPvc': 1.24, 'acAlSteel': 2.04, 'acAlPvc': 2.04, 'xl': 0.050},
    '8 AWG': {'cm': 16510, 'dcCu': 0.764, 'dcAl': 1.26, 'acCuSteel': 0.78, 'acCuPvc': 0.78, 'acAlSteel': 1.28, 'acAlPvc': 1.28, 'xl': 0.052},
    '6 AWG': {'cm': 26240, 'dcCu': 0.491, 'dcAl': 0.808, 'acCuSteel': 0.49, 'acCuPvc': 0.49, 'acAlSteel': 0.81, 'acAlPvc': 0.81, 'xl': 0.051},
    '4 AWG': {'cm': 41740, 'dcCu': 0.308, 'dcAl': 0.508, 'acCuSteel': 0.31, 'acCuPvc': 0.31, 'acAlSteel': 0.52, 'acAlPvc': 0.52, 'xl': 0.048},
    '3 AWG': {'cm': 52620, 'dcCu': 0.245, 'dcAl': 0.403, 'acCuSteel': 0.25, 'acCuPvc': 0.25, 'acAlSteel': 0.41, 'acAlPvc': 0.41, 'xl': 0.045},
    '2 AWG': {'cm': 66360, 'dcCu': 0.194, 'dcAl': 0.319, 'acCuSteel': 0.195, 'acCuPvc': 0.19, 'acAlSteel': 0.33, 'acAlPvc': 0.32, 'xl': 0.045},
    '1 AWG': {'cm': 83690, 'dcCu': 0.154, 'dcAl': 0.253, 'acCuSteel': 0.160, 'acCuPvc': 0.154, 'acAlSteel': 0.26, 'acAlPvc': 0.25, 'xl': 0.044},
    '1/0 AWG': {'cm': 105600, 'dcCu': 0.122, 'dcAl': 0.201, 'acCuSteel': 0.127, 'acCuPvc': 0.120, 'acAlSteel': 0.21, 'acAlPvc': 0.20, 'xl': 0.043},
    '2/0 AWG': {'cm': 133100, 'dcCu': 0.0967, 'dcAl': 0.159, 'acCuSteel': 0.101, 'acCuPvc': 0.095, 'acAlSteel': 0.17, 'acAlPvc': 0.16, 'xl': 0.042},
    '3/0 AWG': {'cm': 167800, 'dcCu': 0.0766, 'dcAl': 0.126, 'acCuSteel': 0.081, 'acCuPvc': 0.077, 'acAlSteel': 0.14, 'acAlPvc': 0.13, 'xl': 0.041},
    '4/0 AWG': {'cm': 211600, 'dcCu': 0.0608, 'dcAl': 0.100, 'acCuSteel': 0.067, 'acCuPvc': 0.062, 'acAlSteel': 0.11, 'acAlPvc': 0.10, 'xl': 0.040},
    '250 kcmil': {'cm': 250000, 'dcCu': 0.0515, 'dcAl': 0.0847, 'acCuSteel': 0.057, 'acCuPvc': 0.052, 'acAlSteel': 0.095, 'acAlPvc': 0.088, 'xl': 0.041},
    '300 kcmil': {'cm': 300000, 'dcCu': 0.0429, 'dcAl': 0.0707, 'acCuSteel': 0.049, 'acCuPvc': 0.044, 'acAlSteel': 0.081, 'acAlPvc': 0.074, 'xl': 0.041},
    '350 kcmil': {'cm': 350000, 'dcCu': 0.0367, 'dcAl': 0.0605, 'acCuSteel': 0.043, 'acCuPvc': 0.038, 'acAlSteel': 0.066, 'acAlPvc': 0.061, 'xl': 0.040},
    '400 kcmil': {'cm': 400000, 'dcCu': 0.0321, 'dcAl': 0.0529, 'acCuSteel': 0.038, 'acCuPvc': 0.033, 'acAlSteel': 0.060, 'acAlPvc': 0.055, 'xl': 0.040},
    '500 kcmil': {'cm': 500000, 'dcCu': 0.0258, 'dcAl': 0.0424, 'acCuSteel': 0.032, 'acCuPvc': 0.027, 'acAlSteel': 0.050, 'acAlPvc': 0.044, 'xl': 0.039},
  };

  // Metric catalog data (IEC 60228 / REBT ITC-BT-19)
  static const Map<String, Map<String, dynamic>> _metricData = {
    '1.5 mm²': {'odMm': 2.90, 'areaMm': 1.50, 'r20': 12.10, 'r75': 14.71, 'amp70': 14.5, 'amp90': 18.5, 'nearestAwg': '16 AWG'},
    '2.5 mm²': {'odMm': 3.50, 'areaMm': 2.50, 'r20': 7.41, 'r75': 9.01, 'amp70': 19.5, 'amp90': 25.0, 'nearestAwg': '14 AWG'},
    '4.0 mm²': {'odMm': 4.10, 'areaMm': 4.00, 'r20': 4.61, 'r75': 5.61, 'amp70': 26.0, 'amp90': 34.0, 'nearestAwg': '12 AWG'},
    '6.0 mm²': {'odMm': 4.70, 'areaMm': 6.00, 'r20': 3.08, 'r75': 3.74, 'amp70': 34.0, 'amp90': 43.0, 'nearestAwg': '10 AWG'},
    '10.0 mm²': {'odMm': 6.00, 'areaMm': 10.00, 'r20': 1.83, 'r75': 2.23, 'amp70': 46.0, 'amp90': 60.0, 'nearestAwg': '8 AWG'},
    '16.0 mm²': {'odMm': 7.10, 'areaMm': 16.00, 'r20': 1.15, 'r75': 1.40, 'amp70': 61.0, 'amp90': 80.0, 'nearestAwg': '6 AWG'},
    '25.0 mm²': {'odMm': 8.80, 'areaMm': 25.00, 'r20': 0.727, 'r75': 0.884, 'amp70': 80.0, 'amp90': 101.0, 'nearestAwg': '4 AWG'},
    '35.0 mm²': {'odMm': 10.00, 'areaMm': 35.00, 'r20': 0.524, 'r75': 0.637, 'amp70': 99.0, 'amp90': 126.0, 'nearestAwg': '2 AWG'},
    '50.0 mm²': {'odMm': 11.90, 'areaMm': 50.00, 'r20': 0.387, 'r75': 0.470, 'amp70': 119.0, 'amp90': 153.0, 'nearestAwg': '1/0 AWG'},
    '70.0 mm²': {'odMm': 13.90, 'areaMm': 70.00, 'r20': 0.268, 'r75': 0.326, 'amp70': 151.0, 'amp90': 196.0, 'nearestAwg': '2/0 AWG'},
    '95.0 mm²': {'odMm': 16.00, 'areaMm': 95.00, 'r20': 0.193, 'r75': 0.235, 'amp70': 182.0, 'amp90': 238.0, 'nearestAwg': '3/0 AWG'},
    '120.0 mm²': {'odMm': 17.80, 'areaMm': 120.00, 'r20': 0.153, 'r75': 0.186, 'amp70': 210.0, 'amp90': 276.0, 'nearestAwg': '4/0 AWG'},
    '150.0 mm²': {'odMm': 20.00, 'areaMm': 150.00, 'r20': 0.124, 'r75': 0.151, 'amp70': 240.0, 'amp90': 316.0, 'nearestAwg': '300 kcmil'},
    '185.0 mm²': {'odMm': 22.20, 'areaMm': 185.00, 'r20': 0.0991, 'r75': 0.120, 'amp70': 273.0, 'amp90': 362.0, 'nearestAwg': '350 kcmil'},
    '240.0 mm²': {'odMm': 25.40, 'areaMm': 240.00, 'r20': 0.0754, 'r75': 0.0916, 'amp70': 321.0, 'amp90': 424.0, 'nearestAwg': '500 kcmil'},
  };

  /// Find a conductor spec for standard AWG/kcmil or metric
  static ConductorSpec? findSpec({
    required String gauge,
    ConductorInsulation insulation = ConductorInsulation.thhn,
    ConductorMaterial material = ConductorMaterial.copper,
  }) {
    // Check AWG/kcmil
    if (_awgDimensions.containsKey(gauge)) {
      final dimMap = _awgDimensions[gauge]?[insulation];
      if (dimMap == null) return null;

      final ampMap = _awgAmpacities[gauge] ?? {};
      final elecMap = _awgElectrical[gauge] ?? {};

      final isCu = material == ConductorMaterial.copper;
      final amp60 = isCu ? (ampMap['cu60'] ?? 0.0) : (ampMap['al60'] ?? 0.0);
      final amp75 = isCu ? (ampMap['cu75'] ?? 0.0) : (ampMap['al75'] ?? 0.0);
      final amp90 = isCu ? (ampMap['cu90'] ?? 0.0) : (ampMap['al90'] ?? 0.0);
      final ocpd = isCu ? ampMap['ocpdCu']?.toInt() : ampMap['ocpdAl']?.toInt();
      final finalOcpd = (ocpd != null && ocpd > 0) ? ocpd : null;

      final acSteel = isCu ? (elecMap['acCuSteel'] ?? 0.0) : (elecMap['acAlSteel'] ?? 0.0);
      final acPvc = isCu ? (elecMap['acCuPvc'] ?? 0.0) : (elecMap['acAlPvc'] ?? 0.0);

      return ConductorSpec(
        gauge: gauge,
        insulation: insulation,
        material: material,
        outerDiameterInches: dimMap['od']!,
        outerDiameterMm: dimMap['odMm']!,
        areaSqInches: dimMap['area']!,
        areaSqMm: dimMap['areaMm']!,
        ampacity60C: amp60,
        ampacity75C: amp75,
        ampacity90C: amp90,
        maxOcpdAmps: finalOcpd,
        circularMils: elecMap['cm'] ?? 0.0,
        dcResistanceCu75C: elecMap['dcCu'] ?? 0.0,
        dcResistanceAl75C: elecMap['dcAl'] ?? 0.0,
        acResistanceSteel: acSteel,
        acResistancePvc: acPvc,
        reactanceXl: elecMap['xl'] ?? 0.0,
      );
    }

    // Check Metric
    if (_metricData.containsKey(gauge)) {
      final m = _metricData[gauge]!;
      final odMm = (m['odMm'] as num).toDouble();
      final areaMm = (m['areaMm'] as num).toDouble();
      final odIn = odMm / 25.4;
      final areaIn = areaMm / 645.16;

      final amp70 = (m['amp70'] as num).toDouble();
      final amp90 = (m['amp90'] as num).toDouble();

      return ConductorSpec(
        gauge: gauge,
        insulation: insulation,
        material: material,
        outerDiameterInches: odIn,
        outerDiameterMm: odMm,
        areaSqInches: areaIn,
        areaSqMm: areaMm,
        ampacity60C: amp70,
        ampacity75C: amp70,
        ampacity90C: amp90,
        maxOcpdAmps: null,
        circularMils: areaMm * 1973.525,
        dcResistanceCu75C: (m['r75'] as num).toDouble() * 0.3048, // convert ohm/km to ohm/kft
        dcResistanceAl75C: 0.0,
        acResistanceSteel: (m['r75'] as num).toDouble() * 0.3048,
        acResistancePvc: (m['r75'] as num).toDouble() * 0.3048,
        reactanceXl: 0.045,
      );
    }

    return null;
  }

  /// Get conductor spec, throwing ArgumentError if not found
  static ConductorSpec getSpec({
    required String gauge,
    ConductorInsulation insulation = ConductorInsulation.thhn,
    ConductorMaterial material = ConductorMaterial.copper,
  }) {
    final spec = findSpec(gauge: gauge, insulation: insulation, material: material);
    if (spec == null) {
      throw ArgumentError('Conductor specification not found for gauge: $gauge, insulation: ${insulation.name}, material: ${material.name}');
    }
    return spec;
  }
}

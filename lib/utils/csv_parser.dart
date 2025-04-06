import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<List<EBTRetailer>> loadRetailers() async {
  final data = await rootBundle.loadString('assets/ebt_stores.csv');
  final csvTable = const CsvToListConverter().convert(data, eol: '\n');

  // Expected CSV columns:
  // 0: Record ID
  // 1: Store Name
  // 2: Store Type
  // 3: Street Number
  // 4: Street Name
  // 5: Additional Address
  // 6: City
  // 7: State
  // 8: Zip Code
  // 9: Zip4
  // 10: County
  // 11: Latitude
  // 12: Longitude
  // 13: Authorization Date
  // 14: End Date

  final List<EBTRetailer> retailers = [];
  for (int i = 1; i < csvTable.length; i++) {
    final row = csvTable[i];

    // Filter out inactive stores: if End Date is not empty, skip this row
    if (row[14] != null && row[14].toString().trim().isNotEmpty) {
      continue;
    }

    final recordId = row[0].toString();
    final name = row[1].toString();
    final storeType = row[2].toString();
    final streetNumber = row[3].toString();
    final streetName = row[4].toString();
    final additionalAddress = row[5].toString();
    final city = row[6].toString();
    final state = row[7].toString();
    final zipCode = row[8].toString();
    final zip4 = row[9].toString();
    final county = row[10].toString();
    final lat = double.tryParse(row[11].toString());
    final lng = double.tryParse(row[12].toString());
    final authorizationDate = row[13].toString();

    if (lat != null && lng != null) {
      retailers.add(EBTRetailer(
        recordId: recordId,
        name: name,
        storeType: storeType,
        streetNumber: streetNumber,
        streetName: streetName,
        additionalAddress: additionalAddress,
        city: city,
        state: state,
        zipCode: zipCode,
        zip4: zip4,
        county: county,
        lat: lat,
        lng: lng,
        authorizationDate: authorizationDate,
      ));
    }
  }
  return retailers;
}

class EBTRetailer {
  final String recordId;
  final String name;
  final String storeType;
  final String streetNumber;
  final String streetName;
  final String additionalAddress;
  final String city;
  final String state;
  final String zipCode;
  final String zip4;
  final String county;
  final double lat;
  final double lng;
  final String authorizationDate;

  EBTRetailer({
    required this.recordId,
    required this.name,
    required this.storeType,
    required this.streetNumber,
    required this.streetName,
    required this.additionalAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.zip4,
    required this.county,
    required this.lat,
    required this.lng,
    required this.authorizationDate,
  });
}
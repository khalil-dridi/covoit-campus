import 'package:flutter_test/flutter_test.dart';
import 'package:covoit_campus/screens/driver/publish/location_picker_screen.dart';

void main() {
  test('OSM tile layer identifies Covoit Campus explicitly', () async {
    final layer = buildCovoitCampusTileLayer();

    expect(layer.urlTemplate, 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');
    expect(
      layer.tileProvider.headers['User-Agent'],
      'CovoitCampus/1.0.0 (com.khalildridi.covoitcampus)',
    );
  });
}

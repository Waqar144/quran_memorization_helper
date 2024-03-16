import 'package:flutter_test/flutter_test.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';

void main() {
  // rhs is para idx so actual is +1
  test("test para for ayah", () {
    expect(paraForAyah(1040), 7);
    expect(paraForAyah(1041), 8);
    expect(paraForAyah(1042), 8);
    expect(paraForAyah(6235), 29);
    // ignore: avoid_print
    print("test para for ayah OK");
  });
}

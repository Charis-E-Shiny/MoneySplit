import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vasool/services/optimizer.dart';

void main() {
  test('optimizer picks gift card + UPI for an 8000 travel booking', () {
    final o = Optimizer.compare(amount: 8000, category: 'Travel');
    expect(o.first.id, 'gift');
    expect(o.first.savings, 480);
    expect(o.first.effective, 7520);
  });
}

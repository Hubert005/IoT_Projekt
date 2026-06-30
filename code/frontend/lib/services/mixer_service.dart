import '../models/drink.dart';

abstract class MixerService {
  Future<void> orderDrink(Drink drink);
}

class MockMixerService implements MixerService {
  @override
  Future<void> orderDrink(Drink drink) async {
    await Future.delayed(const Duration(seconds: 2));
    // ignore: avoid_print
    print('[MockMixerService] Order sent: ${drink.id}');
  }
}

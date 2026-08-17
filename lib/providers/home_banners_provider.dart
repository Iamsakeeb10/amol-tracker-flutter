import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/home_banners_config_model.dart';
import 'auth_provider.dart';

final homeBannersConfigProvider = StreamProvider<HomeBannersConfigModel>((ref) {
  return ref.read(firestoreServiceProvider).homeBannersConfigStream();
});

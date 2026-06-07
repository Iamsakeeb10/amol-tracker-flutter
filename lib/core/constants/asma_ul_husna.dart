import '../../models/husna_name_model.dart';
import 'asma_ul_husna_part1.dart';
import 'asma_ul_husna_part2.dart';

/// All 99 Names of Allah (Asma ul Husna).
const List<HusnaName> kAsmaUlHusna = <HusnaName>[
  ...kAsmaUlHusnaPart1,
  ...kAsmaUlHusnaPart2,
];

const int kHusnaTotalCount = 99;

HusnaName? husnaNameByNumber(int number) {
  if (number < 1 || number > kHusnaTotalCount) return null;
  return kAsmaUlHusna[number - 1];
}

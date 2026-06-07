import '../../l10n/app_localizations.dart';
import '../constants/hijri_events.dart';

class HijriEventLabels {
  HijriEventLabels._();

  static String label(AppLocalizations l10n, HijriEventId id) {
    switch (id) {
      case HijriEventId.islamicNewYear:
        return l10n.eventIslamicNewYear;
      case HijriEventId.ashura:
        return l10n.eventAshura;
      case HijriEventId.mawlid:
        return l10n.eventMawlid;
      case HijriEventId.israMiraj:
        return l10n.eventIsraMiraj;
      case HijriEventId.shabeBarat:
        return l10n.eventShabeBarat;
      case HijriEventId.ramadanStart:
        return l10n.eventRamadanStart;
      case HijriEventId.laylatAlQadr:
        return l10n.eventLaylatAlQadr;
      case HijriEventId.eidAlFitr:
        return l10n.eventEidAlFitr;
      case HijriEventId.arafat:
        return l10n.eventArafat;
      case HijriEventId.eidAlAdha:
        return l10n.eventEidAlAdha;
    }
  }
}

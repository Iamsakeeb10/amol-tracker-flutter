13:45
Claude responded: Here's the fully updated guide with imageUrl added throughout:
Here's the fully updated guide with imageUrl added throughout:

Firestore Structure
announcements/{announcementId}
title: string # "বৃহস্পতিবার রাতের আমল"
message: string # "আজ রাতে বেশি বেশি দরুদ পড়ুন..."
arabicText: string # optional
imageUrl: string # optional — any public image URL, or omit entirely
type: string # 'reminder' | 'announcement' | 'dua' | 'hadith'
isActive: bool
startsAt: timestamp
expiresAt: timestamp
showOnce: bool
adminUid: string
createdAt: timestamp

How you control it as admin
Action
What you do
Show modal to all users
Create document, set isActive: true
Hide it immediately
Set isActive: false
Auto-expire
Set expiresAt timestamp
Show only once per user
Set showOnce: true
Show an image
Set imageUrl to any public direct image URL
No image
Leave imageUrl out of the document entirely
Thursday night Durood
Set startsAt to Thursday 8 PM, expiresAt to Friday 6 AM

Full Implementation Prompt for Cursor
Implement an admin announcement modal system for Amol Tracker.

BEFORE WRITING ANY CODE, read these files:
lib/core/services/firestore_service.dart
lib/core/services/islamic_date_service.dart
lib/models/user_model.dart
lib/providers/auth_provider.dart
lib/features/home/presentation/screens/home_screen.dart
lib/core/theme/colors.dart
lib/core/router/router.dart

STEP 1 — Create AnnouncementModel
Create: lib/models/announcement_model.dart
dart
class AnnouncementModel {
final String id;
final String title;
final String message;
final String? arabicText; // optional Arabic text shown above message
final String? imageUrl; // optional image shown below arabicText
final String type; // 'reminder' | 'announcement' | 'dua' | 'hadith'
final bool isActive;
final DateTime? startsAt; // null = show immediately
final DateTime? expiresAt; // null = never expires
final bool showOnce;
final DateTime createdAt;

bool get isCurrentlyActive {
if (!isActive) return false;
final now = DateTime.now();
if (startsAt != null && now.isBefore(startsAt!)) return false;
if (expiresAt != null && now.isAfter(expiresAt!)) return false;
return true;
}

factory AnnouncementModel.fromDoc(DocumentSnapshot doc) {
final data = doc.data() as Map<String, dynamic>;
return AnnouncementModel(
id: doc.id,
title: data['title'] ?? '',
message: data['message'] ?? '',
arabicText: data['arabicText'] as String?,
imageUrl: data['imageUrl'] as String?, // null if not set
type: data['type'] ?? 'announcement',
isActive: data['isActive'] ?? false,
startsAt: (data['startsAt'] as Timestamp?)?.toDate(),
expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
showOnce: data['showOnce'] ?? false,
createdAt: (data['createdAt'] as Timestamp).toDate(),
);
}
}

STEP 2 — Add Firestore methods to FirestoreService
In lib/core/services/firestore_service.dart, add:
dart
Stream<List<AnnouncementModel>> announcementsStream() {
return \_firestore
.collection('announcements')
.where('isActive', isEqualTo: true)
.orderBy('createdAt', descending: true)
.snapshots()
.map((snap) => snap.docs
.map(AnnouncementModel.fromDoc)
.where((a) => a.isCurrentlyActive)
.toList());
}

Future<void> markAnnouncementSeen(String uid, String announcementId) async {
await \_firestore.collection('users').doc(uid).update({
'seenAnnouncements': FieldValue.arrayUnion([announcementId]),
});
}

STEP 3 — Create AnnouncementProvider
Create: lib/providers/announcement_provider.dart
dart
final announcementsProvider = StreamProvider<List<AnnouncementModel>>((ref) {
final firestoreService = ref.read(firestoreServiceProvider);
return firestoreService.announcementsStream();
});

final pendingAnnouncementProvider = Provider<AnnouncementModel?>((ref) {
final announcements = ref.watch(announcementsProvider).value ?? [];
final user = ref.watch(currentUserProvider).value;
if (user == null || announcements.isEmpty) return null;

final seen = user.seenAnnouncements ?? [];

return announcements.firstWhere(
(a) => !a.showOnce || !seen.contains(a.id),
orElse: () => null,
);
});

STEP 4 — Create the modal widget
Create: lib/shared/widgets/announcement_modal.dart
Design requirements:
Background: AppColors.emeraldDeep (#0D3D2E)
Border: 1px solid rgba(201,168,76,0.4) — gold border
Border radius: 20px
Close X button top-right
Type-based icon at top:
'dua' → Icons.volunteer_activism
'reminder' → Icons.notifications_outlined
'announcement' → Icons.campaign_outlined
'hadith' → Icons.menu_book_outlined
If arabicText is not null/empty → show centered, 20sp, Amiri font, AppColors.goldLight
If imageUrl is not null/empty → show image below arabicText, before title
Title: NotoSansBengali, 16sp, bold, white
Message: NotoSansBengali, 13sp, white70, height 1.6
Bottom: single gold "বুঝেছি" button
dart
class AnnouncementModal extends ConsumerWidget {
final AnnouncementModel announcement;
const AnnouncementModal({super.key, required this.announcement});

@override
Widget build(BuildContext context, WidgetRef ref) {
final hasArabic = announcement.arabicText != null &&
announcement.arabicText!.isNotEmpty;
final hasImage = announcement.imageUrl != null &&
announcement.imageUrl!.isNotEmpty;

    void dismiss() {
      Navigator.pop(context);
      if (announcement.showOnce) {
        final uid = ref.read(currentUserProvider).value?.uid;
        if (uid != null) {
          ref.read(firestoreServiceProvider)
              .markAnnouncementSeen(uid, announcement.id);
        }
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.emeraldDeep,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.goldLight.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button row
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: dismiss,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  // Type icon
                  Icon(_iconForType(announcement.type),
                      color: AppColors.goldLight, size: 32),
                  const SizedBox(height: 12),

                  // Arabic text (optional)
                  if (hasArabic) ...[
                    Text(
                      announcement.arabicText!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        color: AppColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Image (optional)
                  if (hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        announcement.imageUrl!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 180,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                                color: AppColors.goldLight),
                          );
                        },
                        errorBuilder: (context, error, stack) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Title
                  Text(
                    announcement.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Message
                  Text(
                    announcement.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: dismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldLight,
                        foregroundColor: AppColors.emeraldDeep,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'বুঝেছি',
                        style: GoogleFonts.notoSansBengali(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

}

IconData \_iconForType(String type) {
switch (type) {
case 'dua': return Icons.volunteer_activism;
case 'reminder': return Icons.notifications_outlined;
case 'hadith': return Icons.menu_book_outlined;
case 'announcement':
default: return Icons.campaign_outlined;
}
}
}

STEP 5 — Show modal on HomeScreen
dart
ref.listen<AnnouncementModel?>(pendingAnnouncementProvider, (prev, next) {
if (next == null) return;
if (prev?.id == next.id) return;

Future.delayed(const Duration(milliseconds: 800), () {
if (!mounted) return;
showDialog(
context: context,
barrierDismissible: true,
barrierColor: Colors.black54,
builder: (\_) => AnnouncementModal(announcement: next),
);
});
});

STEP 6 — Update UserModel
dart
// Add field
final List<String> seenAnnouncements; // default []

// In fromDoc()
seenAnnouncements: List<String>.from(data['seenAnnouncements'] ?? []),

// In toFirestoreMap() — do NOT include seenAnnouncements

STEP 7 — Firestore Security Rule
match /announcements/{id} {
allow read: if request.auth != null;
allow write: if request.auth != null
&& request.auth.uid == 'YOUR_ADMIN_UID_HERE';
}

WHAT NOT TO DO
Do NOT show the modal on every screen — home screen only
Do NOT block the UI — modal is dismissible
Do NOT crash if announcements collection doesn't exist yet
Do NOT show expired announcements even if isActive is true
Do NOT call markAnnouncementSeen if showOnce is false
Do NOT crash if imageUrl is a broken link — errorBuilder handles it silently

TESTING CHECKLIST
isActive: true → modal appears on home screen
isActive: false → modal disappears immediately
expiresAt in the past → modal not shown
showOnce: true, dismiss → does not show again
showOnce: false, dismiss → shows again next open
startsAt in the future → modal not shown yet
arabicText filled → gold Arabic text shown above image
arabicText empty/null → no Arabic section
imageUrl filled → image shown between arabicText and title
imageUrl empty/null → no image section, layout unchanged
imageUrl is a broken URL → image silently hidden, rest of modal fine
Two active announcements → first shown, second on next open
No documents → no modal, home screen normal

Thursday night Durood example (with image)
title: "বৃহস্পতিবার রাতের আমল"
arabicText: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّد"
imageUrl: "https://images.unsplash.com/photo-xxxxxx?w=800&q=80" ← optional
message: "আজ বৃহস্পতিবার রাত। এই রাতে বেশি বেশি দরুদ পড়ুন।..."
type: "reminder"
isActive: true
showOnce: false
startsAt: [Thursday 8:00 PM timestamp]
expiresAt: [Friday 6:00 AM timestamp]
createdAt: [now]
Leave imageUrl out entirely if you don't want an image — the modal layout adjusts automatically.

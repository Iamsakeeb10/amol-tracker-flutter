# Amal Fields — Firestore Admin Guide

This app loads daily amal (habit) fields from Firestore. There is **no admin screen in the app** — you manage fields in the [Firebase Console](https://console.firebase.google.com).

---

## Collection

| Item | Value |
|------|--------|
| **Collection ID** | `amal_fields` |
| **Document ID** | Same as field `id` (e.g. `fard`, `morning_azkar`) |
| **Query used by app** | `isActive == true`, sorted by `order` ascending |

Users see fields on the next app open (or after pull-to-refresh / retry on Home). The app caches fields locally for offline use.

---

## Document fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique key; must match document ID. Used in daily logs (`amal_logs`). |
| `label` | map | Yes | `en` and `bn` display titles. |
| `sublabel` | map | Yes | `en` and `bn` short descriptions under the title. |
| `points` | number | Yes | Points when fully done (boolean) or at max value (numeric). |
| `order` | number | Yes | Sort order in UI (1 = first). Lower numbers appear first. |
| `isActive` | boolean | Yes | `true` = shown in app. `false` = hidden (soft delete). |
| `type` | string | No | `"boolean"` (default) or `"numeric"`. |
| `maxValue` | number | For numeric | Max count (e.g. `5` for five prayers). Default `1` if omitted. |
| `createdAt` | timestamp | No | Optional metadata for your records. |

### Label / sublabel format

In Firebase Console, add **map** fields:

**`label`**

| Key | Example |
|-----|---------|
| `en` | `Morning Azkar` |
| `bn` | `সকালের আযকার` |

**`sublabel`**

| Key | Example |
|-----|---------|
| `en` | `Morning azkar completed` |
| `bn` | `সকালের আযকার সম্পন্ন` |

If `bn` is empty, the app falls back to `en`.

---

## Field types

### Boolean (default)

- User sees an on/off switch.
- Full `points` when toggled on.
- Omit `type` or set `type` to `"boolean"`.

### Numeric (e.g. Fard, Takbir)

- User picks `0` … `maxValue` (e.g. 0–5).
- Score for that field = `(value / maxValue) * points` (rounded).
- Set `type` to `"numeric"` and `maxValue` to `5` (or your max).

---

## How to add a new amal field

1. Open **Firebase Console** → your project → **Firestore Database**.
2. Open collection **`amal_fields`** (create it if missing).
3. Click **Add document**.
4. Set **Document ID** to a stable slug, e.g. `tahajjud` (lowercase, underscores, no spaces).
5. Add fields:

```text
id          (string)    tahajjud
isActive    (boolean)   true
order       (number)    10
points      (number)    10
type        (string)    boolean
label       (map)       en → "Tahajjud"
                        bn → "তাহাজ্জুদ"
sublabel    (map)       en → "Prayed tahajjud"
                        bn → "তাহাজ্জুদ আদায়"
createdAt   (timestamp) (optional) now
```

6. For a **numeric** field, also set:

```text
type        (string)    numeric
maxValue    (number)    5
```

7. Save.

8. **Composite index** (first time only): If the console shows a link to create an index for  
   `amal_fields` where `isActive` + `orderBy order`, create it.

9. Ask users to **restart the app** or use **Retry** on Home if fields do not appear (cache refreshes on successful fetch).

### Example: new boolean field (JSON import)

If you use Firebase CLI or import JSON:

```json
{
  "id": "tahajjud",
  "label": {
    "en": "Tahajjud",
    "bn": "তাহাজ্জুদ"
  },
  "sublabel": {
    "en": "Tahajjud prayer",
    "bn": "তাহাজ্জুদ নামাজ"
  },
  "points": 10,
  "order": 10,
  "isActive": true,
  "type": "boolean"
}
```

---

## How to remove / hide an amal field

**Recommended: soft delete (do not delete the document)**

1. Open the document in `amal_fields`.
2. Set **`isActive`** to **`false`**.
3. Save.

The field disappears from the app on the next fetch. Old `amal_logs` may still contain that key; the app ignores keys that are not in the active list.

**Hard delete (permanent)**

1. Delete the document in `amal_fields`.
2. Historical logs still keep old keys; they are simply not shown for current active fields.

Prefer **`isActive: false`** so you can turn a field back on later without losing config.

---

## How to edit an existing field

1. Open the document in `amal_fields`.
2. Change `label`, `sublabel`, `points`, `order`, `type`, or `maxValue` as needed.
3. Keep **`id`** and the **document ID** in sync.
4. Save.

**Important:** Changing `id` or document ID breaks matching with old logs. If you must rename, treat it as a new field and deactivate the old one.

---

## Reordering fields

Change **`order`** on each document (1, 2, 3, …). The app sorts by `order` ascending. If two fields share the same `order`, they are sorted by `id` alphabetically.

---

## Scoring and max daily score

- **Max score** = sum of `points` for all **active** fields (not fixed at 100).
- **Displayed score** is clamped to **0–100** in the UI.
- If total points exceed 100 (misconfiguration), the bar still caps at 100 but the raw score can be higher in details.

When adding fields, check that active `points` sum to what you expect (the original app used **100** total).

---

## Default bundled fields (offline fallback)

If Firestore is empty or unreachable and there is no cache, the app uses built-in defaults (same 9 fields as the original app: `fard`, `takbir`, `morning_azkar`, etc.). Once Firestore has documents, **Firestore wins** over defaults.

---

## Checklist after changes

- [ ] Document ID matches `id` field
- [ ] `isActive` is `true` for fields you want visible
- [ ] `order` is set for correct list position
- [ ] Both `label.en`, `label.bn`, `sublabel.en`, `sublabel.bn` are filled
- [ ] Numeric fields have `type: "numeric"` and `maxValue`
- [ ] Firestore composite index exists (`isActive` + `order`)
- [ ] Test on a device: open app or tap Retry on Home

---

## Current default fields (reference)

| order | id | type | points | maxValue |
|------:|-----|------|-------:|---------:|
| 1 | fard | numeric | 30 | 5 |
| 2 | takbir | numeric | 10 | 5 |
| 3 | morning_azkar | boolean | 10 | — |
| 4 | evening_azkar | boolean | 10 | — |
| 5 | quran | boolean | 10 | — |
| 6 | mulk | boolean | 10 | — |
| 7 | miswak | boolean | 5 | — |
| 8 | sunnah | boolean | 10 | — |
| 9 | post_azkar | boolean | 5 | — |

**Total points: 100**

---

## Troubleshooting

| Problem | What to check |
|---------|----------------|
| New field not showing | `isActive == true`, valid `order`, document ID = `id`, restart app or Retry on Home |
| Field still showing after “delete” | You may have only set `isActive: false` on a copy; confirm the correct document |
| Query failed / index error | Create composite index on `amal_fields`: `isActive` Asc, `order` Asc |
| Wrong language | Fill `bn` keys; app uses device locale (`en` or `bn`) |
| Numeric field acts like toggle | Set `type` to `"numeric"` and `maxValue` |
| Score looks wrong | Check `points` and `maxValue`; numeric score is proportional |

---

## Security note

Configure Firestore rules so only **admins** can write to `amal_fields`. All signed-in users should only **read** active fields. Example pattern (adjust to your rules):

```javascript
match /amal_fields/{fieldId} {
  allow read: if request.auth != null;
  allow write: if false; // manage via Console or Admin SDK only
}
```

Use Firebase Console or Admin SDK for writes unless you add a trusted admin role later.

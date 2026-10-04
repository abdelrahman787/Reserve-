# Push notifications (Firebase Cloud Messaging)

The app integration is already built and **guarded**: if Firebase is not
configured, notifications are silently disabled and the app runs normally.
To turn them on you need your own Firebase project.

## How it works

1. On launch, `NotificationService.init()` initializes Firebase and asks for
   notification permission (`lib/core/services/notification_service.dart`).
2. After login, `HomeShell` calls `registerToken()`, which saves the device's
   FCM token to the `device_tokens` table (one row per device, RLS-scoped to
   the user).
3. To send, call the `send-notification` Edge Function with a `user_id`; it
   looks up that user's tokens and pushes via FCM HTTP v1.

## Client setup

1. Create a Firebase project and add Android / iOS / Web apps to it.
2. Install the CLI and generate options:
   ```bash
   dart pub global activate flutterfire_cli
   cd app && flutterfire configure
   ```
   This creates `lib/firebase_options.dart`.
3. Use those options — in `NotificationService.init()` change
   `Firebase.initializeApp()` to:
   ```dart
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```
   (import `package:pharma_reserve/firebase_options.dart`).
4. **Android**: `flutterfire configure` adds `google-services.json` and the
   Gradle plugins. **iOS**: it adds `GoogleService-Info.plist`; also enable
   Push Notifications + an APNs key in the Apple developer portal.
5. **Web**: add your Firebase web config to `web/index.html`, create
   `web/firebase-messaging-sw.js` with the same config, and pass your VAPID
   key: `FirebaseMessaging.instance.getToken(vapidKey: '...')`.

## Backend setup

1. Run `backend/supabase/migrations/0005_device_tokens.sql`.
2. Deploy the function and set its secret:
   ```bash
   supabase functions deploy send-notification
   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat service-account.json)"
   ```
   (`service-account.json` = a Firebase service-account key from
   Project settings → Service accounts → Generate new private key.)

## Sending a notification

```bash
curl -X POST "$SUPABASE_URL/functions/v1/send-notification" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"<uuid>","title":"Order update","body":"Your order is out for delivery"}'
```

To notify a pharmacy automatically when an order status changes, call this
function from the admin flow after `updateStatus`, or add a Postgres trigger /
Database Webhook on `orders` that invokes it. Review the function's auth before
exposing it publicly so only trusted callers can push.

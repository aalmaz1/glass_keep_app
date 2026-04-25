# Glass Keep App

A Flutter-based note-taking application with glass morphism UI.

## Firebase Configuration

This project uses environment variables for Firebase configuration to keep sensitive keys out of the repository.

### Running/Building the App

To run or build the app, you must provide the Firebase configuration using `--dart-define` flags:

```bash
flutter run --dart-define=FIREBASE_API_KEY=your_api_key \
            --dart-define=FIREBASE_APP_ID=your_app_id \
            --dart-define=FIREBASE_MESSAGING_SENDER_ID=your_sender_id \
            --dart-define=FIREBASE_PROJECT_ID=your_project_id \
            --dart-define=FIREBASE_AUTH_DOMAIN=your_auth_domain \
            --dart-define=FIREBASE_STORAGE_BUCKET=your_storage_bucket \
            --dart-define=FIREBASE_MEASUREMENT_ID=your_measurement_id \
            --dart-define=FIREBASE_IOS_BUNDLE_ID=your_ios_bundle_id
```

### Using a Configuration File

Alternatively, you can use a JSON file for configuration:

1. Create a `config.json` file:
```json
{
  "FIREBASE_API_KEY": "your_api_key",
  "FIREBASE_APP_ID": "your_app_id",
  "FIREBASE_MESSAGING_SENDER_ID": "your_sender_id",
  "FIREBASE_PROJECT_ID": "your_project_id",
  "FIREBASE_AUTH_DOMAIN": "your_auth_domain",
  "FIREBASE_STORAGE_BUCKET": "your_storage_bucket",
  "FIREBASE_MEASUREMENT_ID": "your_measurement_id",
  "FIREBASE_IOS_BUNDLE_ID": "your_ios_bundle_id"
}
```

2. Run the app using:
```bash
flutter run --dart-define-from-file=config.json
```

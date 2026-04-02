# Initialize App Version in Firestore

This script adds initial version configuration to Firestore.

## Setup Firestore Data:

### Option 1: Via Firebase Console

1. Go to Firebase Console → Firestore Database
2. Create collection: `app_versions`
3. Add document with ID: `ios`
   ```json
   {
     "platform": "ios",
     "minSupportedVersion": "1.0.0",
     "latestVersion": "1.0.0",
     "updateMessage": "Please update to the latest version",
     "forcedUpdate": false
   }
   ```

### Option 2: Via REST API (when backend is running)

```bash
# You'll need to implement an admin endpoint for this
curl -X POST http://localhost:8080/api/admin/versions \
  -H "Content-Type: application/json" \
  -d '{
    "platform": "ios",
    "minSupportedVersion": "1.0.0",
    "latestVersion": "1.0.0",
    "updateMessage": "Please update to the latest version",
    "forcedUpdate": false
  }'
```

## Version Format:

Use semantic versioning: `MAJOR.MINOR.PATCH`
- Example: `1.0.0`, `1.2.5`, `2.0.0`

## How It Works:

1. **App Launch**: iOS app sends current version to `/api/version/check`
2. **Backend**: Compares app version with `minSupportedVersion`
3. **Response**:
   - `supported: true` → app continues normally
   - `supported: false, updateRequired: true` → show update screen
4. **User**: Sees update screen and button to App Store

## Testing:

### Test 1: Version is supported
```bash
# Set minSupportedVersion to "1.0.0" in Firestore
# App version is "1.0.0"
# Result: App opens normally
```

### Test 2: Version is outdated
```bash
# Set minSupportedVersion to "2.0.0" in Firestore
# App version is "1.0.0"
# Result: Update screen appears
```

### Test 3: Update backend version check:
```bash
curl -X POST http://localhost:8080/api/version/check \
  -H "Content-Type: application/json" \
  -d '{"platform": "ios", "version": "1.0.0"}'
```

Expected response:
```json
{
  "supported": true,
  "updateRequired": false,
  "latestVersion": "1.0.0",
  "updateMessage": null
}
```

## Future: Android Support

When you add Android app, just create another document in `app_versions`:
```json
{
  "platform": "android",
  "minSupportedVersion": "1.0.0",
  "latestVersion": "1.0.0",
  "updateMessage": "Please update to the latest version",
  "forcedUpdate": false
}
```
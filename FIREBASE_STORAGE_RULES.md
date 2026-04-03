# Firebase Storage Rules for UrbanHunt

## Current Rules Configuration

Copy and paste these rules into Firebase Console → Storage → Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile pictures - users can only write to their own profile folder
    match /profiles/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Prize photos - only authenticated users can write
    match /prizes/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Hint photos - only authenticated users can write
    match /hints/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Prize confirmation content - only authenticated users can write
    match /prize-confirmations/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## How to Update Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **urbanhunt-491913**
3. Navigate to **Storage** in the left sidebar
4. Click on the **Rules** tab
5. Replace the existing rules with the rules above
6. Click **Publish**

## Rules Explanation

### `/profiles/{userId}/`
- **Read**: Public (anyone can view profile pictures)
- **Write**: Only the user who owns the profile folder
- **Purpose**: User profile pictures

### `/prizes/`
- **Read**: Public (anyone can view prize photos)
- **Write**: Any authenticated user
- **Purpose**: Challenge prize photos

### `/hints/`
- **Read**: Public (anyone can view hint photos)
- **Write**: Any authenticated user
- **Purpose**: Challenge hint photos/videos

### `/prize-confirmations/`
- **Read**: Public (anyone can view confirmation media)
- **Write**: Any authenticated user
- **Purpose**: Prize confirmation photos/videos from users who found prizes

## Security Notes

- All folders require authentication for write operations
- Profile folders have additional restriction: users can only write to their own folder
- All content is publicly readable (good for sharing)
- Consider adding file size limits in the future if needed
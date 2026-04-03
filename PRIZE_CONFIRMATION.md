# Prize Confirmation System

## Overview
The Prize Confirmation system allows users to confirm when they've found a prize in a challenge. When a challenge is activated, a PrizeConfirmation object is automatically created with status `NEW`. Users can then submit their finding via a deep link.

## Backend Components

### Model: `PrizeConfirmation`
```java
public class PrizeConfirmation {
    private String id;
    private String challengeId;
    private String userId;              // User who found the prize
    private ConfirmationStatus status;   // NEW or DONE
    private String message;              // Optional text message
    private String contentUrl;           // Optional photo or video URL
    private Date createdAt;
    private Date confirmedAt;            // When status changed to DONE
}
```

### Automatic Creation
When a challenge status changes from any status to `ACTIVE`, a PrizeConfirmation is automatically created:
- Location: `ChallengeController.updateStatus()`
- Status: `NEW`
- UserId: Initially `null`

### Confirmation Flow
1. Challenge creator activates challenge → PrizeConfirmation created with status=NEW
2. User finds prize and clicks deep link `urbanhunt://challenge/{id}/confirm`
3. User fills form with optional message and media
4. User submits → PrizeConfirmation updated:
   - status: `DONE`
   - userId: current user
   - message: user's message
   - contentUrl: uploaded media URL
   - confirmedAt: current timestamp
5. Challenge status automatically changed to `COMPLETED`

## API Endpoints

### GET `/api/prize-confirmations/challenge/{challengeId}`
Get prize confirmation for a specific challenge.

**Response:**
```json
{
  "id": "conf123",
  "challengeId": "challenge456",
  "userId": "user789",
  "status": "NEW",
  "message": null,
  "contentUrl": null,
  "createdAt": "2024-01-15T10:00:00Z",
  "confirmedAt": null
}
```

### POST `/api/prize-confirmations/challenge/{challengeId}/confirm`
Confirm prize finding.

**Request:**
```json
{
  "message": "Found it! Amazing prize!",
  "contentUrl": "https://storage.googleapis.com/.../photo.jpg"
}
```

**Response:**
```json
{
  "id": "conf123",
  "challengeId": "challenge456",
  "userId": "user789",
  "status": "DONE",
  "message": "Found it! Amazing prize!",
  "contentUrl": "https://storage.googleapis.com/.../photo.jpg",
  "createdAt": "2024-01-15T10:00:00Z",
  "confirmedAt": "2024-01-15T14:30:00Z"
}
```

### GET `/api/prize-confirmations/user/me`
Get all prize confirmations for current user.

## iOS Components

### Model: `PrizeConfirmation.swift`
Swift struct matching the backend model with `Codable` conformance.

### View: `ConfirmPrizeView`
- Text editor for optional message
- PhotosPicker for selecting photo or video
- Upload to Firebase Storage
- Submit confirmation to API
- Success alert

### Deep Links
- View challenge: `urbanhunt://challenge/{id}`
- Confirm prize: `urbanhunt://challenge/{id}/confirm`

### Storage
Prize confirmation media uploaded to:
```
gs://urbanhunt-app.appspot.com/prize-confirmations/{uuid}
```

## Testing with Bruno

1. **Create and activate challenge**
   - POST `/api/challenges` (create with status=DRAFT)
   - PATCH `/api/challenges/{id}/status?status=ACTIVE`
   - This creates PrizeConfirmation automatically

2. **Check confirmation was created**
   - GET `/api/prize-confirmations/challenge/{challengeId}`
   - Should return confirmation with status=NEW

3. **Confirm prize**
   - First upload media to Firebase Storage
   - POST `/api/prize-confirmations/challenge/{challengeId}/confirm`
   - Check challenge status changed to COMPLETED

## Security Notes
- All endpoints require Firebase authentication
- Users can only confirm prizes for active challenges
- Once confirmed (status=DONE), cannot be re-confirmed
- Content URLs should be validated before storage
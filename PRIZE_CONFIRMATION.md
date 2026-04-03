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
2. Creator receives confirmationId (e.g., `V4ZPSTvvIOhwmy2ANG4n`)
3. Creator shares deep link with confirmationId: `urbanhunt://confirm/{confirmationId}`
4. User finds prize and clicks deep link
5. User fills form with optional message and media
6. User submits → PrizeConfirmation updated:
   - status: `DONE`
   - userId: current user
   - message: user's message
   - contentUrl: uploaded media URL
   - confirmedAt: current timestamp
7. Challenge status automatically changed to `COMPLETED`

### Security Features
- **Unique confirmationId**: Each confirmation has a unique ID that cannot be guessed from the challengeId
- **One-time use**: Once confirmed (status=DONE), the confirmation cannot be reused
- **Challenge isolation**: Users cannot confirm prizes by knowing only the challengeId

## API Endpoints

### GET `/api/prize-confirmations/{confirmationId}`
Get prize confirmation by its unique ID.

**Response:**
```json
{
  "id": "V4ZPSTvvIOhwmy2ANG4n",
  "challengeId": "Rt8QNX0TZUPVE1bi917Y",
  "userId": null,
  "status": "NEW",
  "message": null,
  "contentUrl": null,
  "createdAt": "2024-01-15T10:00:00Z",
  "confirmedAt": null
}
```

### GET `/api/prize-confirmations/challenge/{challengeId}`
Get prize confirmation for a specific challenge (for challenge owners to check status).

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

### POST `/api/prize-confirmations/{confirmationId}/confirm`
Confirm prize finding using the unique confirmationId (primary method - secure).

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
  "id": "V4ZPSTvvIOhwmy2ANG4n",
  "challengeId": "Rt8QNX0TZUPVE1bi917Y",
  "userId": "user789",
  "status": "DONE",
  "message": "Found it! Amazing prize!",
  "contentUrl": "https://storage.googleapis.com/.../photo.jpg",
  "createdAt": "2024-01-15T10:00:00Z",
  "confirmedAt": "2024-01-15T14:30:00Z"
}
```

### POST `/api/prize-confirmations/challenge/{challengeId}/confirm`
Confirm prize finding using challengeId (legacy method - less secure, kept for backward compatibility).

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
- View challenge: `urbanhunt://challenge/{challengeId}`
- Confirm prize (secure): `urbanhunt://confirm/{confirmationId}`

**Example:**
For the confirmation object with:
- `id`: "V4ZPSTvvIOhwmy2ANG4n"
- `challengeId`: "Rt8QNX0TZUPVE1bi917Y"

The secure deep link is: `urbanhunt://confirm/V4ZPSTvvIOhwmy2ANG4n`

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
   - Note the `id` field - this is the confirmationId

3. **Confirm prize (secure method)**
   - First upload media to Firebase Storage
   - POST `/api/prize-confirmations/{confirmationId}/confirm`
   - Check challenge status changed to COMPLETED

## Security Notes
- All endpoints require Firebase authentication
- **Primary security**: confirmationId is a unique, non-guessable identifier
- Users need the exact confirmationId to confirm a prize
- Challenge creators should share `urbanhunt://confirm/{confirmationId}` links, not challengeId
- Once confirmed (status=DONE), cannot be re-confirmed
- Content URLs should be validated before storage
- Legacy endpoint (by challengeId) kept for backward compatibility but less secure
# UrbanHunt

Spring Boot backend for Urban Hunt mobile app (Android & iOS).

## Technologies

- Java 17
- Spring Boot 3.2.4
- Maven
- Google Cloud Firestore (Native Mode)
- Firebase Authentication (Google & Apple Sign-In)
- GCP Cloud Run

## Authentication

Mobile apps authenticate via Firebase Authentication:
- **Google Sign-In** (Android & iOS)
- **Apple Sign-In** (iOS)

Backend validates Firebase ID tokens using Firebase Admin SDK.

## Local Development

### Prerequisites

- Java 17
- Maven 3.6+
- GCP Project with Firestore enabled
- Firebase project configured

### Setup

1. Download service account key from Firebase Console
2. Set environment variable:
```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
export GCP_PROJECT_ID=your-project-id
```

3. (Optional) Use Firestore emulator:
```bash
gcloud emulators firestore start
export FIRESTORE_EMULATOR_HOST=localhost:8080
```

### Run Locally

```bash
mvn spring-boot:run
```

Application starts on `http://localhost:8080`

### Build

```bash
mvn clean package
```

## API Endpoints

### Public Endpoints
- `GET /api/health` - Health check
- `GET /api/challenges` - List all challenges
- `GET /api/challenges/{id}` - Get challenge by ID
- `GET /api/challenges?city=Berlin&status=ACTIVE` - Filter challenges
- `GET /api/challenges/{id}/comments` - Get comments (paginated)

### Protected Endpoints (Require Firebase ID Token)
- `GET /api/auth/me` - Get current user profile
- `POST /api/auth/sync` - Sync user profile from Firebase token
- `POST /api/challenges` - Create challenge
- `POST /api/challenges/{id}/hints` - Add hint
- `POST /api/challenges/{id}/complete` - Complete challenge
- `POST /api/challenges/{id}/comments` - Add comment
- `DELETE /api/challenges/{id}/comments/{commentId}` - Delete comment

### Authentication Header

```
Authorization: Bearer <firebase-id-token>
```

## Deployment to GCP Cloud Run

### Build and Push Image

```bash
mvn compile jib:build -Dimage=gcr.io/PROJECT_ID/urban-hunt
```

### Deploy

```bash
gcloud run deploy urban-hunt \
  --image gcr.io/PROJECT_ID/urban-hunt \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars "GCP_PROJECT_ID=your-project-id"
```

## Firestore Structure

```
/challenges/{challengeId}
  - title, status, cityName, hints[], commentsCount, completion

/comments/{commentId}
  - challengeId, authorId, authorName, content, createdAt

/users/{userId}
  - email, name, pictureUrl, provider, createdAt, lastLoginAt
```

## Required Firestore Index

```
Collection: comments
Fields:
  - challengeId (Ascending)
  - createdAt (Descending)
```

Create via Firebase Console or gcloud:
```bash
gcloud firestore indexes composite create \
  --collection-group=comments \
  --field-config=field-path=challengeId,order=ascending \
  --field-config=field-path=createdAt,order=descending
```
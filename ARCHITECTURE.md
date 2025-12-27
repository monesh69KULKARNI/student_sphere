# StudentSphere Architecture

## Overview

StudentSphere uses a **hybrid architecture** combining Firebase and Supabase:

- **Firebase**: Authentication only
- **Supabase**: Database, Storage, and all other data operations

## Architecture Diagram

```
┌─────────────────┐
│   Flutter App   │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼───┐  ┌──▼──────┐
│Firebase│  │Supabase│
│  Auth  │  │Database│
└───┬───┘  └──┬──────┘
    │         │
    │    ┌────▼──────┐
    │    │ Supabase  │
    │    │  Storage  │
    │    └───────────┘
    │
└─────────┘
```

## Technology Stack

### Authentication
- **Firebase Authentication**
  - Email/Password authentication
  - Secure user sessions
  - Password reset functionality

### Database
- **Supabase (PostgreSQL)**
  - All data storage
  - Real-time subscriptions
  - Row Level Security (RLS)
  - Advanced queries

### Storage
- **Supabase Storage**
  - File uploads
  - Resource files
  - Profile images
  - Event images

## Data Flow

### User Registration
1. User signs up via Firebase Auth
2. Firebase creates authentication record
3. User profile saved to Supabase `users` table
4. Firebase UID stored as `uid` in Supabase

### User Login
1. User authenticates with Firebase
2. App gets Firebase UID
3. App queries Supabase `users` table using UID
4. User data loaded into app

### Data Operations
1. User authenticated via Firebase
2. App gets Firebase UID
3. All CRUD operations go to Supabase
4. RLS policies enforce permissions
5. Service layer validates user role

## Database Schema

See `SUPABASE_DATABASE_SCHEMA.sql` for complete schema.

### Key Tables
- `users` - User profiles (linked to Firebase UID)
- `events` - Event information
- `announcements` - Campus announcements
- `resources` - Shared resources
- `achievements` - Student achievements
- `careers` - Career opportunities

## Security Model

### Authentication Layer (Firebase)
- Secure password hashing
- Session management
- Token-based authentication

### Database Layer (Supabase)
- Row Level Security (RLS)
- Role-based access control
- Service layer validation

### Permission Model
- **Student**: Read public data, register for events
- **Faculty**: Create content, manage resources
- **Admin**: Full access
- **Guest**: Read-only public data

## Service Layer

### AuthService
- Handles Firebase authentication
- Manages user sessions
- Syncs user data with Supabase

### SupabaseDatabaseService
- All database operations
- Converts between camelCase (models) and snake_case (database)
- Handles queries and mutations

### SupabaseService
- File storage operations
- Upload/download files
- Manage storage buckets

## Benefits of This Architecture

### ✅ Firebase Auth
- Industry-standard authentication
- Reliable and secure
- Easy to implement
- Free tier is generous

### ✅ Supabase Database
- PostgreSQL power
- Cost-effective
- Better for complex queries
- Real-time subscriptions
- Row Level Security

### ✅ Supabase Storage
- Cheaper than Firebase Storage
- Better for large files
- Integrated with database

## Migration Notes

If you have existing Firestore data:
1. Export data from Firestore
2. Transform to match Supabase schema
3. Import to Supabase
4. Update `uid` fields to match Firebase UIDs

## Future Enhancements

- [ ] Real-time subscriptions for live updates
- [ ] Database backups and replication
- [ ] Advanced analytics queries
- [ ] Full-text search
- [ ] Database migrations system


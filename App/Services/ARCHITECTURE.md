# CaliCollection Architecture Documentation

**Version:** 2.1a  
**Last Updated:** January 28, 2026  
**Platform:** iOS/iPadOS

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Patterns](#architecture-patterns)
3. [Data Layer](#data-layer)
4. [Service Layer](#service-layer)
5. [Presentation Layer](#presentation-layer)
6. [File Structure](#file-structure)
7. [Data Flow](#data-flow)
8. [Error Handling](#error-handling)
9. [Performance Optimization](#performance-optimization)
10. [Dependencies](#dependencies)

---

## Overview

CaliCollection is an iOS/iPadOS app for managing collectible toy collections (Calico Critters). The architecture follows Apple's modern best practices using **SwiftUI**, **SwiftData**, and **Swift Concurrency**.

### Core Concepts

- **Browse Cache**: Temporary data synced from API (critters, variants, families)
- **User Collection**: Permanent data owned by the user (owned variants, photos, purchase details)
- **Dual-Storage Model**: Browse cache is replaceable; collection data persists

### Key Technologies

- **SwiftUI**: Declarative UI framework
- **SwiftData**: Modern persistence with model-driven approach
- **Swift Concurrency**: Async/await for network and data operations
- **Combine**: Reactive programming for UI updates
- **os.log**: Unified logging system

---

## Architecture Patterns

### MVVM + Service Layer

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Views, ViewModels via @Observable)    │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          Service Layer                  │
│  (SyncService, APIService, etc.)        │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          Data Layer                     │
│  (SwiftData Models, ModelContext)       │
└─────────────────────────────────────────┘
```

### Design Principles

1. **Single Responsibility**: Each service/model has one clear purpose
2. **Dependency Injection**: Services injected via environment or parameters
3. **Actor Isolation**: `@MainActor` for UI-bound objects
4. **Type Safety**: Strong typing with Swift's type system
5. **Error Propagation**: Structured error handling with custom types

---

## Data Layer

### SwiftData Models

All models use `@Model` macro for automatic SwiftData persistence.

#### Browse Cache Models (Temporary, Synced from API)

**Critter** - Base character template
```swift
@Model
final class Critter {
    @Attribute(.unique) var uuid: String
    var familyId: String
    var name: String
    var memberType: String
    var role: String?
    var barcode: String?
    var familyName: String?
    var familySpecies: String?
    var variantsCount: Int
    var lastSynced: Date
}
```

**CritterVariant** - Specific product release
```swift
@Model
final class CritterVariant {
    @Attribute(.unique) var uuid: String
    var critterId: String
    var name: String
    var sku: String?
    var barcode: String?
    var imageURL: String?
    var thumbnailURL: String?
    var releaseYear: Int?
    var notes: String?
    var setId: String?
    var setName: String?
    var epochId: String?
    var isPrimary: Bool?
    var lastSynced: Date
}
```

**Family** - Critter family/species group
```swift
@Model
final class Family {
    @Attribute(.unique) var uuid: String
    var name: String
    var slug: String
    var species: String
    var familyDescription: String?
    var imageURL: String?
    var lastSynced: Date
}
```

#### User Collection Models (Permanent)

**OwnedVariant** - User's tracked variant
```swift
@Model
final class OwnedVariant {
    @Attribute(.unique) var variantUuid: String
    var critterUuid: String
    var critterName: String
    var variantName: String
    var familyId: String
    var familyName: String?
    var familySpecies: String?
    var memberType: String
    var role: String?
    var imageURL: String?
    var thumbnailURL: String?
    var statusRaw: String  // "collection" or "wishlist"
    var photoPath: String?
    var addedDate: Date
    
    // Purchase tracking
    var pricePaid: Double?
    var purchaseDate: Date?
    var purchaseLocation: String?
    var condition: String?
    var notes: String?
    var quantity: Int
}
```

**VariantPhoto** - User-captured photos
```swift
@Model
final class VariantPhoto {
    var id: UUID
    var variantUuid: String
    var imageData: Data
    var caption: String?
    var capturedDate: Date
    var sortOrder: Int
}
```

### Model Relationships

```
Family (1) ──── (Many) Critter ──── (Many) CritterVariant
                                           │
                                           │ (UUID Reference)
                                           │
                                           ▼
                                    OwnedVariant (1) ──── (Many) VariantPhoto
```

**Note**: Relationships are UUID-based, not SwiftData relationships, because browse cache models can be deleted and re-synced.

### Data Integrity

- **Unique Constraints**: All models use `@Attribute(.unique)` on UUID
- **Browse Cache Refresh**: OwnedVariants maintain imageURL sync during critter sync
- **Orphan Prevention**: User photos/data persist even if browse cache is cleared

---

## Service Layer

### SyncService

**Purpose**: Manages synchronization of browse cache from API  
**Pattern**: Singleton with `@MainActor` isolation  
**State Management**: `@Published` properties for UI binding

```swift
@MainActor
class SyncService: ObservableObject {
    static let shared = SyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
}
```

**Key Methods**:
- `syncCritters(modelContext:force:)` - Sync critters and variants
- `syncFamilies(modelContext:force:)` - Sync families
- `syncAll(modelContext:force:)` - Full sync operation

**Sync Strategy**:
1. Check if sync needed (>7 days old or never synced)
2. Fetch data from API
3. Delete existing browse cache (`try modelContext.delete(model: Critter.self)`)
4. Batch insert new data
5. Update OwnedVariant imageURLs with fresh data
6. Single save operation at end
7. Update last sync timestamp

**Performance Optimization**:
- Batch operations (single save at end)
- Conditional sync (needsSync check)
- Error recovery with user feedback

### APIService

**Purpose**: Centralized API communication  
**Pattern**: Singleton with stateless methods  
**Network Layer**: Uses `NetworkConfig` for retry logic

```swift
class APIService {
    static let shared = APIService()
    
    func fetchCritters() async throws -> [CritterResponse]
    func fetchFamilies() async throws -> [FamilyResponse]
    func submitReport(...) async throws -> String
}
```

**API Configuration**:
- Base URL: `Config.apiBaseURL` (environment-based)
- Debug: `https://calicoprod.thetechnodro.me/api/v1`
- Production: `http://api.callicollection.com/api/v1`

**Response Models**:
```swift
struct CritterResponse: Codable {
    let uuid: String
    let familyId: String
    let name: String
    let family: FamilyResponse?
    let variants: [VariantResponse]?
}
```

### NetworkConfig

**Purpose**: Centralized network configuration and retry logic  
**Pattern**: Enum with static properties/methods

**Configuration**:
- Request timeout: 30 seconds
- Resource timeout: 60 seconds
- Max retries: 3 attempts
- Retry delay: 1 second (exponential backoff 2x)
- Retryable status codes: 408, 429, 500, 502, 503, 504

**Retry Strategy**:
```swift
static func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse)
```
- Automatically retries on network errors and retryable HTTP codes
- Exponential backoff between attempts
- Logs warnings on retry attempts

### BackupManager

**Purpose**: Import/export user collection and photos  
**Pattern**: Singleton with `@Published` state  
**Format**: ZIP archive with JSON manifest

**Export Structure**:
```
CaliCollection_Backup_01-28-2026.zip
├── backup.json          (Collection metadata)
└── photos/
    ├── {uuid}_{id}.jpg
    └── ...
```

**Key Methods**:
- `exportCollection(ownedVariants:photos:appVersion:)` - Create ZIP backup
- `importCollection(from:into:)` - Restore from backup

**Import Strategy**:
- Upsert logic: Update existing, insert new
- Photo deduplication by UUID
- Detailed import result reporting

### ToastManager

**Purpose**: Global toast notification system  
**Pattern**: Singleton with `@Published` state

```swift
@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    @Published var toast: Toast?
    
    func show(_ message: String, type: ToastType)
}
```

**Toast Types**:
- `.success` - Green checkmark (auto-dismiss 2s)
- `.error` - Red X mark (auto-dismiss 2s)
- `.info` - Blue info icon (auto-dismiss 2s)

**Animation**: Spring animation with smooth transitions

### AppLogger

**Purpose**: Structured logging with os.log  
**Pattern**: Static methods on enum

**Log Categories**:
- `general` - Debug, info, warning, error
- `network` - API requests/responses
- `sync` - Sync lifecycle events

**Log Levels**:
```swift
AppLogger.debug("🔍 Detail info")        // DEBUG only
AppLogger.info("ℹ️ General info")        // DEBUG only
AppLogger.warning("⚠️ Warning")          // All builds
AppLogger.error("❌ Error")              // All builds
```

**Advantages**:
- Unified logging viewable in Console.app
- Automatic log retention and privacy
- Emoji prefixes for quick visual scanning
- Category-based filtering

---

## Presentation Layer

### View Architecture

**Pattern**: SwiftUI with `@State` and `@Query` for data binding

**Key Views**:

#### ContentView
- Root view with conditional first-sync check
- TabView with 4 tabs: Collection, Wishlist, Settings, Search
- Toast modifier applied at root level

#### FirstSyncView
- Onboarding screen for initial sync
- Forces user to sync before using app
- Sets `hasCompletedFirstSync` UserDefaults flag

#### CollectionView / WishlistView
- Display user's owned variants
- `@Query` for reactive SwiftData fetching
- Grid layout with AsyncImage thumbnails
- Filtering and sorting capabilities

#### SearchView
- Browse critters from API cache
- Add to collection/wishlist
- Real-time search with query predicates

#### SettingsView
- Data management (sync, backup, import)
- App information
- Purchase detail toggle

### Data Binding

**SwiftData Query**:
```swift
@Query(filter: #Predicate<OwnedVariant> { 
    $0.statusRaw == "collection" 
}) var ownedVariants: [OwnedVariant]
```

**Environment Objects**:
```swift
@EnvironmentObject var syncService: SyncService
@Environment(\.modelContext) var modelContext
```

### View Modifiers

**Toast Modifier**:
```swift
.toast()  // Add to root view for global toasts
```

---

## File Structure

```
CaliCollectionV2/
├── Models/
│   ├── Browse Cache/
│   │   ├── Critter.swift
│   │   ├── CritterVariant.swift
│   │   └── Family.swift
│   ├── User Collection/
│   │   ├── OwnedVariant.swift
│   │   └── VariantPhoto.swift
│   └── API Responses/
│       ├── CritterResponse.swift
│       ├── FamilyResponse.swift
│       └── VariantResponse.swift
│
├── Services/
│   ├── SyncService.swift
│   ├── APIService.swift
│   ├── NetworkConfig.swift
│   ├── BackupManager.swift
│   └── ToastManager.swift
│
├── Views/
│   ├── ContentView.swift
│   ├── FirstSyncView.swift
│   ├── CollectionView.swift
│   ├── WishlistView.swift
│   ├── SearchView.swift
│   ├── SettingsView.swift
│   └── DataManagementView.swift
│
├── Utilities/
│   ├── Config.swift
│   ├── AppLogger.swift
│   └── APIError.swift
│
└── Tests/
    └── OwnedVariantTests.swift
```

### Organizational Principles

1. **Model-First Organization**: Models grouped by purpose
2. **Service Layer Isolation**: Clear separation from UI
3. **Flat View Hierarchy**: Avoid deep nesting
4. **Shared Utilities**: Common code in Utilities folder

---

## Data Flow

### Sync Flow

```
User Triggers Sync
      │
      ▼
SyncService.syncCritters()
      │
      ├─► Check needsSync
      │   └─► Skip if recent (unless forced)
      │
      ├─► APIService.fetchCritters()
      │   │
      │   ├─► NetworkConfig.performRequest()
      │   │   └─► Auto-retry on failure
      │   │
      │   └─► Parse CritterResponse[]
      │
      ├─► ModelContext Operations
      │   ├─► Delete existing Critter/CritterVariant
      │   ├─► Insert new models
      │   ├─► Update OwnedVariant imageURLs
      │   └─► Save (single batch operation)
      │
      ├─► Update lastSyncDate
      │
      └─► ToastManager.show("✓ Synced X critters")
```

### Add to Collection Flow

```
User Taps "Add to Collection" on Variant
      │
      ▼
OwnedVariant.create(variant, critter, .collection, context)
      │
      ├─► Check if already exists
      │   ├─► YES: Update status to .collection
      │   └─► NO:  Create new OwnedVariant
      │
      ├─► ModelContext.save()
      │
      └─► SwiftUI auto-updates via @Query
            │
            └─► Variant appears in CollectionView
```

### Image Loading Flow

```
AsyncImage(url: variant.thumbnailURL)
      │
      ├─► URLSession downloads image
      ├─► SwiftUI caches in memory
      └─► Renders placeholder while loading
```

### Backup/Restore Flow

**Export**:
```
BackupManager.exportCollection()
      │
      ├─► Fetch OwnedVariants and VariantPhotos
      ├─► Create temp directory
      ├─► Copy photo files
      ├─► Generate JSON manifest
      ├─► ZIP everything
      ├─► Return URL for ShareSheet
      └─► Update lastBackupDate
```

**Import**:
```
BackupManager.importCollection(from: url)
      │
      ├─► Unzip to temp directory
      ├─► Parse JSON manifest
      ├─► Upsert OwnedVariants (update/insert)
      ├─► Import photos (skip duplicates)
      ├─► ModelContext.save()
      └─► Return ImportResult with stats
```

---

## Error Handling

### Error Types

**APIError** (assumed from context):
```swift
enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case rateLimited
    case decodingError(Error)
    case networkError(Error)
}
```

### Error Propagation Strategy

1. **Services throw errors**: Let caller handle presentation
2. **ViewModels catch and display**: Convert to user-friendly messages
3. **Toast for user feedback**: Non-blocking error notifications
4. **Logging for debugging**: Detailed errors in Console

### Error Handling Patterns

**Async Service Calls**:
```swift
do {
    let data = try await APIService.shared.fetchCritters()
    // Handle success
} catch {
    syncError = error.localizedDescription
    AppLogger.syncError(error.localizedDescription)
    ToastManager.shared.show("Sync failed: \(error.localizedDescription)", type: .error)
}
```

**SwiftData Operations**:
```swift
do {
    try modelContext.save()
} catch {
    AppLogger.error("Failed to save: \(error)")
    // Context auto-rolls back on failure
}
```

**Network Retry Logic**:
- Automatic retry on timeout/connection errors
- Exponential backoff (1s, 2s, 4s)
- Max 3 attempts before failing
- User sees final error if all retries fail

### User-Facing Error Messages

- **Sync failures**: "Sync failed: [reason]" (red toast)
- **Network errors**: Automatic retry, log warnings
- **Import/Export errors**: Detailed error dialog
- **Data corruption**: Graceful fallback, log error

---

## Performance Optimization

### Database Performance

**Batch Operations**:
```swift
// Insert all critters before saving
for response in critterResponses {
    let critter = Critter(from: response)
    modelContext.insert(critter)
}
// Single save at end
try modelContext.save()
```

**Query Optimization**:
```swift
@Query(filter: #Predicate<OwnedVariant> { 
    $0.statusRaw == "collection" 
}, sort: \OwnedVariant.addedDate)
var ownedVariants: [OwnedVariant]
```
- Index on unique attributes
- Predicate pushdown to database level
- Lazy loading of relationships

**Delete Performance**:
```swift
try modelContext.delete(model: Critter.self)  // Batch delete
```

### Network Performance

**Retry Configuration**:
- Fail fast on non-retryable errors
- Exponential backoff prevents server overload
- Timeout limits prevent hanging requests

**Request Timeouts**:
- Request: 30 seconds
- Resource: 60 seconds
- Prevents indefinite waits

**Caching Strategy**:
- API responses: Not cached (always fresh)
- Images: SwiftUI AsyncImage memory cache
- Browse cache: Local SwiftData storage

### UI Performance

**Lazy Loading**:
- Grid views use LazyVGrid/LazyHGrid
- Only visible items rendered

**Image Loading**:
```swift
AsyncImage(url: thumbnailURL) { image in
    image.resizable().aspectRatio(contentMode: .fit)
} placeholder: {
    ProgressView()
}
```
- Asynchronous loading doesn't block UI
- Thumbnail URLs reduce data transfer
- Automatic memory management

**State Management**:
- `@Published` only on properties that affect UI
- Minimize unnecessary view updates
- Use `@MainActor` to ensure UI updates on main thread

### Sync Performance

**Conditional Sync**:
```swift
var needsSync: Bool {
    guard let lastSync = lastSyncDate else { return true }
    let daysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    return lastSync < daysAgo
}
```
- Only sync if >7 days old
- Skip unnecessary API calls
- Force sync option for manual refresh

**Image URL Refresh**:
```swift
// During sync, update OwnedVariant URLs
if let owned = try? modelContext.fetch(descriptor).first {
    owned.imageURL = variantResponse.imageUrl
    owned.thumbnailURL = variantResponse.thumbnailUrl
}
```
- Keeps user collection images fresh
- Handles URL changes on server
- No duplicate image downloads

---

## Dependencies

### Apple Frameworks

- **SwiftUI** - Declarative UI
- **SwiftData** - Persistence
- **Foundation** - Core utilities
- **Combine** - Reactive programming
- **os.log** - Unified logging

### Third-Party

- **ZIPFoundation** - ZIP archive creation/extraction
  - Used by: BackupManager
  - Purpose: Backup/restore functionality

### Build Configuration

**Debug Build**:
- Verbose logging enabled
- Development API endpoint
- Debug-only log statements

**Release Build**:
- Minimal logging (errors/warnings only)
- Production API endpoint
- Optimized performance

---

## Best Practices

### Code Standards

1. **Swift Concurrency**: Use async/await, avoid completion handlers
2. **Main Actor Isolation**: UI services marked `@MainActor`
3. **Error Handling**: Structured errors, never silent failures
4. **Type Safety**: Leverage Swift's type system
5. **Documentation**: Clear comments on complex logic

### SwiftData Usage

1. **Unique Constraints**: Always use on identifiers
2. **Batch Operations**: Insert all, save once
3. **Query Predicates**: Push filtering to database
4. **UUID References**: Not SwiftData relationships for volatile data

### Networking

1. **Retry Logic**: Handle transient failures
2. **Timeout Configuration**: Prevent hanging
3. **Structured Responses**: Codable DTOs
4. **Error Mapping**: Convert network errors to domain errors

### UI Patterns

1. **Single Source of Truth**: SwiftData is source
2. **Reactive Updates**: @Query auto-updates views
3. **Loading States**: Show progress during async operations
4. **Error Feedback**: Toast notifications for non-critical errors

---

## Future Considerations

### Scalability

- **Pagination**: If critter count exceeds 10,000+
- **Background Sync**: Automatic sync on app launch
- **Push Notifications**: Server-side update notifications
- **CloudKit Sync**: Cross-device collection sync

### Features

- **Search Improvements**: Full-text search, filters
- **Statistics**: Collection value, completion percentage
- **Social Features**: Share collections, friend lists
- **Barcode Scanning**: Add items via barcode

### Technical Debt

- **Unit Test Coverage**: Expand beyond OwnedVariantTests
- **UI Tests**: Critical user flows
- **Error Recovery**: More robust retry strategies
- **Offline Mode**: Better offline experience

---

## Glossary

- **Critter**: Base character template (e.g., "Stella Chocolate Rabbit")
- **Variant**: Specific product release of a critter
- **Browse Cache**: Temporary API-synced data
- **Owned Variant**: User's tracked item in collection/wishlist
- **Family**: Group of related critters (e.g., "Chocolate Rabbit Family")
- **Member Type**: Role type (e.g., "Sister", "Baby", "Mother")
- **UUID**: Universally unique identifier from API
- **Sync**: Refresh browse cache from API
- **Backup**: Export user collection to ZIP file

---

## Version History

- **2.1a**: Current version (January 2026)
  - SwiftData migration complete
  - Backup/restore functionality
  - Enhanced sync with image URL updates
  - Toast notification system
  - Unified logging

---

## Contact & Contribution

For questions about this architecture document, refer to:
- Code comments in respective files
- Apple documentation for SwiftUI/SwiftData
- Project README (if available)

---

*This document reflects the architecture as of January 28, 2026.*

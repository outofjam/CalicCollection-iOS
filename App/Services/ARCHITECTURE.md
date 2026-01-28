# CaliCollection Architecture Documentation

**Version:** 2.5a  
**Last Updated:** January 28, 2026  
**Platform:** iOS/iPadOS

---

## ⭐ Major Architectural Changes in v2.5a

### Paradigm Shift: From Offline-First to Hybrid

**OLD (v2.1a)**: Everything cached locally
```
API → SwiftData (Critters, Variants, Families) → Views
      └─ Sync every 7 days
      └─ Stale data between syncs
      └─ Large storage footprint (10,000+ items)
```

**NEW (v2.5a)**: Online browsing, offline collection
```
API (Browse) → Views (online-only, paginated)
               └─ Always fresh, no sync needed

SwiftData (Collection) → Views (offline-capable)
└─ Only user's owned items (~50-500 items)
└─ Cached images for offline access
```

### Key Benefits

1. **Reduced Storage**: ~90% reduction (from 10,000+ items to 100-500 items)
2. **Faster Sync**: <2 seconds (families only) vs. 30-60 seconds (entire catalog)
3. **Always Fresh Data**: Browse shows latest from API, no stale data
4. **Better Offline**: Collection fully offline with cached images
5. **Simpler Code**: No complex dual-storage sync logic

### Migration Impact

**What Changed**:
- ❌ `Critter` and `CritterVariant` models removed from SwiftData
- ❌ `SearchView` replaced by `BrowseView` with pagination
- ✅ `BrowseService` added for online API browsing
- ✅ `ImagePersistenceService` added for offline image caching
- ✅ `OwnedVariant` enhanced with `localImagePath`/`localThumbnailPath`
- ✅ `SyncService` simplified (families only)

**What Stayed the Same**:
- ✅ `OwnedVariant` and `VariantPhoto` (user data)
- ✅ `Family` (small cached dataset for filters)
- ✅ Backup/restore functionality
- ✅ Purchase tracking and user photos

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

- **Online Browsing**: Real-time API browsing with pagination (no local cache for browse data)
- **Offline Collection**: User's collection/wishlist with cached images for offline access
- **Hybrid Architecture**: Browse online, collect offline
- **Image Persistence**: Local image caching for owned variants

### Key Technologies

- **SwiftUI**: Declarative UI framework
- **SwiftData**: Modern persistence for user data only
- **Swift Concurrency**: Async/await for network and data operations
- **Combine**: Reactive programming for UI updates
- **os.log**: Unified logging system
- **UIKit Integration**: Image persistence and barcode scanning

---

## Architecture Patterns

### MVVM + Service Layer (Online-First Architecture)

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Views, ViewModels via @Observable)    │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          Service Layer                  │
│  • BrowseService (Online API)           │
│  • SyncService (Families Only)          │
│  • ImagePersistenceService (Caching)    │
│  • BackupManager (Import/Export)        │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          Data Layer                     │
│  • SwiftData: OwnedVariant, Family      │
│  • File System: Cached images           │
│  • API: Live critter/variant data       │
└─────────────────────────────────────────┘
```

### Design Principles

1. **Online-First Browsing**: Critters/variants fetched on-demand from API (no local cache)
2. **Offline-First Collection**: User's owned items cached locally with images
3. **Single Responsibility**: Each service has one clear purpose
4. **Dependency Injection**: Services injected via environment or parameters
5. **Actor Isolation**: `@MainActor` for UI-bound objects
6. **Type Safety**: Strong typing with Swift's type system
7. **Error Propagation**: Structured error handling with custom types
8. **Image Caching**: Automatic download and caching of images for owned variants

---

## Data Layer

### SwiftData Models

**Note**: Major architectural change in v2.5a - SwiftData is now used **only for user data** (OwnedVariant, VariantPhoto, Family). Critters and variants are no longer cached locally; they are fetched on-demand from the API.

#### User Collection Models (Permanent, Offline-Capable)

**OwnedVariant** - User's tracked variant with cached images
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
    
    // Remote URLs (for reference/re-download)
    var imageURL: String?
    var thumbnailURL: String?
    
    // Local cached paths (for offline access) - NEW in 2.5a
    var localImagePath: String?
    var localThumbnailPath: String?
    
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

**Key Changes**:
- Added `localImagePath` and `localThumbnailPath` for offline image access
- Images automatically cached when variant is added to collection/wishlist
- `hasLocalImages` computed property to check cache status

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

**Family** - Family metadata (small dataset, synced for offline filters)
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

**Why Family is still cached**: Families are a small dataset (~100 items) used for filter dropdowns. Caching them enables offline browsing of the user's collection with family filters.

#### Removed Models (No Longer Cached Locally)

**Critter** and **CritterVariant** models have been **removed** from local storage. These are now fetched on-demand from the API via `BrowseService`.

**Rationale**:
- Eliminates sync complexity and stale data issues
- Reduces app storage footprint
- Ensures users always see latest data when online
- Simplifies architecture (less dual-storage complexity)

### Model Relationships

```
Family (1) ──── (Many) [API: Critter] ──── (Many) [API: Variant]
  │                                              │
  │ (UUID Reference)                             │ (UUID Reference + Cached Images)
  │                                              │
  └─────────────────────► OwnedVariant (1) ──── (Many) VariantPhoto
```

**Data Flow**:
- **Browse**: Families cached locally → Critters fetched from API → Variants fetched from API
- **Collection**: User adds variant → Images downloaded and cached → OwnedVariant created in SwiftData
- **Offline**: User views collection → Images loaded from local cache → Full offline support

### Data Integrity

- **Unique Constraints**: All models use `@Attribute(.unique)` on UUID
- **Image Caching**: OwnedVariants automatically cache images for offline access
- **Orphan Prevention**: User photos/data persist independently of API data
- **Cache Management**: ImagePersistenceService handles automatic download, storage, and cleanup

---

## Service Layer

### BrowseService (NEW in 2.5a)

**Purpose**: Online-only browsing of critters and variants with pagination  
**Pattern**: Singleton with stateless async methods  
**Network Layer**: Uses `NetworkConfig` for retry logic

```swift
class BrowseService {
    static let shared = BrowseService()
    
    func fetchCritters(page: Int, perPage: Int, familyUuid: String?) async throws -> BrowseCrittersAPIResponse
    func fetchCritterVariants(critterUuid: String) async throws -> CritterVariantsResponse
    func fetchFamilies() async throws -> [FamilyBrowseResponse]
    func fetchFamily(uuid: String) async throws -> FamilyDetailResponse
}
```

**Key Features**:
- **Pagination**: Fetch critters in pages (default 30 per page)
- **Family Filtering**: Filter critters by family UUID
- **On-Demand Loading**: No local caching, always fresh data
- **Variant Picker Support**: Fetch all variants for a specific critter

**Response Types**:
```swift
struct BrowseCrittersAPIResponse {
    let data: [BrowseCritter]
    let meta: PaginationMeta
}

struct CritterVariantsResponse {
    let critter: CritterInfo
    let variants: [VariantResponse]
}
```

**Use Cases**:
- Browse all critters with pagination (BrowseView)
- Search/filter critters by family
- Select specific variant when adding to collection
- Always displays latest data from server

### SyncService (Simplified in 2.5a)

**Purpose**: Syncs **only families** from API for offline filter dropdown  
**Pattern**: Singleton with `@MainActor` isolation  
**State Management**: `@Published` properties for UI binding

**Major Change**: Now only syncs families. Critters/variants removed from sync.

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
- `syncFamilies(modelContext:force:)` - Sync families (small dataset ~100 items)
- ~~`syncCritters()`~~ - **REMOVED** (now fetched on-demand via BrowseService)
- ~~`syncAll()`~~ - **REMOVED** (only families need syncing)

**Sync Strategy** (Families Only):
1. Check if sync needed (>7 days old or never synced)
2. Fetch families from `BrowseService.shared.fetchFamilies()`
3. Delete existing families (`try modelContext.delete(model: Family.self)`)
4. Insert new families
5. Single save operation
6. Update last sync timestamp

**Why Only Families?**:
- Small dataset (~100 items vs. thousands of critters/variants)
- Used for offline filter dropdowns in collection view
- Minimal storage impact
- Rarely changes

### ImagePersistenceService (NEW in 2.5a)

**Purpose**: Download and cache images locally for offline collection access  
**Pattern**: Singleton with file system management  
**Storage**: Documents/CachedImages directory

```swift
class ImagePersistenceService {
    static let shared = ImagePersistenceService()
    
    func cacheImage(from urlString: String?, for variantUuid: String) async throws -> String?
    func cacheImages(imageUrl: String?, thumbnailUrl: String?, for variantUuid: String) async throws -> (String?, String?)
    func loadCachedImage(for variantUuid: String) -> UIImage?
    func deleteCachedImage(for variantUuid: String)
    func clearCache()
}
```

**Key Features**:
- **Automatic Caching**: Images cached when variant added to collection/wishlist
- **Offline Access**: Load images from local storage when offline
- **Cache Management**: Track cache size, clear individual or all images
- **Duplicate Detection**: Skip re-downloading existing cached images
- **Parallel Downloads**: Async concurrent download of full image + thumbnail

**Storage Structure**:
```
Documents/CachedImages/
├── {variantUuid}.jpg           (Full image)
├── {variantUuid}_thumb.jpg     (Thumbnail)
└── ...
```

**Integration with OwnedVariant**:
```swift
// When adding to collection
let (imagePath, thumbPath) = try await ImagePersistenceService.shared.cacheImages(
    imageUrl: variant.imageUrl,
    thumbnailUrl: variant.thumbnailUrl,
    for: variantUuid
)

owned.localImagePath = imagePath
owned.localThumbnailPath = thumbPath
```

**Cache Management**:
- `cacheSize()` - Total bytes used
- `formattedCacheSize()` - Human-readable size (e.g., "12.3 MB")
- `clearCache()` - Remove all cached images
- Auto-cleanup when variant removed from collection

### APIService (Deprecated)

### APIService (Deprecated)

**Status**: ~~Most functionality moved to BrowseService~~  
**Remaining**: Report submission only

**Purpose**: Submit data issue reports to API  
**Pattern**: Singleton with stateless methods

```swift
class APIService {
    static let shared = APIService()
    
    func submitReport(variantUuid: String, issueType: ReportIssueType, details: String?, suggestedCorrection: String?) async throws -> String
}
```

**Migration Notes**:
- `fetchCritters()` → `BrowseService.fetchCritters()`
- `fetchFamilies()` → `BrowseService.fetchFamilies()`
- Report functionality remains in APIService

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

### API Configuration

**Base URL**: `Config.apiBaseURL` (environment-based)
- **Debug**: `https://calicoprod.thetechnodro.me/api/v1`
- **Production**: `http://api.callicollection.com/api/v1`

**Endpoints**:
- `GET /critters?page={page}&per_page={perPage}&family={uuid}` - Browse critters (paginated)
- `GET /critters/{uuid}/variants` - Get critter variants for picker
- `GET /families` - Get all families with counts
- `GET /families/{uuid}` - Get family detail with critters
- `POST /variants/report` - Submit data issue report
- `GET /sets/barcode/{barcode}` - Barcode lookup (future)

### BackupManager (Updated in 2.5a)

**Purpose**: Import/export user collection and photos  
**Pattern**: Singleton with `@Published` state  
**Format**: ZIP archive with JSON manifest

**Note**: Does NOT include cached images. Images are re-downloaded from API URLs during import.

**Export Structure**:
```
CaliCollection_Backup_01-28-2026.zip
├── backup.json          (Collection metadata + image URLs)
└── photos/
    ├── {uuid}_{id}.jpg  (User-captured photos only)
    └── ...
```

**Backup Format** (JSON):
```swift
struct CollectionBackup: Codable {
    let exportDate: Date
    let appVersion: String
    let ownedVariants: [BackupVariant]  // Includes imageURL/thumbnailURL
    let photos: [BackupPhoto]           // User photos, not cached images
}
```

**Key Methods**:
- `exportCollection(ownedVariants:photos:appVersion:)` - Create ZIP backup
- `importCollection(from:into:)` - Restore from backup
- `formattedCacheSize()` - Display cache size (via ImagePersistenceService)

**Import Strategy**:
- Upsert logic: Update existing, insert new
- Photo deduplication by UUID
- **Image Re-caching**: Local image paths cleared; images re-downloaded on-demand
- Detailed import result reporting

**Changes in 2.5a**:
- Backup no longer includes cached variant images (only user photos)
- Import process clears `localImagePath`/`localThumbnailPath`
- Images automatically re-cached when user views variants
- Smaller backup file sizes

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
│   ├── User Collection/
│   │   ├── OwnedVariant.swift       (with local image paths)
│   │   ├── VariantPhoto.swift
│   │   └── Family.swift              (small cached dataset)
│   └── API Responses/
│       ├── BrowseResponses.swift     (paginated browse models)
│       ├── SetResponse.swift         (barcode scan models)
│       ├── FamilyResponse.swift
│       └── ReportRequest.swift
│
├── Services/
│   ├── BrowseService.swift           ⭐ NEW - Online browsing
│   ├── ImagePersistenceService.swift ⭐ NEW - Image caching
│   ├── SyncService.swift             (simplified - families only)
│   ├── APIService.swift              (deprecated - reports only)
│   ├── NetworkConfig.swift
│   ├── BackupManager.swift
│   └── ToastManager.swift
│
├── Views/
│   ├── ContentView.swift
│   ├── FirstSyncView.swift           (now families only)
│   ├── CollectionView.swift          (offline-capable)
│   ├── WishlistView.swift            (offline-capable)
│   ├── BrowseView.swift              ⭐ NEW - Online browse with pagination
│   ├── VariantPickerView.swift       ⭐ NEW - Select variant when adding
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

### Key Structural Changes in 2.5a

**Removed**:
- `Critter.swift` - No longer cached locally
- `CritterVariant.swift` - No longer cached locally
- `CritterResponse.swift` - Replaced by `BrowseResponses.swift`
- `SearchView.swift` - Replaced by `BrowseView.swift`

**Added**:
- `BrowseService.swift` - Online browsing with pagination
- `ImagePersistenceService.swift` - Local image caching
- `BrowseResponses.swift` - Paginated API response models
- `BrowseView.swift` - Modern paginated browse UI
- `VariantPickerView.swift` - Choose specific variant

### Organizational Principles

1. **Service-Driven Architecture**: Services own business logic
2. **API Response Models**: Separate from persistent models
3. **View Simplification**: Views consume services, minimal business logic
4. **Shared Utilities**: Common code in Utilities folder

---

## Data Flow

### Browse Flow (NEW in 2.5a)

```
User Opens BrowseView
      │
      ▼
BrowseService.fetchCritters(page: 1)
      │
      ├─► NetworkConfig.performRequest()
      │   └─► Auto-retry on failure
      │
      ├─► Parse BrowseCrittersAPIResponse
      │   ├─► data: [BrowseCritter]
      │   └─► meta: PaginationMeta (current_page, total_pages, etc.)
      │
      └─► Display in paginated grid
            │
            ├─► User scrolls to end → Load next page
            ├─► User taps critter → Fetch variants
            │         │
            │         ▼
            │   BrowseService.fetchCritterVariants(uuid)
            │         │
            │         └─► Show VariantPickerView
            │               │
            │               └─► User selects variant → Add to collection
            │
            └─► No local caching (always fresh from API)
```

### Sync Flow (Simplified in 2.5a)

```
User Triggers Sync (Families Only)
      │
      ▼
SyncService.syncFamilies()
      │
      ├─► Check needsSync
      │   └─► Skip if recent (unless forced)
      │
      ├─► BrowseService.fetchFamilies()
      │   │
      │   ├─► NetworkConfig.performRequest()
      │   │   └─► Auto-retry on failure
      │   │
      │   └─► Parse [FamilyBrowseResponse]
      │
      ├─► ModelContext Operations
      │   ├─► Delete existing Family models
      │   ├─► Insert new families (~100 items)
      │   └─► Save (single batch operation)
      │
      ├─► Update lastSyncDate
      │
      └─► ToastManager.show("✓ Synced X families")

NOTE: Critters/variants NO LONGER synced.
      Fetched on-demand via BrowseService.
```

### Add to Collection Flow (Updated in 2.5a)

```
User Taps "Add to Collection" on Variant
      │
      ▼
OwnedVariant.create(from: variantResponse, status: .collection)
      │
      ├─► ImagePersistenceService.cacheImages()  ⭐ NEW
      │   │
      │   ├─► Download full image (async)
      │   ├─► Download thumbnail (async)
      │   ├─► Save to Documents/CachedImages/
      │   └─► Return local file paths
      │
      ├─► Check if already exists
      │   ├─► YES: Update status + image paths
      │   └─► NO:  Create new OwnedVariant with local paths
      │
      ├─► ModelContext.save()
      │
      └─► SwiftUI auto-updates via @Query
            │
            └─► Variant appears in CollectionView with cached images
```

**Key Change**: Images automatically cached during add process for offline access.

### Image Loading Flow (Updated in 2.5a)

**For OwnedVariants (Collection/Wishlist)**:
```
View displays OwnedVariant
      │
      ├─► Check hasLocalImages
      │   │
      │   ├─► YES: Load from local cache
      │   │   └─► Image(uiImage: ImagePersistenceService.loadCachedImage())
      │   │
      │   └─► NO: Fallback to remote URL
      │       └─► AsyncImage(url: variant.thumbnailURL)
```

**For Browse Results (Online Only)**:
```
AsyncImage(url: variant.thumbnailURL)
      │
      ├─► URLSession downloads image
      ├─► SwiftUI caches in memory (temporary)
      └─► Renders placeholder while loading
```

**Key Difference**:
- **Collection/Wishlist**: Persistent local cache for offline access
- **Browse**: Temporary memory cache, requires internet

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

### Database Performance (Simplified in 2.5a)

**Reduced Storage Footprint**:
- SwiftData now stores only user data (~50-500 items) vs. entire catalog (10,000+ items)
- Family cache: ~100 items (minimal impact)
- Faster app launch (no large dataset queries)
- Smaller iCloud sync payload (if enabled)

**Batch Operations** (Family sync only):
```swift
// Insert all families before saving
for response in familyResponses {
    let family = Family(from: response)
    modelContext.insert(family)
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
- Small dataset (user's collection only)
- Index on unique variantUuid
- Predicate pushdown to database level

**Delete Performance**:
```swift
try modelContext.delete(model: Family.self)  // Batch delete ~100 items
```

### Network Performance (Enhanced in 2.5a)

**Pagination** (NEW):
- Browse critters in pages (default 30 items)
- Reduces initial load time
- Lower memory footprint
- Incremental loading as user scrolls

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
- Images (Browse): SwiftUI AsyncImage memory cache (temporary)
- Images (Collection): Persistent file cache via ImagePersistenceService
- Families: Local SwiftData cache (refreshed weekly)

**Parallel Operations**:
```swift
// Download image + thumbnail concurrently
async let imagePath = cacheImage(from: imageUrl, for: uuid)
async let thumbPath = cacheImage(from: thumbnailUrl, for: "\(uuid)_thumb")
return try await (imagePath, thumbPath)
```

### UI Performance (Improved in 2.5a)

**Lazy Loading**:
- Browse: LazyVGrid with pagination (load as you scroll)
- Collection: LazyVGrid with small dataset (fast rendering)
- Only visible items rendered

**Image Loading**:
```swift
// Collection (offline-capable)
if let cachedImage = ImagePersistenceService.shared.loadCachedThumbnail(for: uuid) {
    Image(uiImage: cachedImage)  // Instant load from disk
} else {
    AsyncImage(url: thumbnailURL)  // Fallback to remote
}

// Browse (online only)
AsyncImage(url: thumbnailURL) { image in
    image.resizable().aspectRatio(contentMode: .fit)
} placeholder: {
    ProgressView()
}
```
- **Collection**: Instant load from cache (no network delay)
- **Browse**: Asynchronous loading doesn't block UI
- Thumbnail URLs reduce data transfer
- Automatic memory management

**State Management**:
- `@Published` only on properties that affect UI
- Minimize unnecessary view updates
- Use `@MainActor` to ensure UI updates on main thread
- Pagination state prevents loading entire catalog at once

**Memory Management**:
- Browse images: Temporary memory cache (SwiftUI managed)
- Collection images: File cache (persistent, managed by service)
- Old cache files cleaned up when variant removed

### Sync Performance (Dramatically Improved in 2.5a)

**Minimal Sync Scope**:
- Only families synced (~100 items vs. 10,000+ critters/variants)
- Sync time reduced from 30-60 seconds to <2 seconds
- Lower bandwidth usage
- Reduced server load

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

**No Image URL Refresh Needed**:
- ~~Removed: Image URL sync for OwnedVariants~~
- Images cached locally, independent of sync
- Simpler sync logic, fewer operations

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
6. **Separation of Concerns**: API models ≠ persistent models

### SwiftData Usage (Updated in 2.5a)

1. **User Data Only**: Only persist user-owned data, not API catalogs
2. **Unique Constraints**: Always use on identifiers
3. **Batch Operations**: Insert all, save once
4. **Query Predicates**: Push filtering to database
5. **File References**: Store local paths for cached images

**Anti-Pattern** (OLD):
```swift
// DON'T cache entire API catalog
@Model class Critter { ... }  // 10,000+ items
```

**Best Practice** (NEW):
```swift
// DO fetch on-demand from API
BrowseService.fetchCritters(page: 1)  // Paginated, fresh data
```

### Networking (Updated in 2.5a)

1. **Retry Logic**: Handle transient failures
2. **Timeout Configuration**: Prevent hanging
3. **Structured Responses**: Codable DTOs
4. **Error Mapping**: Convert network errors to domain errors
5. **Pagination**: Use for large datasets (BrowseService)
6. **Image Caching**: Persist locally for offline access

### UI Patterns (Updated in 2.5a)

1. **Hybrid Data Sources**: 
   - **Collection/Wishlist**: SwiftData @Query (offline-capable)
   - **Browse**: API service (online-only, paginated)
2. **Reactive Updates**: @Query auto-updates collection views
3. **Loading States**: Show progress during async operations
4. **Error Feedback**: Toast notifications for non-critical errors
5. **Offline Handling**: Graceful degradation when offline
6. **Image Strategy**:
   - Browse: AsyncImage with memory cache
   - Collection: Cached UIImage with remote fallback

---

## Future Considerations

### Scalability

- ✅ **Pagination**: Implemented in v2.5a (BrowseService)
- ✅ **Offline Collection**: Implemented with image caching
- **Background Sync**: Automatic sync on app launch
- **Push Notifications**: Server-side update notifications
- **CloudKit Sync**: Cross-device collection sync
- **Image CDN**: Faster image delivery globally

### Features

- **Advanced Search**: Full-text search across critters/variants
- **Barcode Scanning**: Add items via barcode (API ready)
- **Statistics**: Collection value, completion percentage
- **Social Features**: Share collections, friend lists
- **Sets & Themes**: Browse by product sets/epochs
- **Wishlist Alerts**: Notify when wishlist items on sale

### Technical Improvements

- **Offline Browse**: Cache recent browse results for offline viewing
- **Image Optimization**: WebP support, progressive loading
- **Search Debouncing**: Reduce API calls during typing
- **Prefetching**: Preload next page during pagination
- **Better Error Recovery**: Offline queue for failed operations

### Technical Debt (Updated in 2.5a)

- **Unit Test Coverage**: Expand beyond OwnedVariantTests
  - Add tests for BrowseService
  - Add tests for ImagePersistenceService
  - Mock network responses for deterministic testing
- **UI Tests**: Critical user flows
  - Browse → Add to Collection flow
  - Image caching verification
  - Offline collection viewing
- **Migration Testing**: Ensure smooth upgrade from 2.1a → 2.5a
  - Old users had cached critters (now removed)
  - Verify no data loss during migration
- **Image Cache Limits**: Currently unlimited growth
  - Consider max cache size (e.g., 500 MB)
  - LRU eviction strategy for old images
- **API Error Handling**: More granular error types
  - Better offline detection
  - Retry with user confirmation

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

- **2.5a**: Major architectural refactor (January 2026)
  - 🎯 **Online-first browsing**: Removed Critter/CritterVariant local cache
  - 📄 **Pagination**: BrowseService with paginated API calls
  - 💾 **Image caching**: ImagePersistenceService for offline collection access
  - ⚡ **Faster sync**: Only families synced (~100 items vs. 10,000+)
  - 🎨 **Variant picker**: Select specific variant when adding to collection
  - 📦 **Smaller footprint**: Reduced app storage by ~90%
  - 🔄 **Simplified architecture**: Eliminated dual-storage complexity
  
- **2.1a**: SwiftData migration (December 2025)
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

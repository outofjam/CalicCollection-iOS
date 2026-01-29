# LottaPaws Theme

Drop-in theming system for LottaPaws iOS app.

## Quick Start

### 1. Add files to Xcode
Copy all `.swift` files to your project in a `Theme/` group.

### 2. Configure in App file

```swift
@main
struct LottaPawsApp: App {
    init() {
        configureLottaPawsAppearance()
        configureLottaPawsRefreshControl()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .lottaPawsStyle()
        }
    }
}
```

## Components

### Buttons
```swift
Button("Add to Collection") { }.buttonStyle(.primary)
Button("Add to Wishlist") { }.buttonStyle(.secondary)
Button("Skip") { }.buttonStyle(.tertiary)
Button { } label: { Image(systemName: "heart") }.buttonStyle(.icon)
```

### Cards
```swift
LPCard { /* content */ }                    // Shadow card
LPSoftCard { /* content */ }                // Tinted background
LPGradientCard { /* content */ }            // Gradient background
```

### Badges
```swift
MemberTypeBadge(memberType: "Mother")       // Auto-colored by type
StatusBadge(status: .collection)            // Collection/wishlist/owned
FamilyCompletionBadge(owned: 3, total: 5)   // Progress badge
LPBadge(text: "New", color: .successGreen)  // Generic badge
```

### Text
```swift
Text("Title").lpTextStyle(.title1)
Text("Body").lpTextStyle(.body)
LPText("Caption", style: .caption)
```

### Inputs
```swift
LPSearchBar(text: $searchText)
LPTextField(label: "Name", text: $name)
LPToggleRow(title: "Notifications", isOn: $enabled)
LPSegmentedPicker(selection: $tab, options: tabs)
LPChipGroup(selection: $filter, options: filters)
```

### Grid/List Items
```swift
LPGridItem(imageURL: url, title: "Name", subtitle: "Family") { }
LPListItem(imageURL: url, title: "Name", memberType: "Baby") { }
LPHeroImage(imageURL: url, onExpand: { })
```

### Loading
```swift
LPLoadingSpinner()
LPLoadingView(title: "Loading...")
LPProgressBar(progress: 0.5)
LPCircularProgress(progress: 0.75)
LPGridItemSkeleton()  // Placeholder
```

### Layout
```swift
LPSectionHeader(title: "My Section", action: { })
LPStatGroup(stats: [(value: "42", label: "Owned")])
LPInfoRow(label: "Year", value: "2024")
LPEmptyState(icon: "heart.slash", title: "Empty", message: "...")
LPDivider()
```

## Color Reference

| Purpose | Color |
|---------|-------|
| Primary actions | `.primaryPink` |
| Secondary actions | `.secondaryBlue` |
| Success/owned | `.successGreen` |
| Warning | `.warningYellow` |
| Error | `.errorRed` |
| Primary text | `.textPrimary` |
| Secondary text | `.textSecondary` |
| Tertiary text | `.textTertiary` |
| Main background | `.backgroundPrimary` |
| Card background | `.backgroundSecondary` |
| Borders | `.borderColor` |

## Gradients

```swift
LinearGradient.lottaGradient  // Pink to blue diagonal
LinearGradient.pinkGradient   // Horizontal pink
LinearGradient.blueGradient   // Horizontal blue
```

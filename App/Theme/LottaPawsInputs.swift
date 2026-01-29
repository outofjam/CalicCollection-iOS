import SwiftUI

// MARK: - Search Bar

/// Styled search bar
struct LPSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"
    var onSubmit: (() -> Void)? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: LottaPawsTheme.spacingSM) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.textTertiary)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(.textPrimary)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    onSubmit?()
                }
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .padding(.horizontal, LottaPawsTheme.spacingMD)
        .padding(.vertical, LottaPawsTheme.spacingSM + 2)
        .background(Color.backgroundSecondary)
        .cornerRadius(LottaPawsTheme.radiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                .stroke(isFocused ? Color.primaryPink : Color.clear, lineWidth: 1.5)
        )
        .animation(LottaPawsTheme.animationQuick, value: isFocused)
    }
}

// MARK: - Text Field

/// Styled text field
struct LPTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: LottaPawsTheme.spacingSM) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textSecondary)
            
            HStack(spacing: LottaPawsTheme.spacingSM) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.textTertiary)
                        .frame(width: 20)
                }
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.textPrimary)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.textPrimary)
                        .keyboardType(keyboardType)
                        .focused($isFocused)
                }
            }
            .padding(.horizontal, LottaPawsTheme.spacingMD)
            .padding(.vertical, LottaPawsTheme.spacingMD)
            .background(Color.backgroundSecondary)
            .cornerRadius(LottaPawsTheme.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                    .stroke(isFocused ? Color.primaryPink : Color.borderColor, lineWidth: 1)
            )
            .animation(LottaPawsTheme.animationQuick, value: isFocused)
        }
    }
}

// MARK: - Picker / Dropdown

/// Styled dropdown picker
struct LPPicker<T: Hashable>: View where T: CustomStringConvertible {
    let label: String
    @Binding var selection: T
    let options: [T]
    var icon: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: LottaPawsTheme.spacingSM) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textSecondary)
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option.description) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(.textTertiary)
                    }
                    
                    Text(selection.description)
                        .font(.system(size: 16))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textTertiary)
                }
                .padding(.horizontal, LottaPawsTheme.spacingMD)
                .padding(.vertical, LottaPawsTheme.spacingMD)
                .background(Color.backgroundSecondary)
                .cornerRadius(LottaPawsTheme.radiusMD)
                .overlay(
                    RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Toggle Row

/// Styled toggle/switch row
struct LPToggleRow: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: LottaPawsTheme.spacingMD) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.primaryPink)
                    .frame(width: 28)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(.primaryPink)
                .labelsHidden()
        }
        .padding(.vertical, LottaPawsTheme.spacingSM)
    }
}

// MARK: - Segmented Control

/// Styled segmented picker
struct LPSegmentedPicker<T: Hashable>: View where T: CustomStringConvertible {
    @Binding var selection: T
    let options: [T]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(LottaPawsTheme.animationSpring) {
                        selection = option
                    }
                } label: {
                    Text(option.description)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selection == option ? .white : .textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, LottaPawsTheme.spacingSM + 2)
                        .background(
                            selection == option ?
                            Capsule().fill(Color.primaryPink) :
                            Capsule().fill(Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.backgroundSecondary)
        .cornerRadius(LottaPawsTheme.radiusFull)
    }
}

// MARK: - Chip / Filter Chip

/// Selectable filter chip
struct LPChip: View {
    let label: String
    var isSelected: Bool = false
    var icon: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(label)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isSelected ? .white : .textSecondary)
            .padding(.horizontal, LottaPawsTheme.spacingMD)
            .padding(.vertical, LottaPawsTheme.spacingSM)
            .background(
                Capsule()
                    .fill(isSelected ? Color.primaryPink : Color.backgroundSecondary)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Horizontal scrolling chip group
struct LPChipGroup<T: Hashable>: View where T: CustomStringConvertible {
    @Binding var selection: T?
    let options: [T]
    var allowDeselection: Bool = true
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LottaPawsTheme.spacingSM) {
                ForEach(options, id: \.self) { option in
                    LPChip(
                        label: option.description,
                        isSelected: selection == option
                    ) {
                        withAnimation(LottaPawsTheme.animationQuick) {
                            if selection == option && allowDeselection {
                                selection = nil
                            } else {
                                selection = option
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, LottaPawsTheme.spacingLG)
        }
    }
}

// MARK: - Usage Examples
/*
 
 // Search bar
 @State var searchText = ""
 LPSearchBar(text: $searchText, placeholder: "Search critters...")
 
 // Text field
 @State var name = ""
 LPTextField(label: "Name", text: $name, placeholder: "Enter name", icon: "person")
 
 // Secure field
 LPTextField(label: "Password", text: $password, icon: "lock", isSecure: true)
 
 // Picker
 @State var selectedFamily: String = "All"
 LPPicker(label: "Family", selection: $selectedFamily, options: ["All", "Rabbit", "Cat"])
 
 // Toggle row
 @State var notificationsEnabled = true
 LPToggleRow(
     title: "Push Notifications",
     subtitle: "Get notified about new releases",
     isOn: $notificationsEnabled,
     icon: "bell.fill"
 )
 
 // Segmented picker
 enum Tab: String, CustomStringConvertible {
     case collection, wishlist
     var description: String { rawValue.capitalized }
 }
 @State var selectedTab: Tab = .collection
 LPSegmentedPicker(selection: $selectedTab, options: [.collection, .wishlist])
 
 // Filter chips
 @State var selectedFilter: String? = nil
 LPChipGroup(selection: $selectedFilter, options: ["All", "Owned", "Missing"])
 
 */

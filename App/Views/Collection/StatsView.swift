import SwiftUI
import SwiftData

struct StatsView: View {
    let variants: [OwnedVariant]
    
    @Query private var cachedFamilies: [Family]
    
    // Computed stats
    private var totalVariantsCollected: Int {
        variants.count
    }
    
    private var totalCrittersCollected: Int {
        Set(variants.map { $0.critterUuid }).count
    }
    
    private var familyBreakdown: [(family: String, familyId: String, collected: Int, total: Int, percentage: Double)] {
        // Get unique critters collected by family
        let collectedByFamily = Dictionary(grouping: variants) { $0.familyId }
            .mapValues { variants in
                Set(variants.map { $0.critterUuid }).count
            }
        
        // Build breakdown with totals from cached families
        var breakdown: [(family: String, familyId: String, collected: Int, total: Int, percentage: Double)] = []
        
        for (familyId, collectedCount) in collectedByFamily {
            // Find the family name from variants (since we group by familyId)
            let familyName = variants.first { $0.familyId == familyId }?.familyName ?? "Unknown"
            
            // Get total critters from cached family data
            let totalCritters = cachedFamilies.first { $0.uuid == familyId }?.crittersCount ?? collectedCount
            
            let percentage = totalCritters > 0 ? Double(collectedCount) / Double(totalCritters) : 0
            
            breakdown.append((familyName, familyId, collectedCount, totalCritters, min(percentage, 1.0)))
        }
        
        return breakdown.sorted { $0.percentage > $1.percentage }
    }
    
    private var memberTypeBreakdown: [(type: String, collected: Int, percentage: Double)] {
        // Get unique critters collected by member type
        let collectedCrittersByType = Dictionary(grouping: variants) { $0.memberType }
            .mapValues { variants in
                Set(variants.map { $0.critterUuid }).count
            }
        
        return collectedCrittersByType.map { type, collected in
            let percentage = totalCrittersCollected > 0 ? Double(collected) / Double(totalCrittersCollected) : 0
            return (type, collected, percentage)
        }
        .sorted { $0.collected > $1.collected }
    }
    
    private var earliestAdded: OwnedVariant? {
        variants.min(by: { $0.addedDate < $1.addedDate })
    }
    
    private var latestAdded: OwnedVariant? {
        variants.max(by: { $0.addedDate < $1.addedDate })
    }
    
    // Overall completion
    private var overallCompletion: (collected: Int, total: Int, percentage: Double) {
        let totalCrittersInOwnedFamilies = familyBreakdown.reduce(0) { $0 + $1.total }
        let percentage = totalCrittersInOwnedFamilies > 0 ? Double(totalCrittersCollected) / Double(totalCrittersInOwnedFamilies) : 0
        return (totalCrittersCollected, totalCrittersInOwnedFamilies, min(percentage, 1.0))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Overall Stats
                VStack(spacing: 8) {
                    Text("\(totalCrittersCollected)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Unique Critters")
                        .font(.title3)
                        .foregroundColor(.calicoTextSecondary)
                    
                    Text("\(totalVariantsCollected) total variants")
                        .font(.caption)
                        .foregroundColor(.calicoTextSecondary)
                }
                .padding(.top)
                
                // Overall completion for families you've started
                if !familyBreakdown.isEmpty {
                    let overall = overallCompletion
                    VStack(spacing: 8) {
                        HStack {
                            Text("Family Completion")
                                .font(.subheadline)
                                .foregroundColor(.calicoTextSecondary)
                            Spacer()
                            Text("\(overall.collected) of \(overall.total)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * overall.percentage, height: 12)
                            }
                        }
                        .frame(height: 12)
                        
                        Text("\(Int(overall.percentage * 100))% complete across \(familyBreakdown.count) families")
                            .font(.caption)
                            .foregroundColor(.calicoTextSecondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.05))
                    )
                }
                
                Divider()
                
                // MARK: - Family Breakdown
                VStack(alignment: .leading, spacing: 16) {
                    Text("By Family")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if familyBreakdown.isEmpty {
                        Text("No families yet")
                            .foregroundColor(.calicoTextSecondary)
                    } else {
                        ForEach(familyBreakdown, id: \.familyId) { item in
                            FamilyStatRow(
                                family: item.family,
                                collected: item.collected,
                                total: item.total,
                                percentage: item.percentage
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // MARK: - Member Type Breakdown
                VStack(alignment: .leading, spacing: 16) {
                    Text("By Member Type")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if memberTypeBreakdown.isEmpty {
                        Text("No member types yet")
                            .foregroundColor(.calicoTextSecondary)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 16) {
                            ForEach(memberTypeBreakdown, id: \.type) { item in
                                MemberTypeStatCard(
                                    type: item.type,
                                    collected: item.collected,
                                    percentage: item.percentage
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // MARK: - Timeline
                VStack(alignment: .leading, spacing: 16) {
                    Text("Timeline")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let earliest = earliestAdded {
                        TimelineItem(title: "First Added", variant: earliest)
                    }
                    
                    if let latest = latestAdded, latest.variantUuid != earliestAdded?.variantUuid {
                        TimelineItem(title: "Latest Added", variant: latest)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }
}

// MARK: - Family Stat Row
private struct FamilyStatRow: View {
    let family: String
    let collected: Int
    let total: Int
    let percentage: Double
    
    private var isComplete: Bool { collected >= total }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(family)
                    .font(.headline)
                
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                Spacer()
                
                Text("\(collected) of \(total)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isComplete ? .green : .primary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            isComplete
                                ? LinearGradient(colors: [.green, .green], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.blue, .pink], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(percentage * 100))% complete")
                .font(.caption)
                .foregroundColor(isComplete ? .green : .calicoTextSecondary)
        }
    }
}

// MARK: - Member Type Stat Card
private struct MemberTypeStatCard: View {
    let type: String
    let collected: Int
    let percentage: Double
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(percentage * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 2) {
                Text(type.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(collected) critters")
                    .font(.caption)
                    .foregroundColor(.calicoTextSecondary)
            }
        }
    }
}

// MARK: - Timeline Item
private struct TimelineItem: View {
    let title: String
    let variant: OwnedVariant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.calicoTextSecondary)
            
            HStack(spacing: 12) {
                VariantThumbnail(variant: variant, size: 50)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(variant.variantName)
                        .font(.headline)
                    Text(variant.critterName)
                        .font(.subheadline)
                        .foregroundColor(.calicoTextSecondary)
                    Text(variant.addedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.calicoTextSecondary)
                }
            }
        }
    }
}

// MARK: - Variant Thumbnail (supports local + remote)
private struct VariantThumbnail: View {
    let variant: OwnedVariant
    let size: CGFloat
    
    var body: some View {
        Group {
            // Try local cached image first
            if let localPath = variant.localThumbnailPath,
               let uiImage = UIImage(contentsOfFile: localPath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            // Fall back to remote URL
            else if let urlString = variant.thumbnailURL ?? variant.imageURL,
                    let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .overlay {
                Image(systemName: "photo")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
    }
}

#Preview {
    StatsView(variants: [])
}

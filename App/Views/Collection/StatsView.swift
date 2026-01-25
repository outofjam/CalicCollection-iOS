import SwiftUI
import SwiftData

struct StatsView: View {
    let variants: [OwnedVariant]
    
    @Query private var allVariants: [CritterVariant]
    @Query private var allCritters: [Critter]
    
    // Computed stats
    private var totalCollected: Int {
        variants.count
    }
    
    private var familyBreakdown: [(family: String, collected: Int, total: Int, completion: Double)] {
        // Get unique critters collected by family
        let collectedCrittersByFamily = Dictionary(grouping: variants) { $0.familyName ?? "Unknown" }
            .mapValues { variants in
                Set(variants.map { $0.critterUuid }).count
            }
        
        // Get total critters by family
        let totalCrittersByFamily = Dictionary(grouping: allCritters) { $0.familyName ?? "Unknown" }
            .mapValues { $0.count }
        
        // Combine
        return collectedCrittersByFamily.map { family, collected in
            let total = totalCrittersByFamily[family] ?? collected
            let completion = total > 0 ? Double(collected) / Double(total) : 0
            
            return (family, collected, total, completion)
        }
        .sorted { $0.collected > $1.collected }
    }
    
    private var memberTypeBreakdown: [(type: String, collected: Int, total: Int, percentage: Double)] {
        // Get unique critters collected by member type
        let collectedCrittersByType = Dictionary(grouping: variants) { $0.memberType }
            .mapValues { variants in
                Set(variants.map { $0.critterUuid }).count
            }
        
        // Get total critters by member type
        let totalCrittersByType = Dictionary(grouping: allCritters) { $0.memberType }
            .mapValues { $0.count }
        
        // Combine
        let allTypes = Set(collectedCrittersByType.keys).union(totalCrittersByType.keys)
        
        return allTypes.map { type in
            let collected = collectedCrittersByType[type] ?? 0
            let total = totalCrittersByType[type] ?? collected
            let percentage = total > 0 ? Double(collected) / Double(total) : 0
            return (type, collected, total, percentage)
        }
        .sorted { $0.collected > $1.collected }
    }
    
    private var earliestAdded: OwnedVariant? {
        variants.min(by: { $0.addedDate < $1.addedDate })
    }
    
    private var latestAdded: OwnedVariant? {
        variants.max(by: { $0.addedDate < $1.addedDate })
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Total Collected
                VStack(spacing: 8) {
                    Text("\(totalCollected)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Critters Collected")
                        .font(.title3)
                        .foregroundColor(.calicoTextSecondary)
                }
                .padding(.top)
                
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
                        ForEach(familyBreakdown, id: \.family) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(item.family)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(item.collected)/\(item.total) critters")
                                        .font(.subheadline)
                                        .foregroundColor(.calicoTextSecondary)
                                }
                                
                                // Progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 8)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.blue, .pink],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geometry.size.width * item.completion, height: 8)
                                    }
                                }
                                .frame(height: 8)
                                
                                Text("\(Int(item.completion * 100))% complete")
                                    .font(.caption)
                                    .foregroundColor(.calicoTextSecondary)
                            }
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
                                VStack(spacing: 8) {
                                    // Mini pie chart
                                    ZStack {
                                        Circle()
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                            .frame(width: 80, height: 80)
                                        
                                        Circle()
                                            .trim(from: 0, to: item.percentage)
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
                                        
                                        Text("\(Int(item.percentage * 100))%")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                    }
                                    
                                    VStack(spacing: 2) {
                                        Text(item.type)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("\(item.collected)/\(item.total)")
                                            .font(.caption)
                                            .foregroundColor(.calicoTextSecondary)
                                    }
                                }
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
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Earliest Added")
                                .font(.caption)
                                .foregroundColor(.calicoTextSecondary)
                            
                            HStack(spacing: 12) {
                                // Use thumbnail for timeline images
                                if let urlString = earliest.thumbnailURL ?? earliest.imageURL,
                                   let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 50, height: 50)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        default:
                                            placeholderImage
                                        }
                                    }
                                } else {
                                    placeholderImage
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(earliest.variantName)
                                        .font(.headline)
                                    Text(earliest.critterName)
                                        .font(.subheadline)
                                        .foregroundColor(.calicoTextSecondary)
                                    Text(earliest.addedDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.calicoTextSecondary)
                                }
                            }
                        }
                    }
                    
                    if let latest = latestAdded {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latest Added")
                                .font(.caption)
                                .foregroundColor(.calicoTextSecondary)
                            
                            HStack(spacing: 12) {
                                // Use thumbnail for timeline images
                                if let urlString = latest.thumbnailURL ?? latest.imageURL,
                                   let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 50, height: 50)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        default:
                                            placeholderImage
                                        }
                                    }
                                } else {
                                    placeholderImage
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(latest.variantName)
                                        .font(.headline)
                                    Text(latest.critterName)
                                        .font(.subheadline)
                                        .foregroundColor(.calicoTextSecondary)
                                    Text(latest.addedDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.calicoTextSecondary)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 50, height: 50)
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

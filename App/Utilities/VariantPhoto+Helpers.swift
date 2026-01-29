import SwiftUI
import SwiftData

extension View {
    func getFirstPhoto(for variantUuid: String, context: ModelContext) -> VariantPhoto? {
        let descriptor = FetchDescriptor<VariantPhoto>(
            predicate: #Predicate { $0.variantUuid == variantUuid },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        
        return try? context.fetch(descriptor).first
    }
    
    func hasPhotos(for variantUuid: String, context: ModelContext) -> Bool {
        getFirstPhoto(for: variantUuid, context: context) != nil
    }
}

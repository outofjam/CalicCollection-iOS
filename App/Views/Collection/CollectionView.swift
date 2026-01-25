import SwiftUI
import SwiftData

struct CollectionView: View {
    var body: some View {
        OwnedVariantsView(
            status: .collection,
            title: "Collection",
            emptyIcon: "star",
            emptyDescription: "Critters you add to your collection will appear here"
        )
    }
}

#Preview {
    CollectionView()
        .modelContainer(for: OwnedVariant.self, inMemory: true)
}

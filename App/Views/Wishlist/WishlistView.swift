import SwiftUI
import SwiftData

struct WishlistView: View {
    var body: some View {
        OwnedVariantsView(
            status: .wishlist,
            title: "Wishlist",
            emptyIcon: "heart",
            emptyDescription: "Variants you add to your wishlist will appear here"
        )
    }
}

#Preview {
    WishlistView()
        .modelContainer(for: OwnedVariant.self, inMemory: true)
}

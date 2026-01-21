import Foundation

/// Status of a critter variant in user's collection
enum CritterStatus: String, Codable {
    case collection = "collection"
    case wishlist = "wishlist"
}

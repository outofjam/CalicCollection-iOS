// In Critter.swift or create CritterExtensions.swift

extension Array where Element == CritterVariant {
    /// Get the primary variant, or first variant if no primary exists
    func primaryOrFirst() -> CritterVariant? {
        // First try to find a primary variant
        if let primary = self.first(where: { $0.isPrimary == true }) {
            return primary
        }
        // Fall back to first variant
        return self.first
    }
}

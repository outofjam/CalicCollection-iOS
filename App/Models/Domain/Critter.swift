import Foundation
import SwiftData

/// Browse cache: Base critter template (temporary, synced from API)
@Model
final class Critter {
    @Attribute(.unique) var uuid: String
    var familyId: String
    var name: String
    var memberType: String
    var role: String?
    var barcode: String?
    var familyName: String?
    var familySpecies: String?
    var variantsCount: Int
    var lastSynced: Date
    
    init(
        uuid: String,
        familyId: String,
        name: String,
        memberType: String,
        role: String? = nil,
        barcode: String? = nil,
        familyName: String? = nil,
        familySpecies: String? = nil,
        variantsCount: Int = 0,
        lastSynced: Date = Date()
    ) {
        self.uuid = uuid
        self.familyId = familyId
        self.name = name
        self.memberType = memberType
        self.role = role
        self.barcode = barcode
        self.familyName = familyName
        self.familySpecies = familySpecies
        self.variantsCount = variantsCount
        self.lastSynced = lastSynced
    }
    
    /// Create from API response
    convenience init(from response: CritterResponse) {
        self.init(
            uuid: response.uuid,
            familyId: response.familyId,
            name: response.name,
            memberType: response.memberType,
            role: response.role,
            barcode: response.barcode,
            familyName: response.family?.name,
            familySpecies: response.family?.species,
            variantsCount: response.variantsCount
        )
    }
}

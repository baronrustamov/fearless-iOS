import Foundation
import FearlessUtils
import BigInt

struct CreatePoolCall: Codable {
    @StringCodable var amount: BigUInt
    let root: MultiAddress
    let nominator: MultiAddress
    let stateToggler: MultiAddress
}

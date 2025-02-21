import Foundation
import IrohaCrypto

final class NominatorPayoutInfoFactory: PayoutInfoFactoryProtocol {
    let addressPrefix: UInt16
    let precision: Int16
    let addressFactory: SS58AddressFactoryProtocol

    init(addressPrefix: UInt16, precision: Int16, addressFactory: SS58AddressFactoryProtocol) {
        self.precision = precision
        self.addressPrefix = addressPrefix
        self.addressFactory = addressFactory
    }

    func calculate(
        for accountId: AccountId,
        era: EraIndex,
        validatorInfo: EraValidatorInfo,
        erasRewardDistribution: ErasRewardDistribution,
        identities: [AccountAddress: AccountIdentity]
    ) throws -> PayoutInfo? {
        guard
            let totalRewardAmount = erasRewardDistribution.totalValidatorRewardByEra[era],
            let totalReward = Decimal.fromSubstrateAmount(totalRewardAmount, precision: precision),
            let points = erasRewardDistribution.validatorPointsDistributionByEra[era] else {
            return nil
        }

        guard
            let nominatorStakeAmount = validatorInfo.exposure.others
            .first(where: { $0.who == accountId })?.value,
            let nominatorStake = Decimal
            .fromSubstrateAmount(nominatorStakeAmount, precision: precision),
            let comission = Decimal.fromSubstratePerbill(value: validatorInfo.prefs.commission),
            let validatorPoints = points.individual
            .first(where: { $0.accountId == validatorInfo.accountId })?.rewardPoint,
            let totalStake = Decimal
            .fromSubstrateAmount(validatorInfo.exposure.total, precision: precision) else {
            return nil
        }

        let rewardFraction = Decimal(validatorPoints) / Decimal(points.total)
        let validatorTotalReward = totalReward * rewardFraction
        let nominatorReward = validatorTotalReward * (1 - comission) *
            (nominatorStake / totalStake)

        let validatorAddress = try addressFactory
            .addressFromAccountId(data: validatorInfo.accountId, addressPrefix: addressPrefix)

        return PayoutInfo(
            era: era,
            validator: validatorInfo.accountId,
            reward: nominatorReward,
            identity: identities[validatorAddress]
        )
    }
}

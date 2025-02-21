import Foundation
import CommonWallet
import IrohaCrypto

extension SubscanRewardItemData: WalletRemoteHistoryItemProtocol {
    var identifier: String { "\(recordId)-\(eventIndex)" }
    var itemBlockNumber: UInt64 { blockNumber }
    var itemExtrinsicIndex: UInt16 { extrinsicIndex }
    var itemTimestamp: Int64 { timestamp }
    var label: WalletRemoteHistorySourceLabel { .rewards }

    func createTransactionForAddress(
        _ address: String,
        chain: ChainModel,
        asset: AssetModel,
        addressFactory _: SS58AddressFactoryProtocol
    ) -> AssetTransactionData {
        AssetTransactionData.createTransaction(
            from: self,
            address: address,
            chain: chain,
            asset: asset
        )
    }
}

extension SubscanTransferItemData: WalletRemoteHistoryItemProtocol {
    var identifier: String { hash }
    var itemBlockNumber: UInt64 { blockNumber }
    var itemExtrinsicIndex: UInt16 { extrinsicIndex.value }
    var itemTimestamp: Int64 { timestamp }
    var label: WalletRemoteHistorySourceLabel { .transfers }

    func createTransactionForAddress(
        _ address: String,
        chain: ChainModel,
        asset: AssetModel,
        addressFactory: SS58AddressFactoryProtocol
    ) -> AssetTransactionData {
        AssetTransactionData.createTransaction(
            from: self,
            address: address,
            chain: chain,
            asset: asset,
            addressFactory: addressFactory
        )
    }
}

extension SubscanConcreteExtrinsicsItemData: WalletRemoteHistoryItemProtocol {
    var identifier: String { hash }
    var itemBlockNumber: UInt64 { blockNumber }
    var itemExtrinsicIndex: UInt16 { extrinsicIndex.value }
    var itemTimestamp: Int64 { timestamp }
    var label: WalletRemoteHistorySourceLabel { .extrinsics }

    func createTransactionForAddress(
        _ address: String,
        chain: ChainModel,
        asset: AssetModel,
        addressFactory: SS58AddressFactoryProtocol
    ) -> AssetTransactionData {
        AssetTransactionData.createTransaction(
            from: self,
            address: address,
            chain: chain,
            asset: asset,
            addressFactory: addressFactory
        )
    }
}

import Foundation
import CommonWallet
import IrohaCrypto

struct TransactionHistoryMergeResult {
    let historyItems: [AssetTransactionData]
    let identifiersToRemove: [String]
}

enum TransactionHistoryMergeItem {
    case local(item: TransactionHistoryItem)
    case remote(remote: WalletRemoteHistoryItemProtocol)

    func compareWithItem(_ item: TransactionHistoryMergeItem) -> Bool {
        switch (self, item) {
        case let (.local(localItem1), .local(localItem2)):
            if localItem1.status == .pending, localItem2.status != .pending {
                return true
            } else {
                return compareBlockNumberIfExists(
                    number1: localItem1.blockNumber,
                    number2: localItem2.blockNumber,
                    timestamp1: localItem1.timestamp,
                    timestamp2: localItem2.timestamp
                )
            }

        case let (.local(localItem), .remote(remoteItem)):
            if localItem.status == .pending {
                return true
            } else {
                return compareBlockNumberIfExists(
                    number1: localItem.blockNumber,
                    number2: remoteItem.itemBlockNumber,
                    timestamp1: localItem.timestamp,
                    timestamp2: remoteItem.itemTimestamp
                )
            }
        case let (.remote(remoteItem), .local(localItem)):
            if localItem.status == .pending {
                return false
            } else {
                return compareBlockNumberIfExists(
                    number1: remoteItem.itemBlockNumber,
                    number2: localItem.blockNumber,
                    timestamp1: remoteItem.itemTimestamp,
                    timestamp2: localItem.timestamp
                )
            }
        case let (.remote(remoteItem1), .remote(remoteItem2)):
            return compareBlockNumberIfExists(
                number1: remoteItem1.itemBlockNumber,
                number2: remoteItem2.itemBlockNumber,
                timestamp1: remoteItem1.itemTimestamp,
                timestamp2: remoteItem2.itemTimestamp
            )
        }
    }

    func buildTransactionData(
        address: String,
        chain: ChainModel,
        asset: AssetModel,
        addressFactory: SS58AddressFactoryProtocol
    ) -> AssetTransactionData {
        switch self {
        case let .local(item):
            return AssetTransactionData.createTransaction(
                from: item,
                address: address,
                chain: chain,
                asset: asset,
                addressFactory: addressFactory
            )
        case let .remote(item):
            return item.createTransactionForAddress(
                address,
                chain: chain,
                asset: asset,
                addressFactory: addressFactory
            )
        }
    }

    private func compareBlockNumberIfExists(
        number1: UInt64?,
        number2: UInt64?,
        timestamp1: Int64,
        timestamp2: Int64
    ) -> Bool {
        if let number1 = number1, let number2 = number2 {
            return number1 != number2 ? number1 > number2 : timestamp1 > timestamp2
        }

        return timestamp1 > timestamp2
    }
}

final class TransactionHistoryMergeManager {
    let address: String
    let chain: ChainModel
    let asset: AssetModel
    let addressFactory: SS58AddressFactoryProtocol

    init(
        address: String,
        chain: ChainModel,
        asset: AssetModel,
        addressFactory: SS58AddressFactoryProtocol
    ) {
        self.address = address
        self.chain = chain
        self.asset = asset
        self.addressFactory = addressFactory
    }

    func merge(
        subscanItems: [WalletRemoteHistoryItemProtocol],
        localItems: [TransactionHistoryItem]
    ) -> TransactionHistoryMergeResult {
        let existingHashes = Set(subscanItems.map(\.identifier))
        let minSubscanItem = subscanItems.last

        let hashesToRemove: [String] = localItems.compactMap { item in
            if existingHashes.contains(item.txHash) {
                return item.txHash
            }

            guard let subscanItem = minSubscanItem else {
                return nil
            }

            if item.timestamp < subscanItem.itemTimestamp {
                return item.txHash
            }

            return nil
        }

        let filterSet = Set(hashesToRemove)
        let localMergeItems: [TransactionHistoryMergeItem] = localItems.compactMap { item in
            guard !filterSet.contains(item.txHash) else {
                return nil
            }

            return TransactionHistoryMergeItem.local(item: item)
        }

        let remoteMergeItems: [TransactionHistoryMergeItem] = subscanItems.map {
            TransactionHistoryMergeItem.remote(remote: $0)
        }

        let transactionsItems = (localMergeItems + remoteMergeItems)
            .sorted { $0.compareWithItem($1) }
            .map { item in
                item.buildTransactionData(
                    address: address,
                    chain: chain,
                    asset: asset,
                    addressFactory: addressFactory
                )
            }

        let results = TransactionHistoryMergeResult(
            historyItems: transactionsItems,
            identifiersToRemove: hashesToRemove
        )

        return results
    }

    func merge(
        subqueryItems: [WalletRemoteHistoryItemProtocol],
        localItems: [TransactionHistoryItem]
    ) -> TransactionHistoryMergeResult {
        let existingHashes = Set(subqueryItems.map(\.identifier))
        let minSubscanItem = subqueryItems.last

        let hashesToRemove: [String] = localItems.compactMap { item in
            if existingHashes.contains(item.txHash) {
                return item.txHash
            }

            guard let subscanItem = minSubscanItem else {
                return nil
            }

            if item.timestamp < subscanItem.itemTimestamp {
                return item.txHash
            }

            return nil
        }

        let filterSet = Set(hashesToRemove)
        let localMergeItems: [TransactionHistoryMergeItem] = localItems.compactMap { item in
            guard !filterSet.contains(item.txHash) else {
                return nil
            }

            return TransactionHistoryMergeItem.local(item: item)
        }

        let remoteMergeItems: [TransactionHistoryMergeItem] = subqueryItems.map {
            TransactionHistoryMergeItem.remote(remote: $0)
        }

        let transactionsItems = (localMergeItems + remoteMergeItems)
            .sorted { $0.compareWithItem($1) }
            .map { item in
                item.buildTransactionData(
                    address: address,
                    chain: chain,
                    asset: asset,
                    addressFactory: addressFactory
                )
            }

        let results = TransactionHistoryMergeResult(
            historyItems: transactionsItems,
            identifiersToRemove: hashesToRemove
        )

        return results
    }
}

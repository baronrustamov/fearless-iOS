import Foundation
import FearlessUtils

enum LocalStorageKeyFactoryError: Error {
    case invalidParams
}

protocol LocalStorageKeyFactoryProtocol {
    func createKey(from remoteKey: Data, chainId: ChainModel.Id) throws -> String
}

extension LocalStorageKeyFactoryProtocol {
    func createFromStoragePath(_ storagePath: StorageCodingPath, chainId: ChainModel.Id) throws -> String {
        let data = try StorageKeyFactory().createStorageKey(
            moduleName: storagePath.moduleName,
            storageName: storagePath.itemName
        )

        return try createKey(from: data, chainId: chainId)
    }

    func createFromStoragePath(
        _ storagePath: StorageCodingPath,
        accountId: AccountId,
        chainId: ChainModel.Id,
        tokenSymbol: TokenSymbol? = nil
    ) throws -> String {
        let data = try StorageKeyFactory().createStorageKey(
            moduleName: storagePath.moduleName,
            storageName: storagePath.itemName
        )

        if let tokenSymbol = tokenSymbol {
            let currencyId = CurrencyId.token(symbol: tokenSymbol)
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(tokenSymbol)
            return try createKey(from: data + StorageHasher.blake128Concat.hash(data: accountId) + Data(hexString: "56a60a12d72ef524000c"), chainId: chainId)
        }

        return try createKey(from: data + accountId, chainId: chainId)
    }

    func createFromStoragePath(
        _ storagePath: StorageCodingPath,
        encodableElement: ScaleEncodable,
        chainId: ChainModel.Id
    ) throws -> String {
        let storagePathData = try StorageKeyFactory().createStorageKey(
            moduleName: storagePath.moduleName,
            storageName: storagePath.itemName
        )

        let elementData = try encodableElement.scaleEncoded()

        return try createKey(from: storagePathData + elementData, chainId: chainId)
    }
}

final class LocalStorageKeyFactory: LocalStorageKeyFactoryProtocol {
    func createKey(from remoteKey: Data, chainId: ChainModel.Id) throws -> String {
        let concatData = (try Data(hexString: chainId)) + remoteKey
        let localKey = try StorageHasher.twox256.hash(data: concatData)
        return localKey.toHex()
    }
}

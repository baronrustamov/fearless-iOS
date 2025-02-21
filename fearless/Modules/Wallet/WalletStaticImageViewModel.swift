import Foundation
import CommonWallet

final class WalletStaticImageViewModel: WalletImageViewModelProtocol {
    let staticImage: UIImage

    init(staticImage: UIImage) {
        self.staticImage = staticImage
    }

    var image: UIImage? { staticImage }

    func loadImage(with completionBlock: @escaping (UIImage?, Error?) -> Void) {
        completionBlock(image, nil)
    }

    func cancel() {}
}

extension WalletStaticImageViewModel: ImageViewModelProtocol {
    func loadImage(on imageView: UIImageView, targetSize _: CGSize, animated _: Bool, cornerRadius _: CGFloat) {
        imageView.image = staticImage
    }

    func loadImage(on imageView: UIImageView, targetSize _: CGSize, animated _: Bool) {
        imageView.image = staticImage
    }

    func cancel(on _: UIImageView) {}
}

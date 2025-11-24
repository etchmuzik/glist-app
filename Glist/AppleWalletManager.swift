import Foundation
import PassKit
import UIKit

enum AppleWalletManager {
    static func presentPass(from data: Data, in controller: UIViewController) {
        guard let pass = try? PKPass(data: data) else {
            print("Invalid pkpass data")
            return
        }
        guard let vc = PKAddPassesViewController(pass: pass) else {
            print("Failed to create PKAddPassesViewController")
            return
        }
        controller.present(vc, animated: true)
    }
    
    static func presentMultiplePasses(from passes: [Data], in controller: UIViewController) {
        let pkPasses = passes.compactMap { try? PKPass(data: $0) }
        guard let vc = PKAddPassesViewController(passes: pkPasses) else {
            print("No valid passes to present")
            return
        }
        controller.present(vc, animated: true)
    }
}

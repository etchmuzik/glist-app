import Foundation
import PassKit
import UIKit
import SwiftUI

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

struct AddPassViewControllerWrapper: UIViewControllerRepresentable {
    let pass: PKPass

    func makeUIViewController(context: Context) -> PKAddPassesViewController {
        // Force unwrap is safe here because we are passing a valid PKPass object
        return PKAddPassesViewController(pass: pass)!
    }

    func updateUIViewController(_ uiViewController: PKAddPassesViewController, context: Context) {
        // No updates needed
    }
}

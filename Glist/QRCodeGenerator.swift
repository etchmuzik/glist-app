import Foundation
import CoreImage.CIFilterBuiltins
import UIKit

struct QRCodeGenerator {
    static let context = CIContext()
    static let filter = CIFilter.qrCodeGenerator()
    
    static func generate(from string: String) -> UIImage? {
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            // Scale up the image to ensure it's sharp
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
    }
}

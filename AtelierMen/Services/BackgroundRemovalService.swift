import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

public struct SegmentationResult {
    public let cutoutImage: UIImage
    public let cutoutFilename: String
    public let dominantColorHex: String
    public let accentColorHex: String
    public let colorName: String
}

public final class BackgroundRemovalService {
    public static let shared = BackgroundRemovalService()
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    private init() {}
    
    /**
     * Executes on-device foreground segmentation using Apple's Neural Engine Vision framework.
     * - When removeFace is true (default), automatically removes model head, hair, ears, and neck
     *   while preserving the complete shirt collar, lapels, buttons, and shoulder slopes.
     * - When removeArms is true (default), removes exposed model arms & skin on the flanks
     *   so only the pure garment remains.
     * Produces a clean transparent cutout (ARGB 32-bit PNG) and analyzes the dominant & accent colors.
     */
    public func removeBackground(from uiImage: UIImage, removeFace: Bool = true, removeArms: Bool = true) async throws -> SegmentationResult {
        // Fix image orientation if needed
        let normalizedImage = normalizeOrientation(uiImage)
        guard let cgImage = normalizedImage.cgImage else {
            throw NSError(domain: "BackgroundRemovalService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid CGImage representation"])
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // 1. Vision Requests: Foreground Mask + Face Detection + Pose Detection
        let maskRequest = VNGenerateForegroundInstanceMaskRequest()
        let faceRequest = VNDetectFaceRectanglesRequest()
        let poseRequest = VNDetectHumanBodyPoseRequest()
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        if removeFace || removeArms {
            try handler.perform([maskRequest, faceRequest, poseRequest])
        } else {
            try handler.perform([maskRequest])
        }
        
        guard let maskResult = maskRequest.results?.first else {
            throw NSError(domain: "BackgroundRemovalService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No salient subject detected in image"])
        }
        
        // 2. Generate pixel buffer mask at full image resolution
        let maskPixelBuffer = try maskResult.generateScaledMaskForImage(
            forInstances: maskResult.allInstances,
            from: handler
        )
        
        let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)
        let originalCIImage = CIImage(cgImage: cgImage)
        
        // 3. Blend original image with mask on top of empty (transparent) background
        guard let filter = CIFilter(name: "CIBlendWithMask") else {
            throw NSError(domain: "BackgroundRemovalService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize CIBlendWithMask"])
        }
        filter.setValue(originalCIImage, forKey: kCIInputImageKey)
        filter.setValue(CIImage.empty(), forKey: kCIInputBackgroundImageKey)
        filter.setValue(maskCIImage, forKey: kCIInputMaskImageKey)
        
        guard let outputCIImage = filter.outputImage else {
            throw NSError(domain: "BackgroundRemovalService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to produce masked image"])
        }
        
        guard var outputCGImage = ciContext.createCGImage(outputCIImage, from: CGRect(origin: .zero, size: CGSize(width: width, height: height))) else {
            throw NSError(domain: "BackgroundRemovalService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to render transparent CGImage"])
        }
        
        // 4. Processing: Collar preservation & Arm removal
        let detectedFaces = faceRequest.results ?? []
        if (removeFace && !detectedFaces.isEmpty) || removeArms {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            
            var rawData = [UInt8](repeating: 0, count: width * height * 4)
            if let ctx = CGContext(
                data: &rawData,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) {
                ctx.draw(outputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
                
                var lowestCollarY: CGFloat = CGFloat(height)
                
                if removeFace && !detectedFaces.isEmpty {
                    for face in detectedFaces {
                        let box = face.boundingBox
                        let faceW = box.size.width * CGFloat(width)
                        let faceH = box.size.height * CGFloat(height)
                        let faceX = box.origin.x * CGFloat(width)
                        let faceY = box.origin.y * CGFloat(height)
                        
                        let chinY = faceY
                        let centerX = faceX + faceW * 0.5
                        
                        // Keep collar & lapels 100% intact by ending cut right at the base of the chin/throat
                        let collarY = max(0, chinY - faceH * 0.06)
                        lowestCollarY = min(lowestCollarY, collarY)
                        
                        let headHalfW = max(faceW * 0.95, 25.0)
                        let neckHalfW = max(faceW * 0.28, 10.0) // Narrow neck only
                        
                        ctx.saveGState()
                        ctx.setBlendMode(.clear)
                        
                        let path = CGMutablePath()
                        path.move(to: CGPoint(x: max(0, centerX - neckHalfW), y: collarY))
                        path.addQuadCurve(
                            to: CGPoint(x: min(CGFloat(width), centerX + neckHalfW), y: collarY),
                            control: CGPoint(x: centerX, y: max(0, collarY - faceH * 0.04))
                        )
                        path.addLine(to: CGPoint(x: min(CGFloat(width), centerX + headHalfW), y: chinY + faceH * 0.35))
                        path.addLine(to: CGPoint(x: min(CGFloat(width), centerX + headHalfW), y: CGFloat(height)))
                        path.addLine(to: CGPoint(x: max(0, centerX - headHalfW), y: CGFloat(height)))
                        path.addLine(to: CGPoint(x: max(0, centerX - headHalfW), y: chinY + faceH * 0.35))
                        path.closeSubpath()
                        
                        ctx.addPath(path)
                        ctx.fillPath()
                        ctx.restoreGState()
                    }
                }
                
                // 5. Remove bare arms and exposed lateral skin if requested
                if removeArms {
                    let leftArmThreshold = Int(Double(width) * 0.36)
                    let rightArmThreshold = Int(Double(width) * 0.64)
                    
                    for y in 0..<height {
                        let yFromBottom = height - 1 - y
                        for x in 0..<width {
                            let offset = (y * width + x) * 4
                            let a = rawData[offset + 3]
                            if a > 40 {
                                let r = Double(rawData[offset])
                                let g = Double(rawData[offset + 1])
                                let b = Double(rawData[offset + 2])
                                
                                // Standard skin detection in YCbCr & RGB
                                let cb = 128.0 - 0.168736 * r - 0.331264 * g + 0.5 * b
                                let cr = 128.0 + 0.5 * r - 0.418688 * g - 0.081312 * b
                                
                                let isSkin = cb >= 75 && cb <= 135 && cr >= 130 && cr <= 180 && r > g && g > b && (r - g) >= 8
                                
                                // Erase if on the side arm zones or in the upper throat area
                                if isSkin && (x < leftArmThreshold || x > rightArmThreshold || CGFloat(yFromBottom) > lowestCollarY - 12) {
                                    rawData[offset + 3] = 0
                                    rawData[offset] = 0
                                    rawData[offset + 1] = 0
                                    rawData[offset + 2] = 0
                                }
                            }
                        }
                    }
                }
                
                if let cleanedCG = ctx.makeImage() {
                    outputCGImage = cleanedCG
                }
            }
        }
        
        let cutoutUIImage = UIImage(cgImage: outputCGImage)
        
        // 6. Save PNG to Documents
        guard let pngData = cutoutUIImage.pngData() else {
            throw NSError(domain: "BackgroundRemovalService", code: -6, userInfo: [NSLocalizedDescriptionKey: "Failed to encode transparent PNG data"])
        }
        
        let filename = "cutout_\(UUID().uuidString).png"
        _ = ImageManager.shared.saveImageData(pngData, filename: filename)
        
        // 6. Extract dominant colors from the cutout subject
        let (dominantHex, accentHex, colorName) = extractDominantColors(from: outputCGImage)
        
        return SegmentationResult(
            cutoutImage: cutoutUIImage,
            cutoutFilename: filename,
            dominantColorHex: dominantHex,
            accentColorHex: accentHex,
            colorName: colorName
        )
    }
    
    // Normalizes UIImage orientation to .up
    private func normalizeOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return normalized
    }
    
    // Extracts dominant & accent colors from opaque pixels in the cutout
    private func extractDominantColors(from cgImage: CGImage) -> (dominant: String, accent: String, name: String) {
        let width = 64
        let height = 64
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = [UInt8](repeating: 0, count: width * height * 4)
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return ("#1A1A1A", "#C5A059", "Neutral Black")
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var colorBuckets: [Int: Int] = [:]
        var totalSamples = 0
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let alpha = rawData[offset + 3]
                // Only consider non-transparent foreground pixels
                if alpha > 80 {
                    let r = Int(rawData[offset])
                    let g = Int(rawData[offset + 1])
                    let b = Int(rawData[offset + 2])
                    
                    // Quantize to reduce noise (step of 32)
                    let qr = (r / 32) * 32 + 16
                    let qg = (g / 32) * 32 + 16
                    let qb = (b / 32) * 32 + 16
                    let key = (qr << 16) | (qg << 8) | qb
                    
                    colorBuckets[key, default: 0] += 1
                    totalSamples += 1
                }
            }
        }
        
        if totalSamples == 0 || colorBuckets.isEmpty {
            return ("#1E1E1E", "#C5A059", "Classic Dark")
        }
        
        // Sort by frequency
        let sorted = colorBuckets.sorted { $0.value > $1.value }
        let topColorKey = sorted.first!.key
        let topHex = String(format: "#%06X", topColorKey)
        
        var accentHex = topHex
        if sorted.count > 1 {
            // Find secondary color with noticeable difference
            for candidate in sorted.dropFirst() {
                let diff = colorDelta(c1: topColorKey, c2: candidate.key)
                if diff > 60 {
                    accentHex = String(format: "#%06X", candidate.key)
                    break
                }
            }
        }
        
        let colorName = nameForHex(topHex)
        return (topHex, accentHex, colorName)
    }
    
    private func colorDelta(c1: Int, c2: Int) -> Int {
        let r1 = (c1 >> 16) & 0xFF
        let g1 = (c1 >> 8) & 0xFF
        let b1 = c1 & 0xFF
        let r2 = (c2 >> 16) & 0xFF
        let g2 = (c2 >> 8) & 0xFF
        let b2 = c2 & 0xFF
        return abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
    }
    
    private func nameForHex(_ hex: String) -> String {
        let scanner = Scanner(string: hex.replacingOccurrences(of: "#", with: ""))
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
        UIColor(red: r, green: g, blue: b, alpha: 1.0).getHue(&h, saturation: &s, brightness: &v, alpha: &a)
        
        let hueDeg = h * 360.0
        if v < 0.15 { return "Onyx Black" }
        if s < 0.12 && v > 0.88 { return "Pure White" }
        if s < 0.15 { return "Slate Grey" }
        
        if (hueDeg >= 350 || hueDeg <= 12) { return "Royal Crimson" }
        if (hueDeg > 12 && hueDeg <= 40) { return "Warm Amber / Cognac" }
        if (hueDeg > 40 && hueDeg <= 68) { return "Champagne Gold" }
        if (hueDeg > 68 && hueDeg <= 165) { return "Emerald / Olive" }
        if (hueDeg > 165 && hueDeg <= 200) { return "Cyan Teal" }
        if (hueDeg > 200 && hueDeg <= 255) { return "Midnight Navy" }
        if (hueDeg > 255 && hueDeg <= 295) { return "Regal Purple" }
        if (hueDeg > 295 && hueDeg <= 349) { return "Rose Pink" }
        return "Custom Tone"
    }
}

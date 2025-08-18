# QR Code Functionality

This folder contains all QR code related functionality for the BoardingPassKit library.

## Files

### QRCodeGenerator.swift
The main class for generating QR codes from boarding pass data. Provides multiple generation methods with different styling options.

**Key Features:**
- Basic QR code generation with customizable size and error correction
- Custom color support (foreground/background)
- Style-based generation using QRCodeStyle
- Logo overlay support
- Specialized methods for printing and display

**Usage:**
```swift
let generator = QRCodeGenerator(boardingPassData: boardingPass.code)

// Basic QR code
let qrCode = try generator.generate()

// Custom styling
let qrCode = try generator.generate(size: CGSize(width: 300, height: 300),
                                  correctionLevel: "H")

// With logo
let qrCode = try generator.generateWithLogo(logo: airlineLogo)
```

### QRCodeStyle.swift
Configuration struct for QR code appearance and behavior. Provides predefined styles and builder pattern for customization.

**Key Features:**
- Error correction level management (L, M, Q, H)
- Color customization
- Corner radius and shadow effects
- Predefined styles (printing, display, dark mode, airline branding)
- Builder pattern for easy customization

**Usage:**
```swift
// Predefined styles
let style = QRCodeStyle.printing()
let style = QRCodeStyle.darkMode()
let style = QRCodeStyle.airlineBranded(airlineColor: .red)

// Custom styling
let style = QRCodeStyle()
    .withForegroundColor(.blue)
    .withRoundedCorners(10)
    .withShadow()
```

### QRCodeUtilities.swift
Utility methods and helper functions for QR code functionality.

**Key Features:**
- Size optimization calculations
- Data suitability validation
- Error correction level recommendations
- Configuration validation
- Device capability checking

**Usage:**
```swift
// Size optimization
let optimalSize = QRCodeUtilities.optimalSize(for: view.bounds)

// Validation
let isSuitable = QRCodeUtilities.isStringSuitableForQRCode(boardingPass.code)

// Recommendations
let level = QRCodeUtilities.recommendedErrorCorrectionLevel(for: data.count)
```

## Integration with BoardingPass

The BoardingPass struct provides convenient methods that use these classes internally:

```swift
let boardingPass = try decoder.decode(code: code)

// Basic QR code
let qrCode = try boardingPass.qrCode()

// Styled QR code
let qrCode = try boardingPass.qrCode(style: .printing())

// Branded QR code
let qrCode = try boardingPass.brandedQRCode(airlineColor: .blue)

// Logo overlay
let qrCode = try boardingPass.qrCodeWithLogo(logo: logo)
```

## Error Handling

All QR code generation methods throw `BoardingPassError` types:
- `CIQRCodeGeneratorNotFound` - Device doesn't support QR generation
- `CIQRCodeGeneratorOutputFailed` - Generation failed
- `qrCodeGenerationFailed` - General generation failure
- `qrCodeLogoOverlayFailed` - Logo overlay failed
- `qrCodeStylingFailed` - Styling application failed
- `qrCodeDataTooLarge` - Data exceeds QR code capacity

## Platform Support

QR code generation is currently only supported on iOS due to Core Image framework requirements. The code includes proper platform checks using `#if os(iOS)` directives.

## Performance Considerations

- QR codes are generated on-demand, not cached
- Large QR codes (300x300+) may impact performance
- High error correction levels increase processing time
- Logo overlays require additional graphics context operations

## Best Practices

1. **Error Correction**: Use H (high) for printing, M (medium) for display
2. **Size**: 150x150 for mobile, 300x300 for printing
3. **Colors**: Ensure sufficient contrast for reliable scanning
4. **Logo Size**: Keep logos under 25% of QR code size
5. **Validation**: Always check `isSuitableForQRCode` before generation

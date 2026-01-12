# App Icon Guide for Campaign Manager 2026

## Required App Icon Sizes

To submit to the App Store, you need to provide app icons in the following sizes:

### iOS & iPadOS
- **1024x1024** - App Store (PNG, no transparency, no alpha channel)
- **180x180** - iPhone (iOS 14+, @3x)
- **120x120** - iPhone (iOS 14+, @2x)
- **167x167** - iPad Pro (@2x)
- **152x152** - iPad (@2x)
- **76x76** - iPad (@1x)

### Design Recommendations

For Campaign Manager 2026, consider an icon that features:
- A government building (Capitol dome or White House silhouette)
- American flag elements
- Red and blue colors (bipartisan representation)
- Clean, modern design
- Good visibility at small sizes

### Design Tools

You can create your app icon using:
1. **SF Symbols App** (macOS) - Use system symbols
2. **Figma** or **Sketch** - Professional design tools
3. **Canva** - Easy online tool
4. **Icon.kitchen** - Automated icon generator

### Using SF Symbols for Quick Icons

You can use the "building.columns.fill" SF Symbol (already in your app):

1. Open SF Symbols app on macOS
2. Find "building.columns.fill"
3. Export at various sizes
4. Add gradient or colors in an image editor
5. Ensure edges are clean and crisp

### Adding Icons to Xcode

1. Open your project in Xcode
2. Navigate to **Assets.xcassets**
3. Select **AppIcon**
4. Drag and drop your icon files into the appropriate slots
5. Xcode will validate the sizes

### App Icon Checklist

- [ ] 1024x1024 PNG for App Store
- [ ] No transparency or alpha channels
- [ ] Squared corners (iOS adds automatic corner radius)
- [ ] Consistent design across all sizes
- [ ] Test visibility at small sizes
- [ ] Ensure no copyrighted elements
- [ ] High contrast for accessibility
- [ ] Represents your app's purpose

### Quick Placeholder Generation

Until you have a professional icon, you can:
1. Use a solid color background (blue or red)
2. Add white "building.columns" symbol in center
3. Export from any graphics app
4. This is fine for TestFlight but improve before App Store release

### Testing Your Icon

Test your icon by:
- Viewing it on the Home Screen at actual size
- Checking it in dark mode and light mode
- Viewing in the App Store listing
- Ensuring it stands out among other apps

## Next Steps

1. Create or commission your app icon
2. Add it to Assets.xcassets/AppIcon
3. Build and test on a real device
4. Verify it looks good in all contexts

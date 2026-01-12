# QUICK FIX CHECKLIST

## 🚨 Do These Steps IN ORDER 🚨

### 1️⃣ Delete Core Data from Xcode
- [ ] Open Xcode project
- [ ] Find `ApPolForgeSym.xcdatamodeld` in Project Navigator
- [ ] Right-click → Delete → Move to Trash

### 2️⃣ Delete Generated Files (if they exist)
Search for and delete these if found:
- [ ] `Item+CoreDataClass.swift`
- [ ] `Item+CoreDataProperties.swift`
- [ ] `ApPolForgeSym+CoreDataModel.swift`

### 3️⃣ Clean Everything
- [ ] Xcode → Product → Clean Build Folder (⇧⌘K)
- [ ] Close Xcode completely
- [ ] Open Terminal and run:
  ```bash
  rm -rf ~/Library/Developer/Xcode/DerivedData/Campain_Manager-*
  ```

### 4️⃣ Add New Files to Xcode
The files are already in your directory, just add them to Xcode:
- [ ] Open Xcode again
- [ ] Drag these files from Finder into your project:
  - `HapticsManager.swift`
  - `AccessibilityExtensions.swift`  
  - `TutorialView.swift`
- [ ] Ensure "Add to targets: ApPolForgeSym" is checked

### 5️⃣ Fix Code Signing
- [ ] Select project in Navigator
- [ ] Select "ApPolForgeSym" target
- [ ] "Signing & Capabilities" tab
- [ ] Check "Automatically manage signing"
- [ ] Select your Apple ID team

### 6️⃣ Build and Run
- [ ] Press ⌘B (Build)
- [ ] If successful, press ⌘R (Run)
- [ ] 🎉 Celebrate!

## ✅ Success Criteria
After completing all steps, you should have:
- ✅ No build errors
- ✅ App runs on simulator/device
- ✅ Tutorial shows on first launch
- ✅ Game is fully playable
- ✅ Save/load works

## ❌ Still Having Issues?

### Error: "No such module 'CoreData'"
→ Make sure you deleted ALL references to `import CoreData` except in system files

### Error: "Cannot find 'HapticsManager' in scope"
→ Make sure you added the new files to your Xcode target (check Target Membership)

### Error: Still getting duplicate file errors
→ Do Step 3 again (Clean + Delete DerivedData) more thoroughly

### Signing still fails
→ Go to Xcode → Settings → Accounts → Add Apple ID → Select that team

## 📚 Read More
- `BUILD_FIX_GUIDE.md` - Detailed explanation
- `CORE_DATA_EXPLANATION.md` - Why this happened and how to avoid it

## ⏱️ Time Estimate
This should take 5-10 minutes total.

---

**Questions?** Let me know what error you're seeing and I'll help debug!

# New Onboarding Assets Setup

## ⚠️ IMPORTANT: Add Public Folder to Xcode Bundle

The `Public` folder with images needs to be added to your Xcode project as a **folder reference** so the app can access the images at runtime.

### Step-by-Step Instructions:

1. **Open Xcode** and locate your project
2. **Right-click** on the **FitnessApp** folder in the project navigator
3. Select **"Add Files to FitnessApp..."**
4. Navigate to and select the **Public** folder
5. ⚠️ **CRITICAL**: Select **"Create folder references"** (NOT "Create groups")
6. Check **"Copy items if needed"**
7. Ensure **FitnessApp** target is selected
8. Click **Add**

The Public folder should now appear in **blue** (folder reference) in your project navigator.

### Verify Images Are Accessible:

After adding the Public folder:

- You should see: `Public/Images/background_onboarding1.jpg`
- The folder icon should be **blue** (not yellow)
- The images will be accessible via `Bundle.main.path(forResource:ofType:inDirectory:)`

### Alternative: Add to Assets.xcassets

If the above doesn't work, add images to Assets:

1. **Open Assets.xcassets**
2. **Create New Image Set** → Name: `background_onboarding1`
3. **Drag** `Public/Images/background_onboarding1.jpg` into the image set
4. The code will automatically fallback to Assets if folder reference doesn't work

### Add Custom Dumbbell Icon (When Ready)

Once you have your custom dumbbell icon:

1. Place the icon image in `Public/Icon/` folder
2. Follow the same steps as above to add it to Assets.xcassets
3. Name it: `DumbbellIcon`
4. Update `NewOnboardingModels.swift`:
   - Change `logoIcon: "dumbbell.fill"` to `logoIcon: "DumbbellIcon"`
5. Update `NewOnboardingScreen1View.swift`:
   - Replace `Image(systemName: page.logoIcon)` with `Image(page.logoIcon)`

## Testing the New Onboarding

1. **Run the app** in Xcode
2. **Navigate to Profile tab**
3. **Tap "Preview New Onboarding"** in Settings
4. You should see:
   - Full-screen fitness background image
   - Dumbbell icon (top-left)
   - "Consistency is the key to progress" title
   - Orange "Start tracking" button

## Current Status

### Screen 1 (Intro)

✅ Models created (`NewOnboardingModels.swift`)
✅ Screen 1 view built (`NewOnboardingScreen1View.swift`)
✅ Background image added to Assets.xcassets
⏳ Custom dumbbell icon (add when ready)

### Screen 2 (Basic Details)

✅ BasicDetailsView created
✅ GenderSelectionCard component
✅ PageIndicatorView component
✅ Navigation between screens
⏳ Male icon needs to be added to Assets.xcassets
⏳ Female icon needs to be added to Assets.xcassets

### Navigation

✅ Container view created (`NewOnboardingView.swift`)
✅ Navigation link added in ProfileView

## Add Gender Icons to Assets (REQUIRED for Screen 2)

**Step 1: Add Male Icon**

1. In Xcode, click on `Assets.xcassets`
2. Click the **+** button (bottom-left) → **New Image Set**
3. Name it: `MaleIcon_onboarding` (exact name, case-sensitive)
4. Drag `Public/Images/MaleIcon_onboarding.png` into the image well
5. Done!

**Step 2: Add Female Icon**

1. Click the **+** button again → **New Image Set**
2. Name it: `FemaleIcon_onboardin2` (exact name, case-sensitive)
3. Drag `Public/Images/FemaleIcon_onboardin2.png` into the image well
4. Done!

**⚠️ Important:** The names must match exactly as shown above!

## Files Location

- Background Image: `Public/Images/background_onboarding1.jpg` ✅ Added
- Male Icon: `Public/Images/MaleIcon_onboarding.png` ⏳ Add to Assets
- Female Icon: `Public/Images/FemaleIcon_onboardin2.png` ⏳ Add to Assets
- Dumbbell Icon: `Public/Icon/` (to be added later)

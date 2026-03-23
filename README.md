# GourmetAI - AI-Powered Recipe Generator

An elegant Flutter application that generates personalized recipes using AI, helping home cooks create gourmet meals with ease.

## ✨ Features

### 🍳 Recipe Generation
- Create custom recipes based on your cravings and preferences
- Specify meal type, dietary restrictions, servings, and portion sizes
- Get detailed step-by-step cooking instructions

### 🥗 Kitchen Treasures
- Input ingredients you already have
- Discover recipes that match your available ingredients
- Reduce food waste with smart recipe suggestions

### 📱 Beautiful UI
- Modern dark theme with professional design
- Responsive layout for web, Android, and iOS
- Smooth navigation and intuitive user experience

### 🎯 Detailed Recipe Views
- Nutritional information (calories, protein, carbs, fats)
- Visual nutrition breakdown with progress indicators
- Complete ingredient lists with measurements
- Step-by-step cooking instructions
- Prep time, cook time, and total time

### 💎 Subscription Tiers
- **Free Tier**: Basic recipes, standard quality images, limited history
- **Gourmet Pro ($12/month)**: Ultra-realistic images, advanced AI recipes, unlimited portfolio
- **Michelin Elite ($29/month)**: Michelin star precision, 8K hyper-realistic images, priority generation

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.7.2 or higher
- Chrome browser (for web development)
- Android Studio (for Android development)
- Xcode (for iOS development, Mac only)

### Installation

1. Clone or navigate to the project directory:
```bash
cd gourmetai
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:

**For Web (Chrome):**
```bash
flutter run -d chrome
```

**For Android:**
```bash
flutter run -d android
```

**For iOS (Mac only):**
```bash
flutter run -d ios
```

## 📱 Platform Support

- ✅ **Web**: Full support (Chrome, Edge, Safari)
- ✅ **Android**: Native Android app
- ✅ **iOS**: Native iOS app (requires Mac for development)
- ✅ **Windows**: Desktop app

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── theme/
│   └── app_theme.dart          # App-wide theme and colors
└── screens/
    ├── landing_page.dart       # Main landing page
    ├── pricing_page.dart       # Subscription tiers
    ├── recipe_form_page.dart   # Recipe generation form
    ├── kitchen_treasures_page.dart  # Ingredient input
    ├── my_creations_page.dart  # Recipe collection
    └── recipe_detail_page.dart # Detailed recipe view
```

## 🎨 Design Features

- **Dark Theme**: Professional dark color scheme with teal accents
- **Custom Typography**: Google Fonts (Inter) for modern look
- **Smooth Animations**: Seamless page transitions
- **Responsive Design**: Adapts to different screen sizes
- **Accessibility**: High contrast colors and readable text

## 🔧 Technologies Used

- **Flutter 3.29.2**: UI framework
- **Dart 3.7.2**: Programming language
- **Google Fonts**: Custom typography
- **Material Design**: UI components

## 📦 Building for Production

### Web
```bash
flutter build web
```
Output: `build/web/`

### Android APK
```bash
flutter build apk
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS (Mac only)
```bash
flutter build ios
```

## 🧪 Testing

### Run in Chrome Mobile View:
1. Open the app in Chrome
2. Press `F12` to open DevTools
3. Press `Ctrl+Shift+M` to toggle device toolbar
4. Select a mobile device (Pixel, iPhone, etc.)

### Test on Physical Device:
- **Android**: Enable USB Debugging and connect via USB
- **iOS**: Connect iPhone to Mac with cable

## 🌐 Deployment Options

### Web Hosting
- Firebase Hosting
- Netlify
- Vercel
- GitHub Pages

### Mobile App Stores
- **Android**: Google Play Store
- **iOS**: Apple App Store

## 🎯 Future Enhancements

- [ ] AI Integration for real recipe generation
- [ ] User authentication and profiles
- [ ] Save favorite recipes to cloud
- [ ] Share recipes with friends
- [ ] Shopping list generation
- [ ] Meal planning calendar
- [ ] Recipe ratings and reviews
- [ ] Video cooking tutorials
- [ ] Barcode scanner for ingredients

## 📄 License

This project is created for demonstration purposes.

## 👨‍💻 Developer

Built with ❤️ using Flutter

---

**Note**: This is a UI prototype. AI recipe generation requires backend integration with OpenAI, Claude, or similar AI services.

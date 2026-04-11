# 💎 DiamondVault

A comprehensive Flutter-based jewelry management application for tracking inventory, managing clients/suppliers, and calculating prices for diamond jewelry businesses.

## ✨ Features

### 🔐 Authentication & Security
- **Firebase Authentication** - Secure login/logout with email verification
- **User-specific Data Isolation** - Each user's data is completely isolated in separate Firestore collections
- **Real-time Sync** - All data synchronizes across devices instantly

### 📦 Inventory Management
- **Photo Upload** - Capture and store high-quality photos of jewelry items
- **Comprehensive Item Details** - Track gold weight, karat, category, serial numbers
- **Diamond Tracking** - Record diamond groups with carats, pieces, and categories
- **Precious Stones** - Track additional stones with weights and types
- **Stock Management** - Monitor stock levels with low stock alerts
- **Auto-generated Serial Numbers** - Unique SN generation per category per user

### 💰 Price Calculator
- **Category-based Filtering** - Filter items by jewelry type (Ring, Necklace, etc.)
- **Detailed Breakdown** - Calculate gold base price, diamond costs, luxury tax, and discounts
- **Real-time Calculations** - Instant price updates as you select items
- **Customizable Pricing** - Store pricing settings per user

### 👥 Party Management (Clients & Suppliers)
- **Client Database** - Store customer information, contact details, and notes
- **Supplier Management** - Track suppliers with material types and locations
- **Transaction Tracking** - Record payments, purchases, credits, and refunds
- **Balance Monitoring** - View receivable/payable amounts for each party
- **Search & Filter** - Quickly find clients or suppliers

### 📊 Dashboard Analytics
- **Total Inventory Count** - Overview of all jewelry pieces
- **Financial Overview** - Total receivables and payables across all parties
- **Low Stock Alerts** - Track items that need restocking
- **Recent Activity** - View latest inventory additions

### 🎨 User Interface
- **Bottom Navigation** - Easy access to Home, Inventory, Calculator, Parties, and Menu
- **Dark Theme** - Professional dark UI with accent colors
- **Responsive Design** - Optimized for mobile devices
- **Search Functionality** - Find items, clients, and suppliers quickly
- **Category Filters** - Filter inventory by jewelry type
- **Animated Loading Screen** - Beautiful diamond logo animation

### 🔧 Technical Features
- **Firebase Integration** - Firestore for data, Storage for photos, Auth for users
- **Offline Capability** - Local data persistence with cloud sync
- **Real-time Updates** - Live data streams for instant UI updates
- **Error Handling** - Robust error handling and user feedback
- **Performance Optimized** - Efficient queries and data loading

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Firebase project with Authentication, Firestore, and Storage enabled
- Android Studio or VS Code with Flutter extensions

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/bsakriya22-lab/DiamondVault.git
   cd diamond_vault
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Authentication, Firestore, and Storage
   - Download `google-services.json` and place it in `android/app/`
   - Update `firebase_options.dart` with your Firebase config

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase configuration
├── screens/
│   ├── loading_screen.dart      # Animated loading screen
│   ├── main_navigation_wrapper.dart  # Bottom navigation
│   ├── dashboard_screen.dart    # Home dashboard
│   ├── inventory_list_screen.dart   # Inventory management
│   ├── item_detail_screen.dart  # Item details & editing
│   ├── add_item_screen.dart     # Add/edit inventory items
│   ├── price_calculator_screen.dart # Price calculations
│   ├── parties_screen.dart      # Clients & suppliers tabs
│   ├── clients_screen.dart      # Client management
│   ├── suppliers_screen.dart    # Supplier management
│   ├── party_transactions_screen.dart # Transaction tracking
│   ├── user_menu_screen.dart    # User settings & menu
│   └── login_screen.dart        # Authentication
└── models/                      # Data models (if any)
```

## 🗂️ Data Structure

### Firestore Collections
```
users/{userId}/
├── inventory/           # Jewelry items
├── clients/            # Customer data
│   └── {clientId}/
│       └── transactions/  # Client transactions
├── suppliers/          # Supplier data
│   └── {supplierId}/
│       └── transactions/  # Supplier transactions
└── settings/           # User preferences & pricing
```

### Storage Structure
```
users/{userId}/
└── inventory/
    └── {itemId}.jpg    # Item photos
```

## 🎯 Key Workflows

### Adding Inventory
1. Tap the + button in Inventory screen
2. Capture/upload photo
3. Enter item details (name, category, gold weight, karat)
4. Add diamond groups (carats, pieces, category)
5. Add precious stones if any
6. Set stock count
7. Save - auto-generates serial number

### Managing Parties
1. Go to Parties tab
2. Switch between Customers/Suppliers
3. Add new parties with contact details
4. Tap transaction icon to add payments/purchases
5. View balance (receivable/payable)

### Price Calculation
1. Go to Calculator tab
2. Select jewelry category
3. Choose items from filtered list
4. View detailed price breakdown
5. Apply discounts if needed

## 🔧 Configuration

### Pricing Settings
- Gold rates per karat
- Diamond pricing by category
- Luxury tax percentage
- Default discount rates

### User Preferences
- Theme settings
- Default categories
- Notification preferences

## 📋 Requirements

- **Flutter**: >=3.0.0
- **Dart**: >=3.0.0
- **Android**: API 21+ (Android 5.0)
- **iOS**: 11.0+
- **Firebase**: Authentication, Firestore, Storage

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

For support, email [your-email@example.com] or create an issue in this repository.

## 📈 Future Enhancements

- [ ] Barcode scanning for inventory
- [ ] Export reports to PDF/Excel
- [ ] Multi-language support
- [ ] Advanced analytics dashboard
- [ ] Inventory forecasting
- [ ] Integration with jewelry marketplaces
- [ ] Backup and restore functionality

---

**Built with ❤️ using Flutter & Firebase**

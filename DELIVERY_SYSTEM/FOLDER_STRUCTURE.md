# ============================================
# PROJECT FOLDER STRUCTURE - DELIVERY SYSTEM
# ============================================

period_tracker/
│
├── lib/
│   ├── main.dart                          # App entry point
│   ├── supabase_config.dart               # Supabase configuration
│   │
│   ├── config/
│   │   ├── api_config.dart                # API endpoints configuration
│   │   └── app_config.dart                # App-wide configurations
│   │
│   ├── models/
│   │   ├── product.dart                   # Product model
│   │   ├── category.dart                  # Category model
│   │   ├── cart_item.dart                 # Cart item model
│   │   ├── order.dart                     # Order model
│   │   ├── order_item.dart                # Order item model
│   │   ├── delivery_partner.dart          # Delivery partner model
│   │   └── emergency_kit.dart             # Emergency kit model
│   │
│   ├── providers/
│   │   ├── delivery_provider.dart         # State management for delivery
│   │   ├── cart_provider.dart             # Shopping cart state
│   │   ├── orders_provider.dart           # Orders state management
│   │   └── products_provider.dart         # Products state management
│   │
│   ├── screens/
│   │   ├── delivery/
│   │   │   ├── delivery_home_screen.dart        # Main delivery store
│   │   │   ├── category_screen.dart             # Products by category
│   │   │   ├── product_list_screen.dart         # All products view
│   │   │   ├── product_details_screen.dart      # Product details
│   │   │   ├── cart_screen.dart                 # Shopping cart
│   │   │   ├── checkout_screen.dart             # Checkout process
│   │   │   ├── order_tracking_screen.dart       # Track orders
│   │   │   ├── emergency_kit_screen.dart        # Emergency kit page
│   │   │   └── order_history_screen.dart        # Past orders
│   │   │
│   │   ├── home/
│   │   │   └── ... (existing screens)
│   │   │
│   │   └── ... (other existing screens)
│   │
│   ├── services/
│   │   ├── delivery_api_service.dart      # API calls for delivery
│   │   ├── notification_service.dart      # Push notifications
│   │   └── location_service.dart          # GPS tracking
│   │
│   ├── widgets/
│   │   ├── delivery/
│   │   │   ├── product_card.dart          # Reusable product card
│   │   │   ├── category_card.dart         # Category card widget
│   │   │   ├── cart_item_tile.dart        # Cart item widget
│   │   │   ├── order_timeline.dart        # Order status timeline
│   │   │   ├── emergency_banner.dart      # Emergency kit banner
│   │   │   └── delivery_map.dart          # Live tracking map
│   │   │
│   │   └── ... (common widgets)
│   │
│   ├── utils/
│   │   ├── constants.dart                 # App constants
│   │   ├── validators.dart                # Form validators
│   │   └── formatters.dart                # Currency, date formatters
│   │
│   └── routes/
│       ├── app_routes.dart                # Route names
│       └── app_router.dart                # Route generation
│
├── backend/                               # Node.js Backend
│   ├── src/
│   │   ├── controllers/
│   │   │   ├── productController.js       # Product logic
│   │   │   ├── orderController.js         # Order logic
│   │   │   ├── cartController.js          # Cart logic
│   │   │   └── deliveryController.js      # Delivery logic
│   │   │
│   │   ├── routes/
│   │   │   ├── products.js                # Product routes
│   │   │   ├── orders.js                  # Order routes
│   │   │   ├── cart.js                    # Cart routes
│   │   │   └── delivery.js                # Delivery routes
│   │   │
│   │   ├── middleware/
│   │   │   ├── auth.js                    # Authentication
│   │   │   ├── validation.js              # Request validation
│   │   │   └── errorHandler.js            # Error handling
│   │   │
│   │   ├── models/
│   │   │   ├── Product.js                 # Product schema
│   │   │   ├── Order.js                   # Order schema
│   │   │   └── Cart.js                    # Cart schema
│   │   │
│   │   ├── services/
│   │   │   ├── supabaseService.js         # Supabase integration
│   │   │   ├── notificationService.js     # Send notifications
│   │   │   └── deliveryService.js         # Delivery assignment
│   │   │
│   │   └── utils/
│   │       ├── helpers.js                 # Helper functions
│   │       └── constants.js               # Backend constants
│   │
│   ├── .env                               # Environment variables
│   ├── .env.example                       # Example env file
│   ├── server.js                          # Express app entry
│   └── package.json                       # Dependencies
│
├── assets/
│   ├── images/
│   │   ├── products/                      # Product images
│   │   ├── categories/                    # Category icons
│   │   └── delivery/                      # Delivery illustrations
│   │
│   └── animations/
│       ├── loading_cart.json              # Cart loading animation
│       └── success_delivery.json          # Success animation
│
├── test/
│   ├── delivery/
│   │   ├── delivery_api_test.dart         # API tests
│   │   ├── cart_widget_test.dart          # Cart widget tests
│   │   └── order_model_test.dart          # Model tests
│   │
│   └── ... (existing tests)
│
├── DELIVERY_SYSTEM/                       # Documentation
│   ├── ARCHITECTURE.md                    # System architecture
│   ├── DATABASE_SCHEMA.sql                # Supabase schema
│   ├── EXPRESS_API.js                     # API implementation
│   ├── FLUTTER_API_SERVICE.dart           # Flutter API service
│   ├── FLUTTER_SCREENS.dart               # UI implementations
│   ├── FOLDER_STRUCTURE.md                # This file
│   └── INTEGRATION_GUIDE.md               # Integration instructions
│
├── .env                                   # Environment variables (Flutter)
├── pubspec.yaml                           # Flutter dependencies
└── README.md                              # Project documentation

# Clear-Meat API Integration

This directory contains the API integration for the Clear-Meat health assessment service.

## Files Overview

### Core API Files
- **`ClearMeatAPIClient.swift`** - Main API client using Alamofire
- **`ClearMeatModels.swift`** - API response models and mapping logic
- **`ClearMeatAPIClientDependency.swift`** - TCA dependency injection setup
- **`TokenManager.swift`** - Secure JWT token storage using Keychain
- **`APIConfiguration.swift`** - API endpoints and configuration

## Key Features

### Authentication
- **Registration**: Create new user accounts with email/password
- **Login**: Authenticate existing users
- **Token Management**: Secure storage and automatic token refresh
- **Password Validation**: Matches API requirements (8+ chars, 3 of 4 types)

### Product Analysis
- **Barcode Lookup**: Get product details from barcode
- **Health Assessment**: AI-powered health analysis using mobile format
- **MeatScan Conversion**: Transform API responses to app models

### User Management
- **Profile Management**: Get and update user profiles
- **Preferences**: Store dietary preferences and restrictions

## API Endpoints Used

### Authentication
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login

### Products
- `GET /api/v1/products/{barcode}` - Get product details
- `GET /api/v1/products/{barcode}/health-assessment-mcp?format=mobile` - Health assessment

### User Features
- `GET /api/v1/users/me` - Get user profile
- `PUT /api/v1/users/me` - Update user profile
- `GET /api/v1/users/favorites` - Get user favorites
- `GET /api/v1/users/history` - Get scan history
- `GET /api/v1/users/explore` - Get personalized recommendations

## Usage in TCA Features

### Authentication
```swift
@Dependency(\.authService) var authService

// Register user
let response = try await authService.register(email, password, fullName)

// Login user
let response = try await authService.login(email, password)
```

### Product Scanning
```swift
@Dependency(\.productService) var productService

// Get health assessment and convert to MeatScan
let meatScan = try await productService.getMeatScanFromBarcode(barcode)
```

## Error Handling

The API client provides comprehensive error handling:
- Network errors (timeout, connection issues)
- HTTP errors (400, 401, 409, 500)
- JSON parsing errors
- Custom API errors with user-friendly messages

## Testing

- **MockClearMeatAPIClient** - Provides mock responses for testing
- **TestValue** and **PreviewValue** - TCA dependency values for testing
- **MockTokenManager** - In-memory token storage for tests

## Security

- JWT tokens stored securely in iOS Keychain
- Automatic token validation and expiration checking
- Password validation matching API requirements
- Secure HTTP headers and request validation

## Mobile Optimization

- Uses `format=mobile` parameter for 65% smaller responses
- Optimized for mobile data usage
- Efficient JSON parsing and model mapping

## Configuration

- **Development**: Points to localhost for local testing
- **Production**: Points to Railway deployment
- **Debug Mode**: Additional logging and validation in development

## Integration with Existing App

The API client seamlessly integrates with the existing Scanivore app:
- Converts API responses to existing `MeatScan` models
- Maintains existing UI patterns and user experience
- Preserves TCA architecture and dependency injection
- Compatible with existing authentication flow
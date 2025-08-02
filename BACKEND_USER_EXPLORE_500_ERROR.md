# Backend Issue: /api/v1/users/explore Endpoint Returns 500 Error

## Issue Description
The `/api/v1/users/explore` endpoint is returning a 500 Internal Server Error when the iOS app tries to fetch user-specific recommendations that respect dietary preferences.

## Expected Behavior
- The endpoint should return personalized product recommendations based on user preferences
- Should respect meat type selections (e.g., if user selects only beef and chicken, should not return pork products)
- Should respect other dietary preferences like avoiding preservatives, MSG, etc.

## Current Workaround
The iOS app is temporarily using the generic `/api/v1/products/recommendations` endpoint, but this doesn't respect user preferences, causing users to see products they've explicitly excluded (like pork when they've selected only beef and chicken).

## API Details
- Endpoint: `GET /api/v1/users/explore`
- Parameters: `offset` (int), `limit` (int)
- Expected response format: Same as `/api/v1/products/recommendations` but filtered by user preferences

## Impact
Users who have set dietary preferences (especially meat type restrictions) are seeing products that violate their preferences, which is a critical issue for dietary restrictions.

## Temporary Fix in iOS
```swift
// TODO: Switch to getExploreRecommendations when backend 500 error is fixed
// Currently using generic recommendations endpoint
try await gateway.getRecommendations(offset, 10)
```

## Priority
HIGH - This affects core functionality of respecting user dietary preferences
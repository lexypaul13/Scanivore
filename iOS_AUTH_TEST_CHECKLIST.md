# iOS Authentication Test Checklist

## 🧪 Quick Test Steps

### 1. Force Refresh Test
1. Open Scanivore app
2. Go to **Settings**
3. Pull down to refresh (if refresh is implemented)
4. Check user info at top:
   - ✅ Should show YOUR name
   - ✅ Should show YOUR email
   - ❌ Should NOT show "Development User"
   - ❌ Should NOT show "dev@example.com"

### 2. Sign Out/In Test
1. In Settings, tap **Sign Out**
2. Confirm sign out
3. Sign in again with your credentials
4. Go back to Settings
5. Verify your real info appears

### 3. API Response Test
Look for these in Settings header:
```
Expected:
- Name: "Your Actual Name"
- Email: "your.email@example.com"

NOT Expected:
- Name: "Development User"
- Email: "dev@example.com"
```

### 4. Delete Account Test (Optional - Careful!)
1. The Delete Account should delete YOUR account
2. Not a fake development account

## 🔍 Debugging Tips

If still seeing "Development User":

1. **Check network requests** in Xcode console
2. **Look for API response** from `/api/v1/users/me`
3. **Verify the response** contains real user data
4. **Check auth token** is being sent correctly

## 📱 Expected Behavior

After the backend fix:
- ✅ Real user names in Settings
- ✅ Real user emails in Settings
- ✅ Sign out clears real session
- ✅ Delete account affects real account
- ✅ All user-specific features work correctly

## 🚨 Common Issues

1. **Cached Data**: iOS might cache the old "Development User" data
   - Solution: Sign out and sign in again
   
2. **Old Token**: App might have old auth token
   - Solution: Force quit app and reopen
   
3. **Network Cache**: API responses might be cached
   - Solution: Wait a few minutes or reinstall app

## ✅ Success Criteria

The backend fix is working when:
- [ ] Settings shows your real name
- [ ] Settings shows your real email
- [ ] No "Development User" text anywhere
- [ ] No "dev@example.com" text anywhere
- [ ] Sign out/in flow works correctly
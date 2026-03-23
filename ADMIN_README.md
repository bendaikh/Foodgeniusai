# GourmetAI Admin Panel

A comprehensive admin dashboard for managing the GourmetAI application, including user management, API configuration, payments, recipes, and analytics.

## 🎯 Features

### 🔐 Admin Authentication
- Secure login page
- Password visibility toggle
- Protected admin routes

### 📊 Dashboard Overview
- **Real-time Statistics**:
  - Total users with growth metrics
  - Active subscriptions count
  - Recipes generated today
  - Monthly Recurring Revenue (MRR)
- **Revenue Charts**: Visual representation of revenue trends
- **Subscription Distribution**: Breakdown by tier (Free, Pro, Elite)
- **Recent Activity Feed**: Live stream of user actions

### 👥 User Management
- **User List** with searchable/filterable table
- Filter by subscription tier (All, Free, Pro, Elite)
- User details:
  - Name, email, subscription plan
  - Join date
  - Recipe count
  - Account status (Active/Suspended)
- **Actions**:
  - View user details
  - Edit user information
  - Delete/suspend users

### 🤖 API Settings
- **AI Provider Selection**:
  - OpenAI (GPT-4 & DALL-E)
  - Anthropic (Claude)
  - Google (Gemini Pro)
- **OpenAI Configuration**:
  - API key management (secure input)
  - Model selection (GPT-4, GPT-3.5, etc.)
  - Max tokens configuration
  - Temperature settings
  - Connection testing
- **Image Generation**:
  - DALL-E 3 (high quality, 1024x1024)
  - DALL-E 2 (standard quality, 512x512)
  - Stable Diffusion support
  - Cost per image tracking
- **Rate Limits & Usage**:
  - Daily request tracking
  - Token usage monitoring
  - Cost tracking with budget limits
  - Visual progress indicators

### 💳 Payment Management
- **Revenue Metrics**:
  - Monthly recurring revenue
  - Active subscriptions
  - Average revenue per user
  - Churn rate tracking
- **Transaction History**:
  - Transaction ID
  - User email
  - Subscription plan
  - Payment amount
  - Payment method (with card icons)
  - Transaction date
  - Status (Success/Failed)
- **Actions**:
  - View transaction details
  - Generate invoices
  - Export transactions
  - Filter by status

### 🍽️ Recipe Management
- **Recipe Statistics**:
  - Total recipes generated
  - Today's generation count
  - Average generation time
  - Most popular cuisine
- **Recipe Grid View**:
  - Recipe thumbnail/placeholder
  - Recipe title
  - Creator email
  - Difficulty level (Easy/Intermediate/Advanced)
  - Cooking time
- **Actions**:
  - View full recipe
  - Edit recipe details
  - Delete recipes

### 📈 Analytics & Reports
- **Key Metrics**:
  - User growth tracking
  - Engagement rate
  - Free to paid conversion rate
  - Average session duration
- **User Activity Chart**: Visual representation of user behavior
- **Top Cuisines**: Distribution of recipe types
- **Most Popular Recipes**:
  - Recipe ranking
  - View counts
  - Save/bookmark counts
- **Export Functionality**: Download reports as CSV/PDF

## 🚀 Access the Admin Panel

### From the App:
1. Click the **admin icon** (⚙️) in the top-right corner of the landing page
2. Or navigate to: `http://localhost:port/admin`

### Login Credentials (Demo):
- **Email**: `admin@gourmetai.com`
- **Password**: `admin123`
- *(Note: In production, implement proper authentication)*

## 📁 Admin Panel Structure

```
lib/admin/
├── screens/
│   ├── admin_login_page.dart       # Admin authentication
│   ├── admin_dashboard.dart        # Main dashboard with sidebar
│   ├── admin_users_page.dart       # User management
│   ├── admin_api_settings_page.dart # API configuration
│   ├── admin_payments_page.dart    # Payment tracking
│   ├── admin_recipes_page.dart     # Recipe management
│   └── admin_analytics_page.dart   # Analytics & reports
```

## 🎨 Design Features

### Dark Theme
- Professional dark color scheme
- Teal accent color (#2DD4BF)
- High contrast for readability

### Sidebar Navigation
- Fixed left sidebar
- Active page highlighting
- Icon-based navigation
- Settings and logout options

### Responsive Cards
- Clean card-based layout
- Hover effects
- Visual statistics
- Progress indicators

### Data Tables
- Sortable columns
- Filterable data
- Action buttons
- Status badges

## 🔧 Configuration

### API Integration Points

The admin panel is designed to integrate with:

1. **Backend API**:
```dart
// Example API endpoints
GET    /api/admin/users
POST   /api/admin/users
PUT    /api/admin/users/:id
DELETE /api/admin/users/:id

GET    /api/admin/recipes
DELETE /api/admin/recipes/:id

GET    /api/admin/payments
GET    /api/admin/analytics

POST   /api/admin/settings/api-keys
GET    /api/admin/settings/usage
```

2. **OpenAI Integration**:
```dart
// Store API keys securely
POST   /api/admin/openai/configure
POST   /api/admin/openai/test-connection
GET    /api/admin/openai/usage
```

3. **Payment Integration** (Stripe/PayPal):
```dart
GET    /api/admin/stripe/transactions
GET    /api/admin/stripe/invoices
POST   /api/admin/stripe/refund
```

## 🔒 Security Considerations

### For Production:

1. **Authentication**:
   - Implement JWT tokens
   - Add role-based access control (RBAC)
   - Session management
   - Password hashing (bcrypt)

2. **API Security**:
   - Encrypt API keys in database
   - Use environment variables
   - Implement rate limiting
   - Add CORS protection

3. **Data Protection**:
   - Encrypt sensitive data
   - Secure payment information
   - GDPR compliance
   - Data retention policies

4. **Admin Access**:
   - Two-factor authentication (2FA)
   - IP whitelisting
   - Activity logging
   - Permission levels

## 📊 Key Features to Implement

### Backend Integration Needed:

- [ ] Real-time data fetching from API
- [ ] User CRUD operations
- [ ] Payment webhook handlers
- [ ] OpenAI API integration
- [ ] Analytics data aggregation
- [ ] Export functionality (CSV/PDF)
- [ ] Email notifications
- [ ] Audit logging

### Advanced Features:

- [ ] Real-time dashboard updates (WebSocket)
- [ ] Bulk user operations
- [ ] Advanced filtering and search
- [ ] Custom date range selection
- [ ] Automated reports
- [ ] A/B testing dashboard
- [ ] Error monitoring integration
- [ ] Performance metrics

## 🎯 Admin Workflows

### Managing Users:
1. Navigate to **Users** page
2. Search or filter users
3. Click **Edit** to modify user details
4. Change subscription tier
5. Suspend/activate accounts

### Configuring OpenAI:
1. Go to **API Settings**
2. Select provider (OpenAI/Claude/Gemini)
3. Enter API key
4. Configure model parameters
5. Test connection
6. Save settings

### Monitoring Revenue:
1. Visit **Payments** page
2. View revenue metrics
3. Check transaction history
4. Filter by status/date
5. Export reports

### Viewing Analytics:
1. Open **Analytics** page
2. Select date range
3. View key metrics
4. Analyze user behavior
5. Export reports

## 🛠️ Development

### Testing Admin Features:
```bash
# Run the app
flutter run -d chrome

# Access admin panel
# Click admin icon or navigate to /admin route
```

### Adding New Admin Pages:

1. Create new page in `lib/admin/screens/`
2. Add to dashboard sidebar menu
3. Update navigation in `admin_dashboard.dart`

Example:
```dart
_buildMenuItem(6, Icons.settings, 'Settings'),
```

## 📝 Notes

- All admin features are UI mockups
- Backend integration required for production
- Sample data used for demonstration
- Secure authentication needed for deployment
- Consider using state management (Provider/Riverpod/Bloc)

---

**For Production**: Ensure proper authentication, encryption, and security measures before deploying the admin panel.

# Rails 8 Dashboard Application

A modern dashboard application built with Rails 8, featuring authentication, role-based access control, and responsive Flowbite components.

## Features

- 🔐 **Rails Authentication** - Built-in authentication system
- 👥 **Role-Based Access** - Admin and User roles with different dashboards
- 📱 **Responsive Design** - Mobile-first design with Flowbite components
- 🎨 **Role-Based Themes** - Different themes for admin and user interfaces
- 🖼️ **Profile Pictures** - Avatar upload and display functionality
- ⚡ **Hotwire Integration** - Turbo Streams for dynamic interactions
- 🔧 **Modern Stack** - Rails 8, TailwindCSS, Flowbite, SQLite/MySQL

## Screenshots

### Login Page
- Clean, professional login form with demo account information
- Responsive design works on all devices

### User Dashboard
- 2-column layout with widgets and statistics
- Recent activity timeline
- Progress tracking and notifications
- Quick action buttons

### Admin Dashboard
- System overview with server statistics
- User management interface
- System activity monitoring
- Resource usage charts

## Getting Started

### Prerequisites
- Ruby 3.1+
- Rails 8+
- Node.js (for asset compilation)
- SQLite3 (development) or MySQL (production)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd dashboard_app
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up the database**
   ```bash
   rails db:create db:migrate db:seed
   ```

4. **Start the server**
   ```bash
   rails server
   ```

5. **Visit the application**
   Open http://localhost:3000 in your browser

## Demo Accounts

The application comes with pre-seeded demo accounts:

**Admin Account:**
- Email: admin@dashboard.com
- Password: password123
- Access: Full admin dashboard with system management

**Regular User Account:**
- Email: user@dashboard.com
- Password: password123
- Access: User dashboard with personal widgets

## Architecture

### Authentication System
- Custom Rails authentication (no external gems)
- Session-based authentication
- Password encryption with bcrypt
- Role-based authorization

### User Roles
- **Admin**: System management, user oversight, analytics
- **User**: Personal dashboard, activity tracking, profile management

### Database Schema
- **Users Table**: id, email, password_digest, role, profile_picture, timestamps
- **Active Storage**: For profile picture uploads

### Frontend Stack
- **TailwindCSS**: Utility-first CSS framework via CDN
- **Flowbite**: Professional UI components
- **Hotwire Turbo**: For dynamic updates without page refreshes
- **Responsive Design**: Mobile-first approach

## Configuration

### Database
- **Development/Test**: SQLite3
- **Production**: MySQL (configured in database.yml)

### Themes
Role-based CSS theming with CSS custom properties:
- Admin theme: Professional dark blue palette
- User theme: Friendly blue palette

### File Uploads
Profile pictures handled via Active Storage with image processing.

## Deployment

### Production Setup
1. Configure MySQL database in `config/database.yml`
2. Set environment variables:
   ```bash
   export DASHBOARD_APP_DATABASE_PASSWORD="your_password"
   export RAILS_MASTER_KEY="your_master_key"
   ```
3. Precompile assets: `rails assets:precompile`
4. Migrate database: `rails db:migrate RAILS_ENV=production`
5. Start server: `rails server -e production`

### Docker Support
The application includes Docker configuration for containerized deployment.

## Development

### Project Structure
```
app/
├── controllers/
│   ├── application_controller.rb    # Base controller with auth
│   ├── sessions_controller.rb       # Login/logout logic
│   └── dashboard_controller.rb      # Dashboard views
├── models/
│   └── user.rb                     # User model with roles
├── views/
│   ├── layouts/
│   │   ├── application.html.erb    # Main layout
│   │   └── dashboard.html.erb      # Dashboard layout
│   ├── sessions/
│   │   └── new.html.erb           # Login page
│   ├── dashboard/
│   │   ├── index.html.erb         # User dashboard
│   │   └── admin.html.erb         # Admin dashboard
│   └── shared/
│       ├── _navigation.html.erb    # Navigation component
│       └── _flash.html.erb        # Flash messages
```

### Key Components

#### Authentication Flow
1. User visits protected route
2. `authenticate_user!` redirects to login if not authenticated
3. Login form processes credentials via `SessionsController#create`
4. Successful login redirects to appropriate dashboard based on role

#### Role-Based Routing
- Admins automatically redirect to `/admin_dashboard`
- Regular users go to `/dashboard`
- Different navigation and themes based on role

#### Responsive Navigation
- Desktop: Fixed sidebar with role-appropriate menu items
- Mobile: Collapsible hamburger menu with Flowbite components
- Profile dropdown with user info and logout option

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make changes and test thoroughly
4. Commit with descriptive messages
5. Push to your fork and create a Pull Request

## License

This project is open source and available under the MIT License.

## Support

For issues or questions:
1. Check the existing issues on GitHub
2. Create a new issue with detailed information
3. Include steps to reproduce any bugs

---

Built with ❤️ using Rails 8, TailwindCSS, and Flowbite

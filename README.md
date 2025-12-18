# Ships

![Screenshot](screenshot.png)

A dashboard for Hack Club's YSWS (You Ship, We Ship) program. Track your shipped projects, view stats, and see where your projects are being mentioned online.

## Features

- **Dashboard** - View all your shipped projects with screenshots, descriptions, and stats
- **Virality Tracking** - See where your projects are being mentioned across the web
- **GitHub Stars** - Track star counts on your repositories
- **Stats Page** - Global statistics about shipped projects
- **API** - RESTful API for accessing project data

## Tech Stack

- **Ruby on Rails 8.0** with SQLite
- **Hotwire** (Turbo + Stimulus) for reactive UI
- **Vite** for asset bundling
- **Solid Queue/Cache/Cable** for background jobs, caching, and websockets
- **OmniAuth** (OpenID Connect) for authentication via Hack Club
- **Flipper** for feature flags
- **Lockbox** for field encryption
- **Blazer** for analytics

## Setup

### Prerequisites

- Ruby 3.4.3
- Node.js 20+
- pnpm
- PostgreSQL (production) or SQLite (development)

### Installation

```bash
# Install dependencies
bundle install
pnpm install

# Setup database
bin/rails db:prepare

# Start development server
bin/dev
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `RAILS_MASTER_KEY` | Rails credentials master key |
| `HACKCLUB_API_AUTH_KEY` | Auth key for api2.hackclub.com |
| `DATABASE_URL` | PostgreSQL connection string (production) |

### Credentials

Edit credentials with `bin/rails credentials:edit`:

```yaml
hackclub_api:
  auth_key: "your-airbridge-auth-key"

slack:
  bot_token: "xoxb-..."
```

## Commands

```bash
bin/rails server      # Start server
bin/rails console     # Rails console
bin/rails test        # Run tests
bin/rubocop           # Lint
bin/rubocop -a        # Auto-fix lint issues
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/v1/ysws_entries` | List all projects |
| `GET /api/v1/me` | Current user's projects |
| `GET /api/v1/stats` | Global statistics |
| `GET /api/v1/screenshots/:id` | Get project screenshot |

## Architecture

```
app/
├── controllers/     # Request handlers
├── jobs/           # Background jobs (Solid Queue)
├── models/         # ActiveRecord models
├── services/       # Service objects (HackclubAirtable)
└── views/          # ERB templates
```

### Data Flow

1. `AirtableJob` syncs projects from Hack Club's Airtable via api2.hackclub.com
2. Projects stored in `ysws_project_entries` table
3. Users authenticate via Hack Club OAuth
4. Dashboard shows projects matching user's email

## Deployment

Deployed via Docker on Coolify. See `Dockerfile` and `docker-compose.yml`.

Persistent storage required for:
- `/rails/storage` (Active Storage files)

## License

MIT


_this is a temp ai generated readme_
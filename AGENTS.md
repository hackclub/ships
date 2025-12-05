# AGENTS.md

## Commands
- **Server**: `bin/rails server` or `bin/dev`
- **Console**: `bin/rails console`
- **Tests**: `bin/rails test` (all), `bin/rails test test/models/user_test.rb` (single file), `bin/rails test test/models/user_test.rb:42` (single test at line)
- **Lint**: `bin/rubocop` (check), `bin/rubocop -a` (auto-fix)
- **Security**: `bin/brakeman`
- **DB**: `bin/rails db:migrate`, `bin/rails db:seed`

## Architecture
Rails 8.0 app using SQLite, Hotwire (Turbo + Stimulus), Propshaft assets, and importmap. Auth via OmniAuth (OpenID Connect + OAuth2). Uses Solid Queue/Cache/Cable for background jobs, caching, and websockets. Flipper for feature flags. Lockbox for encryption. Blazer for analytics. console1984/audits1984 for audit logging. Norairrecord for Airtable integration.

## Code Style
- Follow [rubocop-rails-omakase](https://github.com/rails/rubocop-rails-omakase) conventions
- Models in `app/models/`, controllers in `app/controllers/`, views in `app/views/`
- Tests mirror app structure in `test/` directory
- Use `snake_case` for methods/variables, `CamelCase` for classes
- Prefer Rails conventions: RESTful routes, concerns for shared behavior, service objects for complex logic

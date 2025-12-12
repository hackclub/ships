from fellow testers:

- [x] project names! (find from gh str)
- [x] malteds map is heavuly broken such as:
      takes to long to load (cut more programs from being loaded or load last 365 days)
      u can click thru the globe
      can phase thru the land
- [x] api keys instead of cookies (cookies will still work, api keys fallback)
- [x] round the hours vro
- [x] optomize speeds
- [x] on docs page dont turbo redirect (turbo is casuing a js error)
- [x] dupe countries, top projects (should go away after name)
- [x]  improve caching
  from me:
-  [x] add webhook slack dm option
- [x] ~~api webhook maybe for on new entry~~ use slack dm
- [ ] airtable webhook to server setup (will do after approval)
- [ ] write up of why we use what for max

additional fixes from this session:
- [x] green ships now stay green when zoomed in (detailedShip gets own material)
- [x] repo/demo links now clickable in details panel
- [x] camera follows arc path to avoid terrain clipping during zoom
- [x] github_stars synced from Airtable instead of GitHub API
- [x] /me page shows project names
- [x] /api/v1/me returns screenshot_url
- [x] added database indexes for faster queries
- [x] backfilled API keys for existing users

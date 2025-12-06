class DocsController < ApplicationController
  # Displays API documentation.
  def index
    @endpoints = build_endpoints
  end

  private

  # Builds the list of API endpoints, filtering admin endpoints for non-admins.
  def build_endpoints
    endpoints = [
      {
        method: "GET",
        path: "/api/v1/ysws_entries",
        auth: false,
        description: "Returns all YSWS project entries (cached 5 min).",
        response: [
          { field: "id", type: "string", description: "Airtable record ID" },
          { field: "ysws", type: "string", description: "YSWS program name" },
          { field: "approved_at", type: "integer|null", description: "Unix timestamp of approval" },
          { field: "code_url", type: "string|null", description: "GitHub/code repository URL" },
          { field: "country", type: "string|null", description: "Country of the creator" },
          { field: "demo_url", type: "string|null", description: "Live demo URL" },
          { field: "description", type: "string|null", description: "Project description" },
          { field: "github_username", type: "string|null", description: "GitHub username" },
          { field: "heard_through", type: "string|null", description: "How they heard about YSWS" },
          { field: "hours", type: "number|null", description: "Hours spent on project" },
          { field: "screenshot_url", type: "string|null", description: "Screenshot URL" }
        ]
      },
      {
        method: "GET",
        path: "/api/v1/stats",
        auth: false,
        description: "Returns global statistics for all projects (cached 5 min).",
        response: [
          { field: "total_projects", type: "integer", description: "Total number of projects" },
          { field: "total_hours", type: "number", description: "Sum of all hours spent" },
          { field: "total_stars", type: "integer", description: "Sum of all GitHub stars" },
          { field: "viral_projects", type: "integer", description: "Projects with >5 stars" },
          { field: "projects_by_country", type: "object", description: "Top 15 countries by project count" },
          { field: "projects_by_ysws", type: "object", description: "Projects grouped by YSWS program" },
          { field: "top_starred", type: "array", description: "Top 10 starred projects" },
          { field: "recent_projects", type: "array", description: "10 most recently approved projects" }
        ]
      },
      {
        method: "GET",
        path: "/api/v1/me",
        auth: true,
        description: "Returns all project entries for the authenticated user.",
        response: [
          { field: "[]", type: "array", description: "Array of YswsProjectEntry objects" }
        ]
      },
      {
        method: "GET",
        path: "/api/v1/dashboard",
        auth: true,
        description: "Returns dashboard data for the authenticated user.",
        response: [
          { field: "user.email", type: "string", description: "User's email" },
          { field: "user.name", type: "string", description: "User's display name" },
          { field: "entries", type: "array", description: "Array of user's project entries" }
        ]
      },
      {
        method: "GET",
        path: "/api/v1/cached_images/:id",
        auth: false,
        description: "Returns cached image data by Airtable ID.",
        response: [
          { field: "original_url", type: "string", description: "Original image URL" },
          { field: "cached_url", type: "string", description: "Cached/proxied image URL" }
        ]
      },
      {
        method: "GET",
        path: "/api/v1/admin/users",
        auth: :admin,
        description: "Returns all users (admin only).",
        response: [
          { field: "total", type: "integer", description: "Total number of users" },
          { field: "users[].id", type: "integer", description: "User ID" },
          { field: "users[].email", type: "string", description: "User's email" },
          { field: "users[].name", type: "string", description: "User's name" },
          { field: "users[].display_name", type: "string", description: "Display name" },
          { field: "users[].slack_id", type: "string|null", description: "Slack user ID" },
          { field: "users[].admin", type: "boolean", description: "Is admin?" },
          { field: "users[].verification_status", type: "string|null", description: "Verification status" },
          { field: "users[].created_at", type: "string", description: "ISO8601 timestamp" }
        ]
      },
      {
        method: "GET",
        path: "/api/v1/admin/entries",
        auth: :admin,
        description: "Returns all YSWS project entries with full details (admin only).",
        response: [
          { field: "total", type: "integer", description: "Total number of entries" },
          { field: "entries[].id", type: "integer", description: "Entry ID" },
          { field: "entries[].airtable_id", type: "string", description: "Airtable record ID" },
          { field: "entries[].ysws", type: "string", description: "YSWS program name" },
          { field: "entries[].email", type: "string", description: "Creator's email" },
          { field: "entries[].description", type: "string|null", description: "Project description" },
          { field: "entries[].hours_spent", type: "number|null", description: "Reported hours" },
          { field: "entries[].country", type: "string|null", description: "Country" },
          { field: "entries[].approved_at", type: "string|null", description: "ISO8601 approval timestamp" },
          { field: "entries[].github_stars", type: "integer|null", description: "GitHub stars" }
        ]
      },
      {
        method: "GET",
        path: "/api/v1/admin/stats",
        auth: :admin,
        description: "Returns admin-specific statistics (admin only).",
        response: [
          { field: "users.total", type: "integer", description: "Total users" },
          { field: "users.admins", type: "integer", description: "Admin count" },
          { field: "users.verified", type: "integer", description: "Verified users" },
          { field: "users.with_slack", type: "integer", description: "Users with Slack connected" },
          { field: "entries.total", type: "integer", description: "Total entries" },
          { field: "entries.approved", type: "integer", description: "Approved entries" },
          { field: "entries.pending", type: "integer", description: "Pending entries" },
          { field: "entries.viral", type: "integer", description: "Viral projects (>5 stars)" },
          { field: "by_ysws", type: "object", description: "Entry counts by YSWS program" },
          { field: "by_country", type: "object", description: "Entry counts by country" },
          { field: "recent_users", type: "array", description: "10 most recent users" }
        ]
      }
    ]

    if current_user&.admin?
      endpoints
    else
      endpoints.reject { |e| e[:auth] == :admin }
    end
  end
end

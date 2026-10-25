# Super Génial

- The repository is public: never commit client data, financial data or secrets.
- All code is written in English: class, method, variable and tool names, comments, tests.
  Only text shown to users (admin interface, flash messages) is in French.
- `admin/` is a Rails 8.1 + SQLite app deployed on every push to `main`. Before merging a PR that adds a
  migration, rebase on `main` and check the migration timestamps do not collide.
- The admin exposes an MCP server at `/mcp` (tools in `admin/app/mcp/admin_mcp/`, one folder per domain),
  protected by its own OAuth 2.1 server (`admin/app/controllers/oauth/`).

Type: research
Status: open

## Question

What does a remote MCP server need to implement for OAuth so that Claude and ChatGPT can connect to it as a Connected assistant? Cover: whether Dynamic Client Registration is required or a pre-registered client is acceptable, the token issuance and refresh flow, how the resulting token should scope subsequent tool calls to one user, and any MCP-spec-mandated endpoints (e.g. `.well-known` metadata) the server must expose. This determines how deeply Supabase Auth can be reused for the MCP OAuth flow versus needing a separate authorization-server component.

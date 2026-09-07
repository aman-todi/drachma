Type: research
Status: resolved

## Question

What does a remote MCP server need to implement for OAuth so that Claude and ChatGPT can connect to it as a Connected assistant? Cover: whether Dynamic Client Registration is required or a pre-registered client is acceptable, the token issuance and refresh flow, how the resulting token should scope subsequent tool calls to one user, and any MCP-spec-mandated endpoints (e.g. `.well-known` metadata) the server must expose. This determines how deeply Supabase Auth can be reused for the MCP OAuth flow versus needing a separate authorization-server component.

## Answer

Dynamic Client Registration is not required. The current MCP spec (2025-11-25) ranks Client ID Metadata Documents first, a pre-registered client second, and DCR third and optional (it was a SHOULD in the 2025-06-18 revision, now downgraded to MAY). A single pre-registered OAuth client per assistant, one for Claude and one for ChatGPT, is spec-compliant and matches Anthropic's own connector fallback order.

The token flow is OAuth 2.1 Authorization Code with mandatory PKCE (S256), a mandatory `resource` parameter (RFC 8707) that binds the token's audience to Drachma's MCP server, and mandatory refresh-token rotation for public clients. A compliant server must expose OAuth 2.0 Protected Resource Metadata (RFC 9728) at `.well-known/oauth-protected-resource`, naming the authorization server, which in turn must expose RFC 8414 (or OIDC discovery) metadata. These can be separate services: Supabase Auth can act as the authorization server (it already exposes OIDC discovery) as long as Drachma's MCP server publishes the RFC 9728 document pointing at it.

Per-user scoping of tool calls comes from validating the token's audience server-side (MUST per RFC 8707) and resolving the authenticated subject from the token, which is standard OAuth resource-server practice the spec assumes rather than a distinct MCP mechanism.

Full findings and citations: [../research/06-mcp-oauth-flow.md](../research/06-mcp-oauth-flow.md)

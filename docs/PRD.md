# Product Requirements Document (PRD) — 9Router AI Gateway

> **Status**: Approved & Baseline  
> **Target Audience**: AI Agents (Antigravity, Cursor, Claude Code), Human Developers  
> **Last Updated**: 2026-09-16  

---

## 1. Executive Summary & Objective

**9Router** is an open-source, high-performance AI model routing gateway designed to sit between developer workstations/applications and upstream AI model providers.

The core objective is to provide a single, unified, OpenAI-compatible API gateway (`/v1`) that optimizes LLM token usage, provides seamless fallback routing, centralizes API credential management, and reduces inference costs across developer environments.

```text
┌──────────────────────────────────────────────────────────┐
│ Clients: Antigravity, Claude Code, Cursor, Cline, Scripts │
└────────────────────────────┬─────────────────────────────┘
                             │  OpenAI-Compatible (/v1)
┌────────────────────────────▼─────────────────────────────┐
│                   9Router AI Gateway                     │
│  • RTK Token Saver (20%-40% context compression)         │
│  • Smart Auto-Fallback (Free -> Cheap -> Frontier)       │
│  • Centralized Key & Quota Management                    │
└────────────────────────────┬─────────────────────────────┘
                             │  Upstream Routing
┌────────────────────────────▼─────────────────────────────┐
│ Upstream Providers: Kiro, OpenCode, Gemini, OpenAI, etc. │
└──────────────────────────────────────────────────────────┘
```

---

## 2. Core Value Proposition & Key Features

### 2.1 Universal Endpoint (`/v1`)
- Standard OpenAI-compatible endpoints (`/v1/models`, `/v1/chat/completions`, `/v1/embeddings`).
- Works drop-in with any tool or SDK supporting OpenAI base URLs.

### 2.2 RTK Token Saver & Context Optimization
- Real-Time Token Kompressor (RTK) automatically strips redundant whitespace, repetitive structural formatting, and verbose tool outputs (e.g., voluminous git diffs, build logs, and repetitive AST dumps).
- Delivers an estimated **20% to 40% reduction** in input token consumption.
- Headroom sidecar capability for extended context cache management.

### 2.3 Smart Auto-Fallback Routing
- Dynamic tier-based routing:
  1. **Tier 0 (Zero-Cost / Free Providers)**: Kiro AI (Claude 4.5, GLM-5, MiniMax quotas), OpenCode Free, Google Gemini free tier.
  2. **Tier 1 (High Efficiency / Low Cost)**: DeepSeek V3/R1, OpenAI GPT-4o-mini.
  3. **Tier 2 (Frontier / High Capability)**: Claude 3.7 / 4.5 Sonnet, OpenAI o3/o1.
- In the event of rate-limiting (HTTP 429), quota exhaustion, or upstream timeouts (HTTP 5xx), requests automatically failover to the next viable tier without failing client workflows.

### 2.4 Centralized Credential & Access Control
- Prevents API keys from being scattered across multiple developer machine configs.
- Admin dashboard allows generating separate client API keys with individual rate limits and usage tracking.

---

## 3. Phased Implementation Roadmap

### Phase 1: Local Verification (Windows Docker Desktop)
- Run 9Router container locally on port `20128`.
- Test web UI dashboard (`http://localhost:20128`).
- Configure initial model providers (starting with free providers).
- Validate RTK compression with test prompts.
- Integrate workstation coding tools (Claude Code CLI, Cursor, Antigravity).

### Phase 2: Production VPS Hardening (Oracle Cloud ARM64)
- Deploy to Oracle Cloud Infrastructure (OCI) ARM64 Ubuntu instance (`vps-main`, `129.225.1.91`).
- Run behind Caddy reverse proxy on internal network `proxy-network`.
- Secure endpoint via `https://router.digitalneeds.my.id` with Cloudflare SSL and Caddy `tls internal`.
- Enforce `REQUIRE_API_KEY=true` and mitigate public exposure.

### Phase 3: Cross-Project Integration
- Connect dependent applications:
  - **VPS-Monitor-Dashboard**: Scheduled automated server health summaries using low-cost models.
  - **Graduance**: AI student portal analysis and features.
  - **Second Brain**: Semantic search and Obsidian daily note augmentation.

---

## 4. Security & Safety Requirements

1. **CVE-2026-46339 Mitigation**:
   - Use official, patched Docker images (`decolua/9router:latest`).
   - Strong randomized `JWT_SECRET` (minimum 32 bytes base64-encoded).
   - Enforce strong `INITIAL_PASSWORD`.
2. **Network Isolation**:
   - On VPS, port 20128 must **never** be exposed directly to the public internet (`0.0.0.0:20128`).
   - Access only through Caddy reverse proxy via internal Docker network `proxy-network`.
3. **Zero Secrets in Git**:
   - All sensitive files (`.env`, credentials, sqlite databases) are gitignored.
   - Deterministic script `execution/init-env.ps1` handles safe local credential generation.
4. **Git as Single Source of Truth**:
   - Direct edits on production VPS are strictly prohibited.
   - All deployments are executed through CI/CD (`.github/workflows/deploy.yml`).

---

## 5. Success Metrics

- [ ] Successful local container startup and healthcheck (`execution/test-connection.ps1`).
- [ ] Working dashboard login with secure randomized credentials.
- [ ] At least 1 free model provider successfully responding to chat completions.
- [ ] Verified token compression on large context prompts.
- [ ] Zero secret leaks in git history.
- [ ] Seamless VPS deployment via GitHub Actions with valid HTTPS certificate.

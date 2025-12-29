# GAAP - Generally Accepted Accounting Platform

<div align="center">

[![License](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE)
[![Go Version](https://img.shields.io/badge/go-1.25+-00ADD8?logo=go)](https://go.dev/)
[![Next.js](https://img.shields.io/badge/Next.js-15+-000000?logo=next.js)](https://nextjs.org/)
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker)](https://www.docker.com/)

**The modern, high-performance alternative to Firefly III.**
*Built for those who take personal finance seriously.*

[Features](#-features) • [Tech Stack](#-tech-stack) • [Quick Start](#-quick-start) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

---

> 🚧 **Note**: This project is currently in active development (Alpha). Star us to follow the journey!

## 🎯 Overview

**GAAP** is a self-hosted, privacy-first personal finance system engineered for performance and extensibility.

While we love tools like *Firefly III*, we wanted something faster, more modern, and easier to extend. GAAP is built on a "Clean Architecture" using **Go (GoFrame)** for high concurrency and **Next.js 15** for a fluid user experience.

### Why GAAP?

- **⚡ Blazing Fast**: Written in Go, designed to handle thousands of transactions with near-zero latency.
- **🔒 Privacy First**: Your data, your server. No tracking, no third-party servers.
- **📊 Professional Accounting**: Implements double-entry bookkeeping logic simplified for personal use.
- **📱 Modern UX**: A responsive, SPA experience (No page reloads between clicks).
- **🐋 Deployment Ready**: One command to launch your own financial cloud.

---

## ✨ Features

### Core Functionality
- **Double-Entry Bookkeeping**: Ensure every cent is accounted for.
- **Multi-Asset Management**: Unified view for Cash, Stocks, Crypto, and Real Estate.
- **Real-Time Currency Conversion**: Auto-update exchange rates for global asset allocation.
- **Investment Portfolio**: (Coming Soon) Track ROI and cost basis for your stock holdings.
- **Budgeting & Goals**: Set limits and track progress visually.

### Technical Highlights
- **GoFrame Backend**: Enterprise-grade logic with rigorous error handling.
- **Type-Safe Frontend**: Full TypeScript support with shadcn/ui components.
- **High Availability**: Built-in support for Redis caching and RabbitMQ (optional for lite mode).
- **Open API**: RESTful API documented with OpenAPI 3.1 for your custom scripts.

---

## 🧠 Development Philosophy

**GAAP** is an experiment in **AI-Native Development** (Vibe Coding). We believe that small teams can build enterprise-grade software by leveraging LLMs for velocity while enforcing strict verification for reliability.

### Vibe Coding meets Financial Rigor
Financial software generally demands zero tolerance for errors, which often conflicts with the "hallucination" risks of AI. To solve this, we adhere to a **"Boundary Verification"** strategy:

1.  **AI for Implementation**: We aggressively use AI tools (Cursor, Windsurf, etc.) to generate feature logic, UI components, and boilerplate.
2.  **Math for Verification**: We do not trust AI with the final truth. All financial operations (rounding, currency conversion, ledger balancing) must be verified by deterministic, property-based tests.
    * *If the AI writes the ledger logic, the Human writes the test that proves Assets = Liabilities + Equity.*
3.  **Strict Typing**: We rely on Go's strong typing and strict decimal handling (no floating-point math for money) to act as guardrails for AI-generated code.

**Note to Contributors**: We encourage you to "vibe code". However, any PR involving money logic **MUST** include boundary tests proving that edge cases (e.g., negative balances, zero-value transactions, precision loss) are handled correctly.

---

## 🛠 Tech Stack

We use a modern, "boring" stack that just works:

| Component | Technology | Description |
|-----------|------------|-------------|
| **Backend** | [GoFrame](https://goframe.org/) | High-performance Go framework |
| **Frontend** | [Next.js 15](https://nextjs.org/) | React Server Components & App Router |
| **Database** | PostgreSQL 18 | ACID compliant data storage |
| **Cache** | Redis 7 | Session & Data caching |
| **Proxy** | Caddy 2 | Automatic HTTPS & Reverse Proxy |

---

## 🚀 Quick Start

Get your instance running in less than 2 minutes.

### Prerequisites
- Docker & Docker Compose
- Git

### Installation

```bash
# 1. Clone the repository (Important: use --recursive for submodules)
git clone --recursive https://github.com/gin-melodic/gaap.git
cd gaap

# 2. Setup configuration
cp .env.example .env
# (Optional) Edit .env if you need to change ports

# 3. Start the engine
docker-compose -f docker-compose.dev.yml up -d

```

### Access

* **Web Interface**: http://localhost:3000 (Default)
* **API Docs**: http://localhost:8080/swagger

> **Tip**: For deployment with HTTPS, please refer to our [Deployment Guide](deployment.md).

---

## 📁 Project Structure

We follow a Monorepo structure managed by Git Submodules for better separation of concerns:

```
gaap/
├── gaap-api/                 # Backend (GoFrame) - Core logic & API
├── gaap-web/                 # Frontend (Next.js) - UI & Client Logic
├── config/                   # Infrastructure config (Caddy, Redis, etc.)
├── volumes/                  # Persistent data storage
└── docker-compose.dev.yml    # Orchestration

```

---

## 🤝 Contributing

We are looking for early adopters and contributors!

**For Developers:**
This project is a great playground to learn **Go + Next.js** architecture.

1. Fork the repo.
2. `git submodule update --init --recursive`
3. Check [dev-guild.md](dev-guild.md) for local setup.
4. Submit a PR!

---

## 📄 License

This project is licensed under the **AGPL-3.0 License**.

* You can use it freely for personal use.
* You can modify it for your own use.
* If you run a public network service based on this code, you must open-source your modifications.

---

## 📧 Connect

* **X (Twitter)**: [@melodicgin](https://x.com/melodicgin) - Follow the dev journey!
* **Issues**: [GitHub Issues](https://github.com/gin-melodic/gaap/issues)

<div align="center">
<sub>Built with ❤️</sub>
</div>
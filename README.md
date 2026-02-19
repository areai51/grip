<!-- LOGO -->
<h1>
<p align="center">
  <img src="https://github.com/user-attachments/assets/fe853809-ba8b-400b-83ab-a9a0da25be8a" alt="Logo" width="128">
  <br>GRIP
</h1>
  <p align="center">
    The AI-powered terminal built on Ghostty — fast, native, with agentic workflows.
    <br />
    <a href="#about">About</a>
    ·
    <a href="https://ghostty.org/download">Download</a>
    ·
    <a href="https://ghostty.org/docs">Documentation</a>
    ·
    <a href="CONTRIBUTING.md">Contributing</a>
    ·
    <a href="HACKING.md">Developing</a>
  </p>
</p>

## About

**GRIP is a fork of [Ghostty](https://ghostty.org) with a singular vision: embed AI as a first-class citizen in the terminal.** Ghostty gives us a blisteringly fast, standards-compliant, native terminal foundation. GRIP builds on that to make the terminal an intelligent partner — not just a shell.

GRIP stands for **G**hostty with **R**einforced **I**ntelligence **P**rocessing. It's Ghostty plus:

- **Natural language to commands:** Describe what you want; get safe, executable commands.
- **Context-aware assistance:** The AI sees your current screen, working directory, and recent command history.
- **Error explanation & recovery:** When something fails, ask "why" and get a human-readable explanation with fixes.
- **Agentic workflows:** Automate multi-step tasks with AI-driven scripts that respect your environment.
- **Local-first AI:** Powered by local models via [Jan](https://jan.ai) — no cloud API keys, your data stays on your machine.

GRIP is for developers, DevOps, and researchers who spend their lives in the terminal and want an AI co-pilot that actually understands their context.

> GRIP is early-stage, experimental software built on Ghostty's excellent foundation. For general terminal usage questions, see [Ghostty's documentation](https://ghostty.org/docs). For GRIP-specific AI features, see our [`AI_INTEGRATION_PLAN.md`](AI_INTEGRATION_PLAN.md).

## Why GRIP?

Existing AI terminals either:

- are cloud-dependent and expensive (Claude Code, GitHub Copilot)
- lack deep terminal integration (ChatGPT in a browser tab)
- force you to copy-paste outputs back to the shell
- don't understand your shell state or recent history

GRIP solves this by:

1. **Direct terminal access:** AI can read what's on your screen and write commands directly to your shell.
2. **Safety layer:** Commands are validated before execution (configurable rules).
3. **Local models:** Use Jan or Ollama; no data leaves your machine.
4. **Ghostty core:** You keep Ghostty's performance, standards compliance, and native UI.

## Current Status

GRIP is in active development. AI features are being integrated incrementally:

| Feature                          | Status  |
|----------------------------------|:-------:|
| Basic natural language command generation | 🚧 WIP |
| Context capture (screen, cwd, history)  | 🚧 WIP |
| Command safety validation        | 🚧 WIP |
| Streaming AI responses           | 🚧 WIP |
| Error explanation                | 🚧 WIP |
| Settings UI for AI config        | ❌ Planned |
| Cross-platform lib integration   | ❌ Planned |

For detailed roadmap and architecture, see [`AI_INTEGRATION_PLAN.md`](AI_INTEGRATION_PLAN.md).

## Download & Installation

GRIP uses the same build and distribution channels as Ghostty. See the [Ghostty download page](https://ghostty.org/download) for official packages.

**Building from source:** GRIP's codebase lives as a fork of Ghostty. Clone and build using Zig:

```bash
git clone https://github.com/your-org/ghostty.git grip
cd grip
zig build
```

(Replace with actual GRIP repository when published.)

## Quick Start (Once AI Features Are Available)

1. Install a local model server (Jan or Ollama) and ensure it's running.
2. Launch GRIP; open the AI panel with `cmd+i` (macOS) or `ctrl+shift+i` (Linux).
3. Type: "list all docker containers that aren't running"
4. Accept the suggested command; it runs in your shell.
5. If a command fails, press `cmd+shift+e` to ask the AI what went wrong.

## Philosophy

GRIP shares Ghostty's commitment to performance, correctness, and native platform experiences. However, we view AI integration not as an add-on but as a fundamental reimagining of what a terminal can be.

We believe:

- **AI should be local:** Your shell history, errors, and environment are sensitive. Keep them on-device.
- **Context is king:** AI that can't see your screen or cwd is guessing. GRIP gives AI full context (with your consent).
- **Safety matters:** Raw AI commands can be destructive. GRIP includes a validation layer you control.
- **Open source, open weights:** The terminal is open source; the AI models should be too (or at least locally runnable).

## Differences from Ghostty

- **AI service layer:** New Zig module (`ai_service.zig`) managing local model clients.
- **Platform UI extensions:** Input panels, suggestion overlays, context displays.
- **Safety subsystem:** Command validation before execution (configurable rules/whitelists).
- **Configuration:** New `ai` section in config for model endpoint, prompts, safety rules.
- **Documentation:** Separate AI usage guide (coming soon).

Everything else — rendering, IO, terminal state, multi-window, tabs, splits — remains Ghostty's battle-tested implementation.

## Contributing

GRIP inherits Ghostty's contribution guidelines with additions for AI features. Please read:

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [HACKING.md](HACKING.md)
- [AI_INTEGRATION_PLAN.md](AI_INTEGRATION_PLAN.md) for AI-specific architecture

**Note:** GRIP-specific code lives under `src/ai/` and platform UI modifications in `macos/` and `pkg/`. When in doubt, follow Ghostty's patterns.

## License

GRIP is licensed under the MIT license, same as Ghostty. See [LICENSE](LICENSE).

## Acknowledgments

GRIP is a fork of the outstanding [Ghostty](https://ghostty.org) project by Mitchell Hashimoto. Ghostty's architecture, performance, and design are the foundation everything else is built on.

---

*GRIP v0.1.0 (in development) — Built with Zig, powered by local LLMs.*

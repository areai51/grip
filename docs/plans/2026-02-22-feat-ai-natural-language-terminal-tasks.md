# AI-Powered Natural Language Terminal - Task List

**Source Plan:** [2026-02-22-feat-ai-natural-language-terminal-plan.md](./2026-02-22-feat-ai-natural-language-terminal-plan.md)
**Generated:** 2026-02-23
**Total Tasks:** 92

---

## Summary

| Category | Count | Status |
|----------|-------|--------|
| Phase 1 (Foundation) | 5 | 1 done, 4 pending |
| Phase 2 (Core Features) | 6 | pending |
| Phase 3 (Advanced) | 7 | pending |
| NL-CMD (Natural Language) | 7 | pending |
| ERR (Error Recovery) | 7 | pending |
| CTX (Context Awareness) | 6 | pending |
| UI (Command Palette) | 7 | pending |
| SEC (Security) | 6 | pending |
| PRIV (Privacy) | 6 | pending |
| PERF (Performance) | 7 | pending |
| A11Y (Accessibility) | 6 | pending |
| COMPAT (Compatibility) | 6 | pending |
| TEST (Testing) | 6 | pending |
| DOC (Documentation) | 5 | pending |
| REVIEW (Code Review) | 4 | pending |

**Priority Distribution:** High: 46 | Medium: 36 | Low: 10

---

## Phase 1: Foundation (Weeks 1-2)

### Implementation Tasks

- [x] **Phase 1.1:** Create src/ai/ module structure `priority: high` ✅ 2026-02-23
- [ ] **Phase 1.2:** Implement LlmInterface trait with Ollama HTTP client `priority: high`
- [ ] **Phase 1.3:** Build ContextCollector for screen/cwd/history `priority: high`
- [ ] **Phase 1.4:** Add basic AI panel UI (macOS and GTK) `priority: high`
- [ ] **Phase 1.5:** Add keybinding configuration (keybind = ctrl+shift+i=open_ai_panel) `priority: high`

---

## Phase 2: Core Features (Weeks 3-4)

### Implementation Tasks

- [ ] **Phase 2.1:** Implement prompt templates for command generation `priority: high`
- [ ] **Phase 2.2:** Add streaming response support `priority: high`
- [ ] **Phase 2.3:** Build SafetyValidator with pattern matching `priority: high`
- [ ] **Phase 2.4:** Implement error detection via OSC 133 and exit codes `priority: high`
- [ ] **Phase 2.5:** Create error analysis and suggestion system `priority: high`
- [ ] **Phase 2.6:** Add confirmation dialogs for dangerous commands `priority: high`

---

## Phase 3: Advanced Features (Weeks 5-6)

### Implementation Tasks

- [ ] **Phase 3.1:** Add llama.cpp FFI integration `priority: medium`
- [ ] **Phase 3.2:** Implement embedded model loading (GGUF format) `priority: medium`
- [ ] **Phase 3.3:** Build model management UI (download, switch, update) `priority: medium`
- [ ] **Phase 3.4:** Add context sanitization and privacy controls `priority: medium`
- [ ] **Phase 3.5:** Implement caching and performance optimizations `priority: medium`
- [ ] **Phase 3.6:** Add settings UI for AI configuration `priority: medium`
- [ ] **Phase 3.7:** Create comprehensive test suite (>80% coverage) `priority: medium`

---

## Acceptance Criteria

### Natural Language to Commands (NL-CMD)

- [ ] **[NL-CMD-1]** User triggers AI panel via configurable keybinding `priority: high`
- [ ] **[NL-CMD-2]** System captures current context (cwd, recent commands, screen) `priority: high`
- [ ] **[NL-CMD-3]** AI generates command suggestion for valid natural language `priority: high`
- [ ] **[NL-CMD-4]** Suggestions include explanations of command `priority: high`
- [ ] **[NL-CMD-5]** User can edit suggested command before execution `priority: medium`
- [ ] **[NL-CMD-6]** User can request alternative suggestions `priority: medium`
- [ ] **[NL-CMD-7]** System handles ambiguous queries with clarification `priority: medium`

### Error Recovery (ERR)

- [ ] **[ERR-1]** Detect command failures via OSC 133 semantic prompts `priority: high`
- [ ] **[ERR-2]** Fallback to exit code + stderr heuristics when OSC 133 unavailable `priority: high`
- [ ] **[ERR-3]** Distinguish expected non-zero exits from actual errors `priority: medium`
- [ ] **[ERR-4]** Provide explanation of error in plain English `priority: high`
- [ ] **[ERR-5]** Provide at least one actionable fix suggestion `priority: high`
- [ ] **[ERR-6]** User can apply fix with single keypress `priority: medium`
- [ ] **[ERR-7]** Handle cascading failures (max 3 retry attempts) `priority: medium`

### Context Awareness (CTX)

- [ ] **[CTX-1]** Capture current working directory `priority: high`
- [ ] **[CTX-2]** Capture up to 50 recent commands from history `priority: high`
- [ ] **[CTX-3]** Capture up to 100 lines of visible screen content `priority: medium`
- [ ] **[CTX-4]** Detect git repository status `priority: medium`
- [ ] **[CTX-5]** Identify shell type (zsh, bash, fish, etc.) `priority: medium`
- [ ] **[CTX-6]** Prioritize relevant context (recent errors, cwd changes) `priority: low`

### Command Palette UI (UI)

- [ ] **[UI-1]** AI panel opens with focus on input field `priority: high`
- [ ] **[UI-2]** Streaming responses display as they generate `priority: high`
- [ ] **[UI-3]** Multiple suggestions display with keyboard navigation `priority: medium`
- [ ] **[UI-4]** Each suggestion includes command and explanation `priority: high`
- [ ] **[UI-5]** User can execute command with Enter `priority: high`
- [ ] **[UI-6]** User can cancel with Escape `priority: high`
- [ ] **[UI-7]** Panel works on both macOS (Cocoa) and Linux (GTK) `priority: high`

---

## Non-Functional Requirements

### Security (SEC)

- [ ] **[SEC-1]** Block commands matching destructive patterns by default `priority: high`
- [ ] **[SEC-2]** Require confirmation for dangerous commands `priority: high`
- [ ] **[SEC-3]** Redact sensitive patterns from context (API keys, passwords) `priority: high`
- [ ] **[SEC-4]** Maintain audit log of AI suggestions for 90 days `priority: medium`
- [ ] **[SEC-5]** Allow users to define custom security policies `priority: low`
- [ ] **[SEC-6]** Validate all AI-generated commands before execution `priority: high`

### Privacy (PRIV)

- [ ] **[PRIV-1]** All AI processing occurs locally (no network for inference) `priority: high`
- [ ] **[PRIV-2]** Provide Privacy Mode that disables context capture `priority: medium`
- [ ] **[PRIV-3]** Allow excluding specific directories from context capture `priority: medium`
- [ ] **[PRIV-4]** Clearly indicate what context is being used `priority: medium`
- [ ] **[PRIV-5]** Users can clear AI context and conversation history `priority: medium`
- [ ] **[PRIV-6]** Model downloads are optional (offline-first design) `priority: high`

### Performance (PERF)

- [ ] **[PERF-1]** Simple queries complete within 500ms (p95) `priority: high`
- [ ] **[PERF-2]** Complex queries complete within 2s (p95) `priority: high`
- [ ] **[PERF-3]** UI remains responsive during AI processing (60fps) `priority: high`
- [ ] **[PERF-4]** Show progress indicator for queries > 300ms `priority: medium`
- [ ] **[PERF-5]** Cache results for identical queries within session `priority: medium`
- [ ] **[PERF-6]** Context capture overhead < 50ms `priority: high`
- [ ] **[PERF-7]** Handle context up to 32KB without degradation `priority: medium`

### Accessibility (A11Y)

- [ ] **[A11Y-1]** All AI UI elements are screen reader accessible `priority: medium`
- [ ] **[A11Y-2]** Respect platform high contrast themes `priority: low`
- [ ] **[A11Y-3]** All features work via keyboard-only navigation `priority: high`
- [ ] **[A11Y-4]** AI suggestions are announced with explanations `priority: medium`
- [ ] **[A11Y-5]** Font sizes in AI panels are user-adjustable `priority: low`
- [ ] **[A11Y-6]** AI panel supports platform text-to-speech `priority: low`

### Compatibility (COMPAT)

- [ ] **[COMPAT-1]** Features work without shell integration (degraded) `priority: medium`
- [ ] **[COMPAT-2]** System works with zsh, bash, fish, and other shells `priority: high`
- [ ] **[COMPAT-3]** macOS and Linux implementations have feature parity `priority: high`
- [ ] **[COMPAT-4]** Handle SSH sessions appropriately (local vs remote) `priority: medium`
- [ ] **[COMPAT-5]** System works in split-screen/multi-pane scenarios `priority: medium`
- [ ] **[COMPAT-6]** Multiple AI backend providers supported `priority: high`

---

## Quality Gates

### Testing (TEST)

- [ ] **[TEST-1]** Unit test coverage > 80% for AI service layer `priority: high`
- [ ] **[TEST-2]** Integration tests for all major user flows `priority: high`
- [ ] **[TEST-3]** Security testing for command validation and sanitization `priority: high`
- [ ] **[TEST-4]** Performance benchmarks meet targets `priority: medium`
- [ ] **[TEST-5]** Accessibility testing with screen readers `priority: medium`
- [ ] **[TEST-6]** Cross-platform testing on macOS and Linux `priority: high`

### Documentation (DOC)

- [ ] **[DOC-1]** User documentation for AI features `priority: medium`
- [ ] **[DOC-2]** Configuration reference for AI settings `priority: medium`
- [ ] **[DOC-3]** Security and privacy documentation `priority: medium`
- [ ] **[DOC-4]** Developer documentation for AI architecture `priority: low`
- [ ] **[DOC-5]** API documentation for LLM backend interface `priority: low`

### Code Review (REVIEW)

- [ ] **[REVIEW-1]** Security review of command validation logic `priority: high`
- [ ] **[REVIEW-2]** Privacy review of context capture system `priority: high`
- [ ] **[REVIEW-3]** Performance review of AI processing pipeline `priority: medium`
- [ ] **[REVIEW-4]** Accessibility review of AI panel UI `priority: medium`

---

## Progress Tracking

| Date | Completed | Notes |
|------|-----------|-------|
| 2026-02-23 | 0/92 | Task list created |
| 2026-02-23 | 1/92 | Phase 1.1: Created src/ai/ module structure (8 files) |

---

## Legend

- `priority: high` - Must complete before release
- `priority: medium` - Should complete but can ship without
- `priority: low` - Nice to have, can defer

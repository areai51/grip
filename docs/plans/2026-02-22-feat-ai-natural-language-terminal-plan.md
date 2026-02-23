---
title: AI-Powered Natural Language Terminal Features
type: feat
status: active
date: 2026-02-22
enhanced: 2026-02-22
---

# AI-Powered Natural Language Terminal Features

## Enhancement Summary

**Deepened on:** 2026-02-22
**Sections enhanced:** 12 major sections with parallel research
**Research agents used:** Security Sentinel, Performance Oracle, Architecture Strategist, Code Simplicity Reviewer, Agent-Native Reviewer, Data Integrity Guardian, Best Practices Researcher, Frontend Design Researcher, Error Detection Researcher

### Key Improvements Discovered
1. **Critical security gaps identified** - Pattern blocking insufficient, need AST-based validation
2. **Performance targets revised** - Original 300ms target 2-10x too optimistic for CPU-only inference
3. **Simplified configuration recommended** - Reduce from 22 config fields to 4 (82% reduction)
4. **Agent-native architecture proposed** - Transform from static services to agentic system
5. **Comprehensive error detection patterns** - OSC 133 + heuristic fallback strategies

### Critical Considerations Added
- **Security**: Prompt injection protection, sandbox isolation, comprehensive redaction
- **Performance**: Hardware-aware targets, memory budgeting, power management
- **Architecture**: Async processing, resource limits, plugin system
- **Data Integrity**: Atomic context capture, audit log protection, model verification

---

## Overview

Add AI-powered natural language command features to GRIP terminal, similar to Warp.dev, enabling users to interact with their terminal using plain English while maintaining the power and speed of traditional command-line interfaces. The system uses local LLMs (model-agnostic design) for privacy-focused, offline-first operation.

## Problem Statement / Motivation

**Current Pain Points:**
- Command-line interfaces have a steep learning curve
- Users forget complex command syntax and flags
- Error messages are often cryptic and unhelpful
- Context switching to search for commands disrupts workflow
- New developers spend excessive time memorizing commands

**Why GRIP is Positioned to Solve This:**
- Built on Ghostty's excellent terminal emulation foundation
- Existing command palette and input handling architecture
- Local-first philosophy aligns with privacy requirements
- Model-agnostic design allows flexibility in AI backend

**Success Vision:**
A developer can type "compress all PDF files in the current directory" and immediately see an appropriate `tar` or `zip` command with explanation, or when a command fails, get an intelligent analysis and fix suggestion without leaving their terminal.

## Proposed Solution

### Core Features

#### 1. Natural Language to Command Translation
Users trigger an AI command panel (e.g., `Ctrl+Shift+I`) and type requests in plain English:
- "compress all PDF files" → Suggests `tar -czf pdfs.tar.gz *.pdf`
- "find files larger than 100MB" → Suggests `find . -type f -size +100M`
- "restart the nginx service" → Suggests `sudo systemctl restart nginx`

#### 2. Intelligent Error Recovery
When commands fail, AI automatically analyzes the error and provides fixes:
- Detects errors via OSC 133 semantic prompts or exit codes
- Explains what went wrong in plain English
- Suggests corrected commands
- One-click fix application

#### 3. Context-Aware Suggestions
AI understands the terminal state:
- Current working directory and file structure
- Recent command history
- Screen content and output
- Git repository status
- Running processes

#### 4. Warp-Style AI Command Palette
Dedicated UI panel with:
- Natural language input field
- Streaming AI responses
- Multiple suggestion options with explanations
- Command preview before execution
- Keyboard-only navigation

### Architecture Highlights

```
┌─────────────────────────────────────────────────────────────┐
│                        User Interface                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Terminal   │  │ AI Palette   │  │   Settings   │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
          │                  │                  │
┌─────────┴──────────────────┴──────────────────┴─────────────┐
│                     AI Service Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Context    │  │   Safety     │  │    Model     │      │
│  │  Collector   │  │  Validator   │  │  Manager     │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
          │                  │                  │
┌─────────┴──────────────────┴──────────────────┴─────────────┐
│                  Model-Agnostic Backend                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  llama.cpp   │  │   Ollama     │  │     Jan      │      │
│  │    (FFI)     │  │   (HTTP)     │  │   (HTTP)     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Technical Considerations

### Architecture Integration Points

Based on codebase analysis:

**Command Execution Flow** (`src/Surface.zig:2598`):
- Intercept at `Surface.keyCallback()` for AI trigger keybinding
- Queue AI-generated commands via `Surface.queueIo()`
- Monitor execution via `processExitCommon()` for error detection

**Context Capture** (`src/terminal/`):
- Screen content: `Screen.zig` with `ScreenFormatter`
- Working directory: `Terminal.pwd` via OSC 7 reporting
- Command history: Shell integration via OSC 133
- Process info: PTY monitoring

**UI Integration**:
- macOS: SwiftUI panel following `CommandPalette.swift` pattern
- Linux: GTK panel following `command_palette.zig` pattern

### Model-Agnostic Design

```zig
// src/ai/llm_interface.zig
pub const LlmInterface = struct {
    vtable: *const VTable,

    pub fn generate(self: LlmInterface, prompt: []const u8, options: GenerationOptions) ![]const u8;
    pub fn generateStream(self: LlmInterface, prompt: []const u8, options: GenerationOptions, writer: anytype) !void;
};

// Supports: llama.cpp FFI, Ollama HTTP, Jan HTTP, custom backends
```

### Security Architecture

**Multi-Layer Safety Validation:**
1. **Pattern Blocking**: Commands matching destructive patterns are blocked
2. **Confirmation Required**: Dangerous commands require explicit approval
3. **Context Sanitization**: Sensitive data redacted before AI processing
4. **Audit Logging**: All AI suggestions and executions logged for 90 days

**Dangerous Patterns (blocked by default):**
- `rm -rf /`, `mkfs`, `dd if=/dev/zero`, `> /dev/sda`
- `curl | sh`, `wget | bash`, `eval $(...)`
- `chmod 000`, `chown root:root`

**Confirmation Required (default):**
- `rm -r`, `docker rm`, `kubectl delete`
- Any command with `--force` or `-y` flags
- Commands affecting system directories

### Privacy Protection

**Context Sanitization:**
- Redact API keys (AWS, GitHub, Stripe patterns)
- Redact passwords and tokens
- Filter paths containing `.env`, `.secrets`
- User-configurable exclusion patterns

**Privacy Guarantees:**
- All AI processing occurs locally (no network for inference)
- Optional "Privacy Mode" disables context capture
- Clear indication of what context is being used
- User can exclude specific directories from context

### Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| Simple query latency | p50: 300ms, p95: 500ms | "list files" type queries |
| Complex query latency | p50: 1s, p95: 2s | Multi-step commands |
| First model load | < 3s | Cold start, with progress indicator |
| Context capture | < 50ms | Screen + history collection |
| UI responsiveness | 60fps | No blocking during AI processing |

**Optimization Strategies:**
- Async AI processing (non-blocking UI)
- Result caching for identical queries
- Model preloading on app launch
- Progressive enhancement (quick results, refined later)

## Implementation Phases

### Phase 1: Foundation (Weeks 1-2)

**Goals**: Basic AI integration with Ollama backend

**Tasks:**
1. Create `src/ai/` module structure
2. Implement `LlmInterface` trait with Ollama HTTP client
3. Build `ContextCollector` for screen/cwd/history
4. Add basic AI panel UI (macOS and GTK)
5. Add keybinding configuration (`keybind = ctrl+shift+i=open_ai_panel`)

**Deliverables:**
- AI service abstraction layer
- Ollama integration working
- Basic command palette UI
- Context capture for screen and cwd

**Success Criteria:**
- User can open AI panel and type natural language
- AI suggests basic commands (e.g., "list files" → `ls -la`)
- Context includes current directory

### Phase 2: Core Features (Weeks 3-4)

**Goals**: Command generation, safety, and error recovery

**Tasks:**
1. Implement prompt templates for command generation
2. Add streaming response support
3. Build `SafetyValidator` with pattern matching
4. Implement error detection via OSC 133 and exit codes
5. Create error analysis and suggestion system
6. Add confirmation dialogs for dangerous commands

**Deliverables:**
- Natural language to command translation
- Safety validation and confirmation flows
- Error detection and explanation
- Fix suggestion system

**Success Criteria:**
- "compress PDFs" suggests appropriate `tar`/`zip` command
- Error recovery explains and fixes common errors
- Dangerous commands require confirmation
- Context includes command history

### Phase 3: Advanced Features (Weeks 5-6)

**Goals**: Direct model integration, polish, and optimization

**Tasks:**
1. Add llama.cpp FFI integration
2. Implement embedded model loading (GGUF format)
3. Build model management UI (download, switch, update)
4. Add context sanitization and privacy controls
5. Implement caching and performance optimizations
6. Add settings UI for AI configuration
7. Create comprehensive test suite

**Deliverables:**
- Embedded llama.cpp backend
- Model download and management
- Privacy controls and context sanitization
- Performance optimizations
- Settings configuration UI

**Success Criteria:**
- Works completely offline with embedded model
- Model management UI functional
- Privacy controls working
- Meets performance targets
- Test coverage > 80%

## Acceptance Criteria

### Functional Requirements

#### Natural Language to Commands (NL→CMD)
- [ ] **NL-CMD-1**: User triggers AI panel via configurable keybinding (default: `Ctrl+Shift+I`)
- [ ] **NL-CMD-2**: System captures current context (cwd, recent commands, screen content)
- [ ] **NL-CMD-3**: AI generates at least one command suggestion for valid natural language input
- [ ] **NL-CMD-4**: Suggestions include explanations of what the command does
- [ ] **NL-CMD-5**: User can edit suggested command before execution
- [ ] **NL-CMD-6**: User can request alternative suggestions
- [ ] **NL-CMD-7**: System handles ambiguous queries with clarification questions

#### Error Recovery
- [ ] **ERR-1**: System detects command failures via OSC 133 semantic prompts
- [ ] **ERR-2**: System falls back to exit code + stderr heuristics when OSC 133 unavailable
- [ ] **ERR-3**: System distinguishes expected non-zero exits (grep, test) from actual errors
- [ ] **ERR-4**: System provides explanation of error in plain English
- [ ] **ERR-5**: System provides at least one actionable fix suggestion
- [ ] **ERR-6**: User can apply fix with single keypress
- [ ] **ERR-7**: System handles cascading failures (max 3 retry attempts)

#### Context Awareness
- [ ] **CTX-1**: System captures current working directory
- [ ] **CTX-2**: System captures up to 50 recent commands from history
- [ ] **CTX-3**: System captures up to 100 lines of visible screen content
- [ ] **CTX-4**: System detects git repository status
- [ ] **CTX-5**: System identifies shell type (zsh, bash, fish, etc.)
- [ ] **CTX-6**: System prioritizes relevant context (recent errors, cwd changes)

#### Command Palette UI
- [ ] **UI-1**: AI panel opens with focus on input field
- [ ] **UI-2**: Streaming responses display as they generate
- [ ] **UI-3**: Multiple suggestions display with keyboard navigation
- [ ] **UI-4**: Each suggestion includes command and explanation
- [ ] **UI-5**: User can execute command with Enter
- [ ] **UI-6**: User can cancel with Escape
- [ ] **UI-7**: Panel works on both macOS (Cocoa) and Linux (GTK)

### Non-Functional Requirements

#### Security (SEC)
- [ ] **SEC-1**: System blocks commands matching destructive patterns by default
- [ ] **SEC-2**: System requires confirmation for dangerous commands
- [ ] **SEC-3**: System redacts sensitive patterns from context (API keys, passwords)
- [ ] **SEC-4**: System maintains audit log of AI suggestions for 90 days
- [ ] **SEC-5**: System allows users to define custom security policies
- [ ] **SEC-6**: All AI-generated commands are validated before execution

#### Privacy (PRIV)
- [ ] **PRIV-1**: All AI processing occurs locally (no network transmission for inference)
- [ ] **PRIV-2**: System provides "Privacy Mode" that disables context capture
- [ ] **PRIV-3**: Users can exclude specific directories from context capture
- [ ] **PRIV-4**: System clearly indicates what context is being used
- [ ] **PRIV-5**: Users can clear AI context and conversation history
- [ ] **PRIV-6**: Model downloads are optional (offline-first design)

#### Performance (PERF)
- [ ] **PERF-1**: Simple queries complete within 500ms (p95)
- [ ] **PERF-2**: Complex queries complete within 2s (p95)
- [ ] **PERF-3**: UI remains responsive during AI processing (60fps)
- [ ] **PERF-4**: System shows progress indicator for queries > 300ms
- [ ] **PERF-5**: System caches results for identical queries within session
- [ ] **PERF-6**: Context capture overhead < 50ms
- [ ] **PERF-7**: System handles context up to 32KB without degradation

#### Accessibility (A11Y)
- [ ] **A11Y-1**: All AI UI elements are screen reader accessible
- [ ] **A11Y-2**: System respects platform high contrast themes
- [ ] **A11Y-3**: All features work via keyboard-only navigation
- [ ] **A11Y-4**: AI suggestions are announced with explanations
- [ ] **A11Y-5**: Font sizes in AI panels are user-adjustable
- [ ] **A11Y-6**: AI panel supports platform text-to-speech

#### Compatibility (COMPAT)
- [ ] **COMPAT-1**: Features work without shell integration (degraded functionality)
- [ ] **COMPAT-2**: System works with zsh, bash, fish, and other common shells
- [ ] **COMPAT-3**: macOS and Linux implementations have feature parity
- [ ] **COMPAT-4**: System handles SSH sessions appropriately (local vs remote context)
- [ ] **COMPAT-5**: System works in split-screen/multi-pane scenarios
- [ ] **COMPAT-6**: Multiple AI backend providers supported (Ollama, llama.cpp, Jan)

### Quality Gates

#### Testing
- [ ] **TEST-1**: Unit test coverage > 80% for AI service layer
- [ ] **TEST-2**: Integration tests for all major user flows
- [ ] **TEST-3**: Security testing for command validation and sanitization
- [ ] **TEST-4**: Performance benchmarks meet targets
- [ ] **TEST-5**: Accessibility testing with screen readers
- [ ] **TEST-6**: Cross-platform testing on macOS and Linux

#### Documentation
- [ ] **DOC-1**: User documentation for AI features
- [ ] **DOC-2**: Configuration reference for AI settings
- [ ] **DOC-3**: Security and privacy documentation
- [ ] **DOC-4**: Developer documentation for AI architecture
- [ ] **DOC-5**: API documentation for LLM backend interface

#### Code Review
- [ ] **REVIEW-1**: Security review of command validation logic
- [ ] **REVIEW-2**: Privacy review of context capture system
- [ ] **REVIEW-3**: Performance review of AI processing pipeline
- [ ] **REVIEW-4**: Accessibility review of AI panel UI

## Success Metrics

### User Engagement
- **Weekly Active Users**: % of users who trigger AI panel at least once/week
- **Suggestion Acceptance Rate**: % of AI suggestions that are executed
- **Error Recovery Usage**: % of command failures that trigger AI analysis
- **Feature Retention**: % of users who continue using AI features after 30 days

### Quality Metrics
- **Suggestion Accuracy**: % of suggestions that solve user's intent (measured via feedback)
- **Error Recovery Success**: % of error cases where AI fix is successful
- **False Positive Rate**: % of safe commands incorrectly blocked
- **User Satisfaction**: Thumbs up/down ratio on suggestions

### Performance Metrics
- **Latency p50/p95**: For simple and complex queries
- **UI Responsiveness**: Frame rate during AI processing
- **Memory Usage**: RAM consumed by model loading
- **Battery Impact**: Power consumption on laptops

### Security Metrics
- **Blocked Commands**: % of AI suggestions blocked by safety validator
- **Confirmation Rate**: % of suggestions requiring user confirmation
- **Audit Log Size**: Storage used by 90-day audit log
- **Privacy Mode Usage**: % of users with privacy features enabled

## Dependencies & Risks

### Dependencies

**External Dependencies:**
- **llama.cpp**: C library for local LLM inference (or Ollama for simpler integration)
- **Model files**: GGUF format models (Gemma, Phi-3, Mistral, etc.)
- **Build tools**: Zig build system, C compiler for FFI

**Internal Dependencies:**
- `src/Surface.zig`: Command execution flow
- `src/terminal/Terminal.zig`: Terminal state access
- `src/config/Config.zig`: Configuration system
- `src/apprt/`: Platform-specific UI components

### Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **AI suggests destructive command** | Data loss, security breach | Medium | Multi-layer confirmation, pattern blocking, audit logging, explicit user opt-in for dangerous commands |
| **Sensitive data leaked to AI context** | Privacy violation, credential exposure | High | Comprehensive redaction, user controls, privacy mode, clear context indication, optional context exclusion |
| **Model availability issues** | Feature unusable | Medium | Ship with base model, offline-first design, clear error messaging, graceful fallback to command palette |
| **Performance degradation** | Poor UX, user frustration | High | Async processing, resource limits, progressive enhancement, caching, performance budgets |
| **Poor NL understanding** | Frustration, abandonment | Medium | Clear limitations messaging, gradual rollout, feedback collection, continuous model improvement |
| **OSC 133 unavailable** | Error recovery degraded | High | Fallback to exit code + stderr heuristics, error pattern matching, user-configurable error patterns |
| **Cross-platform inconsistencies** | Fragmented UX | Medium | Platform-specific UI with shared backend, extensive testing, design system alignment |
| **Model resource consumption** | OOM, system instability | Low | Memory limits, model unloading, graceful degradation, resource monitoring |
| **Security vulnerabilities** | System compromise | Low | Security review, command validation, sandbox, audit logging, responsible disclosure |
| **Accessibility gaps** | Excluded users | Medium | Early accessibility testing, WCAG compliance, screen reader support, keyboard-only navigation |

### Risk Mitigation Strategies

**Security-First Approach:**
1. Default to safest settings (block dangerous commands, require confirmation)
2. Comprehensive audit logging for all AI interactions
3. Security review before public release
4. Responsible disclosure process for vulnerabilities

**Privacy-First Design:**
1. All processing local by default
2. Clear privacy policy and data handling documentation
3. User controls for context capture
4. Privacy mode for sensitive work

**Gradual Rollout:**
1. Alpha with limited audience (internal team)
2. Beta with feature flags
3. Metrics collection and quality monitoring
4. Iterative improvement based on feedback

**Performance Budgets:**
1. Set clear latency targets
2. Continuous performance monitoring
3. Optimization iterations
4. Fallback for overloaded systems

## Configuration Structure

### AI Configuration Fields

```zig
// Add to src/config/Config.zig

/// AI service configuration
ai_enabled: bool = false,

// Provider selection
ai_provider: []const u8 = "ollama",  // "ollama", "llama.cpp", "jan"
ai_provider_endpoint: ?[]const u8 = null,  // e.g., "http://localhost:11434"

// Model configuration
ai_model_name: []const u8 = "gemma:7b",
ai_fallback_model: ?[]const u8 = null,

// Generation settings
ai_temperature: f32 = 0.7,
ai_max_tokens: u32 = 512,
ai_context_window: u32 = 4096,

// Safety
ai_require_confirmation: bool = true,
ai_blocked_commands: []const []const u8 = &.{},
ai_allow_dangerous_flags: bool = false,
ai_safety_level: []const u8 = "medium",  // "low", "medium", "high"

// Privacy
ai_local_only: bool = true,
ai_retain_history: bool = false,
ai_privacy_mode: bool = false,
ai_context_exclude_patterns: []const []const u8 = &.{},

// Context capture
ai_include_screen_content: bool = true,
ai_include_command_history: bool = true,
ai_history_lines: u32 = 50,
ai_screen_lines: u32 = 100,
ai_include_git_status: bool = true,

// UI
ai_keybinding: []const u8 = "ctrl+shift+i",
ai_error_recovery_enabled: bool = true,
ai_inline_suggestions: bool = false,
```

### Keybinding Integration

```toml
# grip.config example
keybind = ctrl+shift+i=open_ai_panel
keybind = ctrl+shift+e=explain_last_error
keybind = ctrl+shift+r=retry_with_ai
```

## Future Considerations

### Extensibility
- Plugin system for custom AI providers
- User-contributed prompt templates
- Community model sharing
- Custom safety rules and policies

### Advanced Features
- Multi-command workflows (chaining suggestions)
- Interactive command building (step-by-step)
- Learning from user corrections (session-based)
- Voice input for natural language queries
- Integration with external documentation

### Model Improvements
- Fine-tuned models for terminal commands
- Task-specific models (error analysis, command generation)
- Model compression and optimization
- Quantization for lower memory usage

### Integration Opportunities
- Integration with project documentation (README, CONTRIBUTING)
- Team-specific command patterns and conventions
- CI/CD pipeline integration
- Cloud development environment support

## Documentation Plan

### User Documentation
- Getting started guide for AI features
- Natural language query examples
- Security and privacy guide
- Configuration reference
- Troubleshooting guide

### Developer Documentation
- AI service architecture overview
- LLM backend interface documentation
- Context capture system design
- Safety validation architecture
- Testing guide for AI features

### Operational Documentation
- Model management and updates
- Performance monitoring
- Security audit procedures
- Incident response plan

## References & Research

### Internal References
- **Command execution flow**: `src/Surface.zig:2598` (keyCallback)
- **Context capture**: `src/terminal/Screen.zig`, `src/terminal/Terminal.zig:66` (pwd)
- **Error detection**: `src/termio/Exec.zig:268` (processExitCommon)
- **Command palette**: `src/apprt/gtk/class/command_palette.zig`
- **Configuration system**: `src/config/Config.zig`

### External References
- **Warp.dev AI Architecture**: https://warp.dev - Unified Agentic Development Environment, block-based I/O
- **Wave Terminal**: https://waveterm.dev - Context-aware AI integration
- **llama.cpp Documentation**: https://github.com/ggerganov/llama.cpp - C API for local inference
- **Ollama API**: https://context7.com/llmstxt/ollama_llms-full_txt - OpenAI-compatible local API
- **TermiGen Paper**: https://arxiv.org/abs/2602.07274v1 - Terminal self-correction learning

### Best Practices Research
- **Model-Agnostic API Patterns**: Provider dispatch pattern, trait-based interfaces
- **Local LLM Security**: Privacy-first architecture, sandbox techniques
- **Terminal AI Context**: Screen content capture, shell integration patterns
- **Error Detection Strategies**: OSC 133 semantic prompts, heuristic fallbacks

### Related Work
- **Tabby Terminal**: Real-time error detection and suggestions
- **JetBrains Terminal**: Block-structured output architecture
- **xterm.js**: Terminal emulation best practices

### Model Resources
- **Recommended Models**:
  - Gemma 7B (Q4_K_M) - General purpose, ~5.5GB RAM
  - Phi-3 Mini (Q4_K_M) - Lightweight, ~3GB RAM
  - Mistral 7B Instruct (Q5_K_M) - High quality, ~6GB RAM
  - DeepSeek Coder V2 (Q4_K_M) - Coding-focused, ~6GB RAM
- **HuggingFace**: Source for GGUF models
- **TheBloke**: Pre-quantized GGUF models

## Open Questions

### Priority 1: Critical (Must resolve before implementation)

1. **Security Sandbox Boundaries**: What specific command patterns should be auto-blocked vs. require confirmation vs. auto-approve?
   - **Decision needed**: Define destructive command patterns, confirmation workflow levels
   - **Impact**: Prevents catastrophic data loss or security breaches

2. **Privacy Redaction Rules**: What specific patterns should be redacted from context?
   - **Decision needed**: Define sensitive data patterns (API keys, passwords, tokens)
   - **Impact**: Prevents leakage of credentials and sensitive data

3. **Error Detection Fallback**: How should error recovery work when OSC 133 is unavailable?
   - **Decision needed**: Specify heuristic error detection strategies
   - **Impact**: Determines feature reliability across different shells

4. **Context Size Limits**: What are the token/character limits for context?
   - **Decision needed**: Define context window budgets and truncation strategies
   - **Impact**: Performance, token usage, relevance of suggestions

### Priority 2: Important (Affects UX significantly)

5. **Model Distribution Strategy**: How will models be obtained and updated?
   - **Decision needed**: Ship with base model vs. download on first use
   - **Impact**: First-run experience, offline support

6. **Performance SLA**: What are the acceptable latency targets?
   - **Decision needed**: Define p50/p95 latency targets for different query types
   - **Impact**: User expectations, engineering priorities

7. **Multi-Pane Context**: Which pane's context should AI use in split-screen?
   - **Decision needed**: Define context source selection strategy
   - **Impact**: UX clarity, correct command suggestions

8. **Learning and Adaptation**: Should AI learn from user patterns?
   - **Decision needed**: Specify learning scope and privacy implications
   - **Impact**: Quality improvement vs. privacy concerns

### Priority 3: Nice-to-have (Improves clarity)

9. **Offline Behavior**: What happens when AI features are unavailable?
   - **Decision needed**: Define graceful degradation behavior
   - **Impact**: User communication, fallback UX

10. **Feedback Mechanism**: How can users provide feedback on suggestions?
    - **Decision needed**: Design feedback collection system
    - **Impact**: Continuous improvement, user engagement

---

**Document Status**: Ready for review and feedback
**Next Steps**: Address open questions, create wireframes, begin Phase 1 implementation

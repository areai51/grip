//! AI module for natural language terminal features.
//!
//! This module provides AI-powered features including:
//! - Natural language to command translation
//! - Intelligent error recovery
//! - Context-aware suggestions
//!
//! The design is model-agnostic, supporting multiple LLM backends
//! (Ollama, llama.cpp, etc.) through a common interface.

const llm_interface = @import("llm_interface.zig");
const context_collector = @import("context_collector.zig");
const safety_validator = @import("safety_validator.zig");
const error_analyzer = @import("error_analyzer.zig");
const providers = @import("providers/mod.zig");

pub const LlmInterface = llm_interface.LlmInterface;
pub const GenerationOptions = llm_interface.GenerationOptions;
pub const GenerationResult = llm_interface.GenerationResult;
pub const StreamCallback = llm_interface.StreamCallback;
pub const LlmError = llm_interface.LlmError;
pub const VTable = llm_interface.VTable;

pub const ContextCollector = context_collector.ContextCollector;
pub const Context = context_collector.Context;

pub const SafetyValidator = safety_validator.SafetyValidator;
pub const SafetyLevel = safety_validator.SafetyLevel;
pub const ValidationResult = safety_validator.ValidationResult;

pub const ErrorAnalyzer = error_analyzer.ErrorAnalyzer;
pub const ErrorContext = error_analyzer.ErrorContext;
pub const ErrorSuggestion = error_analyzer.ErrorSuggestion;

pub const OllamaProvider = providers.OllamaProvider;
pub const OllamaConfig = providers.OllamaConfig;
pub const LlamaProvider = providers.LlamaProvider;
pub const LlamaConfig = providers.LlamaConfig;

test {
    @import("std").testing.refAllDecls(@This());
}

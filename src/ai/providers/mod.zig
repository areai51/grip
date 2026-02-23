//! Provider module for LLM backends.
//!
//! This module exports different LLM backend implementations:
//! - Ollama: HTTP-based local LLM server
//! - llama.cpp: Direct FFI to llama.cpp library

pub const ollama = @import("ollama.zig");
pub const llama = @import("llama.zig");

pub const OllamaProvider = ollama.OllamaProvider;
pub const OllamaConfig = ollama.Config;

pub const LlamaProvider = llama.LlamaProvider;
pub const LlamaConfig = llama.Config;

test {
    @import("std").testing.refAllDecls(@This());
}

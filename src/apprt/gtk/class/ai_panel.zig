//! AI Panel - GTK UI for AI-powered terminal assistance.
//!
//! This module provides the GTK implementation of the AI panel,
//! allowing users to interact with AI for natural language commands.

const std = @import("std");
const gobject = @import("gobject");
const gtk = @import("gtk");
const adw = @import("adw");

const gresource = @import("../build/gresource.zig");
const i18n = @import("../../../os/main.zig").i18n;
const Common = @import("../class.zig").Common;
const Dialog = @import("dialog.zig").Dialog;
const ai = @import("../../../ai/mod.zig");

const log = std.log.scoped(.gtk_ghostty_ai_panel);

pub const AIPanel = extern struct {
    const Self = @This();
    parent_instance: Parent,
    pub const Parent = Dialog;
    pub const getGObjectType = gobject.ext.defineClass(Self, .{
        .name = "GhosttyAIPanel",
        .instanceInit = &init,
        .classInit = &Class.init,
        .parent_class = &Class.parent,
        .private = .{ .Type = Private, .offset = &Private.offset },
    });

    pub const properties = struct {
        pub const config = struct {
            pub const name = "config";
            const impl = gobject.ext.defineProperty(
                name,
                Self,
                *ai.ContextCollector,
                .{
                    .accessor = gobject.ext.privateFieldAccessor(
                        Self,
                        Private,
                        &Private.offset,
                        "config",
                    ),
                },
            );
        };
    };

    pub const signals = struct {
        pub const @"generate-request" = struct {
            pub const name = "generate-request";
            pub const connect = impl.connect;
            const impl = gobject.ext.defineSignal(
                name,
                Self,
                &.{ .{ .type = gobject.ext.gstr } },
                void,
            );
        };

        pub const @"execute-request" = struct {
            pub const name = "execute-request";
            pub const connect = impl.connect;
            const impl = gobject.ext.defineSignal(
                name,
                Self,
                &.{ .{ .type = gobject.ext.gstr } },
                void,
            );
        };

        pub const cancel = struct {
            pub const name = "cancel";
            pub const connect = impl.connect;
            const impl = gobject.ext.defineSignal(
                name,
                Self,
                &.{},
                void,
            );
        };
    };

    const Private = struct {
        config: ?*ai.ContextCollector = null,
        entry: ?*gtk.Entry = null,
        response_view: ?*gtk.TextView = null,
        response_buffer: ?*gtk.TextBuffer = null,
        generate_button: ?*gtk.Button = null,
        execute_button: ?*gtk.Button = null,
        cancel_button: ?*gtk.Button = null,
        pending_request: bool = false,
        generated_command: ?[]const u8 = null,
        allocator: std.mem.Allocator = undefined,

        pub var offset: c_int = 0;
    };

    pub fn new(allocator: std.mem.Allocator) *Self {
        const self = gobject.ext.newInstance(Self, .{});
        self.private().allocator = allocator;
        return self;
    }

    fn init(self: *Self, _: *Class) callconv(.c) void {
        gtk.Widget.initTemplate(self.as(gtk.Widget));

        const priv = self.private();

        // Connect entry activate signal
        if (priv.entry) |entry| {
            _ = entry.signals.activate.connect(
                entry,
                &onEntryActivate,
            );
        }

        // Connect generate button
        if (priv.generate_button) |btn| {
            _ = btn.signals.clicked.connect(
                btn,
                &onGenerateClicked,
            );
        }

        // Connect execute button
        if (priv.execute_button) |btn| {
            _ = btn.signals.clicked.connect(
                btn,
                &onExecuteClicked,
            );
        }

        // Connect cancel button
        if (priv.cancel_button) |btn| {
            _ = btn.signals.clicked.connect(
                btn,
                &onCancelClicked,
            );
        }

        // Initialize text buffer
        priv.response_buffer = gtk.TextBuffer.new(null);
        if (priv.response_view) |view| {
            view.setBuffer(priv.response_buffer);
        }
    }

    pub fn present(self: *Self, parent: ?*gtk.Widget) void {
        const priv = self.private();

        // Focus on entry field
        if (priv.entry) |entry| {
            gtk.Widget.grabFocus(entry);
        }

        // Clear previous content
        self.clearResponse();

        // Show it
        self.as(Dialog).present(parent);
    }

    pub fn setContextCollector(self: *Self, collector: *ai.ContextCollector) void {
        self.private().config = collector;
    }

    pub fn appendResponse(self: *Self, text: []const u8) void {
        const priv = self.private();
        if (priv.response_buffer) |buffer| {
            var iter = gtk.TextBuffer.getEndIter(buffer);
            _ = gtk.TextBuffer.insert(buffer, &iter, text);
        }
    }

    pub fn setGeneratedCommand(self: *Self, command: []const u8) void {
        const priv = self.private();

        // Free previous command
        if (priv.generated_command) |prev| {
            priv.allocator.free(prev);
        }

        priv.generated_command = priv.allocator.dupe(u8, command) catch return;
        priv.pending_request = false;

        // Enable execute button
        if (priv.execute_button) |btn| {
            btn.setSensitive(true);
        }

        // Append command to response
        self.appendResponse("\n\n");
        self.appendResponse("Suggested command:\n");
        self.appendResponse(command);
    }

    pub fn getGeneratedCommand(self: *Self) ?[]const u8 {
        return self.private().generated_command;
    }

    pub fn clearResponse(self: *Self) void {
        const priv = self.private();
        if (priv.response_buffer) |buffer| {
            const text = gtk.TextBuffer.getText(buffer, null, null, false);
            if (text) |t| {
                priv.allocator.free(t);
            }
            gtk.TextBuffer.set_text(buffer, "", 0);
        }

        if (priv.generated_command) |cmd| {
            priv.allocator.free(cmd);
            priv.generated_command = null;
        }

        priv.pending_request = false;

        // Disable execute button
        if (priv.execute_button) |btn| {
            btn.setSensitive(false);
        }
    }

    pub fn setLoading(self: *Self, loading: bool) void {
        const priv = self.private();
        priv.pending_request = loading;

        // Disable buttons during loading
        if (priv.generate_button) |btn| {
            btn.setSensitive(!loading);
        }
        if (priv.entry) |entry| {
            entry.setEditable(!loading);
        }
    }

    fn onEntryActivate(entry: *gtk.Entry) callconv(.c) void {
        const text = entry.getText();
        if (text.len == 0) return;

        // Get parent AIPanel
        const self = gobject.ext.cast(Self, entry) orelse return;
        const priv = self.private();

        if (priv.pending_request) return;

        // Add user query to response
        self.appendResponse("> ");
        self.appendResponse(text);
        self.appendResponse("\n");

        // Emit generate request
        signals.@"generate-request".impl.emit(
            self,
            null,
            .{ text },
            null,
        );
    }

    fn onGenerateClicked(button: *gtk.Button) callconv(.c) void {
        // Trigger entry activate
        const self = gobject.ext.cast(Self, button) orelse return;
        const priv = self.private();

        if (priv.entry) |entry| {
            const text = entry.getText();
            if (text.len > 0 and !priv.pending_request) {
                onEntryActivate(entry);
            }
        }
    }

    fn onExecuteClicked(button: *gtk.Button) callconv(.c) void {
        const self = gobject.ext.cast(Self, button) orelse return;
        const priv = self.private();

        if (priv.generated_command) |cmd| {
            signals.@"execute-request".impl.emit(
                self,
                null,
                .{ cmd },
                null,
            );
        }

        self.close();
    }

    fn onCancelClicked(button: *gtk.Button) callconv(.c) void {
        const self = gobject.ext.cast(Self, button) orelse return;
        signals.cancel.impl.emit(
            self,
            null,
            .{},
            null,
        );
        self.close();
    }

    fn dispose(self: *Self) callconv(.c) void {
        const priv = self.private();

        // Free generated command
        if (priv.generated_command) |cmd| {
            priv.allocator.free(cmd);
        }

        gtk.Widget.disposeTemplate(
            self.as(gtk.Widget),
            getGObjectType(),
        );

        gobject.Object.virtual_methods.dispose.call(
            Class.parent,
            self.as(Parent),
        );
    }

    const C = Common(Self, Private);
    pub const as = C.as;
    pub const ref = C.ref;
    pub const refSink = C.refSink;
    pub const unref = C.unref;
    const private = C.private;

    pub const Class = extern struct {
        parent_class: Parent.Class,
        var parent: *Parent.Class = undefined;
        pub const Instance = Self;

        fn init(class: *Class) callconv(.c) void {
            gobject.ext.ensureType(Dialog);
            gtk.Widget.Class.setTemplateFromResource(
                class.as(gtk.Widget.Class),
                comptime gresource.blueprint(.{
                    .major = 1,
                    .minor = 5,
                    .name = "ai-panel",
                }),
            );

            gobject.ext.bindTemplateChild(
                class.as(gtk.Widget.Class),
                Self,
                "entry",
                false,
                @offsetOf(Private, "entry"),
                0,
            );

            gobject.ext.bindTemplateChild(
                class.as(gtk.Widget.Class),
                Self,
                "response_view",
                false,
                @offsetOf(Private, "response_view"),
                0,
            );

            gobject.ext.bindTemplateChild(
                class.as(gtk.Widget.Class),
                Self,
                "generate_button",
                false,
                @offsetOf(Private, "generate_button"),
                0,
            );

            gobject.ext.bindTemplateChild(
                class.as(gtk.Widget.Class),
                Self,
                "execute_button",
                false,
                @offsetOf(Private, "execute_button"),
                0,
            );

            gobject.ext.bindTemplateChild(
                class.as(gtk.Widget.Class),
                Self,
                "cancel_button",
                false,
                @offsetOf(Private, "cancel_button"),
                0,
            );

            class.as(gobject.Object.Class).dispose = &dispose;
        }

        pub fn as(class: *Class, comptime T: type) *T {
            return gobject.ext.as(T, class);
        }
    };
};

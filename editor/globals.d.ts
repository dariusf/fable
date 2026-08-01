type AceEditor = import("ace-builds").Ace.Editor;
type AceEditSession = import("ace-builds").Ace.EditSession;
type AcePoint = import("ace-builds").Ace.Point;
type AceCompletion = import("ace-builds").Ace.Completion;
type AceCompleter = import("ace-builds").Ace.Completer;

declare const ace: typeof import("ace-builds") & {
  config: import("ace-builds").Ace.Config & {
    loadModule(name: string, onLoad: (module: { Vim: any }) => void): void;
  };
};

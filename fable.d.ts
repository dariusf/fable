// Type declarations for the Fable OCaml library.
// See fabula/machine.mli and fablejs.ml.

type ChoiceId = number & { readonly __kind: "choice" };
type NodeId = number & { readonly __kind: "node" };
type LinkId = number & { readonly __kind: "link" };

type Inline =
  | { type: "text"; text: string }
  | { type: "space" }
  | { type: "verbatim"; html: string }
  | { type: "link"; linkId: LinkId; label: string }
  | { type: "emph"; content: Inline[] };

type FableEvent =
  | { type: "para"; content: Inline[] }
  | { type: "verbatimBlock"; html: string }
  | {
      type: "choices";
      nodeId: NodeId;
      items: { choiceId: ChoiceId; content: Inline[] }[];
    }
  | { type: "removeChoices"; nodeId: NodeId }
  | { type: "markOld" }
  | { type: "error"; message: string };

type Status = "running" | "awaiting" | "halted" | "done";

interface Result {
  status: Status;
  events: FableEvent[];
  choices: { choiceId: ChoiceId; label: string }[];
  diverged?: boolean;
  divergedAt?: string;
}

// Capabilities the machine needs from its host
interface Host {
  eval(code: string): unknown;
  seed: number;
}

interface FableMachine {
  start(): Result;
  choose(choiceId: ChoiceId): Result;
  chooseByLabel(label: string): Result;
  activate(linkId: LinkId): Result;
  activateByLabel(label: string): Result;
  rewind(n?: number): Result;
  loadSaved(labels: string[]): Result;
  hotReload(story: Story): Result;
  status(): Status;
  choices(): { choiceId: ChoiceId; label: string }[];
  turns(): number;
  currentScene(): string | null;
  history(): string[];
  turnsSince(scene: string): number;
  seen(scene: string): number;
  seed(): number;

  // Replay-safe randomness

  /** Random float in [0, 1) */
  random(): number;
  /** Random integer in [lo, hi]. */
  randomIncl(lo: number, hi: number): number;
  /** Random integer in [lo, hi). */
  randomExcl(lo: number, hi: number): number;
  coin(): boolean;
}

declare const Machine: {
  create(story: Story, host: Host): FableMachine;
};

interface Story {
  frontmatter: Record<string, string>;
  // instructions are abstract
  scenes: { name: string; cmds: unknown[] }[];
}

// Defined by story.js
declare var story: Story;

// Editor -> story iframe protocol
type EditorMsg =
  | { type: "LOAD"; md: string }
  | { type: "EDIT"; md: string }
  | { type: "BACK" }
  | { type: "CHOOSE"; index: number };

// Story iframe -> editor protocol
type StoryMsg =
  | { type: "READY" }
  | { type: "STATUS"; historyLength: number; divergedAt?: string };

declare const Fable: {
  parse(markdown: string): Story;
  graph(markdown: string): string;
  produceStyleOverride(frontmatter: Record<string, string>): string;
};

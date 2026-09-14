interface SaveData {
  choices: string[];
  seed?: number;
}

// Capabilities the runtime needs from its environment (browser or test harness)
interface RuntimeCapabilities {
  render(events: FableEvent[], scrollBehavior?: ScrollBehavior): void;
  clear(): void;
  defaultSeed(): number;
  storage: {
    get(): SaveData | null;
    set(save: SaveData): void;
    clear(): void;
  };
  configure?(frontmatter: Record<string, string>): void;
  afterInteract?(): void;
}

// The user defines this to load assets and such
declare var init: (() => Promise<void> | void) | undefined;

declare var afterRender: (() => void) | undefined;

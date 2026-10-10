interface SaveData {
  choices: HistoryEntry[];
  // every write includes a seed, some paths initialising this don't include a seed
  seed?: number;
  data?: Record<string, any>;
}

// Capabilities the runtime needs from its environment (browser or test harness)
interface RuntimeCapabilities {
  render(events: FableEvent[], scrollBehavior?: ScrollBehavior): void;
  clear(): void;
  defaultSeed(): number;
  storage: {
    get(key: string): SaveData | null;
    set(key: string, save: SaveData): void;
    clear(key: string): void;
  };
  configure?(frontmatter: Record<string, string>): void;
  afterInteract?(): void;
  readWidgets?(): Record<string, string>;
}

// The user defines this to load assets and such
declare var init: (() => Promise<void> | void) | undefined;

declare var afterRender: (() => void) | undefined;

declare var beforeSave: (() => void) | undefined;

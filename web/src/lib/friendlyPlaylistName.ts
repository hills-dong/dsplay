/**
 * Map Synology's internal playlist sentinels (e.g. `__SYNO_AUDIO_SHARED_SONGS__`)
 * to human-readable names. Falls through to the raw name otherwise.
 */
const KNOWN: Record<string, string> = {
  "__SYNO_AUDIO_SHARED_SONGS__": "Shared Songs",
  "__SYNO_AUDIO_FAVORITES__": "Favorites",
};

export function friendlyPlaylistName(name: string): string {
  if (KNOWN[name]) return KNOWN[name];
  // Strip leading/trailing underscores from anything else like __FOO__ → Foo
  const m = name.match(/^_+(.+?)_+$/);
  if (m) {
    return m[1]
      .toLowerCase()
      .replace(/_+/g, " ")
      .replace(/\b\w/g, (c) => c.toUpperCase());
  }
  return name;
}

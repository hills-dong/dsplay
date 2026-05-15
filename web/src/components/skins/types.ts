import type { Track } from "../../types";

export interface SkinProps {
  track: Track;
  isPlaying: boolean;
  position: number;
  duration: number;
  coverUrl: string;          // empty string if no cover available
  onPlayPause: () => void;
  onSeek: (seconds: number) => void;
  onNext: () => void;
  onPrev: () => void;
  onClose: () => void;
}

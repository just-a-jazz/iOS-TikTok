# TikTok Clone Architecture

Architecture notes for the proof‑of‑concept infinitely scrolling reel feed with inline messaging. The focus is on smooth video playback, controlled resource usage, and keyboard‑friendly UX.

## High‑level structure
- **UI composition** (`Features/Reels/Views`): SwiftUI feed built with `ScrollView` + `LazyVStack` + `.scrollTargetBehavior(.paging)` to mimic TikTok/Reels snapping in `Home.swift`. Each cell hosts `ReelView`, AVPlayer rendering via `ReelPlayerUIView` (UIKit wrapper), and the inline composer (`InlineMessagingBar.swift`).
- **State & orchestration** (`ReelFeedViewModel.swift`): Single observable view model binds scrolling position, typing state, and delegates playback to the coordinator. Guard rails prevent advancing to reels that are not yet ready.
- **Playback domain** (`Features/Reels/Playback`): `ReelPlaybackCoordinator` owns a bounded pool of `ReelPlayer` instances and applies buffer/bitrate policies per proximity. `PrefetchConfig.swift` centralizes window sizing and buffer tuning. `ReelPlayer` wraps `AVPlayer`, exposes readiness, and handles looping.
- **Data** (`ReelService.swift`): Fetches the manifest from the provided CDN and initializes `Reel` models.

## Feed & scrolling strategy
- **Paging feed**: Pure SwiftUI scroll view provides natural scroll physics and smooth transitions avoiding UIKit complexity while allowing `.scrollPosition(id:)` to keep the active reel in sync with playback. Tradeoff: Scrolling past currently loading reels causes subtle snapping animation that can feel glitchy if network is very bad. Creating a custom gesture solution would solve this but increase code and view complexity.
- **Active reel gating**: `ReelFeedViewModel.resolveActiveReelChange` blocks jumps beyond a not‑ready reel and falls back to the last loaded reel. This keeps UX responsive (no black frames) at the cost of occasionally “snapping back” if the user scrolls faster than readiness.
- **Loading & readiness overlay**: `ReelView` overlays a spinner until `ReelPlayer.isReadyToPlay` to signal buffering instead of just showing a stalled frame. Uses a completion handler to unlock UI as soon as possible for a smooth UX and scrolling experience.
- **Looping**: `ReelPlayer` listens for `.AVPlayerItemDidPlayToEndTime` and seeks to `.zero`, avoiding `AVQueuePlayer` complexity while keeping memory predictable. I intentionally skipped `AVPlayerLooper` (which keeps multiple items queued and buffers them at the same time to manage looping) to reduce extra memory/CPU/network churn; the notification observer for `.AVPlayerItemDidPlayToEndTime` only exists while the reel is inside the active window and is torn down when it leaves.

## Playback lifecycle, reuse, and memory
- **Bounded pool**: Pool size 5 (2 ahead, 2 behind) ensures only a small set of `AVPlayer`/`AVPlayerItem` objects exist simultaneously ensuring smooth scrolling. Tradeoff: Reuse logic introduces complexity. Alternative would be to have a `AVPlayer`/`AVPlayerItem` per reel which would introduce chances of memory leaking when having to deinitialize a `AVPlayer`/`AVPlayerItem` object after every scroll, and require significantly higher CPU usage to do so resulting in laggy scrolling when doing quickly.
- **Reuse policy**: If the pool is full, the coordinator selects the farthest reel (prefer outside the active window) and retargets the existing player via `ReelPlayer.configure`. This reuses buffer warmth but resets readiness; slight delay is acceptable versus the cost of allocating new players.
- **Status‑driven buffering**: `ReelPlaybackCoordinator` assigns `ReelPlayer.Status` based on proximity. `ReelPlayer.applyStatus` adjusts `preferredForwardBufferDuration` and `preferredPeakBitRate`, prioritizing the active reel, warming neighbors, and throttling distant items. Tradeoff: relies on AVPlayer heuristics instead of custom HLS segment prefetching, but keeps implementation lean and CDN‑friendly.
- **Readiness callback**: `ReelPlayer.whenReadyToPlay` defers `.play()` until `.readyToPlay` to avoid black frames; the coordinator rechecks that the reel is still active before starting, preventing race conditions on fast scrolls.

## Network & prefetch considerations
- **Manifest fetch**: Simple `URLSession` request to the provided manifest (`ReelService.fetchReels`).
- **Prefetch stance**: Leverages AVPlayer’s buffering knobs instead of manual HLS segment management. This minimizes implementation time and integrates with adaptive bitrate which watches network conditions and playback headroom, then chooses which HLS variant bitrate to request next. Tradeoff: limits explicit control over disk caching and exact segment prefetching policies. Alternative: Custom prefetch via `AVAssetResourceLoader` or a dedicated “warm-up” `AVURLAsset` pipeline which would increase complexity and control.
- **Failure handling**: Errors surface to `errorMessage`; retry/backoff and offline cache are not yet implemented.

## Inline messaging UX & focus management
- **Hybrid text control**: `InlineMessagingBar` embeds a UIKit `UITextView` (`GrowingTextView`) to get reliable multi‑line growth and internal scrolling after 5 lines, while the surrounding view stays SwiftUI. A separate messaging bar is created for each reel to allow users to input messages, scroll away, and come back to their unfinished message. Alternative: a pure SwiftUI `TextEditor` would improve view hierarchy/readability and allow for simple state management through bindings, but offers less precise sizing and keyboard control.
- **Focus rules**: The composer drives `viewModel.isTyping`; when focused, `ScrollView` is disabled and the active player is paused. Unfocusing resumes playback. This matches the requirement that swipes should scroll text, and not the feed.
- **Keyboard ergonomics**: The bar pins above the keyboard via safe‑area padding, the feed stays stationary, and the video is dimmed while typing. Reaction buttons fade/move out when focused; the send button only appears with non‑empty text, and expands with the bar.
- **Input behavior**: Send trims/clears text, hides keyboard, and calls `onSend`. Placeholder is low‑opacity white; accessibility labels added for input and actions.

## Responsiveness & transitions
- **Smooth paging**: `.scrollTargetBehavior(.paging)` gives consistent snap without custom gesture tuning; animations on focus/placeholder/reactions use short `.easeOut` or spring responses to keep UI lively.
- **Black‑frame avoidance**: Active reel change waits on readiness and blocks leaps past unready reels.
- **Loop continuity**: Manual loop avoids flashes at end of item and keeps timeline stable during reuse.

## Future expansions
- Clean up code further so that `reels` and `activeReelId` isn't being duplicated to `ReelPlaybackCoordinator`
- Improve network resilience (retry, offline caching, HLS asset prewarming) and adopt `AVPlayerItemPreferredForwardBufferDuration` tuning per network conditions.
- Tune scroll physics with a custom gesture recognizer if finer velocity control is needed.
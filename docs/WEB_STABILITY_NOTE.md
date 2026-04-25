# Web Stability Note (April 2026)

## Symptom

On GitHub Pages (`https://aalmaz1.github.io/glass_keep_app/`) after successful login (`LOGGED_IN`) the app could render an almost white/empty screen. In many cases only the top search bar and the **New Note** button were visible.

## Reproduced behavior

- Renderer: **skwasm** (`window._flutter_skwasmInstance === true`)
- Auth transitioned to `LOGGED_IN` successfully.
- No Firebase/Auth initialization errors in console.
- Notes UI shell was mounted, but background rendering became visually broken (white/blank), making content appear missing.

## Root causes

1. **Runtime shader path on web/wasm**
   - `FragmentProgram` film grain shader path was active on web.
   - In skwasm release path this rendering path is not stable enough for this UI composition and can produce a broken white background layer.

2. **Notes stream robustness after auth transition**
   - Notes stream creation depended on current auth state at creation time and had no timeout fallback.
   - Under transient web/network conditions this could keep the content area in a long-loading state.

## What was changed

### 1) Safe shader fallback for web

- Runtime shader loading is now disabled on web in `main.dart`.
- Noise painter has a guarded fallback path:
  - uses cached lightweight noise when shader is unavailable,
  - auto-falls back if shader paint throws.

### 2) Safer notes stream lifecycle

- Notes stream now waits for a valid authenticated user before opening Firestore listener (race-safe startup).
- Added timeout fallback to cached/empty notes to avoid indefinite waiting states.
- Replaced fragile cached lookup pattern with explicit safe lookup helper.

### 3) CI web build deploy hardening

- GitHub Pages `base-href` is now derived dynamically from repository name:
  - `--base-href="/${{ github.event.repository.name }}/"`

## How to verify

1. Build web release (wasm) and serve build output.
2. Login with a valid account.
3. Confirm Notes screen renders with normal dark background (not white/blank).
4. Confirm there are no runtime null-check crashes in the post-login render path.
5. Confirm GitHub Actions web build/deploy uses correct base path for Pages.

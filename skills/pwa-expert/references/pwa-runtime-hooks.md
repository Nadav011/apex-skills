# PWA Runtime Hooks v24.5.0 NVIDIA-LEVEL

> React hooks for NVIDIA-level PWA performance

## Hook Index

| Hook | Purpose | Impact |
|------|---------|--------|
| usePageLifecycle | Page freeze/resume handling | 0% CPU frozen |
| useIdleCallback | Background task scheduling | Non-blocking work |
| useCacheSync | Multi-tab cache synchronization | Consistent UX |
| useBfcache | Back/forward cache handling | 10x faster navigation |
| usePageVisibility | Visibility state tracking | Pause operations |
| useAppBadge | App badge management | Notification count |
| useAndroidBackButton | Android back prevention | UX improvement |
| useWebShare | Web Share API | Native sharing |

---

## 1. usePageLifecycle

```typescript
// src/hooks/pwa/usePageLifecycle.ts
import { useEffect, useState } from "react";

// React Compiler auto-memoizes — no manual useCallback needed

export type PageLifecycleState =
  | "active"
  | "passive"
  | "hidden"
  | "frozen"
  | "terminated";

export interface UsePageLifecycleOptions {
  onFreeze?: () => void;
  onResume?: () => void;
  onHidden?: () => void;
  onVisible?: () => void;
}

export interface UsePageLifecycleReturn {
  state: PageLifecycleState;
  isFrozen: boolean;
  isVisible: boolean;
  isActive: boolean;
}

export function usePageLifecycle(
  options: UsePageLifecycleOptions = {}
): UsePageLifecycleReturn {
  const { onFreeze, onResume, onHidden, onVisible } = options;
  const [state, setState] = useState<PageLifecycleState>("active");

  useEffect(() => {
    const handleFreeze = () => {
      onFreeze?.();
      setState("frozen");
    };

    const handleResume = () => {
      onResume?.();
      setState("active");
    };

    const handleVisibilityChange = () => {
      if (document.hidden) {
        onHidden?.();
        setState("hidden");
      } else {
        onVisible?.();
        setState(document.hasFocus() ? "active" : "passive");
      }
    };

    document.addEventListener("freeze", handleFreeze);
    document.addEventListener("resume", handleResume);
    document.addEventListener("visibilitychange", handleVisibilityChange);

    return () => {
      document.removeEventListener("freeze", handleFreeze);
      document.removeEventListener("resume", handleResume);
      document.removeEventListener("visibilitychange", handleVisibilityChange);
    };
  }, [onFreeze, onResume, onHidden, onVisible]);

  return {
    state,
    isFrozen: state === "frozen",
    isVisible: !document.hidden,
    isActive: state === "active",
  };
}
```

**Usage:**

```tsx
function App() {
  const { state, isFrozen } = usePageLifecycle({
    onFreeze: () => {
      // Save state, pause timers
      saveAppState();
    },
    onResume: () => {
      // Restore state, refresh data
      queryClient.invalidateQueries();
    },
  });

  return <div>State: {state}</div>;
}
```

---

## 2. useIdleCallback

```typescript
// src/hooks/pwa/useIdleCallback.ts
import { useEffect, useRef, useState } from "react";

// React Compiler auto-memoizes — no manual useCallback needed

export interface UseIdleCallbackOptions {
  timeout?: number;
}

export function useIdleCallback(
  callback: () => void,
  options?: UseIdleCallbackOptions
): void {
  const callbackRef = useRef(callback);
  callbackRef.current = callback;

  useEffect(() => {
    if ("requestIdleCallback" in window) {
      const id = requestIdleCallback(() => callbackRef.current(), options);
      return () => cancelIdleCallback(id);
    } else {
      // Safari fallback
      const id = setTimeout(() => callbackRef.current(), 1);
      return () => clearTimeout(id);
    }
  }, [options?.timeout]);
}

// Process arrays in idle periods
export function useIdleChunkedWork<T>(
  items: T[],
  processor: (item: T) => void,
  chunkSize = 10
): { isProcessing: boolean; progress: number } {
  const [progress, setProgress] = useState(0);
  const [isProcessing, setIsProcessing] = useState(false);

  useEffect(() => {
    if (items.length === 0) return;

    let processed = 0;
    setIsProcessing(true);

    const processChunk = (deadline: IdleDeadline) => {
      while (processed < items.length && deadline.timeRemaining() > 0) {
        processor(items[processed]);
        processed++;
        setProgress((processed / items.length) * 100);
      }

      if (processed < items.length) {
        requestIdleCallback(processChunk);
      } else {
        setIsProcessing(false);
      }
    };

    if ("requestIdleCallback" in window) {
      requestIdleCallback(processChunk);
    } else {
      // Fallback: process all immediately
      items.forEach(processor);
      setProgress(100);
      setIsProcessing(false);
    }
  }, [items, processor, chunkSize]);

  return { isProcessing, progress };
}

// Defer function to idle
// React Compiler auto-memoizes the returned function
export function useDeferToIdle<T extends (...args: unknown[]) => void>(
  callback: T
): T {
  const callbackRef = useRef(callback);
  callbackRef.current = callback;

  const deferred = ((...args: Parameters<T>) => {
    if ("requestIdleCallback" in window) {
      requestIdleCallback(() => callbackRef.current(...args));
    } else {
      setTimeout(() => callbackRef.current(...args), 1);
    }
  }) as T;

  return deferred;
}
```

**Usage:**

```tsx
function HeavyList({ items }) {
  const { isProcessing, progress } = useIdleChunkedWork(
    items,
    (item) => processItem(item),
    50
  );

  return (
    <div>
      {isProcessing && <ProgressBar value={progress} />}
      <List items={items} />
    </div>
  );
}
```

---

## 3. useCacheSync

```typescript
// src/hooks/useCacheSync.ts
import { useEffect } from "react";
import { useQueryClient } from "@tanstack/react-query";

// React Compiler auto-memoizes — no manual useCallback needed

export type CacheSyncMessageType =
  | "CACHE_UPDATED"
  | "CACHE_INVALIDATED"
  | "DATA_CHANGED";

export interface CacheSyncMessage {
  type: CacheSyncMessageType;
  url?: string;
  queryKey?: string[];
  timestamp: number;
}

export interface UseCacheSyncOptions {
  channelName?: string;
  onMessage?: (message: CacheSyncMessage) => void;
}

export interface UseCacheSyncReturn {
  broadcast: (message: Omit<CacheSyncMessage, "timestamp">) => void;
}

export function useCacheSync(
  options: UseCacheSyncOptions = {}
): UseCacheSyncReturn {
  const { channelName = "cache-updates", onMessage } = options;
  const queryClient = useQueryClient();

  // React Compiler auto-memoizes this function
  const broadcast = (message: Omit<CacheSyncMessage, "timestamp">) => {
    const channel = new BroadcastChannel(channelName);
    channel.postMessage({
      ...message,
      timestamp: Date.now(),
    });
    channel.close();
  };

  useEffect(() => {
    const channel = new BroadcastChannel(channelName);

    channel.onmessage = (event: MessageEvent<CacheSyncMessage>) => {
      const message = event.data;
      onMessage?.(message);

      switch (message.type) {
        case "CACHE_UPDATED":
        case "CACHE_INVALIDATED":
          if (message.queryKey) {
            queryClient.invalidateQueries({ queryKey: message.queryKey });
          } else {
            queryClient.invalidateQueries();
          }
          break;
        case "DATA_CHANGED":
          queryClient.invalidateQueries();
          break;
      }
    };

    return () => channel.close();
  }, [channelName, queryClient, onMessage]);

  return { broadcast };
}
```

**Usage:**

```tsx
function App() {
  const { broadcast } = useCacheSync({
    onMessage: (msg) => console.log("Cache sync:", msg),
  });

  const handleSave = async () => {
    await saveData();
    broadcast({ type: "DATA_CHANGED" });
  };

  return <button onClick={handleSave}>Save</button>;
}
```

---

## 4. useBfcache

```typescript
// src/hooks/pwa/useBfcache.ts
import { useEffect } from "react";
import { useQueryClient } from "@tanstack/react-query";

// React Compiler auto-memoizes — no manual useCallback needed

export interface UseBfcacheOptions {
  onFreeze?: () => void;
  onResume?: () => void;
  stateToSave?: () => unknown;
  storageKey?: string;
}

export interface UseBfcacheReturn {
  isRestored: boolean;
  savedState: unknown | null;
}

export function useBfcache(
  options: UseBfcacheOptions = {}
): UseBfcacheReturn {
  const {
    onFreeze,
    onResume,
    stateToSave,
    storageKey = "bfcache-state",
  } = options;
  const queryClient = useQueryClient();

  useEffect(() => {
    const handlePageShow = (event: PageTransitionEvent) => {
      if (event.persisted) {
        // Page was restored from bfcache
        onResume?.();
        queryClient.invalidateQueries();
      }
    };

    const handlePageHide = (event: PageTransitionEvent) => {
      if (event.persisted) {
        // Page is being frozen
        if (stateToSave) {
          sessionStorage.setItem(storageKey, JSON.stringify(stateToSave()));
        }
        onFreeze?.();
      }
    };

    window.addEventListener("pageshow", handlePageShow);
    window.addEventListener("pagehide", handlePageHide);

    return () => {
      window.removeEventListener("pageshow", handlePageShow);
      window.removeEventListener("pagehide", handlePageHide);
    };
  }, [onFreeze, onResume, stateToSave, storageKey, queryClient]);

  // Check if we were restored
  const savedState = sessionStorage.getItem(storageKey);

  return {
    isRestored: savedState !== null,
    savedState: savedState ? JSON.parse(savedState) : null,
  };
}
```

**Usage:**

```tsx
function App() {
  const { isRestored, savedState } = useBfcache({
    stateToSave: () => ({
      scrollY: window.scrollY,
      formData: getFormData(),
    }),
    onResume: () => {
      toast.info("Welcome back!");
    },
  });

  useEffect(() => {
    if (isRestored && savedState) {
      window.scrollTo(0, savedState.scrollY);
      restoreFormData(savedState.formData);
    }
  }, [isRestored, savedState]);

  return <App />;
}
```

---

## 5. usePageVisibility

```typescript
// src/hooks/pwa/usePageVisibility.ts
import { useState, useEffect } from "react";

// React Compiler auto-memoizes — no manual useCallback needed

export interface UsePageVisibilityOptions {
  onVisible?: () => void;
  onHidden?: () => void;
  recentThreshold?: number;
}

export interface PageVisibilityState {
  isVisible: boolean;
  wasRecentlyHidden: boolean;
  hiddenAt: number | null;
  visibleAt: number | null;
}

export function usePageVisibility(
  options: UsePageVisibilityOptions = {}
): PageVisibilityState {
  const { onVisible, onHidden, recentThreshold = 5000 } = options;
  const [isVisible, setIsVisible] = useState(() => !document.hidden);
  const [hiddenAt, setHiddenAt] = useState<number | null>(null);
  const [visibleAt, setVisibleAt] = useState<number | null>(null);

  useEffect(() => {
    const handleVisibilityChange = () => {
      const nowVisible = !document.hidden;
      setIsVisible(nowVisible);

      if (nowVisible) {
        setVisibleAt(Date.now());
        onVisible?.();
      } else {
        setHiddenAt(Date.now());
        onHidden?.();
      }
    };

    document.addEventListener("visibilitychange", handleVisibilityChange);
    return () =>
      document.removeEventListener("visibilitychange", handleVisibilityChange);
  }, [onVisible, onHidden]);

  const wasRecentlyHidden =
    hiddenAt !== null && Date.now() - hiddenAt < recentThreshold;

  return { isVisible, wasRecentlyHidden, hiddenAt, visibleAt };
}

// Pause operations when hidden
export function usePauseWhenHidden(
  pauseCallback: () => void,
  resumeCallback: () => void
): void {
  usePageVisibility({
    onHidden: pauseCallback,
    onVisible: resumeCallback,
  });
}
```

---

## 6. useAppBadge

```typescript
// src/hooks/pwa/useAppBadge.ts
// React Compiler auto-memoizes — no manual useCallback needed

export interface UseAppBadgeReturn {
  isSupported: boolean;
  setBadge: (count: number) => Promise<void>;
  clearBadge: () => Promise<void>;
}

export function useAppBadge(): UseAppBadgeReturn {
  const isSupported = typeof navigator.setAppBadge === "function";

  const setBadge = async (count: number) => {
    if (!navigator.setAppBadge) return;

    try {
      if (count <= 0) {
        await navigator.clearAppBadge();
      } else {
        await navigator.setAppBadge(count);
      }
    } catch (error) {
      console.warn("App badge not supported:", error);
    }
  };

  const clearBadge = async () => {
    if (!navigator.clearAppBadge) return;

    try {
      await navigator.clearAppBadge();
    } catch (error) {
      console.warn("App badge not supported:", error);
    }
  };

  return { isSupported, setBadge, clearBadge };
}
```

---

## 7. useAndroidBackButton

```typescript
// src/hooks/pwa/useAndroidBackButton.ts
import { useEffect, useRef } from "react";
import { useNavigate, useLocation } from "react-router-dom";

// React Compiler auto-memoizes — no manual useCallback needed

export interface UseAndroidBackButtonOptions {
  exitDelay?: number;
  onExitAttempt?: () => void;
  preventExitOnRoot?: boolean;
}

function isPWAStandalone(): boolean {
  return (
    window.matchMedia("(display-mode: standalone)").matches ||
    (window.navigator as any).standalone === true
  );
}

export function useAndroidBackButton(
  options: UseAndroidBackButtonOptions = {}
): void {
  const { exitDelay = 2000, onExitAttempt, preventExitOnRoot = true } = options;
  const navigate = useNavigate();
  const location = useLocation();
  const lastBackPressRef = useRef<number>(0);

  useEffect(() => {
    if (!isPWAStandalone()) return;

    const handlePopState = (event: PopStateEvent) => {
      const isAtRoot = location.pathname === "/" || location.pathname === "";
      const now = Date.now();

      if (isAtRoot && preventExitOnRoot) {
        if (now - lastBackPressRef.current >= exitDelay) {
          // First press - show warning
          event.preventDefault();
          lastBackPressRef.current = now;
          window.history.pushState(null, "", location.pathname);
          navigator.vibrate?.(50);
          onExitAttempt?.();
          return;
        }
        // Second press within delay - allow exit
      }

      navigate(-1);
    };

    // Push initial state
    window.history.pushState(null, "", location.pathname);

    window.addEventListener("popstate", handlePopState);
    return () => window.removeEventListener("popstate", handlePopState);
  }, [navigate, location, exitDelay, preventExitOnRoot, onExitAttempt]);
}
```

---

## 8. useWebShare

```typescript
// src/hooks/pwa/useWebShare.ts
// React Compiler auto-memoizes — no manual useCallback needed

export interface ShareData {
  title?: string;
  text?: string;
  url?: string;
  files?: File[];
}

export interface UseWebShareReturn {
  isSupported: boolean;
  canShareFiles: boolean;
  share: (data: ShareData) => Promise<boolean>;
}

export function useWebShare(): UseWebShareReturn {
  const isSupported = typeof navigator.share === "function";
  const canShareFiles =
    isSupported && typeof navigator.canShare === "function";

  // React Compiler auto-memoizes this function
  const share = async (data: ShareData): Promise<boolean> => {
    if (!isSupported) return false;

    // Check if we can share this data
    if (data.files && canShareFiles) {
      if (!navigator.canShare({ files: data.files })) {
        console.warn("Cannot share files of this type");
        return false;
      }
    }

    try {
      await navigator.share(data);
      return true;
    } catch (error) {
      if ((error as Error).name !== "AbortError") {
        console.error("Share failed:", error);
      }
      return false;
    }
  };

  return { isSupported, canShareFiles, share };
}
```

---

## Export Index

```typescript
// src/hooks/pwa/index.ts
export { usePageLifecycle } from "./usePageLifecycle";
export { useIdleCallback, useIdleChunkedWork, useDeferToIdle } from "./useIdleCallback";
export { useCacheSync } from "./useCacheSync";
export { useBfcache } from "./useBfcache";
export { usePageVisibility, usePauseWhenHidden } from "./usePageVisibility";
export { useAppBadge } from "./useAppBadge";
export { useAndroidBackButton } from "./useAndroidBackButton";
export { useWebShare } from "./useWebShare";
```

---

<!-- PWA_RUNTIME_HOOKS v24.5.0 | Updated: 2026-02-19 -->

"use client";

import clsx from "clsx";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Activity, Boxes, Clock3, Cpu, History, Moon, PlayCircle, Settings, Sun } from "lucide-react";
import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import { fetchActiveTasks, fetchProviders } from "@/services/apiClient";
import type { HubProject, RunningTask } from "@/services/types";

type ThemeMode = "dark" | "light";
type SettingsTabId = "running" | "history";

const navigationItems = [
  {
    href: "/",
    label: "Home",
    icon: Cpu,
    match: "exact",
  },
  {
    href: "/hub",
    label: "Hub",
    icon: Boxes,
    match: "exact",
  },
] as const;

const settingsTabs: Array<{ id: SettingsTabId; label: string }> = [
  { id: "running", label: "Đang chạy" },
  { id: "history", label: "Lịch sử" },
];

function applyHubPerformanceMode() {
  const root = document.documentElement;
  root.style.setProperty("--page-accent", "#23b7a9");
  root.style.setProperty("--page-accent-soft", "#dff8f3");
  root.setAttribute("data-hub-performance", "balanced");
}

function clearHubPerformanceMode() {
  const root = document.documentElement;
  root.style.removeProperty("--page-accent");
  root.style.removeProperty("--page-accent-soft");
  root.removeAttribute("data-hub-performance");
}

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const currentPathname = pathname ?? "/";
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [activeSettingsTab, setActiveSettingsTab] = useState<SettingsTabId>("running");

  useEffect(() => {
    const root = document.documentElement;
    const syncTheme = () => {
      root.style.setProperty("--canvas-theme", root.dataset.theme === "light" ? "light" : "dark");
    };
    syncTheme();
    const observer = new MutationObserver(syncTheme);
    observer.observe(root, { attributes: true, attributeFilter: ["data-theme"] });
    return () => observer.disconnect();
  }, []);

  useLayoutEffect(() => {
    if (currentPathname.startsWith("/hub")) {
      applyHubPerformanceMode();
      return;
    }

    clearHubPerformanceMode();
  }, [currentPathname]);

  return (
    <div className="app-frame">
      <CanvasAtmosphere />
      <LensScrollBackground />
      <aside className="side-dock" aria-label="Dieu huong chinh">
        <Link href="/" className="brand-mark" aria-label="AI Hub Home">
          <span className="brand-core">AI</span>
        </Link>

        <nav className="dock-nav">
          {navigationItems.map((item) => {
            const Icon = item.icon;
            const isActive =
              item.match === "exact"
                ? currentPathname === item.href
                : currentPathname === item.href || currentPathname.startsWith(`${item.href}/`);

            return (
              <Link
                key={item.href}
                href={item.href}
                className={clsx("dock-link", isActive && "is-active")}
                aria-label={item.label}
                title={item.label}
                onClick={() => {
                  if (item.href.startsWith("/hub")) {
                    applyHubPerformanceMode();
                  } else {
                    clearHubPerformanceMode();
                  }
                  setIsSettingsOpen(false);
                }}
              >
                <Icon size={20} aria-hidden="true" />
              </Link>
            );
          })}
        </nav>

        <button
          className={clsx("dock-link dock-button", isSettingsOpen && "is-active")}
          type="button"
          aria-label={isSettingsOpen ? "Close settings" : "Open settings"}
          aria-expanded={isSettingsOpen}
          aria-controls="settings-panel"
          title={isSettingsOpen ? "Close settings" : "Settings"}
          onClick={() => setIsSettingsOpen((current) => !current)}
        >
          <Settings size={20} aria-hidden="true" />
        </button>
      </aside>

      <div className="content-shell">
        <header className="command-bar">
          <LiveTaskStatus />
          <ThemeToggle />
        </header>

        <button
          className={clsx("settings-scrim", isSettingsOpen && "is-open")}
          type="button"
          aria-label="Close settings"
          tabIndex={isSettingsOpen ? 0 : -1}
          onClick={() => setIsSettingsOpen(false)}
        />

        <SettingsPanel activeTab={activeSettingsTab} isOpen={isSettingsOpen} onTabChange={setActiveSettingsTab} />

        <main className="main-stage">{children}</main>
      </div>
    </div>
  );
}

function LensScrollBackground() {
  useEffect(() => {
    const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (prefersReducedMotion) return;

    const root = document.documentElement;
    const rootStyle = root.style;
    let frameId = 0;
    const isBalancedHub = () => root.dataset.hubPerformance === "balanced";
    const setLensOffsets = (lensY: number) => {
      rootStyle.setProperty("--scroll-lens-y", `${lensY}px`);
      rootStyle.setProperty("--scroll-lens-y-slow", `${Math.round(lensY * 0.16)}px`);
      rootStyle.setProperty("--scroll-lens-y-mid", `${Math.round(lensY * 0.5)}px`);
      rootStyle.setProperty("--scroll-lens-y-fast", `${Math.round(lensY * 0.72)}px`);
      rootStyle.setProperty("--scroll-lens-y-near", `${Math.round(lensY * 0.95)}px`);
      rootStyle.setProperty("--scroll-lens-y-back", `${Math.round(lensY * -0.08)}px`);
      rootStyle.setProperty("--scroll-lens-y-back-strong", `${Math.round(lensY * -0.18)}px`);
    };
    const syncLens = () => {
      frameId = 0;
      if (isBalancedHub()) {
        setLensOffsets(0);
        return;
      }

      const lensY = Math.round(window.scrollY * 0.18);
      setLensOffsets(lensY);
    };
    const requestSync = () => {
      if (!frameId) frameId = window.requestAnimationFrame(syncLens);
    };
    const observer = new MutationObserver(requestSync);

    syncLens();
    observer.observe(root, { attributes: true, attributeFilter: ["data-hub-performance"] });
    window.addEventListener("scroll", requestSync, { passive: true });
    return () => {
      observer.disconnect();
      window.removeEventListener("scroll", requestSync);
      if (frameId) window.cancelAnimationFrame(frameId);
    };
  }, []);

  return null;
}

function LiveTaskStatus() {
  const [activeTaskCount, setActiveTaskCount] = useState(0);

  useEffect(() => {
    let isMounted = true;
    const load = () => {
      const controller = new AbortController();
      void fetchActiveTasks({ signal: controller.signal, timeoutMs: 900 })
        .then((response) => {
          if (isMounted) setActiveTaskCount(response.count);
        })
        .catch(() => {
          if (isMounted) setActiveTaskCount(0);
        });
      return controller;
    };

    let controller = load();
    const interval = window.setInterval(() => {
      controller.abort();
      controller = load();
    }, 2000);

    return () => {
      isMounted = false;
      controller.abort();
      window.clearInterval(interval);
    };
  }, []);

  return (
    <div className="top-status">
      <span className="live-dot" aria-hidden="true" />
      <span>{activeTaskCount} task live</span>
    </div>
  );
}

function ThemeToggle() {
  const [theme, setTheme] = useState<ThemeMode>("dark");
  const switchTimer = useRef<number | null>(null);

  const applyTheme = useCallback((nextTheme: ThemeMode) => {
    document.documentElement.dataset.theme = nextTheme;
    window.localStorage.setItem("ai-hub-theme", nextTheme);
    setTheme(nextTheme);
  }, []);

  useEffect(() => {
    const savedTheme = window.localStorage.getItem("ai-hub-theme") as ThemeMode | null;
    const preferredTheme = window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
    const nextTheme = savedTheme ?? preferredTheme;
    applyTheme(nextTheme);
  }, [applyTheme]);

  useEffect(() => {
    return () => {
      if (switchTimer.current !== null) {
        window.clearTimeout(switchTimer.current);
      }
      delete document.documentElement.dataset.themeSwitching;
    };
  }, []);

  const handleToggleTheme = () => {
    const root = document.documentElement;
    const nextTheme = theme === "dark" ? "light" : "dark";
    root.dataset.themeSwitching = "1";
    if (switchTimer.current !== null) {
      window.clearTimeout(switchTimer.current);
    }

    window.requestAnimationFrame(() => {
      applyTheme(nextTheme);
      switchTimer.current = window.setTimeout(() => {
        delete root.dataset.themeSwitching;
      }, 120);
    });
  };

  return (
    <button
      className="theme-toggle"
      type="button"
      onClick={handleToggleTheme}
      aria-label={theme === "dark" ? "Switch to light theme" : "Switch to dark theme"}
      title={theme === "dark" ? "Light" : "Dark"}
    >
      {theme === "dark" ? <Sun size={18} aria-hidden="true" /> : <Moon size={18} aria-hidden="true" />}
    </button>
  );
}

function SettingsPanel({
  activeTab,
  isOpen,
  onTabChange,
}: {
  activeTab: SettingsTabId;
  isOpen: boolean;
  onTabChange: (tab: SettingsTabId) => void;
}) {
  const [providers, setProviders] = useState<HubProject[]>([]);
  const [tasks, setTasks] = useState<RunningTask[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [hasLoadError, setHasLoadError] = useState(false);

  useEffect(() => {
    if (!isOpen) return;

    let isMounted = true;
    const loadRuntime = () => {
      const controller = new AbortController();
      setIsLoading(true);
      setHasLoadError(false);

      void Promise.all([
        fetchProviders({ signal: controller.signal, timeoutMs: 1800 }),
        fetchActiveTasks({ signal: controller.signal, timeoutMs: 1400 }),
      ])
        .then(([providerResponse, taskResponse]) => {
          if (!isMounted) return;
          setProviders(providerResponse.providers);
          setTasks(taskResponse.tasks);
        })
        .catch(() => {
          if (!isMounted) return;
          setHasLoadError(true);
        })
        .finally(() => {
          if (isMounted) setIsLoading(false);
        });

      return controller;
    };

    let controller = loadRuntime();
    const interval = window.setInterval(() => {
      controller.abort();
      controller = loadRuntime();
    }, 3500);

    return () => {
      isMounted = false;
      controller.abort();
      window.clearInterval(interval);
    };
  }, [isOpen]);

  const taskByProvider = useMemo(() => new Map(tasks.map((task) => [task.projectId, task])), [tasks]);
  const runningProviders = useMemo(
    () => providers.filter((provider) => provider.runStatus === "running" || taskByProvider.has(provider.id)),
    [providers, taskByProvider],
  );
  const historyProviders = useMemo(
    () =>
      providers
        .filter((provider) => provider.installStatus === "installed" && provider.runStatus !== "running" && !taskByProvider.has(provider.id))
        .sort((left, right) => readTimestamp(right.lastRunAt) - readTimestamp(left.lastRunAt)),
    [providers, taskByProvider],
  );
  const visibleProviders = activeTab === "running" ? runningProviders : historyProviders;

  return (
    <aside
      id="settings-panel"
      className={clsx("settings-panel", isOpen && "is-open")}
      aria-hidden={!isOpen}
      aria-label="Hub settings"
    >
      <div className="settings-panel-head">
        <div>
          <span className="settings-kicker">AI HUB RUNTIME</span>
          <h2>Provider monitor</h2>
        </div>
        <div className="settings-counts" aria-label="Provider runtime summary">
          <span>{runningProviders.length} đang chạy</span>
          <span>{historyProviders.length} đã tắt</span>
        </div>
      </div>

      <div className="settings-tabs" role="tablist" aria-label="Settings sections">
        {settingsTabs.map((tab) => {
          const Icon = tab.id === "running" ? Activity : History;
          return (
            <button
              key={tab.id}
              className={clsx(activeTab === tab.id && "is-active")}
              type="button"
              role="tab"
              aria-selected={activeTab === tab.id}
              onClick={() => onTabChange(tab.id)}
            >
              <Icon size={16} aria-hidden="true" />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      <div className="settings-panel-body">
        <div className="settings-provider-grid">
          {hasLoadError ? <SettingsEmptyState title="Không tải được runtime" detail="Backend chưa sẵn sàng hoặc API bị timeout." /> : null}
          {!hasLoadError && isLoading && visibleProviders.length === 0 ? (
            <SettingsEmptyState title="Đang đọc provider" detail="Đang đồng bộ trạng thái chạy từ Hub." />
          ) : null}
          {!hasLoadError && !isLoading && visibleProviders.length === 0 ? (
            <SettingsEmptyState
              title={activeTab === "running" ? "Không có provider đang chạy" : "Chưa có provider đã tắt"}
              detail={activeTab === "running" ? "Runtime provider đang mở sẽ hiện ở đây." : "Provider đã cài, đã tắt và chưa xoá sẽ hiện ở đây."}
            />
          ) : null}
          {visibleProviders.map((provider) => (
            <SettingsProviderCard key={provider.id} provider={provider} task={provider.runStatus === "running" ? taskByProvider.get(provider.id) : undefined} />
          ))}
        </div>
      </div>
    </aside>
  );
}

function SettingsProviderCard({ provider, task }: { provider: HubProject; task?: RunningTask }) {
  const isRunning = provider.runStatus === "running";
  const port = provider.runtime?.defaultPort ?? provider.editableConfig.port;
  const statusLabel = formatRunStatus(provider.runStatus);

  return (
    <article className={clsx("settings-provider-card", isRunning && "is-running")}>
      <div className="settings-provider-icon" aria-hidden="true">
        {isRunning ? <PlayCircle size={20} /> : <Clock3 size={20} />}
      </div>
      <div className="settings-provider-main">
        <div className="settings-provider-topline">
          <span>{provider.type.replaceAll("-", " ")}</span>
          <strong>{statusLabel}</strong>
        </div>
        <h3>{provider.name}</h3>
        <p>{provider.description}</p>
        <div className="settings-provider-meta">
          <span>Port {port}</span>
          <span>{formatLastRun(provider.lastRunAt)}</span>
          <span>{formatInstallStatus(provider.installStatus)}</span>
        </div>
        {task ? (
          <div className="settings-task-progress" aria-label={`${task.progressPercent}% ${task.currentStep}`}>
            <div>
              <span>{task.currentStep}</span>
              <strong>{formatDuration(task.durationSec)}</strong>
            </div>
            <span style={{ width: `${Math.max(3, Math.min(100, task.progressPercent))}%` }} />
          </div>
        ) : null}
      </div>
    </article>
  );
}

function SettingsEmptyState({ detail, title }: { detail: string; title: string }) {
  return (
    <div className="settings-empty-state">
      <Activity size={18} aria-hidden="true" />
      <div>
        <strong>{title}</strong>
        <span>{detail}</span>
      </div>
    </div>
  );
}

function formatRunStatus(status: HubProject["runStatus"]) {
  if (status === "running") return "Đang chạy";
  if (status === "error") return "Lỗi";
  return "Đã tắt";
}

function formatInstallStatus(status: HubProject["installStatus"]) {
  if (status === "installed") return "Đã cài";
  if (status === "installing") return "Đang cài";
  if (status === "failed") return "Cài lỗi";
  return "Chưa cài";
}

function formatTaskStatus(status: RunningTask["status"]) {
  const labels: Record<RunningTask["status"], string> = {
    completed: "Hoàn tất",
    deleting: "Đang xoá",
    failed: "Lỗi",
    installing: "Đang cài",
    queued: "Đang chờ",
    running: "Đang chạy",
    stopping: "Đang tắt",
  };
  return labels[status];
}

function formatLastRun(value: string) {
  const timestamp = readTimestamp(value);
  if (!timestamp) return "Chưa chạy";
  return new Intl.DateTimeFormat("vi-VN", {
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    month: "2-digit",
  }).format(timestamp);
}

function formatDuration(totalSeconds: number) {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = Math.max(0, Math.floor(totalSeconds % 60));
  if (minutes >= 60) {
    const hours = Math.floor(minutes / 60);
    return `${hours}h ${minutes % 60}m`;
  }
  return `${minutes}m ${seconds.toString().padStart(2, "0")}s`;
}

function readTimestamp(value: string) {
  const timestamp = Date.parse(value);
  return Number.isFinite(timestamp) ? timestamp : 0;
}

function CanvasAtmosphere() {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const context = canvas.getContext("2d", { alpha: true });
    if (!context) return;

    let frameId = 0;
    let width = 0;
    let height = 0;
    let pixelRatio = 1;
    let lastFrameTime = 0;
    let isLightTheme = document.documentElement.dataset.theme === "light";
    let isBalancedHub = document.documentElement.dataset.hubPerformance === "balanced";
    const lineOffsets = [0, 0.22, 0.44];
    const dotSeeds = Array.from({ length: 9 }, (_, index) => ({
      phase: index * 0.137,
      y: index * 0.217,
      radius: index % 3 === 0 ? 2.4 : 1.6,
      isAccent: index % 3 === 0,
    }));

    const scheduleDraw = () => {
      if (!document.hidden && !frameId) frameId = window.requestAnimationFrame(draw);
    };

    const syncEnvironment = () => {
      isLightTheme = document.documentElement.dataset.theme === "light";
      isBalancedHub = document.documentElement.dataset.hubPerformance === "balanced";
      scheduleDraw();
    };

    const resize = () => {
      const nextPixelRatio = Math.min(window.devicePixelRatio || 1, 1.5);
      const nextWidth = window.innerWidth;
      const nextHeight = window.innerHeight;
      if (nextWidth === width && nextHeight === height && nextPixelRatio === pixelRatio) return;

      pixelRatio = nextPixelRatio;
      width = nextWidth;
      height = nextHeight;
      canvas.width = Math.floor(width * pixelRatio);
      canvas.height = Math.floor(height * pixelRatio);
      canvas.style.width = `${width}px`;
      canvas.style.height = `${height}px`;
      context.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
    };

    const draw = (time: number) => {
      if (document.hidden) {
        frameId = 0;
        return;
      }

      if (time - lastFrameTime < 32) {
        frameId = window.requestAnimationFrame(draw);
        return;
      }
      lastFrameTime = time;

      const cyan = isLightTheme ? "rgba(22, 188, 188, 0.16)" : "rgba(22, 235, 235, 0.18)";
      const slate = isLightTheme ? "rgba(56, 90, 98, 0.08)" : "rgba(138, 180, 255, 0.1)";
      const progress = isBalancedHub ? 0.18 : (time / 22000) % 1;

      context.clearRect(0, 0, width, height);
      context.globalCompositeOperation = isLightTheme ? "multiply" : "screen";

      for (const [index, offset] of lineOffsets.entries()) {
        const lineX = ((progress + offset) % 1) * width;
        context.beginPath();
        context.moveTo(lineX, 0);
        context.lineTo(lineX - width * 0.22, height);
        context.strokeStyle = index === 1 ? slate : cyan;
        context.lineWidth = index === 1 ? 1 : 1.4;
        context.stroke();
      }

      context.globalCompositeOperation = "source-over";
      for (const dot of dotSeeds) {
        const dotX = ((progress + dot.phase) % 1) * width;
        const dotY = height * (0.18 + ((dot.y + Math.sin(time / 7000 + dot.phase * 9) * 0.04) % 0.66));
        context.beginPath();
        context.arc(dotX, dotY, dot.radius, 0, Math.PI * 2);
        context.fillStyle = dot.isAccent ? cyan : slate;
        context.fill();
      }

      frameId = isBalancedHub ? 0 : window.requestAnimationFrame(draw);
    };

    const resumeWhenVisible = () => {
      if (!document.hidden && !frameId) frameId = window.requestAnimationFrame(draw);
    };

    const observer = new MutationObserver(syncEnvironment);
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme", "data-hub-performance"] });
    resize();
    window.addEventListener("resize", resize, { passive: true });
    document.addEventListener("visibilitychange", resumeWhenVisible);
    frameId = window.requestAnimationFrame(draw);

    return () => {
      if (frameId) window.cancelAnimationFrame(frameId);
      window.removeEventListener("resize", resize);
      document.removeEventListener("visibilitychange", resumeWhenVisible);
      observer.disconnect();
    };
  }, []);

  return <canvas ref={canvasRef} className="canvas-atmosphere" aria-hidden="true" />;
}

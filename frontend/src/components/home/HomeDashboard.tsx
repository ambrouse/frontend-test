"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Activity,
  ArrowUpRight,
  Cpu,
  Database,
  HardDrive,
  Thermometer,
  Zap,
} from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";
import { cacheSelectedProvider, clearTaskHistory, fetchActiveTasks, fetchFeaturedProviders, fetchHardwareSnapshot, fetchProviderSummary, fetchProviders, resolveApiAssetUrl } from "@/services/apiClient";
import { emptyHardwareSnapshot, emptyProviderSummary } from "@/services/emptyState";
import type { HardwareSnapshot, HubProject, ProviderSummary, RunningTask } from "@/services/types";
import { formatMemory, formatProjectType } from "@/utils/format";

const HOME_SHORTCUT_ROW_STEP = 84;
const HUB_CACHE_KEY = "hub-providers-cache-v1";

type HubCachePayload = {
  providers: HubProject[];
  featuredProjects: HubProject[];
  providersCacheVersion: number;
  featuredCacheVersion: number;
  cachedAt: string;
};

function readHubCache() {
  if (typeof window === "undefined") return null;

  const cachedRaw = window.sessionStorage.getItem(HUB_CACHE_KEY);
  if (!cachedRaw) return null;

  try {
    return JSON.parse(cachedRaw) as HubCachePayload;
  } catch {
    window.sessionStorage.removeItem(HUB_CACHE_KEY);
    return null;
  }
}

function primeHubRoutePaint() {
  const root = document.documentElement;
  root.style.setProperty("--page-accent", "#23b7a9");
  root.style.setProperty("--page-accent-soft", "#dff8f3");
  root.setAttribute("data-hub-performance", "balanced");
}

export function HomeDashboard() {
  const router = useRouter();
  const hasWarmedHubRouteRef = useRef(false);
  const [hardware, setHardware] = useState<HardwareSnapshot>(emptyHardwareSnapshot);
  const [summary, setSummary] = useState<ProviderSummary>(emptyProviderSummary);
  const [tasks, setTasks] = useState<RunningTask[]>([]);
  const [featuredProviders, setFeaturedProviders] = useState<HubProject[]>([]);
  const [homeSlideIndex, setHomeSlideIndex] = useState(0);
  const [homeShortcutIndex, setHomeShortcutIndex] = useState(0);
  const [isHomeShortcutTransitioning, setIsHomeShortcutTransitioning] = useState(true);
  const [isBackendOnline, setIsBackendOnline] = useState(false);
  const freeVramMb = Math.max(0, hardware.gpu.vramTotalMb - hardware.gpu.vramUsedMb);
  const freeRamMb = Math.max(0, hardware.ram.totalMb - hardware.ram.usedMb);
  const activeVramPercent = safePercent(hardware.gpu.vramUsedMb, hardware.gpu.vramTotalMb);
  const activeRamPercent = safePercent(hardware.ram.usedMb, hardware.ram.totalMb);
  const providerReadinessPercent = safePercent(summary.ready, summary.total);
  const diskHeadroomPercent = Math.min(100, Math.max(0, hardware.disk.installPathFreeGb / 4));
  const backendStatusLabel = isBackendOnline ? "backend live" : "connecting";
  const homeBannerProject = featuredProviders.length ? featuredProviders[homeSlideIndex % featuredProviders.length] : null;
  const previousHomeBannerProject =
    featuredProviders.length > 1 && homeSlideIndex > 0 ? featuredProviders[(homeSlideIndex - 1) % featuredProviders.length] : null;
  const homeShortcutBaseProjects = homeBannerProject
    ? featuredProviders.filter((project) => project.id !== homeBannerProject.id)
    : featuredProviders;
  const homeShortcutProjects = [
    ...homeShortcutBaseProjects,
    ...homeShortcutBaseProjects.slice(0, Math.min(3, homeShortcutBaseProjects.length)),
  ];
  const homeShortcutOffset = homeShortcutIndex * HOME_SHORTCUT_ROW_STEP * -1;

  const warmHubRoute = useCallback(() => {
    if (hasWarmedHubRouteRef.current || typeof window === "undefined") return;
    hasWarmedHubRouteRef.current = true;
    router.prefetch("/hub");

    if (window.sessionStorage.getItem(HUB_CACHE_KEY)) return;

    void Promise.all([fetchProviders({ timeoutMs: 1600 }), fetchFeaturedProviders({ timeoutMs: 1600 })])
      .then(([providersResponse, featuredResponse]) => {
        const featuredFromBackend = featuredResponse.providers.length ? featuredResponse.providers : providersResponse.providers.slice(0, 4);
        window.sessionStorage.setItem(
          HUB_CACHE_KEY,
          JSON.stringify({
            providers: providersResponse.providers,
            featuredProjects: featuredFromBackend,
            providersCacheVersion: providersResponse.cacheVersion,
            featuredCacheVersion: featuredResponse.cacheVersion,
            cachedAt: new Date().toISOString(),
          }),
        );
      })
      .catch(() => {
        hasWarmedHubRouteRef.current = false;
      });
  }, [router]);

  useEffect(() => {
    const controller = new AbortController();
    void clearTaskHistory("finished", { signal: controller.signal }).catch(() => {});
    return () => controller.abort();
  }, []);

  useEffect(() => {
    const idleWindow = window as Window & {
      requestIdleCallback?: (callback: IdleRequestCallback, options?: IdleRequestOptions) => number;
      cancelIdleCallback?: (handle: number) => void;
    };

    if (idleWindow.requestIdleCallback && idleWindow.cancelIdleCallback) {
      const idleId = idleWindow.requestIdleCallback(warmHubRoute, { timeout: 1200 });
      return () => idleWindow.cancelIdleCallback?.(idleId);
    }

    const timer = window.setTimeout(warmHubRoute, 450);
    return () => window.clearTimeout(timer);
  }, [warmHubRoute]);

  useEffect(() => {
    const controller = new AbortController();
    const cached = readHubCache();
    const cachedFeatured = cached?.featuredProjects.length ? cached.featuredProjects : cached?.providers.slice(0, 4);

    if (cachedFeatured?.length) {
      setFeaturedProviders(cachedFeatured.slice(0, 8));
    }

    void fetchFeaturedProviders({ signal: controller.signal, timeoutMs: 2600 })
      .then((response) => {
        setFeaturedProviders(response.providers.slice(0, 8));
      })
      .catch(() => {
        if (!cachedFeatured?.length) setFeaturedProviders([]);
      });

    return () => controller.abort();
  }, []);

  useEffect(() => {
    let isMounted = true;
    const loadSnapshot = () => {
      const controller = new AbortController();
      void Promise.allSettled([
        fetchHardwareSnapshot({ signal: controller.signal, timeoutMs: 1000 }),
        fetchProviderSummary({ signal: controller.signal, timeoutMs: 1000 }),
        fetchActiveTasks({ signal: controller.signal, timeoutMs: 900 }),
      ]).then(([hardwareResult, summaryResult, taskResult]) => {
        if (!isMounted) return;

        if (hardwareResult.status === "fulfilled") {
          setHardware(hardwareResult.value);
          setIsBackendOnline(true);
        } else {
          setIsBackendOnline(false);
        }

        if (summaryResult.status === "fulfilled") {
          setSummary(summaryResult.value);
        }

        if (taskResult.status === "fulfilled") {
          setTasks(taskResult.value.tasks);
        } else {
          setTasks([]);
        }
      });

      return controller;
    };

    let controller = loadSnapshot();
    const interval = window.setInterval(() => {
      controller.abort();
      controller = loadSnapshot();
    }, 2500);

    return () => {
      isMounted = false;
      controller.abort();
      window.clearInterval(interval);
    };
  }, []);

  useEffect(() => {
    setHomeSlideIndex(0);
    setHomeShortcutIndex(0);
    setIsHomeShortcutTransitioning(true);
  }, [featuredProviders.length]);

  useEffect(() => {
    if (featuredProviders.length < 2) return;
    const interval = window.setInterval(() => setHomeSlideIndex((current) => current + 1), 10000);
    return () => window.clearInterval(interval);
  }, [featuredProviders.length]);

  useEffect(() => {
    if (homeShortcutBaseProjects.length < 4) return;
    const interval = window.setInterval(() => {
      setIsHomeShortcutTransitioning(true);
      setHomeShortcutIndex((current) => current + 1);
    }, 5000);
    return () => window.clearInterval(interval);
  }, [homeShortcutBaseProjects.length]);

  const handleHomeShortcutTransitionEnd = () => {
    setIsHomeShortcutTransitioning(false);
    if (homeShortcutBaseProjects.length === 0 || homeShortcutIndex < homeShortcutBaseProjects.length) return;
    setHomeShortcutIndex(0);
  };

  return (
    <div className="page-flow sougen-home">
      <section className="home-hero sougen-home-hero">
        <div className="hero-copy sougen-hero-copy">
          <div className="section-kicker sougen-kicker">
            <Zap size={16} aria-hidden="true" />
            <span>Local AI command center</span>
            <em>{backendStatusLabel}</em>
          </div>

          <div className="sougen-home-title">
            <h1>AI Hub</h1>
            <p>
              A local control surface for provider apps, hardware readiness, and long-running setup tasks.
            </p>
          </div>

          <div className="sougen-actions" aria-label="Primary home actions">
            <Link
              className="sougen-action sougen-action-primary"
              href="/hub"
              aria-label="Open Hub"
              prefetch
              onClick={() => {
                primeHubRoutePaint();
                warmHubRoute();
              }}
              onFocus={warmHubRoute}
              onPointerDown={() => {
                primeHubRoutePaint();
                warmHubRoute();
              }}
              onPointerEnter={warmHubRoute}
            >
              <span className="sougen-action-vines" aria-hidden="true">
                <i />
                <i />
                <i />
                <i />
                <i />
                <i />
              </span>
              <span className="sougen-ink-field" aria-hidden="true">
                <b />
                <b />
                <b />
                <b />
                <b />
                <b />
              </span>
              <span className="sougen-blue-flood" aria-hidden="true" />
              <span className="sougen-action-label" aria-hidden="true">
                <span className="sougen-action-text sougen-action-text-primary">Open Hub</span>
                <span className="sougen-action-text sougen-action-text-secondary">Open Hub</span>
              </span>
            </Link>
            <span className={`sougen-backend-state ${isBackendOnline ? "is-live" : "is-waiting"}`}>
              <span aria-hidden="true" />
              {backendStatusLabel}
            </span>
          </div>
        </div>

        <div
          className="sougen-stage"
          aria-label="Runtime overview"
        >
          {homeBannerProject ? (
            <div className="sougen-stage-banner-stack">
              {previousHomeBannerProject ? (
                <HomeStageBanner key={`previous-${previousHomeBannerProject.id}-${homeSlideIndex}`} project={previousHomeBannerProject} motionState="exiting" />
              ) : null}
              <HomeStageBanner key={`current-${homeBannerProject.id}-${homeSlideIndex}`} project={homeBannerProject} motionState="current" />
            </div>
          ) : (
            <div className="sougen-stage-banner sougen-stage-banner-empty">
              <span>Providers</span>
              <strong>Loading provider banners</strong>
            </div>
          )}

          <div className="sougen-stage-overlay">
            <div className="sougen-stage-topline">
              <span>Ready providers</span>
              <strong>
                {summary.ready}
                <small>/{summary.total}</small>
              </strong>
            </div>

            <div className="sougen-loader-line" aria-label={`Provider readiness ${Math.round(providerReadinessPercent)}%`}>
              <span style={{ width: `${providerReadinessPercent}%` }} />
            </div>

            <div className="sougen-stage-meta" aria-label="System signals">
              <span>
                <Activity size={14} aria-hidden="true" />
                {tasks.length} active tasks
              </span>
              <span>
                <Cpu size={14} aria-hidden="true" />
                {formatMemory(freeVramMb)} VRAM free
              </span>
              <span>
                <Database size={14} aria-hidden="true" />
                {formatMemory(freeRamMb)} RAM free
              </span>
            </div>
          </div>

          <div className="sougen-home-shortcuts" aria-label="Featured provider shortcuts">
            <div
              className="sougen-home-shortcut-track"
              data-transitioning={isHomeShortcutTransitioning ? "true" : "false"}
              onTransitionEnd={handleHomeShortcutTransitionEnd}
              style={{ transform: `translate3d(0, ${homeShortcutOffset}px, 0)` }}
            >
              {homeShortcutProjects.map((project, index) => (
                <Link
                  key={`${project.id}-${index}`}
                  className="sougen-home-shortcut"
                  href={`/hub/${project.id}`}
                  onClick={() => cacheSelectedProvider(project)}
                  style={projectVisualStyle(project)}
                >
                  <span>{formatProjectType(project.type)}</span>
                  <strong>{project.name}</strong>
                  <small>{project.runStatus === "running" ? "Running" : "Stopped"}</small>
                </Link>
              ))}
            </div>
          </div>

          <div className="sougen-reading-grid">
            <ResourceLine label="VRAM free" value={100 - activeVramPercent} detail={`${formatMemory(freeVramMb)} available`} />
            <ResourceLine label="RAM free" value={100 - activeRamPercent} detail={`${formatMemory(freeRamMb)} available`} />
            <ResourceLine label="Disk headroom" value={diskHeadroomPercent} detail={`${hardware.disk.installPathFreeGb} GB install free`} />
          </div>
        </div>
      </section>

      <section className="metric-strip" aria-label="System resources">
        <MetricCard
          icon={<Cpu size={18} />}
          label="CPU"
          value={hardware.cpu.name}
          meta={`${hardware.cpu.cores} cores / ${hardware.cpu.usagePercent}%`}
        />
        <MetricCard
          icon={<Database size={18} />}
          label="RAM"
          value={`${formatMemory(hardware.ram.usedMb)} used`}
          meta={`${Math.round(activeRamPercent)}% of ${formatMemory(hardware.ram.totalMb)}`}
        />
        <MetricCard
          icon={<HardDrive size={18} />}
          label="Disk"
          value={`${hardware.disk.installPathFreeGb} GB install free`}
          meta={`${hardware.disk.freeGb} GB total free`}
        />
        <MetricCard
          icon={<Thermometer size={18} />}
          label="Thermal"
          value={`${formatTemperature(hardware.cpu.temperatureC)} CPU / ${formatTemperature(hardware.gpu.temperatureC)} GPU`}
          meta={hardware.gpu.vendor === "unknown" ? "GPU probe unavailable" : "Live hardware probe"}
        />
      </section>

    </div>
  );
}

function ResourceLine({
  label,
  value,
  detail,
}: {
  label: string;
  value: number;
  detail: string;
}) {
  const width = Math.round(Math.min(100, Math.max(0, value)));

  return (
    <div className="sougen-resource-line">
      <div>
        <span>{label}</span>
        <strong>{detail}</strong>
      </div>
      <i style={{ "--line-width": `${width}%` } as React.CSSProperties} aria-hidden="true" />
    </div>
  );
}

function safePercent(used: number, total: number) {
  if (total <= 0) return 0;
  return Math.min(100, Math.max(0, (used / total) * 100));
}

function formatTemperature(value: number | null) {
  return value === null ? "unknown" : `${value}C`;
}

function HomeStageBanner({
  motionState,
  project,
}: {
  motionState: "current" | "exiting";
  project: HubProject;
}) {
  return (
    <Link
      className={`sougen-stage-banner is-${motionState}`}
      href={`/hub/${project.id}`}
      onClick={() => cacheSelectedProvider(project)}
      style={projectVisualStyle(project)}
    >
      <span>{formatProjectType(project.type)}</span>
      <strong>{project.name}</strong>
      <small>
        Open provider
        <ArrowUpRight size={15} aria-hidden="true" />
      </small>
    </Link>
  );
}

function projectVisualStyle(project: HubProject) {
  return {
    "--home-project-accent": project.accentColor,
    "--home-project-image": `url(${resolveApiAssetUrl(project.visual.imageUrl)})`,
    "--home-project-focus": project.visual.focus,
  } as React.CSSProperties;
}

function MetricCard({
  icon,
  label,
  value,
  meta,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  meta: string;
}) {
  return (
    <article className="metric-card">
      <div className="metric-icon" aria-hidden="true">
        {icon}
      </div>
      <span>{label}</span>
      <strong>{value}</strong>
      <p>{meta}</p>
    </article>
  );
}

"use client";

import Link from "next/link";
import {
  ArrowUpRight,
  Boxes,
  Cpu,
  Database,
  HardDrive,
  Search,
  Server,
  Sparkles,
} from "lucide-react";
import { memo, startTransition, useDeferredValue, useEffect, useInsertionEffect, useMemo, useState } from "react";
import { cacheSelectedProvider, fetchActiveTasks, fetchFeaturedProviders, fetchProviders, resolveApiAssetUrl } from "@/services/apiClient";
import type { HubProject, ProjectType, RunningTask } from "@/services/types";
import { formatMemory, formatProjectType } from "@/utils/format";
import { CompatibilityPing } from "./CompatibilityPing";

const projectTypes: Array<ProjectType | "all"> = [
  "all",
  "llm",
  "vision",
  "spark-llm",
  "nvidia-blueprint",
  "embedding",
  "speech",
  "tooling",
];

const HUB_CACHE_KEY = "hub-providers-cache-v1";
const SHORTCUT_ROW_STEP = 96;

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

export function HubExplorer() {
  const [activeType, setActiveType] = useState<ProjectType | "all">("all");
  const [query, setQuery] = useState("");
  const [projects, setProjects] = useState<HubProject[]>([]);
  const [featuredProjects, setFeaturedProjects] = useState<HubProject[]>([]);
  const [tasks, setTasks] = useState<RunningTask[]>([]);
  const [heroSlideIndex, setHeroSlideIndex] = useState(0);
  const [shortcutSlideIndex, setShortcutSlideIndex] = useState(0);
  const [isShortcutTransitioning, setIsShortcutTransitioning] = useState(true);
  const [slideSeed] = useState(() => Math.floor(Math.random() * 4096));
  const [isOffline, setIsOffline] = useState(false);
  const deferredQuery = useDeferredValue(query);

  useInsertionEffect(() => {
    const root = document.documentElement;
    root.style.setProperty("--page-accent", "#23b7a9");
    root.style.setProperty("--page-accent-soft", "#dff8f3");
    root.setAttribute("data-hub-performance", "balanced");
  }, []);

  useEffect(() => {
    const controller = new AbortController();
    const cached = readHubCache();

    if (cached) {
      setProjects(cached.providers);
      setFeaturedProjects(cached.featuredProjects);
    }

    void Promise.all([
      fetchProviders({ signal: controller.signal, timeoutMs: 2800 }),
      fetchFeaturedProviders({ signal: controller.signal, timeoutMs: 2800 }),
    ])
      .then(([providersResponse, featuredResponse]) => {
        const featuredFromBackend = featuredResponse.providers.length ? featuredResponse.providers : providersResponse.providers.slice(0, 4);
        const payload: HubCachePayload = {
          providers: providersResponse.providers,
          featuredProjects: featuredFromBackend,
          providersCacheVersion: providersResponse.cacheVersion,
          featuredCacheVersion: featuredResponse.cacheVersion,
          cachedAt: new Date().toISOString(),
        };
        window.sessionStorage.setItem(HUB_CACHE_KEY, JSON.stringify(payload));

        startTransition(() => {
          setProjects(providersResponse.providers);
          setFeaturedProjects(featuredFromBackend);
          setIsOffline(false);
        });
      })
      .catch(() => {
        setIsOffline(true);
      });

    return () => controller.abort();
  }, []);

  useEffect(() => {
    let isMounted = true;
    const loadTasks = () => {
      const controller = new AbortController();
      void fetchActiveTasks({ signal: controller.signal, timeoutMs: 900 })
        .then((response) => {
          if (isMounted) setTasks(response.tasks);
        })
        .catch(() => {
          if (isMounted) setTasks([]);
        });
      return controller;
    };

    let controller = loadTasks();
    const interval = window.setInterval(() => {
      controller.abort();
      controller = loadTasks();
    }, 2000);

    return () => {
      isMounted = false;
      controller.abort();
      window.clearInterval(interval);
    };
  }, []);

  useEffect(() => {
    if (featuredProjects.length === 0) return;

    const preload = () => {
      featuredProjects.slice(0, 4).forEach((project) => {
        const image = new Image();
        image.decoding = "async";
        image.src = resolveApiAssetUrl(project.visual.imageUrl);
      });
    };

    const idleWindow = window as Window & {
      requestIdleCallback?: (callback: IdleRequestCallback, options?: IdleRequestOptions) => number;
      cancelIdleCallback?: (handle: number) => void;
    };

    if (idleWindow.requestIdleCallback && idleWindow.cancelIdleCallback) {
      const idleId = idleWindow.requestIdleCallback(preload, { timeout: 1800 });
      return () => idleWindow.cancelIdleCallback?.(idleId);
    }

    const timer = window.setTimeout(preload, 900);

    return () => window.clearTimeout(timer);
  }, [featuredProjects]);

  const visibleProjects = useMemo(() => {
    const normalizedQuery = deferredQuery.trim().toLowerCase();

    return projects.filter((project) => {
      const matchesType = activeType === "all" || project.type === activeType;
      const matchesQuery =
        normalizedQuery.length === 0 ||
        project.name.toLowerCase().includes(normalizedQuery) ||
        project.description.toLowerCase().includes(normalizedQuery) ||
        project.tags.some((tag) => tag.toLowerCase().includes(normalizedQuery)) ||
        project.repoUrl.toLowerCase().includes(normalizedQuery);

      return matchesType && matchesQuery;
    });
  }, [activeType, deferredQuery, projects]);

  const heroProjects = useMemo(
    () => seededProjectOrder(featuredProjects.length ? featuredProjects : projects, slideSeed),
    [featuredProjects, projects, slideSeed],
  );
  const featuredProject = heroProjects.length ? heroProjects[heroSlideIndex % heroProjects.length] : null;
  const previousFeaturedProject =
    heroProjects.length > 1 && heroSlideIndex > 0 ? heroProjects[(heroSlideIndex - 1) % heroProjects.length] : null;
  const shortcutBaseProjects = useMemo(
    () => seededProjectOrder(projects, slideSeed + 17).filter((project) => project.id !== featuredProject?.id),
    [featuredProject?.id, projects, slideSeed],
  );
  const shortcutTrackProjects = useMemo(
    () => [...shortcutBaseProjects, ...shortcutBaseProjects.slice(0, Math.min(3, shortcutBaseProjects.length))],
    [shortcutBaseProjects],
  );
  const shortcutTrackOffset = shortcutSlideIndex * SHORTCUT_ROW_STEP * -1;
  const taskProviderIds = useMemo(() => new Set(tasks.map((task) => task.projectId)), [tasks]);
  const summary = useMemo(() => readProviderSummary(projects, taskProviderIds, tasks.length), [projects, taskProviderIds, tasks.length]);

  useEffect(() => {
    setHeroSlideIndex(0);
    setShortcutSlideIndex(0);
    setIsShortcutTransitioning(true);
  }, [projects.length, featuredProjects.length]);

  useEffect(() => {
    if (heroProjects.length < 2) return;
    const interval = window.setInterval(() => setHeroSlideIndex((current) => current + 1), 10000);
    return () => window.clearInterval(interval);
  }, [heroProjects.length]);

  useEffect(() => {
    if (shortcutBaseProjects.length < 4) return;
    const interval = window.setInterval(() => {
      setIsShortcutTransitioning(true);
      setShortcutSlideIndex((current) => current + 1);
    }, 5000);
    return () => window.clearInterval(interval);
  }, [shortcutBaseProjects.length]);

  const handleShortcutTransitionEnd = () => {
    setIsShortcutTransitioning(false);
    if (shortcutBaseProjects.length === 0 || shortcutSlideIndex < shortcutBaseProjects.length) return;
    setShortcutSlideIndex(0);
  };

  return (
    <div className="hub-v2 page-flow">
      <section className="hub-v2-hero" aria-label="Provider overview">
        {featuredProject ? (
          <div className="hub-v2-feature-stack">
            {previousFeaturedProject ? (
              <FeaturedProvider
                key={`previous-${previousFeaturedProject.id}-${heroSlideIndex}`}
                project={previousFeaturedProject}
                isOffline={isOffline}
                motionState="exiting"
              />
            ) : null}
            <FeaturedProvider
              key={`current-${featuredProject.id}-${heroSlideIndex}`}
              project={featuredProject}
              isOffline={isOffline}
              motionState="current"
            />
          </div>
        ) : (
          <div className="hub-v2-feature-card hub-v2-feature-empty">
            <span className="hub-v2-eyebrow">Loading</span>
            <h1>Loading providers</h1>
          </div>
        )}

        <aside className="hub-v2-side" aria-label="Hub status">
          <div className="hub-v2-status-strip" aria-label="Hub runtime status">
            <span>
              <Server size={15} aria-hidden="true" />
              Status
            </span>
            <strong>{summary.activeTasks} task live</strong>
            <strong>{summary.running} running</strong>
            <strong>{summary.ready} ready</strong>
            <strong>{summary.installed} installed</strong>
            <strong>{summary.total} providers</strong>
          </div>

          <div className="hub-v2-shortcut-list">
            <div
              className="hub-v2-shortcut-track"
              data-transitioning={isShortcutTransitioning ? "true" : "false"}
              onTransitionEnd={handleShortcutTransitionEnd}
              style={{ transform: `translate3d(0, ${shortcutTrackOffset}px, 0)` }}
            >
              {shortcutTrackProjects.map((project, index) => (
                <ShortcutProvider key={`${project.id}-${index}`} project={project} />
              ))}
            </div>
          </div>
        </aside>
      </section>

      <section className="hub-v2-toolbar" aria-label="Provider tools">
        <div className="hub-v2-filter" aria-label="Filter providers">
          {projectTypes.map((type) => (
            <button
              key={type}
              className={activeType === type ? "is-active" : undefined}
              type="button"
              onClick={() => setActiveType(type)}
            >
              {type === "all" ? "All" : formatProjectType(type)}
            </button>
          ))}
        </div>

        <label className="hub-v2-search">
          <Search size={18} aria-hidden="true" />
          <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search providers, tags, repos..." />
        </label>
      </section>

      <section className="hub-v2-results" aria-label="Provider list">
        <div className="hub-v2-results-head">
          <span>{visibleProjects.length} shown</span>
          {activeType !== "all" ? <strong>{formatProjectType(activeType)}</strong> : null}
        </div>

        <div className="hub-v2-provider-grid">
          {visibleProjects.length === 0 ? <p className="hub-v2-empty">No providers match this filter.</p> : null}
          {visibleProjects.map((project) => (
            <ProviderCard key={project.id} project={project} />
          ))}
        </div>
      </section>
    </div>
  );
}

const FeaturedProvider = memo(function FeaturedProvider({
  isOffline,
  motionState = "current",
  project,
}: {
  isOffline: boolean;
  motionState?: "current" | "exiting";
  project: HubProject;
}) {
  return (
    <Link
      className={`hub-v2-feature-card is-${motionState}`}
      data-project-type={project.type}
      href={`/hub/${project.id}`}
      onClick={() => cacheSelectedProvider(project)}
      style={projectStyle(project)}
    >
      <span className="hub-v2-feature-visual" aria-hidden="true" />
      <span className="hub-v2-feature-ripple" aria-hidden="true" />

      <span className="hub-v2-eyebrow">
        <Sparkles size={16} aria-hidden="true" />
        {isOffline ? "Cached provider" : "Featured provider"}
      </span>

      <div className="hub-v2-feature-copy">
        <span>{formatProjectType(project.type)}</span>
        <h1>{project.name}</h1>
        <p>{project.description}</p>
      </div>

      <div className="hub-v2-feature-meta" aria-label="Featured provider status">
        <CompatibilityPing level={project.compatibility.level} reasons={project.compatibility.reasons} />
        <span>{formatInstallStatus(project.installStatus)}</span>
        <span>{formatRunStatus(project.runStatus)}</span>
      </div>

      <div className="hub-v2-feature-action">
        <span>{project.lastBenchmark.headlineMetric}</span>
        <ArrowUpRight size={18} aria-hidden="true" />
      </div>
    </Link>
  );
});

const ShortcutProvider = memo(function ShortcutProvider({
  project,
}: {
  project: HubProject;
}) {
  return (
    <Link
      className="hub-v2-shortcut"
      href={`/hub/${project.id}`}
      onClick={() => cacheSelectedProvider(project)}
      style={projectStyle(project)}
    >
      <span>{formatProjectType(project.type)}</span>
      <strong>{project.name}</strong>
      <small>{formatRunStatus(project.runStatus)}</small>
    </Link>
  );
});

const ProviderCard = memo(function ProviderCard({ project }: { project: HubProject }) {
  return (
    <article className="hub-v2-card" data-project-type={project.type} style={projectStyle(project)}>
      <Link className="hub-v2-card-media" href={`/hub/${project.id}`} onClick={() => cacheSelectedProvider(project)} aria-label={`Open ${project.name}`}>
        <span>{formatProjectType(project.type)}</span>
      </Link>

      <div className="hub-v2-card-body">
        <div className="hub-v2-card-top">
          <CompatibilityPing level={project.compatibility.level} reasons={project.compatibility.reasons} />
          <span>{formatInstallStatus(project.installStatus)}</span>
        </div>

        <div className="hub-v2-card-title">
          <span aria-hidden="true">
            <Boxes size={18} />
          </span>
          <div>
            <h2>{project.name}</h2>
            <p>{project.description}</p>
          </div>
        </div>

        <div className="hub-v2-tags" aria-label={`${project.name} tags`}>
          {project.tags.slice(0, 4).map((tag) => (
            <span key={tag}>{tag}</span>
          ))}
        </div>

        <div className="hub-v2-requirements" aria-label={`${project.name} minimum requirements`}>
          <span>
            <Cpu size={14} aria-hidden="true" />
            {project.requirements.minimum.cpuCores}c
          </span>
          <span>
            <Database size={14} aria-hidden="true" />
            {formatMemory(project.requirements.minimum.ramMb)}
          </span>
          <span>
            <HardDrive size={14} aria-hidden="true" />
            {project.requirements.minimum.diskGb} GB
          </span>
        </div>

        <div className="hub-v2-card-bottom">
          <div>
            <span>{formatRunStatus(project.runStatus)}</span>
            <strong>{project.lastBenchmark.headlineMetric}</strong>
          </div>
          <Link href={`/hub/${project.id}`} aria-label={`Open ${project.name}`} onClick={() => cacheSelectedProvider(project)}>
            <ArrowUpRight size={18} aria-hidden="true" />
          </Link>
        </div>
      </div>
    </article>
  );
});

function readProviderSummary(projects: HubProject[], taskProviderIds: Set<string>, activeTasks: number) {
  return {
    activeTasks,
    total: projects.length,
    ready: projects.filter((project) => project.compatibility.level === "green").length,
    installed: projects.filter((project) => project.installStatus === "installed").length,
    running: projects.filter((project) => project.runStatus === "running" || taskProviderIds.has(project.id)).length,
  };
}

function seededProjectOrder(projects: HubProject[], seed: number) {
  return [...projects].sort((left, right) => readProjectHash(left.id, seed) - readProjectHash(right.id, seed));
}

function readProjectHash(value: string, seed: number) {
  let hash = seed || 17;
  for (let index = 0; index < value.length; index += 1) {
    hash = (hash * 31 + value.charCodeAt(index)) % 1000003;
  }
  return hash;
}

function projectStyle(project: HubProject) {
  return {
    "--project-accent": project.accentColor,
    "--project-image": `url(${resolveApiAssetUrl(project.visual.imageUrl)})`,
    "--project-focus": project.visual.focus,
  } as React.CSSProperties;
}

function formatInstallStatus(status: HubProject["installStatus"]) {
  const labels: Record<HubProject["installStatus"], string> = {
    failed: "Install failed",
    installed: "Installed",
    installing: "Installing",
    not_installed: "Not installed",
  };
  return labels[status];
}

function formatRunStatus(status: HubProject["runStatus"]) {
  const labels: Record<HubProject["runStatus"], string> = {
    error: "Runtime error",
    running: "Running",
    stopped: "Stopped",
  };
  return labels[status];
}

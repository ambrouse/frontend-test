"use client";

import { Search } from "lucide-react";
import { memo, startTransition, useEffect, useMemo, useState } from "react";
import { fetchFeaturedProviders, fetchProviders, resolveApiAssetUrl } from "@/services/apiClient";
import type { HubProject, ProjectType } from "@/services/types";
import { formatProjectType } from "@/utils/format";
import { CompatibilityPing } from "./CompatibilityPing";
import { ProjectCard } from "./ProjectCard";

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

type HubCachePayload = {
  providers: HubProject[];
  featuredProjects: HubProject[];
  providersCacheVersion: number;
  featuredCacheVersion: number;
  cachedAt: string;
};

function readHubCache() {
  if (typeof window === "undefined") {
    return null;
  }
  const cachedRaw = window.sessionStorage.getItem(HUB_CACHE_KEY);
  if (!cachedRaw) {
    return null;
  }
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
  const [activeSlide, setActiveSlide] = useState(0);
  const [previousProject, setPreviousProject] = useState<HubProject | null>(null);
  const [isOffline, setIsOffline] = useState(false);

  useEffect(() => {
    const root = document.documentElement;
    root.style.setProperty("--page-accent", "#0ea5b7");
    root.style.setProperty("--page-accent-soft", "#062026");
    root.setAttribute("data-hub-performance", "balanced");

    return () => {
      root.removeAttribute("data-hub-performance");
    };
  }, []);

  useEffect(() => {
    if (featuredProjects.length === 0) {
      return;
    }

    const idleWindow = window as Window & {
      requestIdleCallback?: (callback: IdleRequestCallback, options?: IdleRequestOptions) => number;
      cancelIdleCallback?: (handle: number) => void;
    };

    const preload = () => {
      featuredProjects.slice(0, 8).forEach((project) => {
        const image = new Image();
        image.decoding = "async";
        image.src = resolveApiAssetUrl(project.visual.imageUrl);
      });
    };

    if (idleWindow.requestIdleCallback && idleWindow.cancelIdleCallback) {
      const idleId = idleWindow.requestIdleCallback(preload, { timeout: 1200 });
      return () => idleWindow.cancelIdleCallback?.(idleId);
    }

    const timer = globalThis.setTimeout(preload, 240);
    return () => globalThis.clearTimeout(timer);
  }, [featuredProjects]);

  useEffect(() => {
    const controller = new AbortController();
    const cached = readHubCache();
    if (cached) {
      setProjects(cached.providers);
      setFeaturedProjects(cached.featuredProjects);
    }

    void Promise.all([
      fetchProviders({ signal: controller.signal }),
      fetchFeaturedProviders({ signal: controller.signal }),
    ])
      .then(([providersResponse, featuredResponse]) => {
        const payload: HubCachePayload = {
          providers: providersResponse.providers,
          featuredProjects: featuredResponse.providers,
          providersCacheVersion: providersResponse.cacheVersion,
          featuredCacheVersion: featuredResponse.cacheVersion,
          cachedAt: new Date().toISOString(),
        };
        window.sessionStorage.setItem(HUB_CACHE_KEY, JSON.stringify(payload));

        startTransition(() => {
          setProjects(providersResponse.providers);
          setFeaturedProjects(featuredResponse.providers);
          setActiveSlide(0);
          setIsOffline(false);
        });
      })
      .catch(() => {
        if (!cached?.providers.length && !cached?.featuredProjects.length) {
          setIsOffline(true);
        }
      });

    return () => controller.abort();
  }, []);

  useEffect(() => {
    if (featuredProjects.length === 0) {
      return;
    }

    const timer = window.setInterval(() => {
      setActiveSlide((currentSlide) => {
        setPreviousProject(featuredProjects[currentSlide] ?? null);
        return (currentSlide + 1) % featuredProjects.length;
      });
    }, 6200);

    return () => window.clearInterval(timer);
  }, [featuredProjects]);

  useEffect(() => {
    if (!previousProject) {
      return;
    }

    const timer = window.setTimeout(() => setPreviousProject(null), 620);
    return () => window.clearTimeout(timer);
  }, [previousProject]);

  const visibleProjects = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase();

    return projects.filter((project) => {
      const matchesType = activeType === "all" || project.type === activeType;
      const matchesQuery =
        normalizedQuery.length === 0 ||
        project.name.toLowerCase().includes(normalizedQuery) ||
        project.tags.some((tag) => tag.toLowerCase().includes(normalizedQuery)) ||
        project.repoUrl.toLowerCase().includes(normalizedQuery);

      return matchesType && matchesQuery;
    });
  }, [activeType, projects, query]);

  const featuredProject = featuredProjects[activeSlide] ?? projects[0] ?? null;

  return (
    <div className="page-flow hub-page">
      {featuredProject ? (
        <HubCarousel featuredProject={featuredProject} previousProject={previousProject} />
      ) : (
        <section className="hub-carousel hub-carousel-empty">
          <div className="hub-carousel-copy">
            <span className="project-type">{isOffline ? "offline" : "loading"}</span>
            <h1>{isOffline ? "Backend unavailable" : "Loading providers"}</h1>
            <div className="hub-status-strip" aria-label="Provider loading status">
              <span>{isOffline ? "Check backend API" : "Real backend data"}</span>
            </div>
          </div>
        </section>
      )}

      <div className="hub-tools">
        <div className="filter-dock" aria-label="Loc provider">
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

        <label className="hub-search hub-search-inline">
          <Search size={18} aria-hidden="true" />
          <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Tim LLM, vision, repo..." />
        </label>
      </div>

      <ProjectGrid projects={visibleProjects} />
    </div>
  );
}

const HubCarousel = memo(function HubCarousel({
  featuredProject,
  previousProject,
}: {
  featuredProject: HubProject;
  previousProject: HubProject | null;
}) {
  return (
    <section
      className="hub-carousel"
      data-project-type={featuredProject.type}
      style={
        {
          "--project-accent": featuredProject.accentColor,
          "--project-image": `url(${resolveApiAssetUrl(featuredProject.visual.imageUrl)})`,
          "--project-focus": featuredProject.visual.focus,
        } as React.CSSProperties
      }
    >
      {previousProject ? (
        <div
          key={`previous-${previousProject.id}`}
          className="hub-carousel-bg is-previous"
          style={
            {
              "--project-image": `url(${resolveApiAssetUrl(previousProject.visual.imageUrl)})`,
              "--project-focus": previousProject.visual.focus,
              "--project-accent": previousProject.accentColor,
            } as React.CSSProperties
          }
          aria-hidden="true"
        />
      ) : null}
      <div key={`current-${featuredProject.id}`} className="hub-carousel-bg is-current" aria-hidden="true" />
      <div key={`copy-${featuredProject.id}`} className="hub-carousel-copy">
        <span className="project-type">{formatProjectType(featuredProject.type)}</span>
        <h1>{featuredProject.name}</h1>
        <div className="hub-status-strip" aria-label="Tong quan project">
          <CompatibilityPing level={featuredProject.compatibility.level} reasons={featuredProject.compatibility.reasons} />
          <span>{featuredProject.installStatus.replace("_", " ")}</span>
          <span>{featuredProject.lastBenchmark.headlineMetric}</span>
        </div>
      </div>
    </section>
  );
});

const ProjectGrid = memo(function ProjectGrid({ projects }: { projects: HubProject[] }) {
  return (
    <section className="project-bento" aria-label="Danh sach project">
      {projects.length === 0 ? <p className="empty-log">No backend providers loaded.</p> : null}
      {projects.map((project) => (
        <ProjectCard key={project.id} project={project} />
      ))}
    </section>
  );
});

"use client";

import { Search } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { hubProjects } from "@/services/mockData";
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
];

export function HubExplorer() {
  const [activeType, setActiveType] = useState<ProjectType | "all">("all");
  const [query, setQuery] = useState("");
  const [featuredProjects, setFeaturedProjects] = useState<HubProject[]>(hubProjects.slice(0, 4));
  const [activeSlide, setActiveSlide] = useState(0);
  const [previousProject, setPreviousProject] = useState<HubProject | null>(null);

  useEffect(() => {
    setFeaturedProjects(shuffleProjects(hubProjects).slice(0, 4));
  }, []);

  useEffect(() => {
    const timer = window.setInterval(() => {
      setActiveSlide((currentSlide) => {
        setPreviousProject(featuredProjects[currentSlide] ?? null);
        return (currentSlide + 1) % featuredProjects.length;
      });
    }, 5400);

    return () => window.clearInterval(timer);
  }, [featuredProjects.length]);

  const visibleProjects = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase();

    return hubProjects.filter((project) => {
      const matchesType = activeType === "all" || project.type === activeType;
      const matchesQuery =
        normalizedQuery.length === 0 ||
        project.name.toLowerCase().includes(normalizedQuery) ||
        project.tags.some((tag) => tag.toLowerCase().includes(normalizedQuery)) ||
        project.repoUrl.toLowerCase().includes(normalizedQuery);

      return matchesType && matchesQuery;
    });
  }, [activeType, query]);

  const featuredProject = featuredProjects[activeSlide] ?? hubProjects[0];

  useEffect(() => {
    if (!previousProject) {
      return;
    }

    const timer = window.setTimeout(() => setPreviousProject(null), 720);
    return () => window.clearTimeout(timer);
  }, [previousProject]);

  useEffect(() => {
        document.documentElement.style.setProperty("--page-accent", featuredProject.visual.ambient);
        document.documentElement.style.setProperty("--page-accent-soft", featuredProject.visual.ambientSoft);
  }, [featuredProject]);

  return (
    <div className="page-flow">
      <section
        className="hub-carousel"
        style={
          {
            "--project-accent": featuredProject.accentColor,
            "--project-image": `url(${featuredProject.visual.imageUrl})`,
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
                "--project-image": `url(${previousProject.visual.imageUrl})`,
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
          <div className="hub-status-strip" aria-label="Tổng quan project">
            <CompatibilityPing
              level={featuredProject.compatibility.level}
              reasons={featuredProject.compatibility.reasons}
            />
            <span>{featuredProject.installStatus.replace("_", " ")}</span>
            <span>{featuredProject.lastBenchmark.headlineMetric}</span>
          </div>
        </div>

      </section>

      <div className="hub-tools">
        <div className="filter-dock" aria-label="Lọc provider">
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
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Tìm LLM, vision, repo..."
          />
        </label>
      </div>

      <section className="project-bento" aria-label="Danh sách project">
        {visibleProjects.map((project) => (
          <ProjectCard key={project.id} project={project} />
        ))}
      </section>
    </div>
  );
}

function shuffleProjects(projects: HubProject[]) {
  return [...projects]
    .map((project) => ({
      project,
      sort: Math.random(),
    }))
    .sort((left, right) => left.sort - right.sort)
    .map(({ project }) => project);
}

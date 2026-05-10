import Link from "next/link";
import { ArrowUpRight, Box, Cpu, Database, HardDrive } from "lucide-react";
import type { HubProject } from "@/services/types";
import { formatMemory, formatProjectType } from "@/utils/format";
import { CompatibilityPing } from "./CompatibilityPing";

export function ProjectCard({ project }: { project: HubProject }) {
  return (
    <article
      className="project-card"
      data-project-type={project.type}
      style={
        {
          "--project-accent": project.accentColor,
          "--project-image": `url(${project.visual.imageUrl})`,
          "--project-focus": project.visual.focus,
        } as React.CSSProperties
      }
    >
      <div className="project-card-image" aria-hidden="true" />
      <div className="project-card-top">
        <span className="project-type">{formatProjectType(project.type)}</span>
        <CompatibilityPing level={project.compatibility.level} reasons={project.compatibility.reasons} />
      </div>

      <div className="project-title-row">
        <div className="project-glyph" aria-hidden="true">
          <Box size={20} />
        </div>
        <div>
          <h2>{project.name}</h2>
          <p>{project.description}</p>
        </div>
      </div>

      <div className="tag-row">
        {project.tags.map((tag) => (
          <span key={tag}>{tag}</span>
        ))}
      </div>

      <div className="requirement-row" aria-label="Yêu cầu tối thiểu">
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

      <div className="project-card-bottom">
        <div>
          <span>Last metric</span>
          <strong>{project.lastBenchmark.headlineMetric}</strong>
        </div>
        <Link href={`/hub/${project.id}`} className="open-link" aria-label={`Mở ${project.name}`}>
          <ArrowUpRight size={18} aria-hidden="true" />
        </Link>
      </div>
    </article>
  );
}

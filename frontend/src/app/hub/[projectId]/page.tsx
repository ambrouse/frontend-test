import { notFound } from "next/navigation";
import { ProjectDetailView } from "@/components/hub/ProjectDetailView";
import { getProjectById, hubProjects } from "@/services/mockData";

type ProjectPageProps = {
  params: Promise<{
    projectId: string;
  }>;
};

export function generateStaticParams() {
  return hubProjects.map((project) => ({
    projectId: project.id,
  }));
}

export default async function ProjectPage({ params }: ProjectPageProps) {
  const { projectId } = await params;
  const project = getProjectById(projectId);

  if (!project) {
    notFound();
  }

  return <ProjectDetailView project={project} />;
}

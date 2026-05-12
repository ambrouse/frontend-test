import { ProjectDetailView } from "@/components/hub/ProjectDetailView";

type ProjectPageProps = {
  params: Promise<{
    projectId: string;
  }>;
};

export default async function ProjectPage({ params }: ProjectPageProps) {
  const { projectId } = await params;
  return <ProjectDetailView projectId={projectId} />;
}

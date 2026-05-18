import { evaluateCompatibility } from "./compatibility";
import type { HardwareSnapshot, HubProject, ProjectLog, RunningTask } from "./types";

export const hardwareSnapshot: HardwareSnapshot = {
  cpu: {
    name: "AMD Ryzen 9 7950X",
    cores: 16,
    usagePercent: 38,
    temperatureC: 61,
  },
  gpu: {
    name: "NVIDIA RTX 4090",
    vendor: "NVIDIA",
    usagePercent: 46,
    temperatureC: 68,
    vramTotalMb: 24576,
    vramUsedMb: 11320,
    driverVersion: "560.94",
  },
  ram: {
    totalMb: 65536,
    usedMb: 27480,
  },
  disk: {
    totalGb: 2048,
    freeGb: 842,
    installPathFreeGb: 318,
  },
  timestamp: "2026-05-10T10:33:00.000Z",
};

const projectsSeed = [
    {
        "id":  "agentic-commerce-blueprint",
        "name":  "Agentic Commerce Blueprint",
        "type":  "nvidia-blueprint",
        "repoUrl":  "https://github.com/baolnq-ai/Agentic-Commerce-blueprint-provider-",
        "description":  "Dockerized NVIDIA agentic commerce stack with storefront, merchant APIs, agents, Milvus, MinIO and Phoenix.",
        "tags":  [
                     "commerce",
                     "agents",
                     "nvidia"
                 ],
        "accentColor":  "#22c55e",
        "visual":  {
                       "imageUrl":  "/assets/projects/nvidia-blueprint.jpg",
                       "focus":  "54% 50%",
                       "ambient":  "#22c55e",
                       "ambientSoft":  "#052e16"
                   },
        "installStatus":  "not_installed",
        "runStatus":  "stopped",
        "requirements":  {
                             "minimum":  {
                                             "cpuCores":  8,
                                             "ramMb":  24576,
                                             "vramMb":  0,
                                             "diskGb":  32,
                                             "gpuRequired":  false,
                                             "notes":  "API mode can use NVIDIA hosted endpoints; local NIM mode needs NVIDIA GPU."
                                         },
                             "recommended":  {
                                                 "cpuCores":  16,
                                                 "ramMb":  65536,
                                                 "vramMb":  24576,
                                                 "diskGb":  160,
                                                 "gpuRequired":  true
                                             }
                         },
        "editableConfig":  {
                               "profile":  "api mode",
                               "branch":  "main",
                               "port":  8088,
                               "installDirectory":  "deploy/agentic-commerce-blueprint"
                           },
        "environment":  {
                            "supportedOs":  [
                                                "windows",
                                                "linux"
                                            ],
                            "architectures":  [
                                                  "x64",
                                                  "arm64"
                                              ],
                            "frameworks":  [
                                               "Docker Compose",
                                               "Python 3.12 containers",
                                               "Node 22 containers",
                                               "NVIDIA Agent Intelligence Toolkit",
                                               "Milvus",
                                               "MinIO",
                                               "Phoenix",
                                               "Next.js"
                                           ],
                            "requiredTools":  [
                                                  {
                                                      "id":  "git",
                                                      "label":  "Git",
                                                      "command":  "git --version",
                                                      "required":  true,
                                                      "installHint":  "Windows: winget install Git.Git. Linux: install git from your package manager."
                                                  },
                                                  {
                                                      "id":  "docker",
                                                      "label":  "Docker",
                                                      "command":  "docker --version",
                                                      "required":  true,
                                                      "installHint":  "Install Docker Desktop on Windows/macOS or Docker Engine on Linux."
                                                  },
                                                  {
                                                      "id":  "docker-compose",
                                                      "label":  "Docker Compose v2",
                                                      "command":  "docker compose version",
                                                      "required":  true,
                                                      "installHint":  "Install Docker Compose v2 plugin or Docker Desktop."
                                                  },
                                                  {
                                                      "id":  "docker-daemon",
                                                      "label":  "Docker daemon",
                                                      "command":  "docker info --format {{.ServerVersion}}",
                                                      "required":  true,
                                                      "installHint":  "Start Docker Desktop and wait until the Linux engine is running."
                                                  }
                                              ],
                            "runtimeModes":  [
                                                 {
                                                     "id":  "api",
                                                     "label":  "NVIDIA API mode",
                                                     "description":  "Uses NVIDIA hosted NIM-compatible endpoints. No local GPU is required, but NVIDIA_API_KEY is required.",
                                                     "requiresGpu":  false,
                                                     "requiresNvidiaKey":  true
                                                 },
                                                 {
                                                     "id":  "local_nim",
                                                     "label":  "Local NIM mode",
                                                     "description":  "Starts local NIM LLM and embedding containers. Requires NVIDIA GPU, NVIDIA runtime and model access.",
                                                     "requiresGpu":  true,
                                                     "requiresNvidiaKey":  true
                                                 }
                                             ],
                            "setupNotes":  [
                                               "Install clones the source into deploy/agentic-commerce-blueprint.",
                                               "Default Hub run path uses Docker Compose and fixed gateway port 8088.",
                                               "Source repo supports Git Bash/Linux shell through runall.sh; Hub wrapper supports Windows PowerShell and Linux."
                                           ]
                        },
        "lastBenchmark":  {
                              "headlineMetric":  "0 req/min",
                              "secondaryMetric":  "not started",
                              "latencyMs":  0,
                              "throughput":  0,
                              "vramPeakMb":  0,
                              "measuredAt":  "2026-05-10T00:00:00.000Z"
                          },
        "lastRunAt":  "2026-05-10T00:00:00.000Z",
        "runtime":  {
                        "defaultPort":  8088,
                        "healthUrl":  "http://localhost:8088/api/health",
                        "metricsUrl":  "http://localhost:8088/metrics",
                        "statusFile":  "runtime/status.json",
                        "metricsFile":  "runtime/metrics.json",
                        "pidFile":  "runtime/provider.pid",
                        "logFile":  "logs/runtime.log"
                    },
        "commands":  {
                         "windows":  {
                                         "setup":  "scripts/windows/setup.ps1",
                                         "run":  "scripts/windows/run.ps1",
                                         "stop":  "scripts/windows/stop.ps1",
                                         "delete":  "scripts/windows/delete.ps1",
                                         "health":  "scripts/windows/health.ps1",
                                         "metrics":  "scripts/windows/collect-metrics.ps1"
                                     },
                         "linux":  {
                                       "setup":  "scripts/linux/setup.sh",
                                       "run":  "scripts/linux/run.sh",
                                       "stop":  "scripts/linux/stop.sh",
                                       "delete":  "scripts/linux/delete.sh",
                                       "health":  "scripts/linux/health.sh",
                                       "metrics":  "scripts/linux/collect-metrics.sh"
                                   }
                     }
    },
    {
        "id":  "ai-virtual-assistant-provider",
        "name":  "AI Virtual Assistant Provider",
        "type":  "nvidia-blueprint",
        "repoUrl":  "https://github.com/mionm/ai-virtual-assistant-provider.git",
        "description":  "Deprecated NVIDIA AI Virtual Assistant customer service blueprint with agent, retrievers, analytics, API gateway, UI and data services.",
        "tags":  [
                     "assistant",
                     "customer-service",
                     "rag",
                     "deprecated",
                     "nvidia"
                 ],
        "accentColor":  "#f59e0b",
        "visual":  {
                       "imageUrl":  "/assets/projects/nvidia-blueprint.jpg",
                       "focus":  "50% 50%",
                       "ambient":  "#f59e0b",
                       "ambientSoft":  "#451a03"
                   },
        "installStatus":  "not_installed",
        "runStatus":  "stopped",
        "requirements":  {
                             "minimum":  {
                                             "cpuCores":  12,
                                             "ramMb":  32768,
                                             "vramMb":  0,
                                             "diskGb":  100,
                                             "gpuRequired":  false,
                                             "notes":  "Project is deprecated upstream as of Apr 2026; Hub default uses hosted NVIDIA endpoints and CPU Milvus override."
                                         },
                             "recommended":  {
                                                 "cpuCores":  24,
                                                 "ramMb":  131072,
                                                 "vramMb":  81920,
                                                 "diskGb":  400,
                                                 "gpuRequired":  true
                                             }
                         },
        "editableConfig":  {
                               "profile":  "hosted api mode",
                               "branch":  "main",
                               "port":  13001,
                               "installDirectory":  "deploy/aiva"
                           },
        "environment":  {
                            "supportedOs":  [
                                                "windows",
                                                "linux"
                                            ],
                            "architectures":  [
                                                  "x64"
                                              ],
                            "frameworks":  [
                                               "Docker Compose",
                                               "FastAPI",
                                               "React",
                                               "LangGraph",
                                               "Milvus",
                                               "Postgres",
                                               "Redis",
                                               "NVIDIA API"
                                           ],
                            "requiredTools":  [
                                                  {
                                                      "id":  "git",
                                                      "label":  "Git",
                                                      "command":  "git --version",
                                                      "required":  true,
                                                      "installHint":  "Install Git."
                                                  },
                                                  {
                                                      "id":  "bash",
                                                      "label":  "Bash",
                                                      "command":  "bash --version",
                                                      "required":  true,
                                                      "installHint":  "Install Git Bash on Windows."
                                                  },
                                                  {
                                                      "id":  "docker",
                                                      "label":  "Docker",
                                                      "command":  "docker --version",
                                                      "required":  true,
                                                      "installHint":  "Install Docker."
                                                  }
                                              ],
                            "runtimeModes":  [
                                                 {
                                                     "id":  "hosted",
                                                     "label":  "Hosted API mode",
                                                     "description":  "Uses NVIDIA hosted endpoints with local app/data containers.",
                                                     "requiresGpu":  false,
                                                     "requiresNvidiaKey":  true
                                                 }
                                             ],
                            "setupNotes":  [
                                               "This provider wraps a deprecated upstream blueprint for reproducible local evaluation.",
                                               "Run writes compose overrides so Quick config ports are effective."
                                           ]
                        },
        "lastBenchmark":  {
                              "headlineMetric":  "not started",
                              "secondaryMetric":  "no runtime sample",
                              "latencyMs":  0,
                              "throughput":  0,
                              "vramPeakMb":  0,
                              "measuredAt":  "2026-05-13T00:00:00.000Z"
                          },
        "lastRunAt":  "2026-05-13T00:00:00.000Z",
        "runtime":  {
                        "defaultPort":  13001,
                        "healthUrl":  "http://localhost:13001",
                        "metricsUrl":  "http://localhost:9000/agent/health",
                        "statusFile":  "runtime/status.json",
                        "metricsFile":  "runtime/metrics.json",
                        "pidFile":  "runtime/provider.pid",
                        "logFile":  "logs/runtime.log"
                    },
        "commands":  {
                         "windows":  {
                                         "setup":  "scripts/windows/setup.ps1",
                                         "run":  "scripts/windows/run.ps1",
                                         "stop":  "scripts/windows/stop.ps1",
                                         "delete":  "scripts/windows/delete.ps1",
                                         "health":  "scripts/windows/health.ps1",
                                         "metrics":  "scripts/windows/collect-metrics.ps1"
                                     },
                         "linux":  {
                                       "setup":  "scripts/linux/setup.sh",
                                       "run":  "scripts/linux/run.sh",
                                       "stop":  "scripts/linux/stop.sh",
                                       "delete":  "scripts/linux/delete.sh",
                                       "health":  "scripts/linux/health.sh",
                                       "metrics":  "scripts/linux/collect-metrics.sh"
                                   }
                     }
    },
    {
        "id":  "aiq",
        "name":  "NVIDIA AI-Q Blueprint",
        "type":  "nvidia-blueprint",
        "repoUrl":  "https://github.com/PhuongHo03/aiq.git",
        "description":  "NVIDIA AI-Q research assistant blueprint with FastAPI async jobs, Knowledge API, LlamaIndex retrieval and a Next.js UI.",
        "tags":  [
                     "research",
                     "agents",
                     "nvidia",
                     "knowledge",
                     "nextjs"
                 ],
        "accentColor":  "#76b900",
        "visual":  {
                       "imageUrl":  "/assets/projects/nvidia-blueprint.jpg",
                       "focus":  "52% 50%",
                       "ambient":  "#76b900",
                       "ambientSoft":  "#052e16"
                   },
        "installStatus":  "not_installed",
        "runStatus":  "stopped",
        "requirements":  {
                             "minimum":  {
                                             "cpuCores":  8,
                                             "ramMb":  16384,
                                             "vramMb":  0,
                                             "diskGb":  32,
                                             "gpuRequired":  false,
                                             "notes":  "Validated in hosted NVIDIA API mode with local SQLite/Dask and Knowledge API. Full web/paper search requires Tavily and Serper keys."
                                         },
                             "recommended":  {
                                                 "cpuCores":  12,
                                                 "ramMb":  32768,
                                                 "vramMb":  0,
                                                 "diskGb":  80,
                                                 "gpuRequired":  false
                                             }
                         },
        "editableConfig":  {
                               "profile":  "hosted knowledge mode",
                               "branch":  "develop",
                               "port":  13080,
                               "installDirectory":  "deploy/aiq"
                           },
        "environment":  {
                            "supportedOs":  [
                                                "windows",
                                                "linux"
                                            ],
                            "architectures":  [
                                                  "x64"
                                              ],
                            "frameworks":  [
                                               "Python 3.11+",
                                               "NVIDIA Agent Intelligence Toolkit",
                                               "FastAPI",
                                               "Dask",
                                               "LlamaIndex",
                                               "Next.js",
                                               "NVIDIA API"
                                           ],
                            "requiredTools":  [
                                                  {
                                                      "id":  "git",
                                                      "label":  "Git",
                                                      "command":  "git --version",
                                                      "required":  true,
                                                      "installHint":  "Windows: winget install Git.Git. Linux: install git from your package manager."
                                                  },
                                                  {
                                                      "id":  "bash",
                                                      "label":  "Bash",
                                                      "command":  "bash --version",
                                                      "required":  true,
                                                      "installHint":  "Windows: install Git Bash. Linux: bash is usually preinstalled."
                                                  },
                                                  {
                                                      "id":  "python",
                                                      "label":  "Python 3.11-3.13",
                                                      "command":  "python --version",
                                                      "required":  true,
                                                      "installHint":  "Install Python 3.11, 3.12 or 3.13. Windows launcher py -3.11 is supported."
                                                  },
                                                  {
                                                      "id":  "node",
                                                      "label":  "Node.js",
                                                      "command":  "node --version",
                                                      "required":  true,
                                                      "installHint":  "Install Node.js 20+."
                                                  },
                                                  {
                                                      "id":  "npm",
                                                      "label":  "npm",
                                                      "command":  "npm --version",
                                                      "required":  true,
                                                      "installHint":  "npm ships with Node.js."
                                                  }
                                              ],
                            "runtimeModes":  [
                                                 {
                                                     "id":  "hosted_knowledge",
                                                     "label":  "Hosted knowledge mode",
                                                     "description":  "Uses NVIDIA hosted endpoints, local SQLite/Dask and the built-in Knowledge API. NVIDIA_API_KEY is required.",
                                                     "requiresGpu":  false,
                                                     "requiresNvidiaKey":  true
                                                 },
                                                 {
                                                     "id":  "full_sources",
                                                     "label":  "Full source mode",
                                                     "description":  "Also enables Tavily web search and Serper paper search when TAVILY_API_KEY and SERPER_API_KEY are available.",
                                                     "requiresGpu":  false,
                                                     "requiresNvidiaKey":  true
                                                 }
                                             ],
                            "setupNotes":  [
                                               "Install clones branch develop from PhuongHo03/aiq.git into deploy/aiq.",
                                               "Hub applies a tested lifecycle patch during install because direct upstream push is currently blocked by GitHub permissions.",
                                               "Default Hub run path disables optional Docker support services and uses local SQLite/Dask."
                                           ]
                        },
        "lastBenchmark":  {
                              "headlineMetric":  "not started",
                              "secondaryMetric":  "no runtime sample",
                              "latencyMs":  0,
                              "throughput":  0,
                              "vramPeakMb":  0,
                              "measuredAt":  "2026-05-12T00:00:00.000Z"
                          },
        "lastRunAt":  "2026-05-12T00:00:00.000Z",
        "runtime":  {
                        "defaultPort":  13080,
                        "healthUrl":  "http://localhost:18080/health",
                        "metricsUrl":  "http://localhost:18080/v1/jobs/async/agents",
                        "statusFile":  "runtime/status.json",
                        "metricsFile":  "runtime/metrics.json",
                        "pidFile":  "runtime/provider.pid",
                        "logFile":  "logs/runtime.log"
                    },
        "commands":  {
                         "windows":  {
                                         "setup":  "scripts/windows/setup.ps1",
                                         "run":  "scripts/windows/run.ps1",
                                         "stop":  "scripts/windows/stop.ps1",
                                         "delete":  "scripts/windows/delete.ps1",
                                         "health":  "scripts/windows/health.ps1",
                                         "metrics":  "scripts/windows/collect-metrics.ps1"
                                     },
                         "linux":  {
                                       "setup":  "scripts/linux/setup.sh",
                                       "run":  "scripts/linux/run.sh",
                                       "stop":  "scripts/linux/stop.sh",
                                       "delete":  "scripts/linux/delete.sh",
                                       "health":  "scripts/linux/health.sh",
                                       "metrics":  "scripts/linux/collect-metrics.sh"
                                   }
                     }
    },
    {
        "id":  "nemotron-voice-agent-provider",
        "name":  "Nemotron Voice Agent Provider",
        "type":  "speech",
        "repoUrl":  "https://github.com/mionm/nemotron-voice-agent-provider.git",
        "description":  "Nemotron voice agent blueprint with WebRTC UI, Pipecat pipeline, hosted NVIDIA ASR/TTS/LLM defaults and optional local NIM mode.",
        "tags":  [
                     "voice",
                     "webrtc",
                     "nemotron",
                     "asr",
                     "tts"
                 ],
        "accentColor":  "#38bdf8",
        "visual":  {
                       "imageUrl":  "/assets/projects/nvidia-blueprint.jpg",
                       "focus":  "50% 50%",
                       "ambient":  "#38bdf8",
                       "ambientSoft":  "#082f49"
                   },
        "installStatus":  "not_installed",
        "runStatus":  "stopped",
        "requirements":  {
                             "minimum":  {
                                             "cpuCores":  8,
                                             "ramMb":  24576,
                                             "vramMb":  0,
                                             "diskGb":  80,
                                             "gpuRequired":  false,
                                             "notes":  "Hub default starts API mode python-app and ui-app without local NIM services."
                                         },
                             "recommended":  {
                                                 "cpuCores":  16,
                                                 "ramMb":  65536,
                                                 "vramMb":  98304,
                                                 "diskGb":  320,
                                                 "gpuRequired":  true
                                             }
                         },
        "editableConfig":  {
                               "profile":  "api mode",
                               "branch":  "main",
                               "port":  9000,
                               "installDirectory":  "deploy/nemotron-voice-agent-provider"
                           },
        "environment":  {
                            "supportedOs":  [
                                                "windows",
                                                "linux"
                                            ],
                            "architectures":  [
                                                  "x64"
                                              ],
                            "frameworks":  [
                                               "Docker Compose",
                                               "Pipecat",
                                               "WebRTC",
                                               "NVIDIA API"
                                           ],
                            "requiredTools":  [
                                                  {
                                                      "id":  "git",
                                                      "label":  "Git",
                                                      "command":  "git --version",
                                                      "required":  true,
                                                      "installHint":  "Install Git."
                                                  },
                                                  {
                                                      "id":  "bash",
                                                      "label":  "Bash",
                                                      "command":  "bash --version",
                                                      "required":  true,
                                                      "installHint":  "Install Git Bash on Windows."
                                                  },
                                                  {
                                                      "id":  "docker",
                                                      "label":  "Docker",
                                                      "command":  "docker --version",
                                                      "required":  true,
                                                      "installHint":  "Install Docker."
                                                  }
                                              ],
                            "runtimeModes":  [
                                                 {
                                                     "id":  "api",
                                                     "label":  "Hosted API mode",
                                                     "description":  "Uses NVIDIA hosted ASR/TTS/LLM endpoints.",
                                                     "requiresGpu":  false,
                                                     "requiresNvidiaKey":  true
                                                 }
                                             ],
                            "setupNotes":  [
                                               "Install clones the source and prepares .env from config/env.example.",
                                               "Run starts python-app and ui-app with bounded health checks."
                                           ]
                        },
        "lastBenchmark":  {
                              "headlineMetric":  "not started",
                              "secondaryMetric":  "no runtime sample",
                              "latencyMs":  0,
                              "throughput":  0,
                              "vramPeakMb":  0,
                              "measuredAt":  "2026-05-13T00:00:00.000Z"
                          },
        "lastRunAt":  "2026-05-13T00:00:00.000Z",
        "runtime":  {
                        "defaultPort":  9000,
                        "healthUrl":  "http://localhost:9000",
                        "metricsUrl":  "http://localhost:7860/docs",
                        "statusFile":  "runtime/status.json",
                        "metricsFile":  "runtime/metrics.json",
                        "pidFile":  "runtime/provider.pid",
                        "logFile":  "logs/runtime.log"
                    },
        "commands":  {
                         "windows":  {
                                         "setup":  "scripts/windows/setup.ps1",
                                         "run":  "scripts/windows/run.ps1",
                                         "stop":  "scripts/windows/stop.ps1",
                                         "delete":  "scripts/windows/delete.ps1",
                                         "health":  "scripts/windows/health.ps1",
                                         "metrics":  "scripts/windows/collect-metrics.ps1"
                                     },
                         "linux":  {
                                       "setup":  "scripts/linux/setup.sh",
                                       "run":  "scripts/linux/run.sh",
                                       "stop":  "scripts/linux/stop.sh",
                                       "delete":  "scripts/linux/delete.sh",
                                       "health":  "scripts/linux/health.sh",
                                       "metrics":  "scripts/linux/collect-metrics.sh"
                                   }
                     }
    },
    {
        "id":  "shop-retail-provider",
        "name":  "Shop Retail Provider",
        "type":  "nvidia-blueprint",
        "repoUrl":  "https://github.com/mionm/Shop-Retail-Provider-mion-.git",
        "description":  "Retail shopping assistant stack with React UI, chain server, catalog and memory retrievers, guardrails, Milvus, MinIO and nginx.",
        "tags":  [
                     "retail",
                     "shopping",
                     "rag",
                     "agents",
                     "nvidia"
                 ],
        "accentColor":  "#76b900",
        "visual":  {
                       "imageUrl":  "/assets/projects/nvidia-blueprint.jpg",
                       "focus":  "54% 50%",
                       "ambient":  "#76b900",
                       "ambientSoft":  "#052e16"
                   },
        "installStatus":  "not_installed",
        "runStatus":  "stopped",
        "requirements":  {
                             "minimum":  {
                                             "cpuCores":  8,
                                             "ramMb":  24576,
                                             "vramMb":  0,
                                             "diskGb":  60,
                                             "gpuRequired":  false,
                                             "notes":  "Default Hub mode uses NVIDIA hosted endpoints with local Docker services."
                                         },
                             "recommended":  {
                                                 "cpuCores":  16,
                                                 "ramMb":  65536,
                                                 "vramMb":  24576,
                                                 "diskGb":  180,
                                                 "gpuRequired":  true
                                             }
                         },
        "editableConfig":  {
                               "profile":  "api mode",
                               "branch":  "main",
                               "port":  13000,
                               "installDirectory":  "deploy/shop-retail-provider"
                           },
        "environment":  {
                            "supportedOs":  [
                                                "windows",
                                                "linux"
                                            ],
                            "architectures":  [
                                                  "x64"
                                              ],
                            "frameworks":  [
                                               "Docker Compose",
                                               "FastAPI",
                                               "React",
                                               "Milvus",
                                               "MinIO",
                                               "NVIDIA API"
                                           ],
                            "requiredTools":  [
                                                  {
                                                      "id":  "git",
                                                      "label":  "Git",
                                                      "command":  "git --version",
                                                      "required":  true,
                                                      "installHint":  "Install Git."
                                                  },
                                                  {
                                                      "id":  "docker",
                                                      "label":  "Docker",
                                                      "command":  "docker --version",
                                                      "required":  true,
                                                      "installHint":  "Install Docker Desktop or Docker Engine."
                                                  },
                                                  {
                                                      "id":  "docker-compose",
                                                      "label":  "Docker Compose v2",
                                                      "command":  "docker compose version",
                                                      "required":  true,
                                                      "installHint":  "Install Docker Compose v2."
                                                  }
                                              ],
                            "runtimeModes":  [
                                                 {
                                                     "id":  "api",
                                                     "label":  "Hosted API mode",
                                                     "description":  "Uses NVIDIA hosted endpoints for LLM, embeddings and rails.",
                                                     "requiresGpu":  false,
                                                     "requiresNvidiaKey":  true
                                                 }
                                             ],
                            "setupNotes":  [
                                               "Install clones the mionm source into deploy/shop-retail-provider.",
                                               "Quick config env keys are written to ignored .env files before Docker Compose starts."
                                           ]
                        },
        "lastBenchmark":  {
                              "headlineMetric":  "not started",
                              "secondaryMetric":  "no runtime sample",
                              "latencyMs":  0,
                              "throughput":  0,
                              "vramPeakMb":  0,
                              "measuredAt":  "2026-05-13T00:00:00.000Z"
                          },
        "lastRunAt":  "2026-05-13T00:00:00.000Z",
        "runtime":  {
                        "defaultPort":  13000,
                        "healthUrl":  "http://localhost:13000/api/health",
                        "metricsUrl":  "http://localhost:8009/health",
                        "statusFile":  "runtime/status.json",
                        "metricsFile":  "runtime/metrics.json",
                        "pidFile":  "runtime/provider.pid",
                        "logFile":  "logs/runtime.log"
                    },
        "commands":  {
                         "windows":  {
                                         "setup":  "scripts/windows/setup.ps1",
                                         "run":  "scripts/windows/run.ps1",
                                         "stop":  "scripts/windows/stop.ps1",
                                         "delete":  "scripts/windows/delete.ps1",
                                         "health":  "scripts/windows/health.ps1",
                                         "metrics":  "scripts/windows/collect-metrics.ps1"
                                     },
                         "linux":  {
                                       "setup":  "scripts/linux/setup.sh",
                                       "run":  "scripts/linux/run.sh",
                                       "stop":  "scripts/linux/stop.sh",
                                       "delete":  "scripts/linux/delete.sh",
                                       "health":  "scripts/linux/health.sh",
                                       "metrics":  "scripts/linux/collect-metrics.sh"
                                   }
                     }
    },
    {
        "id":  "multi-agent-intelligent-warehouse",
        "name":  "Multi-Agent Intelligent Warehouse",
        "type":  "nvidia-blueprint",
        "repoUrl":  "https://github.com/baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia",
        "description":  "NVIDIA Blueprint-aligned warehouse assistant with LangGraph agents, RAG, Milvus, monitoring and React dashboard.",
        "tags":  [
                     "warehouse",
                     "rag",
                     "nvidia"
                 ],
        "accentColor":  "#38bdf8",
        "visual":  {
                       "imageUrl":  "/assets/projects/nvidia-blueprint.jpg",
                       "focus":  "54% 50%",
                       "ambient":  "#0284c7",
                       "ambientSoft":  "#061f35"
                   },
        "installStatus":  "not_installed",
        "runStatus":  "stopped",
        "requirements":  {
                             "minimum":  {
                                             "cpuCores":  8,
                                             "ramMb":  24576,
                                             "vramMb":  0,
                                             "diskGb":  48,
                                             "gpuRequired":  false,
                                             "notes":  "CPU/dev compose can boot without GPU; GPU/NIM mode needs NVIDIA runtime."
                                         },
                             "recommended":  {
                                                 "cpuCores":  16,
                                                 "ramMb":  65536,
                                                 "vramMb":  24576,
                                                 "diskGb":  180,
                                                 "gpuRequired":  true
                                             }
                         },
        "editableConfig":  {
                               "profile":  "dev compose",
                               "branch":  "main",
                               "port":  13002,
                               "installDirectory":  "deploy/multi-agent-intelligent-warehouse"
                           },
        "environment":  {
                            "supportedOs":  [
                                                "windows",
                                                "linux"
                                            ],
                            "architectures":  [
                                                  "x64",
                                                  "arm64"
                                              ],
                            "frameworks":  [
                                               "Docker Compose",
                                               "Python 3.11 containers",
                                               "Node 20 containers",
                                               "FastAPI",
                                               "React",
                                               "LangGraph",
                                               "Milvus",
                                               "TimescaleDB",
                                               "Redis",
                                               "Kafka"
                                           ],
                            "requiredTools":  [
                                                  {
                                                      "id":  "git",
                                                      "label":  "Git",
                                                      "command":  "git --version",
                                                      "required":  true,
                                                      "installHint":  "Windows: winget install Git.Git. Linux: install git from your package manager."
                                                  },
                                                  {
                                                      "id":  "docker",
                                                      "label":  "Docker",
                                                      "command":  "docker --version",
                                                      "required":  true,
                                                      "installHint":  "Install Docker Desktop on Windows/macOS or Docker Engine on Linux."
                                                  },
                                                  {
                                                      "id":  "docker-compose",
                                                      "label":  "Docker Compose v2",
                                                      "command":  "docker compose version",
                                                      "required":  true,
                                                      "installHint":  "Install Docker Compose v2 plugin or Docker Desktop."
                                                  }
                                              ],
                            "runtimeModes":  [
                                                 {
                                                     "id":  "api",
                                                     "label":  "NVIDIA API mode",
                                                     "description":  "Uses NVIDIA hosted LLM/embedding endpoints and does not start local NIM by default.",
                                                     "requiresGpu":  false,
                                                     "requiresNvidiaKey":  true
                                                 },
                                                 {
                                                     "id":  "local-nim",
                                                     "label":  "Local NIM profile",
                                                     "description":  "Optional compose profile for local NIM. Requires NVIDIA GPU, NVIDIA runtime and enough VRAM.",
                                                     "requiresGpu":  true,
                                                     "requiresNvidiaKey":  true
                                                 }
                                             ],
                            "setupNotes":  [
                                               "Install clones the source into deploy/multi-agent-intelligent-warehouse.",
                                               "Default Hub run path publishes frontend UI on the configured port (default 13002) and keeps backend API on host port 8091.",
                                               "Frontend provider UI is exposed by the source stack on port 13002 and nginx on 13003 when running standalone."
                                           ]
                        },
        "lastBenchmark":  {
                              "headlineMetric":  "0 q/min",
                              "secondaryMetric":  "not started",
                              "latencyMs":  0,
                              "throughput":  0,
                              "vramPeakMb":  0,
                              "measuredAt":  "2026-05-10T00:00:00.000Z"
                          },
        "lastRunAt":  "2026-05-10T00:00:00.000Z",
        "runtime":  {
                        "defaultPort":  13002,
                        "healthUrl":  "http://localhost:8091/api/v1/health",
                        "metricsUrl":  "http://localhost:8091/metrics",
                        "statusFile":  "runtime/status.json",
                        "metricsFile":  "runtime/metrics.json",
                        "pidFile":  "runtime/provider.pid",
                        "logFile":  "logs/runtime.log"
                    },
        "commands":  {
                         "windows":  {
                                         "setup":  "scripts/windows/setup.ps1",
                                         "run":  "scripts/windows/run.ps1",
                                         "stop":  "scripts/windows/stop.ps1",
                                         "delete":  "scripts/windows/delete.ps1",
                                         "health":  "scripts/windows/health.ps1",
                                         "metrics":  "scripts/windows/collect-metrics.ps1"
                                     },
                         "linux":  {
                                       "setup":  "scripts/linux/setup.sh",
                                       "run":  "scripts/linux/run.sh",
                                       "stop":  "scripts/linux/stop.sh",
                                       "delete":  "scripts/linux/delete.sh",
                                       "health":  "scripts/linux/health.sh",
                                       "metrics":  "scripts/linux/collect-metrics.sh"
                                   }
                     }
    },
    {
        "id":  "pdf-to-podcast",
        "name":  "PDF to Podcast",
        "type":  "speech",
        "repoUrl":  "https://github.com/PhuongHo03/pdf-to-podcast.git",
        "description":  "PDF-to-podcast pipeline with FastAPI services, local PDF extraction, NVIDIA-backed agent scripting, ElevenLabs TTS, Redis, MinIO, Jaeger and a Gradio frontend.",
        "tags":  [
                     "pdf",
                     "podcast",
                     "tts",
                     "gradio",
                     "nvidia"
                 ],
        "accentColor":  "#14b8a6",
        "visual":  {
                       "imageUrl":  "/assets/projects/embedding-foundry.jpg",
                       "focus":  "45% 50%",
                       "ambient":  "#14b8a6",
                       "ambientSoft":  "#042f2e"
                   },
        "installStatus":  "not_installed",
        "runStatus":  "stopped",
        "requirements":  {
                             "minimum":  {
                                             "cpuCores":  8,
                                             "ramMb":  16384,
                                             "vramMb":  0,
                                             "diskGb":  40,
                                             "gpuRequired":  false,
                                             "notes":  "Default stack runs with hosted NVIDIA and ElevenLabs APIs. Docker images are large because the PDF model worker is CUDA-capable."
                                         },
                             "recommended":  {
                                                 "cpuCores":  12,
                                                 "ramMb":  32768,
                                                 "vramMb":  12288,
                                                 "diskGb":  120,
                                                 "gpuRequired":  false
                                             }
                         },
        "editableConfig":  {
                               "profile":  "hosted api mode",
                               "branch":  "main",
                               "port":  7860,
                               "installDirectory":  "deploy/pdf-to-podcast"
                           },
        "environment":  {
                            "supportedOs":  [
                                                "windows",
                                                "linux"
                                            ],
                            "architectures":  [
                                                  "x64"
                                              ],
                            "frameworks":  [
                                               "Docker Compose",
                                               "FastAPI",
                                               "Gradio",
                                               "Redis",
                                               "MinIO",
                                               "Jaeger",
                                               "NVIDIA API",
                                               "ElevenLabs"
                                           ],
                            "requiredTools":  [
                                                  {
                                                      "id":  "git",
                                                      "label":  "Git",
                                                      "command":  "git --version",
                                                      "required":  true,
                                                      "installHint":  "Windows: winget install Git.Git. Linux: install git from your package manager."
                                                  },
                                                  {
                                                      "id":  "bash",
                                                      "label":  "Bash",
                                                      "command":  "bash --version",
                                                      "required":  true,
                                                      "installHint":  "Windows: install Git Bash. Linux: bash is usually preinstalled."
                                                  },
                                                  {
                                                      "id":  "docker",
                                                      "label":  "Docker",
                                                      "command":  "docker --version",
                                                      "required":  true,
                                                      "installHint":  "Install Docker Desktop on Windows/macOS or Docker Engine on Linux."
                                                  },
                                                  {
                                                      "id":  "docker-compose",
                                                      "label":  "Docker Compose v2",
                                                      "command":  "docker compose version",
                                                      "required":  true,
                                                      "installHint":  "Install Docker Compose v2 plugin or Docker Desktop."
                                                  }
                                              ],
                            "runtimeModes":  [
                                                 {
                                                     "id":  "hosted",
                                                     "label":  "Hosted API mode",
                                                     "description":  "Uses hosted NVIDIA endpoints for script generation and ElevenLabs for TTS. API keys are needed for full podcast generation; health checks run without real keys.",
                                                     "requiresGpu":  false,
                                                     "requiresNvidiaKey":  true
                                                 }
                                             ],
                            "setupNotes":  [
                                               "Install clones the source into deploy/pdf-to-podcast.",
                                               "Run delegates to the provider setup.sh --up script and records the auto-selected frontend/API ports.",
                                               "The app defaults to the Gradio frontend on port 7860 when available."
                                           ]
                        },
        "lastBenchmark":  {
                              "headlineMetric":  "0 jobs/min",
                              "secondaryMetric":  "not started",
                              "latencyMs":  0,
                              "throughput":  0,
                              "vramPeakMb":  0,
                              "measuredAt":  "2026-05-11T00:00:00.000Z"
                          },
        "lastRunAt":  "2026-05-11T00:00:00.000Z",
        "runtime":  {
                        "defaultPort":  7860,
                        "healthUrl":  "http://localhost:7860",
                        "metricsUrl":  "http://localhost:8002/health",
                        "statusFile":  "runtime/status.json",
                        "metricsFile":  "runtime/metrics.json",
                        "pidFile":  "runtime/provider.pid",
                        "logFile":  "logs/runtime.log"
                    },
        "commands":  {
                         "windows":  {
                                         "setup":  "scripts/windows/setup.ps1",
                                         "run":  "scripts/windows/run.ps1",
                                         "stop":  "scripts/windows/stop.ps1",
                                         "delete":  "scripts/windows/delete.ps1",
                                         "health":  "scripts/windows/health.ps1",
                                         "metrics":  "scripts/windows/collect-metrics.ps1"
                                     },
                         "linux":  {
                                       "setup":  "scripts/linux/setup.sh",
                                       "run":  "scripts/linux/run.sh",
                                       "stop":  "scripts/linux/stop.sh",
                                       "delete":  "scripts/linux/delete.sh",
                                       "health":  "scripts/linux/health.sh",
                                       "metrics":  "scripts/linux/collect-metrics.sh"
                                   }
                     }
    }
] satisfies Omit<HubProject, "compatibility">[];

export const hubProjects: HubProject[] = projectsSeed.map((project) => ({
  ...project,
  compatibility: evaluateCompatibility(
    hardwareSnapshot,
    project.requirements.minimum,
    project.requirements.recommended,
  ),
}));

export const runningTasks: RunningTask[] = [];

export const projectLogs: ProjectLog[] = [];

export function getProjectById(projectId: string) {
  return hubProjects.find((project) => project.id === projectId);
}

export function getProjectLogs(projectId: string) {
  return projectLogs.filter((log) => log.projectId === projectId);
}

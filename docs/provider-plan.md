# AI Hub Provider Plan

Muc tieu: moi provider project tren GitHub co mot contract toi thieu giong nhau de AI Hub co the clone, doc thong tin, setup, run, stop, lay log, lay runtime status va ve dashboard/detail page ma khong can viet adapter rieng cho tung repo. Contract nay phai chay duoc tren ca Windows va Linux.

## 1. Cau truc repo toi thieu

```text
provider-repo/
  aihub.provider.json
  README.md
  scripts/
    windows/
      setup.ps1
      run.ps1
      stop.ps1
      health.ps1
      collect-metrics.ps1
    linux/
      setup.sh
      run.sh
      stop.sh
      health.sh
      collect-metrics.sh
  config/
    default.json
    profiles/
      small.json
      recommended.json
  runtime/
    .gitkeep
  logs/
    .gitkeep
```

Neu project dung Docker la chinh, van nen co script cho ca hai OS. Script co the chi wrap `docker compose` nhung phai ghi cung mot bo file runtime/log.

## 2. Manifest bat buoc

File `aihub.provider.json` la nguon du lieu chinh de frontend hien thi card va detail page.

```json
{
  "id": "local-llm-studio",
  "name": "Local LLM Studio",
  "type": "llm",
  "version": "0.1.0",
  "description": "Serve local GGUF models through an OpenAI-compatible API.",
  "tags": ["gguf", "chat", "api"],
  "accentColor": "#2dd4bf",
  "visual": {
    "image": "assets/cover.jpg",
    "focus": "60% 50%"
  },
  "requirements": {
    "minimum": {
      "cpuCores": 8,
      "ramMb": 16384,
      "vramMb": 8192,
      "diskGb": 24,
      "gpuRequired": true
    },
    "recommended": {
      "cpuCores": 12,
      "ramMb": 32768,
      "vramMb": 16000,
      "diskGb": 80,
      "gpuRequired": true
    }
  },
  "commands": {
    "windows": {
      "setup": "scripts/windows/setup.ps1",
      "run": "scripts/windows/run.ps1",
      "stop": "scripts/windows/stop.ps1",
      "health": "scripts/windows/health.ps1",
      "metrics": "scripts/windows/collect-metrics.ps1"
    },
    "linux": {
      "setup": "scripts/linux/setup.sh",
      "run": "scripts/linux/run.sh",
      "stop": "scripts/linux/stop.sh",
      "health": "scripts/linux/health.sh",
      "metrics": "scripts/linux/collect-metrics.sh"
    }
  },
  "runtime": {
    "defaultPort": 7860,
    "healthUrl": "http://localhost:7860/health",
    "metricsUrl": "http://localhost:7860/metrics",
    "statusFile": "runtime/status.json",
    "metricsFile": "runtime/metrics.json",
    "pidFile": "runtime/provider.pid",
    "logFile": "logs/runtime.log"
  },
  "environment": {
    "supportedOs": ["windows", "linux"],
    "architectures": ["x64", "arm64"],
    "frameworks": ["Docker Compose", "Python 3.12", "FastAPI"],
    "requiredTools": [
      {
        "id": "git",
        "label": "Git",
        "command": "git --version",
        "required": true,
        "installHint": "Windows: winget install Git.Git. Linux: install git from package manager."
      },
      {
        "id": "docker",
        "label": "Docker",
        "command": "docker --version",
        "required": true,
        "installHint": "Install Docker Desktop or Docker Engine."
      }
    ],
    "runtimeModes": [
      {
        "id": "api",
        "label": "Hosted API mode",
        "description": "Uses remote inference endpoints.",
        "requiresGpu": false,
        "requiresNvidiaKey": true
      }
    ],
    "setupNotes": ["Install clones source into deploy/{provider_id} only when user clicks Install."]
  }
}
```

AI Hub chon command theo OS hien tai:

- Windows: dung `commands.windows.*`.
- Linux: dung `commands.linux.*`.
- Neu mot OS chua support, manifest nen khai bao ro trong `platforms.unsupported` hoac script tra exit code `2`.
- `environment.requiredTools` duoc backend enrich bang OS/arch hien tai va tool availability de frontend hien may dang thieu gi truoc khi install.

## 3. Quy uoc cross-platform

Tat ca path trong manifest nen dung slash `/`, ke ca tren Windows. Backend co the resolve sang path native khi thuc thi.

Script phai:

- Chay tu repo root.
- Khong hard-code `C:\...` hoac `/home/...`.
- Doc config tu `config/default.json`.
- Ghi output vao `runtime/` va `logs/` voi cung schema tren ca Windows/Linux.
- Tra stdout JSON cho `health` va `metrics`.

Quy uoc shell:

- Windows script dung PowerShell 7 neu co the. Lenh goi nen la `pwsh -File scripts/windows/run.ps1`.
- Linux script dung POSIX shell hoac bash. Lenh goi nen la `bash scripts/linux/run.sh`.
- Linux script can co executable bit trong repo: `chmod +x scripts/linux/*.sh`.

## 4. Setup va lifecycle scripts

Moi script nen tra exit code ro rang:

- `0`: thanh cong.
- `1`: loi co the retry.
- `2`: thieu dependency hoac cau hinh.
- `3`: khong du phan cung.

`setup` nen:

- Kiem tra Python/Node/Docker/CUDA tuy project.
- Tao virtualenv/container neu can.
- Tai model hoac in huong dan neu model qua lon.
- Ghi `runtime/install-state.json`.

`run` nen:

- Doc `config/default.json` va profile dang chon.
- Start service o background.
- Ghi `runtime/provider.pid`.
- Ghi `runtime/status.json` ngay khi process bat dau.

`stop` nen:

- Dung process/container theo pid/name.
- Cap nhat `runtime/status.json`.

`health` nen:

- Kiem tra process con song.
- Kiem tra port hoac health endpoint.
- In JSON ngan ra stdout.

`collect-metrics` nen:

- Lay CPU/RAM/GPU/VRAM cua process neu co.
- Lay request/latency/error tu service neu co.
- Ghi `runtime/metrics.json`.
- In cung JSON ra stdout.

## 5. Runtime status chuan

File `runtime/status.json` la du lieu co ban de frontend ve trang thai live.

```json
{
  "projectId": "local-llm-studio",
  "state": "running",
  "pid": 18420,
  "port": 7860,
  "platform": "linux",
  "startedAt": "2026-05-10T09:42:00.000Z",
  "uptimeSec": 3120,
  "currentStep": "Serving OpenAI-compatible endpoint",
  "progressPercent": 100,
  "health": {
    "level": "ok",
    "message": "Endpoint healthy",
    "checkedAt": "2026-05-10T10:34:00.000Z"
  }
}
```

`state` nen nam trong nhom: `not_installed`, `installing`, `installed`, `running`, `stopping`, `stopped`, `failed`.

`platform` nen la `windows`, `linux`, hoac `docker`.

## 6. Metrics chuan cho dashboard

File `runtime/metrics.json` hoac endpoint `/metrics` nen co cung shape co ban:

```json
{
  "sampledAt": "2026-05-10T10:34:00.000Z",
  "platform": "linux",
  "process": {
    "cpuPercent": 18,
    "ramMb": 9140,
    "gpuPercent": 42,
    "vramMb": 12680
  },
  "service": {
    "requestsTotal": 1284,
    "requestsPerMin": 184,
    "latencyP50Ms": 410,
    "latencyP95Ms": 1800,
    "errorsLastHour": 2
  },
  "benchmark": {
    "headlineMetric": "72.4 tok/s",
    "secondaryMetric": "TTFT 410 ms",
    "vramPeakMb": 14820,
    "measuredAt": "2026-05-10T09:12:00.000Z"
  }
}
```

Frontend chi can cac field co ban nay de ve:

- Card: status, compatibility, last benchmark, resource minimum.
- Detail: process resource, health, port, uptime, benchmark, config, recent logs.
- Dashboard: running providers, GPU/VRAM pressure, request/error trend.

## 7. Log chuan

Log nen ghi newline JSON de de stream va filter:

```json
{"time":"2026-05-10T09:42:18.000Z","level":"info","source":"runtime","message":"Loaded model","meta":{"profile":"Qwen 14B Q4_K_M"}}
{"time":"2026-05-10T09:42:22.000Z","level":"debug","source":"runtime","message":"CUDA graph warmup completed","meta":{"durationMs":3400}}
```

Level toi thieu: `debug`, `info`, `warn`, `error`.

Source toi thieu: `setup`, `runtime`, `health`, `system`.

Nen dung UTF-8 cho moi log/config tren ca Windows va Linux.

## 8. Config profile

`config/default.json` nen chua cau hinh dang dung, con `config/profiles/*.json` la preset:

```json
{
  "profile": "Qwen 14B Q4_K_M",
  "port": 7860,
  "branch": "main",
  "env": {
    "CUDA_VISIBLE_DEVICES": "0"
  },
  "resources": {
    "maxVramMb": 16000,
    "maxRamMb": 32768
  },
  "platform": {
    "windows": {
      "python": ".venv/Scripts/python.exe"
    },
    "linux": {
      "python": ".venv/bin/python"
    }
  }
}
```

AI Hub chi can doc/ghi mot so field co ban: `profile`, `port`, `branch`, `env`, `resources`, `platform`.

## 9. Linux implementation notes

Linux provider nen:

- Dung `#!/usr/bin/env bash` va `set -euo pipefail`.
- Ghi pid bang `$!` vao `runtime/provider.pid` khi start background process.
- Dung `nohup`, `setsid`, `systemd-run --user`, hoac Docker Compose tuy project.
- Kiem tra GPU bang `nvidia-smi` neu provider can CUDA.
- Kiem tra port bang `ss -ltn` hoac health endpoint.
- Dung `jq` neu can ghi JSON phuc tap; neu khong co `jq`, script nen fallback bang Python.

Vi du `run.sh` toi thieu:

```bash
#!/usr/bin/env bash
set -euo pipefail

mkdir -p runtime logs
PORT="${AIHUB_PORT:-7860}"

nohup .venv/bin/python -m provider_server --port "$PORT" >> logs/runtime.log 2>&1 &
PID="$!"
echo "$PID" > runtime/provider.pid

python - <<PY
import json, datetime
status = {
  "projectId": "local-llm-studio",
  "state": "running",
  "pid": $PID,
  "port": $PORT,
  "platform": "linux",
  "startedAt": datetime.datetime.utcnow().isoformat() + "Z",
  "currentStep": "Process started",
  "progressPercent": 100,
}
open("runtime/status.json", "w", encoding="utf-8").write(json.dumps(status, indent=2))
PY
```

## 10. Detail page nen hien thi

Moi provider detail page nen co phan co ban giong nhau:

- Header: ten project, type, install/run status, compatibility, action Run/Stop/Install/Delete.
- Live runtime: state, platform, pid, port, uptime, current step, health message.
- Resource usage: CPU, RAM, GPU, VRAM hien tai va peak.
- Benchmark: headline metric, latency p50/p95, throughput, vram peak, measured time.
- Requirements: minimum/recommended so voi may hien tai.
- Config: profile, branch, install path, env quan trong, selected port.
- Logs: filter theo level/source, copy/export.

Phan dashboard rieng cua tung project co the sau hon, nhung cac muc tren nen la chuan bat buoc de AI Hub quan ly thong nhat.

## 11. Co che cap nhat du lieu

Muc co ban:

- Frontend/backend poll `runtime/status.json` va `runtime/metrics.json` moi 1-3 giay khi provider dang chay.
- Khi provider stopped, poll cham lai hoac chi refresh theo action.
- Logs doc tail tu `logs/runtime.log`.

Muc tot hon:

- Backend expose `/api/providers/:id/status`, `/metrics`, `/logs?tail=200`.
- Provider chi can ghi file chuan; backend gom du lieu va chuan hoa cho frontend.

## 12. Checklist de repo duoc add vao AI Hub

- Co `aihub.provider.json` hop le.
- Co script Windows trong `scripts/windows/*.ps1`.
- Co script Linux trong `scripts/linux/*.sh`.
- Linux scripts co executable bit.
- Co `runtime/status.json` sau khi run hoac health.
- Co `runtime/metrics.json` khi dang chay.
- Co `logs/runtime.log` newline JSON.
- Co `config/default.json`.
- Co requirement minimum/recommended ro rang.
- Co health signal de AI Hub biet project chay that hay chi co process.

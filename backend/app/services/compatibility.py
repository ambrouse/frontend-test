from __future__ import annotations

from app.schemas.models import HardwareSnapshot


def evaluate_compatibility(hardware: HardwareSnapshot, minimum: dict, recommended: dict) -> dict:
    reasons: list[str] = []
    available_ram_mb = hardware.ram.totalMb - hardware.ram.usedMb
    available_vram_mb = hardware.gpu.vramTotalMb - hardware.gpu.vramUsedMb

    if hardware.cpu.cores < minimum["cpuCores"]:
        reasons.append(f"CPU needs at least {minimum['cpuCores']} cores.")
    if available_ram_mb < minimum["ramMb"]:
        reasons.append(f"RAM free is short by {minimum['ramMb'] - available_ram_mb} MB.")
    if minimum["gpuRequired"] and hardware.gpu.vramTotalMb == 0:
        reasons.append("GPU is required but no GPU was detected.")
    if available_vram_mb < minimum["vramMb"]:
        reasons.append(f"VRAM free is short by {minimum['vramMb'] - available_vram_mb} MB.")
    if hardware.disk.installPathFreeGb < minimum["diskGb"]:
        reasons.append(f"Install disk needs {minimum['diskGb'] - hardware.disk.installPathFreeGb} GB more.")

    if reasons:
        return {"level": "red", "reasons": reasons}

    warnings: list[str] = []
    if available_ram_mb < recommended["ramMb"]:
        warnings.append("Runs, but free RAM is below recommended level.")
    if available_vram_mb < recommended["vramMb"]:
        warnings.append("Runs, but VRAM is near the limit; use a lighter profile.")
    if hardware.gpu.temperatureC is not None and hardware.gpu.temperatureC >= 78:
        warnings.append("GPU is warm; watch temperature on long sessions.")
    if hardware.disk.installPathFreeGb < recommended["diskGb"]:
        warnings.append("Install disk free space is below recommended level.")

    if warnings:
        return {"level": "yellow", "reasons": warnings}

    return {"level": "green", "reasons": ["Hardware has enough resources for the recommended profile."]}

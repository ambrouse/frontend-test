import type { CompatibilityLevel, HardwareSnapshot, RequirementProfile } from "./types";

type CompatibilityResult = {
  level: CompatibilityLevel;
  reasons: string[];
};

export function evaluateCompatibility(
  hardware: HardwareSnapshot,
  minimum: RequirementProfile,
  recommended: RequirementProfile,
): CompatibilityResult {
  const reasons: string[] = [];
  const availableRamMb = hardware.ram.totalMb - hardware.ram.usedMb;
  const availableVramMb = hardware.gpu.vramTotalMb - hardware.gpu.vramUsedMb;

  if (hardware.cpu.cores < minimum.cpuCores) {
    reasons.push(`CPU cần tối thiểu ${minimum.cpuCores} cores.`);
  }

  if (availableRamMb < minimum.ramMb) {
    reasons.push(`RAM trống thiếu ${minimum.ramMb - availableRamMb} MB.`);
  }

  if (minimum.gpuRequired && hardware.gpu.vramTotalMb === 0) {
    reasons.push("Project cần GPU nhưng máy chưa phát hiện GPU.");
  }

  if (availableVramMb < minimum.vramMb) {
    reasons.push(`VRAM trống thiếu ${minimum.vramMb - availableVramMb} MB.`);
  }

  if (hardware.disk.installPathFreeGb < minimum.diskGb) {
    reasons.push(`Ổ cài đặt cần thêm ${minimum.diskGb - hardware.disk.installPathFreeGb} GB.`);
  }

  if (reasons.length > 0) {
    return {
      level: "red",
      reasons,
    };
  }

  const warnings: string[] = [];

  if (availableRamMb < recommended.ramMb) {
    warnings.push("Chạy được nhưng RAM trống thấp hơn mức khuyến nghị.");
  }

  if (availableVramMb < recommended.vramMb) {
    warnings.push("Chạy được nhưng VRAM gần ngưỡng, nên dùng profile nhẹ hơn.");
  }

  if ((hardware.gpu.temperatureC ?? 0) >= 78) {
    warnings.push("GPU đang nóng, nên theo dõi nhiệt độ khi chạy lâu.");
  }

  if (hardware.disk.installPathFreeGb < recommended.diskGb) {
    warnings.push("Dung lượng ổ cài đặt thấp hơn mức khuyến nghị.");
  }

  if (warnings.length > 0) {
    return {
      level: "yellow",
      reasons: warnings,
    };
  }

  return {
    level: "green",
    reasons: ["Máy hiện tại đủ tài nguyên cho profile khuyến nghị."],
  };
}

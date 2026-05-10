import { describe, expect, it } from "vitest";
import { evaluateCompatibility } from "@/services/compatibility";
import type { HardwareSnapshot, RequirementProfile } from "@/services/types";

const hardware: HardwareSnapshot = {
  cpu: {
    name: "Test CPU",
    cores: 12,
    usagePercent: 10,
    temperatureC: 52,
  },
  gpu: {
    name: "Test GPU",
    vendor: "NVIDIA",
    usagePercent: 20,
    temperatureC: 62,
    vramTotalMb: 16384,
    vramUsedMb: 4096,
    driverVersion: "test",
  },
  ram: {
    totalMb: 32768,
    usedMb: 8192,
  },
  disk: {
    totalGb: 1024,
    freeGb: 500,
    installPathFreeGb: 200,
  },
  timestamp: "2026-05-10T00:00:00.000Z",
};

const minimum: RequirementProfile = {
  cpuCores: 8,
  ramMb: 12000,
  vramMb: 8000,
  diskGb: 40,
  gpuRequired: true,
};

it("returns green when hardware meets recommended requirements", () => {
  const result = evaluateCompatibility(hardware, minimum, {
    ...minimum,
    ramMb: 20000,
    vramMb: 10000,
    diskGb: 80,
  });

  expect(result.level).toBe("green");
});

it("returns yellow when hardware meets minimum but misses recommended requirements", () => {
  const result = evaluateCompatibility(hardware, minimum, {
    ...minimum,
    ramMb: 30000,
    vramMb: 14000,
    diskGb: 80,
  });

  expect(result.level).toBe("yellow");
  expect(result.reasons.length).toBeGreaterThan(0);
});

it("returns red when hardware misses minimum requirements", () => {
  const result = evaluateCompatibility(hardware, {
    ...minimum,
    vramMb: 20000,
  }, minimum);

  expect(result.level).toBe("red");
});

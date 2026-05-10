import type { HardwareSnapshot, ProviderSummary } from "./types";

export const emptyHardwareSnapshot: HardwareSnapshot = {
  cpu: {
    name: "Detecting CPU",
    cores: 0,
    usagePercent: 0,
    temperatureC: null,
  },
  gpu: {
    name: "Detecting GPU",
    vendor: "unknown",
    usagePercent: 0,
    temperatureC: null,
    vramTotalMb: 0,
    vramUsedMb: 0,
    driverVersion: "unknown",
  },
  ram: {
    totalMb: 0,
    usedMb: 0,
  },
  disk: {
    totalGb: 0,
    freeGb: 0,
    installPathFreeGb: 0,
  },
  timestamp: "",
};

export const emptyProviderSummary: ProviderSummary = {
  total: 0,
  ready: 0,
  blocked: 0,
  installed: 0,
  running: 0,
};

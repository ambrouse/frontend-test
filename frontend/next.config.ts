import type { NextConfig } from "next";

const localLanHost = process.env.AIHUB_LAN_HOST?.trim();
const defaultAllowedDevOrigins = [
  "localhost",
  "127.0.0.1",
  "localhost:8080",
  "127.0.0.1:8080",
  ...(localLanHost ? [localLanHost, `${localLanHost}:3000`, `${localLanHost}:8080`] : []),
];
const configuredAllowedDevOrigins = process.env.AIHUB_ALLOWED_DEV_ORIGINS?.split(",")
  .map((origin) => origin.trim())
  .filter(Boolean) ?? [];
const allowedDevOrigins = Array.from(new Set([...defaultAllowedDevOrigins, ...configuredAllowedDevOrigins]));
const apiProxyHost = process.env.API_PROXY_HOST || "127.0.0.1";
const apiProxyPort = process.env.API_PROXY_PORT || "8000";
const apiProxyTarget = (process.env.API_PROXY_TARGET || `http://${apiProxyHost}:${apiProxyPort}`).replace(/\/$/, "");

const nextConfig: NextConfig = {
  reactStrictMode: true,
  devIndicators: false,
  allowedDevOrigins,
  output: "standalone",
  turbopack: {
    root: process.cwd(),
  },
  async rewrites() {
    return [
      {
        source: "/api/:path*",
        destination: `${apiProxyTarget}/api/:path*`,
      },
    ];
  },
};

export default nextConfig;

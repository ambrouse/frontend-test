import type { NextConfig } from "next";

const localLanHost = process.env.AIHUB_LAN_HOST?.trim();
const defaultAllowedDevOrigins = [
  "localhost",
  "127.0.0.1",
  "localhost:6900",
  "127.0.0.1:6900",
  "localhost:6901",
  "127.0.0.1:6901",
  ...(localLanHost ? [localLanHost, `${localLanHost}:6900`, `${localLanHost}:6901`] : []),
];
const configuredAllowedDevOrigins = process.env.AIHUB_ALLOWED_DEV_ORIGINS?.split(",")
  .map((origin) => origin.trim())
  .filter(Boolean) ?? [];
const allowedDevOrigins = Array.from(new Set([...defaultAllowedDevOrigins, ...configuredAllowedDevOrigins]));
const apiProxyHost = process.env.API_PROXY_HOST || "127.0.0.1";
const apiProxyPort = process.env.API_PROXY_PORT || "6902";
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

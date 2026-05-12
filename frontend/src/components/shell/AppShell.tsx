"use client";

import clsx from "clsx";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Boxes, Cpu, Moon, Settings, Sun } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { fetchActiveTasks } from "@/services/apiClient";

type ThemeMode = "dark" | "light";

const navigationItems = [
  {
    href: "/",
    label: "Home",
    icon: Cpu,
    match: "exact",
  },
  {
    href: "/hub",
    label: "Hub",
    icon: Boxes,
    match: "exact",
  },
] as const;

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const currentPathname = pathname ?? "/";

  return (
    <div className="app-frame">
      <aside className="side-dock" aria-label="Dieu huong chinh">
        <Link href="/" className="brand-mark" aria-label="AI Hub Home">
          <span className="brand-core">AI</span>
        </Link>

        <nav className="dock-nav">
          {navigationItems.map((item) => {
            const Icon = item.icon;
            const isActive =
              item.match === "exact"
                ? currentPathname === item.href
                : currentPathname === item.href || currentPathname.startsWith(`${item.href}/`);

            return (
              <Link
                key={item.href}
                href={item.href}
                className={clsx("dock-link", isActive && "is-active")}
                aria-label={item.label}
                title={item.label}
              >
                <Icon size={20} aria-hidden="true" />
              </Link>
            );
          })}
        </nav>

        <button className="dock-link dock-button" type="button" aria-label="Settings" title="Settings">
          <Settings size={20} aria-hidden="true" />
        </button>
      </aside>

      <div className="content-shell">
        <header className="command-bar">
          <LiveTaskStatus />
          <ThemeToggle />
        </header>

        <main className="main-stage">{children}</main>
      </div>
    </div>
  );
}

function LiveTaskStatus() {
  const [activeTaskCount, setActiveTaskCount] = useState(0);

  useEffect(() => {
    let isMounted = true;
    const load = () => {
      const controller = new AbortController();
      void fetchActiveTasks({ signal: controller.signal, timeoutMs: 900 })
        .then((response) => {
          if (isMounted) setActiveTaskCount(response.count);
        })
        .catch(() => {
          if (isMounted) setActiveTaskCount(0);
        });
      return controller;
    };

    let controller = load();
    const interval = window.setInterval(() => {
      controller.abort();
      controller = load();
    }, 2000);

    return () => {
      isMounted = false;
      controller.abort();
      window.clearInterval(interval);
    };
  }, []);

  return (
    <div className="top-status">
      <span className="live-dot" aria-hidden="true" />
      <span>{activeTaskCount} task live</span>
    </div>
  );
}

function ThemeToggle() {
  const [theme, setTheme] = useState<ThemeMode>("dark");
  const switchTimer = useRef<number | null>(null);

  const applyTheme = (nextTheme: ThemeMode) => {
    document.documentElement.dataset.theme = nextTheme;
    window.localStorage.setItem("ai-hub-theme", nextTheme);
    setTheme(nextTheme);
  };

  useEffect(() => {
    const savedTheme = window.localStorage.getItem("ai-hub-theme") as ThemeMode | null;
    const preferredTheme = window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
    const nextTheme = savedTheme ?? preferredTheme;
    applyTheme(nextTheme);
  }, []);

  useEffect(() => {
    return () => {
      if (switchTimer.current !== null) {
        window.clearTimeout(switchTimer.current);
      }
      delete document.documentElement.dataset.themeSwitching;
    };
  }, []);

  const handleToggleTheme = () => {
    const root = document.documentElement;
    const nextTheme = theme === "dark" ? "light" : "dark";
    root.dataset.themeSwitching = "1";
    if (switchTimer.current !== null) {
      window.clearTimeout(switchTimer.current);
    }

    window.requestAnimationFrame(() => {
      applyTheme(nextTheme);
      switchTimer.current = window.setTimeout(() => {
        delete root.dataset.themeSwitching;
      }, 120);
    });
  };

  return (
    <button className="theme-toggle" type="button" onClick={handleToggleTheme} aria-label="Doi theme">
      {theme === "dark" ? <Sun size={18} aria-hidden="true" /> : <Moon size={18} aria-hidden="true" />}
      <span>{theme === "dark" ? "Light" : "Dark"}</span>
    </button>
  );
}

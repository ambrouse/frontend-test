"use client";

import clsx from "clsx";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Boxes, Cpu, Moon, Settings, Sun, Workflow } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { runningTasks } from "@/services/mockData";

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
  {
    href: "/hub/local-llm-studio",
    label: "Live",
    icon: Workflow,
    match: "section",
  },
];

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const currentPathname = pathname ?? "/";
  const [theme, setTheme] = useState<ThemeMode>("dark");
  const [isThemeChanging, setIsThemeChanging] = useState(false);
  const activeTasks = useMemo(
    () => runningTasks.filter((task) => task.status === "running" || task.status === "installing"),
    [],
  );

  useEffect(() => {
    const savedTheme = window.localStorage.getItem("ai-hub-theme") as ThemeMode | null;
    const preferredTheme = window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
    setTheme(savedTheme ?? preferredTheme);
  }, []);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    window.localStorage.setItem("ai-hub-theme", theme);
  }, [theme]);

  const handleToggleTheme = () => {
    if (isThemeChanging) {
      return;
    }

    setIsThemeChanging(true);
    const nextTheme = theme === "dark" ? "light" : "dark";
    document.documentElement.dataset.themeNext = nextTheme;
    document.documentElement.dataset.themeTransition = "prepare";

    window.setTimeout(() => {
      document.documentElement.dataset.themeTransition = "commit";
      setTheme(nextTheme);
    }, 180);

    window.setTimeout(() => {
      delete document.documentElement.dataset.themeTransition;
      delete document.documentElement.dataset.themeNext;
      setIsThemeChanging(false);
    }, 1180);
  };

  return (
    <div className="app-frame">
      <aside className="side-dock" aria-label="Điều hướng chính">
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
          <div className="top-status">
            <span className="live-dot" aria-hidden="true" />
            <span>{activeTasks.length} task live</span>
          </div>

          <button className="theme-toggle" type="button" onClick={handleToggleTheme} aria-label="Đổi theme">
            {theme === "dark" ? <Sun size={18} aria-hidden="true" /> : <Moon size={18} aria-hidden="true" />}
            <span>{theme === "dark" ? "Light" : "Dark"}</span>
          </button>
        </header>

        <main className="main-stage">{children}</main>
      </div>
    </div>
  );
}

import type { Metadata } from "next";
import { Open_Sans, Rubik } from "next/font/google";
import "../styles/globals.css";
import "../styles/shell.css";
import { AppShell } from "@/components/shell/AppShell";

const openSans = Open_Sans({
  subsets: ["latin", "vietnamese"],
  variable: "--font-sougen-body",
  display: "swap",
});

const rubik = Rubik({
  subsets: ["latin", "latin-ext"],
  variable: "--font-sougen-display",
  display: "swap",
});

export const metadata: Metadata = {
  title: "AI Hub",
  description: "Local AI project hub with hardware-aware install decisions.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi" suppressHydrationWarning>
      <body className={`${openSans.variable} ${rubik.variable}`}>
        <AppShell>{children}</AppShell>
      </body>
    </html>
  );
}

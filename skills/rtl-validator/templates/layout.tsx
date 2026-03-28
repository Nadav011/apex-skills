/**
 * Next.js App Router Root Layout - RTL-First Configuration
 *
 * This template provides the correct RTL setup for Hebrew/Arabic applications.
 * Copy this to your app/layout.tsx file.
 *
 * Key RTL requirements:
 * - html element has dir="rtl" and lang="he" (or "ar")
 * - Hebrew-optimized font (Heebo) is loaded
 * - Proper meta tags for RTL SEO
 *
 * @version 1.0.0
 */

import type { Metadata, Viewport } from "next";
import { Heebo } from "next/font/google";
import "./globals.css";

// =============================================================================
// Font Configuration
// =============================================================================

/**
 * Heebo - Hebrew-optimized font
 * - Supports Hebrew and Latin character sets
 * - Variable font for optimal performance
 * - display: swap for better CLS scores
 */
const heebo = Heebo({
  subsets: ["hebrew", "latin"],
  display: "swap",
  variable: "--font-heebo",
  // Preload specific weights for better performance
  weight: ["300", "400", "500", "600", "700"],
});

// For Arabic applications, use Noto Sans Arabic or similar:
// import { Noto_Sans_Arabic } from 'next/font/google';
// const notoArabic = Noto_Sans_Arabic({
//   subsets: ['arabic'],
//   display: 'swap',
//   variable: '--font-noto-arabic',
// });

// =============================================================================
// Metadata Configuration
// =============================================================================

export const metadata: Metadata = {
  // Base URL for all relative URLs
  metadataBase: new URL(
    process.env.NEXT_PUBLIC_APP_URL || "https://example.com",
  ),

  // Title configuration with template
  title: {
    default: "שם האפליקציה",
    template: "%s | שם האפליקציה",
  },

  // Description for SEO
  description: "תיאור האפליקציה בעברית לצורכי SEO",

  // Keywords (in Hebrew)
  keywords: ["מילת מפתח 1", "מילת מפתח 2", "מילת מפתח 3"],

  // Author information
  authors: [{ name: "שם החברה" }],
  creator: "שם החברה",

  // Robots configuration
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },

  // Open Graph (Facebook, LinkedIn)
  openGraph: {
    type: "website",
    locale: "he_IL", // Hebrew locale
    url: "/",
    siteName: "שם האפליקציה",
    title: "שם האפליקציה",
    description: "תיאור האפליקציה בעברית",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "שם האפליקציה",
      },
    ],
  },

  // Twitter Card
  twitter: {
    card: "summary_large_image",
    title: "שם האפליקציה",
    description: "תיאור האפליקציה בעברית",
    images: ["/og-image.png"],
  },

  // Alternate languages (for i18n)
  alternates: {
    canonical: "/",
    languages: {
      "he-IL": "/he",
      "en-US": "/en",
      // 'ar-SA': '/ar',
    },
  },

  // App manifest
  manifest: "/manifest.json",

  // Icons
  icons: {
    icon: "/favicon.ico",
    apple: "/apple-touch-icon.png",
  },
};

// =============================================================================
// Viewport Configuration
// =============================================================================

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#ffffff" },
    { media: "(prefers-color-scheme: dark)", color: "#000000" },
  ],
};

// =============================================================================
// Root Layout Component
// =============================================================================

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="he" // Hebrew language code (use "ar" for Arabic)
      dir="rtl" // Right-to-left text direction
      className={heebo.variable}
      suppressHydrationWarning // For theme switching
    >
      <head>
        {/* Preconnect to external origins for performance */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin="anonymous"
        />

        {/* DNS prefetch for API endpoints */}
        {/* <link rel="dns-prefetch" href="https://api.example.com" /> */}
      </head>
      <body
        className={`
          font-heebo
          antialiased
          bg-background
          text-foreground
          min-h-screen
        `}
      >
        {/* Skip to main content link for accessibility */}
        <a
          href="#main-content"
          className="
            sr-only
            focus:not-sr-only
            focus:absolute
            focus:top-4
            focus:inset-s-4
            focus:z-50
            focus:px-4
            focus:py-2
            focus:bg-primary
            focus:text-primary-foreground
            focus:rounded-md
          "
        >
          דלג לתוכן הראשי
        </a>

        {/* Main content */}
        <main id="main-content">{children}</main>

        {/* Global providers can be added here */}
        {/* <Providers>{children}</Providers> */}
      </body>
    </html>
  );
}

// =============================================================================
// Usage Notes
// =============================================================================

/**
 * RTL-First Checklist for this layout:
 *
 * 1. HTML Attributes:
 *    ✅ lang="he" (or "ar" for Arabic)
 *    ✅ dir="rtl"
 *
 * 2. Font:
 *    ✅ Heebo font loaded (Hebrew-optimized)
 *    ✅ font-heebo class applied to body
 *
 * 3. Typography:
 *    ✅ antialiased for smooth rendering
 *
 * 4. Accessibility:
 *    ✅ Skip to content link
 *    ✅ Proper heading structure
 *
 * 5. SEO:
 *    ✅ Hebrew metadata
 *    ✅ he_IL locale for Open Graph
 *    ✅ Alternate language links
 *
 * 6. Performance:
 *    ✅ Font preloading with display: swap
 *    ✅ Preconnect to external origins
 *
 * Remember to:
 * - Use logical CSS properties (ms-, me-, ps-, pe-, start-, end-)
 * - Never use ml-, mr-, pl-, pr-, left-, right-
 * - Add rtl:rotate-180 to directional icons
 * - Wrap numbers/code in dir="ltr" spans
 */

# CI/CD Reference for PWA v24.5.0

> **PWA Expert Reference** | CI/CD Pipeline for PWA Deployment

## GitHub Actions Workflow

```yaml
name: PWA CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: [self-hosted, linux, x64, pop-os]
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v4
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: '24'
          cache: 'pnpm'

      - run: pnpm install
      - run: pnpm lint
      - run: pnpm test
      - run: pnpm build

      # PWA-specific checks
      - name: Lighthouse CI
        uses: treosh/lighthouse-ci-action@v12
        with:
          configPath: ./lighthouserc.json

      - name: Check bundle size
        run: |
          SIZE=$(du -sk dist/assets/*.js | awk '{sum+=$1} END {print sum}')
          if [ $SIZE -gt 120 ]; then
            echo "Bundle too large: ${SIZE}KB"
            exit 1
          fi

  deploy:
    needs: build-and-test
    if: github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, pop-os]
    steps:
      - uses: actions/checkout@v4
      - run: pnpm install
      - run: pnpm build

      - name: Deploy to Cloudflare Pages/Netlify
        uses: amondnet/cloudflare-pages-action@v25
        with:
          cloudflare-pages-token: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          cloudflare-pages-org-id: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          cloudflare-pages-project-id: ${{ secrets.CF_PAGES_PROJECT }}
          cloudflare-pages-args: '--prod'
```

## Lighthouse CI Config

```json
{
  "ci": {
    "collect": {
      "numberOfRuns": 3,
      "settings": {
        "preset": "desktop"
      }
    },
    "assert": {
      "assertions": {
        "categories:pwa": ["error", { "minScore": 1 }],
        "categories:performance": ["warn", { "minScore": 0.9 }],
        "categories:accessibility": ["warn", { "minScore": 0.9 }]
      }
    }
  }
}
```

## PWA Verification Steps

1. **Build** - Generate optimized production build
2. **Lighthouse** - PWA score must be 100
3. **Bundle Size** - Must be under 120KB gzipped
4. **SW Test** - Service worker registers correctly
5. **Offline Test** - App works offline

## Deployment Checklist

- [ ] All tests pass
- [ ] Lighthouse PWA = 100
- [ ] Bundle < 100KB target | < 120KB critical
- [ ] SW registered
- [ ] Manifest valid
- [ ] Icons present (192, 512, maskable)

## Related

- `pwa-lighthouse-fixes.md` - Fix Lighthouse issues
- `pwa-testing-patterns.md` - E2E testing

---

<!-- CICD_REFERENCE v24.5.0 | Updated: 2026-02-19 -->

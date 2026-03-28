# Performance Report Template

> **APEX-PERF v24.7.0** | Domain: Performance/Reporting
> Template for comprehensive performance audit reports

---

## Report Template

```markdown
# Performance Audit Report

**Project:** [Project Name]
**URL:** [Production URL]
**Date:** [YYYY-MM-DD]
**Auditor:** [Name / perf-analyzer agent]
**Version:** APEX-PERF v24.7.0

---

## Executive Summary

| Area | Status | Score/Value | Target |
|------|--------|-------------|--------|
| Overall Performance | [PASS/WARN/FAIL] | [Lighthouse score] | >= 90 |
| Core Web Vitals | [PASS/WARN/FAIL] | [pass/fail count] | All Good |
| Bundle Size | [PASS/WARN/FAIL] | [total KB] | < 100KB initial |
| Runtime | [PASS/WARN/FAIL] | [long tasks count] | 0 long tasks |

**Overall Assessment:** [1-2 sentence summary]

---

## 1. Core Web Vitals Scorecard

### Lab Data (Lighthouse)

| Metric | Value | Rating | APEX Target | Status |
|--------|-------|--------|-------------|--------|
| LCP | [value]s | [Good/NI/Poor] | < 1.5s | [PASS/WARN/FAIL] |
| INP | [value]ms | [Good/NI/Poor] | < 150ms | [PASS/WARN/FAIL] |
| CLS | [value] | [Good/NI/Poor] | < 0.05 | [PASS/WARN/FAIL] |
| FCP | [value]s | [Good/NI/Poor] | < 1.2s | [PASS/WARN/FAIL] |
| TTFB | [value]ms | [Good/NI/Poor] | < 400ms | [PASS/WARN/FAIL] |
| TBT | [value]ms | [Good/NI/Poor] | < 150ms | [PASS/WARN/FAIL] |
| SI | [value]s | [Good/NI/Poor] | < 2.0s | [PASS/WARN/FAIL] |

### Field Data (CrUX p75)

| Metric | Value (p75) | Rating | Status |
|--------|-------------|--------|--------|
| LCP | [value]s | [Good/NI/Poor] | [PASS/FAIL] |
| INP | [value]ms | [Good/NI/Poor] | [PASS/FAIL] |
| CLS | [value] | [Good/NI/Poor] | [PASS/FAIL] |

**Field Data Available:** [Yes/No — requires sufficient traffic for CrUX]

---

## 2. Bundle Analysis

### Size Breakdown

| Category | Size (gz) | Budget | Status |
|----------|-----------|--------|--------|
| Initial JS | [value]KB | < 100KB | [PASS/WARN/FAIL] |
| Initial CSS | [value]KB | < 20KB | [PASS/WARN/FAIL] |
| Total Initial | [value]KB | < 350KB | [PASS/WARN/FAIL] |
| Largest route chunk | [value]KB | < 30KB | [PASS/WARN/FAIL] |
| Third-party JS | [value]KB | < 30KB | [PASS/WARN/FAIL] |

### Bundle Composition

| Category | Size (gz) | Percentage | Target |
|----------|-----------|------------|--------|
| Framework | [value]KB | [%] | 35% |
| UI Components | [value]KB | [%] | 20% |
| State Management | [value]KB | [%] | 10% |
| Utilities | [value]KB | [%] | 10% |
| Business Logic | [value]KB | [%] | 15% |
| Third-party | [value]KB | [%] | 10% |

### Heavy Dependencies

| Package | Size (gz) | Tree-shakeable | Recommendation |
|---------|-----------|:-:|----------------|
| [name] | [size]KB | [Yes/No] | [Replace/Lazy-load/Keep] |

### Unused Code

| Type | Total | Used | Unused | % Unused |
|------|-------|------|--------|----------|
| JavaScript | [size]KB | [size]KB | [size]KB | [%] |
| CSS | [size]KB | [size]KB | [size]KB | [%] |

---

## 3. Runtime Analysis

### Long Tasks

| Count | Total Blocking Time | Worst Task | Source |
|-------|--------------------:|:----------:|--------|
| [n] | [value]ms | [value]ms | [source file/function] |

### DOM Size

| Metric | Value | Threshold | Status |
|--------|------:|:---------:|--------|
| Total elements | [n] | < 1000 | [PASS/WARN/FAIL] |
| Max depth | [n] | < 32 | [PASS/WARN/FAIL] |
| Max children | [n] | < 60 | [PASS/WARN/FAIL] |

### Memory

| Metric | Value | Status |
|--------|------:|--------|
| JS Heap Used | [n]MB | [OK/WARN] |
| Detached DOM nodes | [n] | [OK/WARN] |
| Memory trend | [stable/growing] | [OK/WARN] |

### Anti-Patterns Detected

| ID | Pattern | Elements | Severity |
|----|---------|----------|----------|
| [CP-XX] | [description] | [count] | [HIGH/MEDIUM/LOW] |

---

## 4. Resource Optimization

### Images

| Check | Status | Details |
|-------|--------|---------|
| Modern formats (AVIF/WebP) | [PASS/FAIL] | [% served in modern format] |
| Responsive sizes | [PASS/FAIL] | [count without sizes attribute] |
| Lazy loading | [PASS/FAIL] | [count without lazy loading below fold] |
| Hero image preloaded | [PASS/FAIL] | [priority attribute present] |
| Alt text | [PASS/FAIL] | [count missing alt] |

### Fonts

| Check | Status | Details |
|-------|--------|---------|
| font-display: swap | [PASS/FAIL] | [fonts without swap] |
| WOFF2 format | [PASS/FAIL] | [fonts not in WOFF2] |
| Preloaded critical fonts | [PASS/FAIL] | [preload links] |
| Font count | [PASS/WARN] | [n] families (target: <= 3) |

### Compression

| Check | Status | Details |
|-------|--------|---------|
| Brotli enabled | [PASS/FAIL] | [Content-Encoding header] |
| Cache headers | [PASS/FAIL] | [immutable on static] |
| Text compression | [PASS/FAIL] | [uncompressed text resources] |

---

## 5. Third-Party Scripts

| Script | Size (gz) | Loading Strategy | Main Thread | Recommendation |
|--------|-----------|-----------------|:-----------:|----------------|
| [name] | [size]KB | [strategy] | [ms] | [Keep/Optimize/Remove] |

**Total Third-Party:** [size]KB | **Budget:** < 30KB | **Status:** [PASS/WARN/FAIL]

---

## 6. Lighthouse Audit Summary

### Scores

| Category | Score | Target | Status |
|----------|:-----:|:------:|--------|
| Performance | [0-100] | >= 90 | [PASS/WARN/FAIL] |
| Accessibility | [0-100] | >= 90 | [PASS/WARN/FAIL] |
| Best Practices | [0-100] | >= 90 | [PASS/WARN/FAIL] |
| SEO | [0-100] | >= 90 | [PASS/WARN/FAIL] |

### Top Opportunities

| Opportunity | Estimated Savings | Priority |
|-------------|:--:|:---:|
| [description] | [time/size saved] | [HIGH/MEDIUM/LOW] |

### Diagnostics

| Diagnostic | Current | Target | Priority |
|------------|---------|--------|:---:|
| [description] | [value] | [target] | [HIGH/MEDIUM/LOW] |

---

## 7. Verification Gates

### Gate Results (30 gates)

| Cluster | Passed | Failed | Blocked |
|---------|:------:|:------:|:-------:|
| CWV (8 gates) | [n]/8 | [n]/8 | [Yes/No] |
| Bundle (6 gates) | [n]/6 | [n]/6 | [Yes/No] |
| Lighthouse (6 gates) | [n]/6 | [n]/6 | [Yes/No] |
| Runtime (6 gates) | [n]/6 | [n]/6 | [Yes/No] |
| Modern (4 gates) | [n]/4 | [n]/4 | [Yes/No] |

**Overall:** [n]/30 gates passed | **Deploy Status:** [CLEAR/BLOCKED]

---

## 8. Recommendations

### Priority 1 (BLOCKING -- Fix Before Deploy)

| # | Issue | Impact | Effort | Fix |
|---|-------|:------:|:------:|-----|
| 1 | [issue] | [High/Critical] | [Low/Med/High] | [specific fix] |

### Priority 2 (HIGH -- Fix This Sprint)

| # | Issue | Impact | Effort | Fix |
|---|-------|:------:|:------:|-----|
| 1 | [issue] | [Medium/High] | [Low/Med/High] | [specific fix] |

### Priority 3 (MEDIUM -- Fix Next Sprint)

| # | Issue | Impact | Effort | Fix |
|---|-------|:------:|:------:|-----|
| 1 | [issue] | [Low/Medium] | [Low/Med/High] | [specific fix] |

---

## 9. Before/After Comparison

*Include this section when re-auditing after optimizations.*

| Metric | Before | After | Change | Target Met? |
|--------|:------:|:-----:|:------:|:-----------:|
| LCP | [v]s | [v]s | [+/-n%] | [Yes/No] |
| INP | [v]ms | [v]ms | [+/-n%] | [Yes/No] |
| CLS | [v] | [v] | [+/-n%] | [Yes/No] |
| TBT | [v]ms | [v]ms | [+/-n%] | [Yes/No] |
| Bundle (gz) | [v]KB | [v]KB | [+/-n%] | [Yes/No] |
| Lighthouse | [v] | [v] | [+/-n] | [Yes/No] |

---

## 10. Monitoring Setup

| Check | Status | Details |
|-------|--------|---------|
| RUM (web-vitals) | [Active/Missing] | [endpoint] |
| Vercel Speed Insights | [Active/Missing] | |
| Lighthouse CI | [Active/Missing] | [workflow URL] |
| Bundle size CI check | [Active/Missing] | [workflow URL] |
| Performance alerts | [Active/Missing] | [alert config] |
| CrUX review schedule | [Set/Missing] | [frequency] |

---

## Appendix

### Environment

| Setting | Value |
|---------|-------|
| Node.js | [version] |
| Next.js | [version] |
| React | [version] |
| Lighthouse | [version] |
| Device emulation | [Desktop/Mobile] |
| Network throttling | [profile] |

### URLs Audited

| URL | Page Type |
|-----|-----------|
| [url] | [homepage/dashboard/product/etc] |

---

*Report generated by APEX-PERF v24.7.0 | perf-analyzer agent (Opus 4.6)*
```

---

## Usage

### Generating the Report

1. Run `/perf-audit` to collect all data
2. The report populates automatically from audit results
3. Review and add manual observations
4. Share with stakeholders

### Report Cadence

| Report Type | Frequency | Audience |
|------------|-----------|----------|
| Full audit | Monthly | Engineering + Product |
| Quick check | Weekly | Engineering |
| CI report | Every PR | Engineering |
| Executive summary | Quarterly | Leadership |

---

<!-- PERF_REPORT_TEMPLATE v24.7.0 | Comprehensive audit report template -->

# testing-rules — Real-World Examples

The skill enforces the APEX testing stack: Vitest 4 for unit/integration,
Playwright for E2E, MSW for network mocking, and Zod for validating test data.
The before/after gap shows the difference between tests that give false
confidence and tests that actually catch bugs.

## Before / After

### Example 1: Testing implementation details instead of behavior

**Before** (triggers the skill):
```typescript
// ❌ Tests implementation: spies on internal state, checks DOM structure
// ❌ No MSW — real fetch calls (flaky, slow, environment-dependent)
import { render, screen } from '@testing-library/react';
import { vi } from 'vitest';
import { UserProfile } from './UserProfile';

test('fetches user and renders', async () => {
  const fetchSpy = vi.spyOn(global, 'fetch');

  render(<UserProfile userId="123" />);

  // Testing that fetch was called — not what the user sees
  expect(fetchSpy).toHaveBeenCalledWith('/api/users/123');

  // Brittle: breaks on any className or element type change
  const container = document.querySelector('.user-profile-container');
  expect(container?.children[0]?.tagName).toBe('H2');
});
```

**After** (skill-compliant):
```typescript
// ✅ Behavior-focused: tests what the user sees
// ✅ MSW intercepts the network layer — no real HTTP, no flakiness
import { render, screen } from '@testing-library/react';
import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';
import { waitFor } from '@testing-library/react';
import { UserProfile } from './UserProfile';

const server = setupServer(
  http.get('/api/users/123', () =>
    HttpResponse.json({ id: '123', name: 'Dana Cohen', role: 'admin' })
  )
);

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

test('shows user name and role after loading', async () => {
  render(<UserProfile userId="123" />);

  // Loading state is visible while the request is in flight
  expect(screen.getByText(/loading/i)).toBeInTheDocument();

  // User-visible content appears after the request resolves
  await waitFor(() => {
    expect(screen.getByRole('heading', { name: 'Dana Cohen' })).toBeInTheDocument();
    expect(screen.getByText('admin')).toBeInTheDocument();
  });
});

test('shows error state when API fails', async () => {
  server.use(
    http.get('/api/users/123', () => HttpResponse.json(null, { status: 500 }))
  );
  render(<UserProfile userId="123" />);

  await waitFor(() => {
    expect(screen.getByRole('alert')).toHaveTextContent(/failed to load/i);
  });
});
```

**Why:** Spying on `fetch` tests that code runs, not that it works correctly.
Checking `.children[0].tagName` couples the test to DOM structure — any
refactor breaks the tests even if behavior is unchanged. MSW intercepts requests
at the network level, making tests deterministic and fast without touching
implementation details.

---

### Example 2: Missing edge cases and incomplete coverage

**Before** (triggers the skill):
```typescript
// ❌ Only tests the happy path
// ❌ No test for the guard that prevents double-submit
// ❌ Coverage report will show green but critical paths are untested
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ContactForm } from './ContactForm';

describe('ContactForm', () => {
  it('submits the form', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();
    render(<ContactForm onSubmit={onSubmit} />);

    await user.type(screen.getByLabelText('Email'), 'test@example.com');
    await user.type(screen.getByLabelText('Message'), 'Hello');
    await user.click(screen.getByRole('button', { name: 'Send' }));

    expect(onSubmit).toHaveBeenCalledOnce();
  });
});
```

**After** (skill-compliant):
```typescript
// ✅ Happy path + validation errors + double-submit guard + network failure
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';
import { ContactForm } from './ContactForm';

const server = setupServer(
  http.post('/api/contact', () => HttpResponse.json({ ok: true }))
);
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe('ContactForm', () => {
  it('submits valid data and shows confirmation', async () => {
    const user = userEvent.setup();
    render(<ContactForm />);

    await user.type(screen.getByLabelText('Email'), 'dana@example.com');
    await user.type(screen.getByLabelText('Message'), 'Hello there');
    await user.click(screen.getByRole('button', { name: 'Send' }));

    await waitFor(() =>
      expect(screen.getByText(/message sent/i)).toBeInTheDocument()
    );
  });

  it('shows field-level validation errors on empty submit', async () => {
    const user = userEvent.setup();
    render(<ContactForm />);

    await user.click(screen.getByRole('button', { name: 'Send' }));

    expect(screen.getByText(/email is required/i)).toBeInTheDocument();
    expect(screen.getByText(/message is required/i)).toBeInTheDocument();
  });

  it('disables the submit button while request is in flight (prevents double-submit)', async () => {
    let resolveRequest!: () => void;
    server.use(
      http.post('/api/contact', () =>
        new Promise<Response>(resolve => {
          resolveRequest = () => resolve(HttpResponse.json({ ok: true }));
        })
      )
    );

    const user = userEvent.setup();
    render(<ContactForm />);
    await user.type(screen.getByLabelText('Email'), 'dana@example.com');
    await user.type(screen.getByLabelText('Message'), 'Hello');
    await user.click(screen.getByRole('button', { name: 'Send' }));

    expect(screen.getByRole('button', { name: /sending/i })).toBeDisabled();
    resolveRequest();
  });

  it('shows error message when the API fails', async () => {
    server.use(http.post('/api/contact', () => HttpResponse.json(null, { status: 500 })));
    const user = userEvent.setup();
    render(<ContactForm />);
    await user.type(screen.getByLabelText('Email'), 'dana@example.com');
    await user.type(screen.getByLabelText('Message'), 'Hello');
    await user.click(screen.getByRole('button', { name: 'Send' }));

    await waitFor(() =>
      expect(screen.getByRole('alert')).toHaveTextContent(/something went wrong/i)
    );
  });
});
```

**Why:** One happy-path test gives false confidence. Validation errors, in-flight
state, and server failures are the scenarios most likely to surface bugs reported
by users. The double-submit test explicitly prevents a real race condition
(sending the form twice on slow connections) that a single happy-path test
would never catch.

---

### Example 3: Vitest config missing coverage thresholds and worker limits

**Before** (triggers the skill):
```typescript
// ❌ vitest.config.ts — no coverage thresholds, no worker limit, wrong provider
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    // No coverage configuration — runs with defaults, no enforcement
    // No maxWorkers — can spawn N workers and OOM on CI
  },
});
```

**After** (skill-compliant):
```typescript
// ✅ Coverage thresholds enforced, worker limit set, Istanbul provider
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
    maxWorkers: 4,          // prevents OOM on CI machines
    reporters: ['verbose'],
    coverage: {
      provider: 'istanbul', // Istanbul (not V8) for accurate React/JSX coverage
      reporter: ['text', 'lcov', 'html'],
      exclude: [
        'node_modules/**',
        'src/test/**',
        '**/*.d.ts',
        '**/*.config.*',
        '**/index.ts',      // re-export barrels add noise to coverage
      ],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 75,
        statements: 80,
      },
    },
  },
});
```

**Why:** Without coverage thresholds, the CI passes even at 10% coverage —
nothing enforces a floor. Without `maxWorkers: 4`, Vitest can spawn 32 workers
on a 32-core CI machine, exhausting memory and causing flaky OOM failures.
Istanbul is required for correct branch coverage in JSX/TSX files; V8 coverage
mis-reports conditional renders as covered when only one branch was taken.

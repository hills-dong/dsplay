import { describe, it, expect } from "vitest";
import { render } from "@solidjs/testing-library";
import { Router, Route } from "@solidjs/router";
import AppShell from "./AppShell";

describe("AppShell wordmark", () => {
  it("renders DSPLAY with an accent-colored period", () => {
    const { container } = render(() => (
      <Router>
        <Route path="*" component={() => <AppShell />} />
      </Router>
    ));
    const wordmark = container.querySelector("header span.serif");
    expect(wordmark?.textContent).toBe("DSPLAY.");
    const period = wordmark?.querySelector("span");
    expect(period?.textContent).toBe(".");
    expect(period?.getAttribute("style") ?? "").toMatch(/color\s*:\s*var\(--accent\)/);
  });
});

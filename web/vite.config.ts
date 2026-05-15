import { defineConfig, type Plugin } from "vitest/config";
import solid from "vite-plugin-solid";
import { viteSingleFile } from "vite-plugin-singlefile";
import { resolve } from "node:path";

/**
 * Inline JS+CSS into the HTML so the bundle is a self-contained classic script,
 * then strip `type="module"` and `crossorigin` so WKWebView (even via our custom
 * dsplay:// scheme) runs it as a regular script. Vite's IIFE-style bundle works
 * fine as a classic script once imports/exports are resolved by singlefile.
 */
function wkWebViewScriptCompat(): Plugin {
  return {
    name: "dsplay-wkwebview-script-compat",
    enforce: "post",
    transformIndexHtml(html) {
      // Strip module-only attributes (custom dsplay:// scheme + classic script
      // is more compatible with WKWebView than ES modules).
      let out = html
        .replace(/\s+crossorigin(="[^"]*")?/g, "")
        .replace(/\stype="module"/g, "");
      // Inline classic scripts run BEFORE the body parses, so #root isn't
      // available yet. Move every inlined script tag (one or more) from <head>
      // to just before </body>.
      const scriptRegex = /<script\b[^>]*>[\s\S]*?<\/script>/g;
      const scripts = out.match(scriptRegex) ?? [];
      console.log(`[dsplay-wk-compat] moving ${scripts.length} script tag(s) to end of body`);
      out = out.replace(scriptRegex, "");
      if (scripts.length) {
        out = out.replace("</body>", `${scripts.join("\n")}\n</body>`);
      }
      return out;
    },
  };
}

export default defineConfig({
  plugins: [solid(), viteSingleFile(), wkWebViewScriptCompat()],
  root: __dirname,
  base: "./",
  resolve: { alias: { "@shared": resolve(__dirname, "../shared") } },
  build: {
    outDir: resolve(__dirname, "../DSPlay/Resources/WebDist"),
    emptyOutDir: true,
    target: "safari17",
    modulePreload: false,
    rollupOptions: { input: resolve(__dirname, "index.html") },
  },
  server: { port: 1420, strictPort: true },
  test: { environment: "jsdom", globals: true, setupFiles: ["./src/test-setup.ts"] },
});

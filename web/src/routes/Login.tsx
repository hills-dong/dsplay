import { createSignal } from "solid-js";
import { useNavigate } from "@solidjs/router";
import { bridge } from "../bridge";
import { setAuthed } from "../stores/auth";

export default function LoginView() {
  const navigate = useNavigate();
  const [url, setUrl] = createSignal("");
  const [user, setUser] = createSignal("");
  const [password, setPassword] = createSignal("");
  const [busy, setBusy] = createSignal(false);
  const [error, setError] = createSignal<string | null>(null);

  const submit = async (e: Event) => {
    e.preventDefault();
    setBusy(true); setError(null);
    try {
      await bridge.call("auth.login", { url: url(), user: user(), password: password() });
      setAuthed(url(), user());
      navigate("/search", { replace: true });
    } catch (err: any) {
      setError(err?.message ?? String(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <main class="container" style="padding-top: 96px; max-width: 480px;">
      <div class="label" style="margin-bottom: 8px;">Connect</div>
      <h1 style="font-family: var(--font-serif); font-size: 36px; font-weight: 500; margin: 0 0 32px; font-style: italic;">
        Sign in to your library.
      </h1>

      <form onsubmit={submit}>
        <Field label="NAS URL" value={url()} onInput={setUrl} type="url" />
        <Field label="Username" value={user()} onInput={setUser} />
        <Field label="Password" value={password()} onInput={setPassword} type="password" />

        {error() && (
          <div style="color: var(--accent); font-family: var(--font-sans); font-size: 13px; margin: 16px 0;">
            {error()}
          </div>
        )}

        <button
          type="submit"
          disabled={busy()}
          style={`margin-top:24px; padding:12px 24px; border:1px solid var(--ink); background:var(--ink); color:#fafaf7; font-family:var(--font-sans); font-size:12px; letter-spacing:0.15em; text-transform:uppercase; cursor:${busy()?"wait":"pointer"}; opacity:${busy()?0.5:1};`}
        >
          {busy() ? "Connecting…" : "Connect"}
        </button>
      </form>
    </main>
  );
}

function Field(props: { label: string; value: string; onInput: (v: string) => void; type?: string }) {
  return (
    <label style="display:block; margin-bottom:16px;">
      <div class="label" style="margin-bottom:6px;">{props.label}</div>
      <input
        type={props.type ?? "text"}
        value={props.value}
        onInput={(e) => props.onInput(e.currentTarget.value)}
        style="width:100%; border-bottom:1px solid var(--ink); padding:6px 0; font-family:var(--font-serif); font-size:18px;"
      />
    </label>
  );
}

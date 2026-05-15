// web/src/bridge.ts — typed RPC client over WKScriptMessageHandler.

import type {
  IPCRequest,
  IPCResponse,
  IPCEvent,
  BridgeError,
} from "../../shared/ipc-schema";

declare global {
  interface Window {
    __dsplay?: { send: (envelope: unknown) => void };
    __dsplay_handler?: (envelope: unknown) => void;
  }
}

type RequestType = IPCRequest["type"];

// Helper: extract the payload type for a given request `type`.
type RequestPayload<K extends RequestType> = Extract<IPCRequest, { type: K }>["payload"];
// Helper: extract the matching response payload.
type ResponsePayload<K extends RequestType> = Extract<IPCResponse, { type: K }>["payload"];

interface Pending {
  resolve: (value: any) => void;
  reject: (err: BridgeError) => void;
  timer: ReturnType<typeof setTimeout>;
}

const pending = new Map<string, Pending>();
const eventListeners: Array<(e: IPCEvent) => void> = [];

let nextId = 0;
function newRequestId(): string {
  nextId += 1;
  return `r${Date.now().toString(36)}-${nextId}`;
}

function installHandler() {
  window.__dsplay_handler = (raw: unknown) => {
    const env = raw as
      | { kind: "response"; requestId: string; ok: true; message: IPCResponse }
      | { kind: "response"; requestId: string; ok: false; error: BridgeError }
      | { kind: "event"; message: IPCEvent };

    if (env.kind === "event") {
      for (const l of eventListeners) l(env.message);
      return;
    }
    const p = pending.get(env.requestId);
    if (!p) return;
    pending.delete(env.requestId);
    clearTimeout(p.timer);
    if (env.ok) p.resolve(env.message.payload);
    else p.reject(env.error);
  };
}
installHandler();

function isAvailable(): boolean {
  return typeof window.__dsplay?.send === "function";
}

export const bridge = {
  available: isAvailable,

  call<K extends RequestType>(
    type: K,
    payload: RequestPayload<K>,
    options: { timeoutMs?: number } = {}
  ): Promise<ResponsePayload<K>> {
    if (!isAvailable()) {
      return Promise.reject<BridgeError>({
        kind: "Unknown",
        message: "Bridge not available — are you running inside the WKWebView host?",
      }) as Promise<never>;
    }
    const requestId = newRequestId();
    const envelope = {
      kind: "request" as const,
      requestId,
      message: { type, payload } as IPCRequest,
    };

    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        pending.delete(requestId);
        reject({ kind: "Unknown", message: `Bridge call '${type}' timed out` } as BridgeError);
      }, options.timeoutMs ?? 15_000);
      pending.set(requestId, { resolve, reject, timer });
      window.__dsplay!.send(envelope);
    });
  },

  onEvent(listener: (event: IPCEvent) => void): () => void {
    eventListeners.push(listener);
    return () => {
      const i = eventListeners.indexOf(listener);
      if (i >= 0) eventListeners.splice(i, 1);
    };
  },
};

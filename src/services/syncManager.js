import { localDb } from "./localDb";
import { queueChange } from "./syncQueue";

const BASE = import.meta.env.VITE_API_URL || (typeof window !== "undefined" && window.location.port === "5173" ? "/waia-api" : "/backend/api");
const DEVICE_KEY = "waia_device_id";

function deviceId() {
  let id = localStorage.getItem(DEVICE_KEY);
  if (!id) {
    id = crypto.randomUUID?.() || `device-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    localStorage.setItem(DEVICE_KEY, id);
  }
  return id;
}

function scope() {
  try {
    const user = JSON.parse(localStorage.getItem("waia_user") || "null");
    if (user?.id != null) return `user:${user.id}`;
  } catch {}
  return `device:${deviceId()}`;
}

async function request(path, options = {}) {
  const response = await fetch(`${BASE}${path}`, {
    ...options,
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
      "X-WAIA-Device": deviceId(),
      ...(options.method && options.method !== "GET" ? { "X-CSRF-Token": localStorage.getItem("waia_csrf_token") || "" } : {}),
      ...(options.headers || {}),
    },
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(body.error || `HTTP ${response.status}`);
  return body;
}

export async function enqueueChange(entity, recordId, action, data, version = 0) {
  return queueChange({ scope: scope(), entity, recordId, action, data, version });
}

export async function syncNow() {
  if (!navigator.onLine) return { offline: true };
  const pending = await localDb.getPending();
  const sinceVersion = Number(await localDb.getMeta("serverVersion", 0));

  const result = await request("/sync", {
    method: "POST",
    body: JSON.stringify({
      scope: scope(),
      sinceVersion,
      changes: pending.map((item) => ({
        id: item.id,
        entity: item.entity,
        recordId: item.recordId,
        action: item.action,
        version: item.version,
        data: item.data,
      })),
    }),
  });

  for (const accepted of result.accepted || []) {
    const item = pending.find((x) => x.entity === accepted.entity && String(x.recordId) === String(accepted.id));
    if (item) await localDb.removeQueue(item.id);
  }

  const pull = result.pull || { changes: [], nextVersion: sinceVersion };
  for (const change of pull.changes || []) {
    const key = `${scope()}:${change.entity}:${change.recordId}`;
    if (change.action === "delete") await localDb.deleteRecord(key);
    else await localDb.putRecord({ key, scope: scope(), entity: change.entity, id: change.recordId, version: change.version, data: change.data, updatedAt: change.updatedAt });
  }
  await localDb.setMeta("serverVersion", pull.nextVersion ?? sinceVersion);
  return result;
}

export function startSyncManager() {
  const run = () => syncNow().catch((error) => console.warn("WAIA sync:", error.message));
  window.addEventListener("online", run);
  const timer = window.setInterval(run, 30000);
  run();
  return () => {
    window.removeEventListener("online", run);
    window.clearInterval(timer);
  };
}

export const syncManager = { syncNow, startSyncManager, enqueueChange };

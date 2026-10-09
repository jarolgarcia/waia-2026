import { localDb } from "./localDb";

const id = () => crypto.randomUUID?.() || `${Date.now()}-${Math.random().toString(36).slice(2)}`;

export async function queueChange({ scope, entity, recordId, action = "upsert", version = 0, data }) {
  const item = {
    id: id(),
    scope,
    entity,
    recordId: String(recordId),
    action,
    version,
    data,
    status: "pending",
    attempts: 0,
    createdAt: new Date().toISOString(),
  };
  await localDb.enqueue(item);
  return item;
}

export const syncQueue = { queueChange };

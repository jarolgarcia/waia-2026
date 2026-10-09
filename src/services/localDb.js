const DB_NAME = "waia-local-v1";
const DB_VERSION = 1;
const STORES = ["records", "queue", "meta"];

function openDb() {
  return new Promise((resolve, reject) => {
    if (!("indexedDB" in window)) return reject(new Error("IndexedDB no está disponible."));
    const request = indexedDB.open(DB_NAME, DB_VERSION);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains("records")) {
        const store = db.createObjectStore("records", { keyPath: "key" });
        store.createIndex("entity", "entity", { unique: false });
        store.createIndex("scope", "scope", { unique: false });
      }
      if (!db.objectStoreNames.contains("queue")) {
        const store = db.createObjectStore("queue", { keyPath: "id" });
        store.createIndex("status", "status", { unique: false });
        store.createIndex("createdAt", "createdAt", { unique: false });
      }
      if (!db.objectStoreNames.contains("meta")) db.createObjectStore("meta", { keyPath: "key" });
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

const fallback = new Map();

async function tx(storeName, mode, callback) {
  try {
    const db = await openDb();
    return await new Promise((resolve, reject) => {
      const transaction = db.transaction(storeName, mode);
      const store = transaction.objectStore(storeName);
      let value;
      try { value = callback(store); } catch (e) { reject(e); return; }
      transaction.oncomplete = () => resolve(value);
      transaction.onerror = () => reject(transaction.error);
    });
  } catch {
    return callback({
      get: (key) => ({ onsuccess: null, result: fallback.get(key) }),
      put: (value) => { fallback.set(value.key || value.id, value); },
      delete: (key) => fallback.delete(key),
      clear: () => fallback.clear(),
      getAll: () => ({ onsuccess: null, result: [...fallback.values()] }),
    });
  }
}

export const localDb = {
  async putRecord(record) {
    return tx("records", "readwrite", (store) => store.put(record));
  },
  async getRecord(key) {
    const db = await openDb().catch(() => null);
    if (!db) return fallback.get(key) ?? null;
    return new Promise((resolve, reject) => {
      const req = db.transaction("records", "readonly").objectStore("records").get(key);
      req.onsuccess = () => resolve(req.result ?? null);
      req.onerror = () => reject(req.error);
    });
  },
  async getRecords(entity, scope) {
    const db = await openDb().catch(() => null);
    if (!db) return [...fallback.values()].filter((x) => x.entity === entity && (!scope || x.scope === scope));
    return new Promise((resolve, reject) => {
      const req = db.transaction("records", "readonly").objectStore("records").getAll();
      req.onsuccess = () => resolve(req.result.filter((x) => x.entity === entity && (!scope || x.scope === scope)));
      req.onerror = () => reject(req.error);
    });
  },
  async deleteRecord(key) {
    return tx("records", "readwrite", (store) => store.delete(key));
  },
  async enqueue(item) {
    return tx("queue", "readwrite", (store) => store.put(item));
  },
  async getPending() {
    const db = await openDb().catch(() => null);
    if (!db) return [...fallback.values()].filter((x) => x.status === "pending");
    return new Promise((resolve, reject) => {
      const req = db.transaction("queue", "readonly").objectStore("queue").getAll();
      req.onsuccess = () => resolve(req.result.filter((x) => x.status === "pending"));
      req.onerror = () => reject(req.error);
    });
  },
  async removeQueue(id) {
    return tx("queue", "readwrite", (store) => store.delete(id));
  },
  async setMeta(key, value) {
    return tx("meta", "readwrite", (store) => store.put({ key, value }));
  },
  async getMeta(key, fallbackValue = null) {
    const db = await openDb().catch(() => null);
    if (!db) return fallbackValue;
    return new Promise((resolve, reject) => {
      const req = db.transaction("meta", "readonly").objectStore("meta").get(key);
      req.onsuccess = () => resolve(req.result?.value ?? fallbackValue);
      req.onerror = () => reject(req.error);
    });
  },
};

import experiencesData from "../data/experiencesData";
import placesData from "../data/placesData";
import { departmentsData, municipalitiesData } from "../data/nicaraguaTerritory";
import { tourismCategories } from "../data/tourismCategories";
import { localDb } from "./localDb";
import { enqueueChange } from "./syncManager";

export const API_BASE_URL = import.meta.env.VITE_API_URL || (typeof window !== "undefined" && window.location.port === "5173" ? "/waia-api" : "/backend/api");
export const USE_API = import.meta.env.VITE_USE_API !== "false";

const KEYS = {
  users: "waia_users", user: "waia_user", bookings: "waia_bookings", favorites: "waia_favorites",
  itinerary: "waia_itinerary", hosts: "waia_hosts", reviews: "waia_reviews", contacts: "waia_contacts",
};

const sleep = (ms = 30) => new Promise((resolve) => setTimeout(resolve, ms));
function read(key, fallback) { try { return JSON.parse(localStorage.getItem(key) || "null") ?? fallback; } catch { return fallback; } }
function write(key, value) { localStorage.setItem(key, JSON.stringify(value)); return value; }
function clearAuthStorage() { [KEYS.user, "waia_host_session", "waia_csrf_token"].forEach((key) => localStorage.removeItem(key)); document.cookie.split(";").forEach((cookie) => { const name = cookie.split("=")[0].trim(); if (name) document.cookie = `${name}=; Max-Age=0; path=/`; }); }
async function apiRequest(path, options = {}) { const isFormData = typeof FormData !== "undefined" && options.body instanceof FormData; const response = await fetch(`${API_BASE_URL}${path}`, { credentials: "include", ...options, headers: { ...(isFormData ? {} : { "Content-Type": "application/json" }), ...(options.method && options.method !== "GET" ? { "X-CSRF-Token": localStorage.getItem("waia_csrf_token") || "" } : {}), ...(options.headers || {}) } }); const body = await response.json().catch(() => ({})); if (!response.ok) { const error = new Error(body.message || body.error || `HTTP ${response.status}`); error.status = response.status; error.retryAfter = Number(response.headers.get("Retry-After") || 0); throw error; } if (body.csrfToken) localStorage.setItem("waia_csrf_token", body.csrfToken); return body; }
function uid() { return crypto.randomUUID?.() || `${Date.now()}-${Math.random().toString(36).slice(2)}`; }
function textMatches(item, query) { if (!query) return true; return [item.name,item.title,item.category,item.categoryLabel,item.department,item.municipality,item.location,item.host,item.description,item.shortDescription,...(item.tags||[])].filter(Boolean).join(" ").toLowerCase().includes(query.toLowerCase()); }

function ensureSeed() {
  if (!localStorage.getItem(KEYS.users)) write(KEYS.users, [{ id: uid(), name: "Turista Demo", email: "turista@waia.local", password: "WaiaDemo2026!", role: "turista", createdAt: new Date().toISOString() }]);
  if (!localStorage.getItem(KEYS.hosts)) write(KEYS.hosts, [{ id: uid(), userId: 1, name: "Anfitrión WAIA Demo", email: "anfitrion@waia.local", password: "WaiaHost2026!", description: "Perfil local de demostración.", services: ["Experiencias", "Tours"], experiences: experiencesData.filter((x) => x.department === "León").slice(0, 4).map((x) => x.id) }]);
  if (!localStorage.getItem(KEYS.bookings)) write(KEYS.bookings, []);
  if (!localStorage.getItem(KEYS.favorites)) write(KEYS.favorites, []);
  if (!localStorage.getItem(KEYS.itinerary)) write(KEYS.itinerary, { id: uid(), name: "Mi viaje a Nicaragua", items: [] });
  if (!localStorage.getItem(KEYS.reviews)) write(KEYS.reviews, []);
  if (!localStorage.getItem(KEYS.contacts)) write(KEYS.contacts, []);
}
ensureSeed();

async function persist(key, entity, data, action = "upsert") {
  write(key, data);
  const recordId = Array.isArray(data) ? uid() : (data.id || uid());
  await enqueueChange(entity, recordId, action, data);
  return data;
}

export const api = {
  async getExperiences(filters = {}) {
    if (USE_API) {
      const params = new URLSearchParams();
      if (filters.query) params.set("q", filters.query);
      if (filters.category && filters.category !== "Todas") params.set("category", filters.category);
      if (filters.department) params.set("department", filters.department);
      if (filters.limit) params.set("limit", filters.limit);
      if (filters.page) params.set("page", filters.page);
      const result = await apiRequest(`/experiences${params.toString() ? `?${params}` : ""}`);
      return { data: result.data || [], total: result.total || 0 };
    }
    await sleep(); let data = [...experiencesData];
    if (filters.category && filters.category !== "Todas") data = data.filter((x) => x.category === filters.category);
    if (filters.department) data = data.filter((x) => x.department === filters.department);
    if (filters.municipality) data = data.filter((x) => x.municipality === filters.municipality);
    if (filters.query) data = data.filter((x) => textMatches(x, filters.query));
    if (filters.sort === "price-asc") data.sort((a,b) => a.price-b.price);
    if (filters.sort === "price-desc") data.sort((a,b) => b.price-a.price);
    return { data: filters.limit ? data.slice(0, filters.limit) : data, total: data.length };
  },
  async getExperience(id) {
    if (USE_API) {
      try { const result = await apiRequest(`/experiences/${encodeURIComponent(id)}`); return result.data || null; } catch { return null; }
    }
    await sleep(); return experiencesData.find((x) => String(x.id) === String(id)) || null;
  },
  async getPlaces(filters = {}) {
    await sleep(); let data = [...placesData];
    if (filters.category && filters.category !== "todas") data = data.filter((x) => x.category === filters.category || x.categoryLabel?.toLowerCase() === filters.category.toLowerCase());
    if (filters.department) data = data.filter((x) => x.department === filters.department);
    if (filters.municipality) data = data.filter((x) => x.municipality === filters.municipality);
    if (filters.query) data = data.filter((x) => textMatches(x, filters.query));
    if (filters.sort === "rating") data.sort((a,b) => (b.rating||0)-(a.rating||0));
    return { data, total: data.length };
  },
  async getPlace(id) { await sleep(); return placesData.find((x) => String(x.id) === String(id)) || null; },
  async getCategories() { await sleep(); return tourismCategories; },
  async getDepartments() { await sleep(); return departmentsData; },
  async getMunicipalities(department) { await sleep(); return department ? municipalitiesData.filter((x) => x.department === department) : municipalitiesData; },

  async createBooking(payload) {
    const now = new Date();
    const booking = { ...payload, id: uid(), bookingCode: `WAIA-${now.toISOString().slice(0,10).replaceAll("-","")}-${Math.random().toString(36).slice(2,8).toUpperCase()}`, status: "confirmed", version: 1, createdAt: now.toISOString(), updatedAt: now.toISOString() };
    const list = [...read(KEYS.bookings, []), booking]; write(KEYS.bookings, list);
    await enqueueChange("booking", booking.id, "create", booking, booking.version);
    return booking;
  },
  async getBookings() { await sleep(); return read(KEYS.bookings, []); },
  async cancelBooking(id) { const list = read(KEYS.bookings, []).map((x) => x.id === id ? { ...x, status: "cancelled", version: (x.version||1)+1, updatedAt: new Date().toISOString() } : x); write(KEYS.bookings, list); const item=list.find((x)=>x.id===id); if(item) await enqueueChange("booking", id, "update", item, item.version); return list; },
  async getFavorites() { await sleep(); return read(KEYS.favorites, []); },
  async addFavorite(userId, itemId, type="experience") { const key=`${type}:${itemId}`; const list=read(KEYS.favorites, []); const next=list.includes(key)?list:[...list,key]; write(KEYS.favorites,next); await enqueueChange("favorite", key, "upsert", { id:key, userId, itemId, type }); return next; },
  async removeFavorite(userId, itemId, type="experience") { const key=`${type}:${itemId}`; const next=read(KEYS.favorites,[]).filter((x)=>x!==key&&x!==itemId); write(KEYS.favorites,next); await enqueueChange("favorite",key,"delete",{id:key,userId,itemId,type}); return next; },
  async sendContact(form) { const item={...form,id:uid(),createdAt:new Date().toISOString()}; write(KEYS.contacts,[...read(KEYS.contacts,[]),item]); await enqueueChange("contact",item.id,"create",item); return {ok:true}; },
  async register(data) { if (USE_API) throw new Error("El registro debe implementarse en el backend para mantener la seguridad."); const users=read(KEYS.users,[]); if(users.some((u)=>u.email.toLowerCase()===data.email.toLowerCase())) throw new Error("Ese correo ya está registrado en modo local."); const user={id:uid(),...data,createdAt:new Date().toISOString()}; write(KEYS.users,[...users,user]); write(KEYS.user,{id:user.id,name:user.name,email:user.email,role:user.role}); await enqueueChange("user",user.id,"create",{...user,password:undefined}); return user; },
  async login(email,password) { if (USE_API) { const result = await apiRequest("/auth/login", { method: "POST", body: JSON.stringify({ email, password }) }); write(KEYS.user, result.user); return result.user; } const user=read(KEYS.users,[]).find((x)=>x.email.toLowerCase()===email.toLowerCase()&&x.password===password); if(!user) throw new Error("Correo o contraseña incorrectos en el modo local."); const session={id:user.id,name:user.name,email:user.email,role:user.role}; write(KEYS.user,session); return session; },
  async currentUser() { if (USE_API) { try { const result = await apiRequest("/auth/me"); write(KEYS.user, result.user); return result.user; } catch { clearAuthStorage(); return null; } } await sleep(); return read(KEYS.user,null); },
  async logout() { if (USE_API) { try { await apiRequest("/auth/logout", { method: "POST" }); } finally { clearAuthStorage(); } } else clearAuthStorage(); },
  async getItinerary() { await sleep(); return read(KEYS.itinerary,{id:uid(),name:"Mi viaje a Nicaragua",items:[]}); },
  async saveItinerary(payload) { write(KEYS.itinerary,payload); await enqueueChange("itinerary",payload.id||"default","upsert",payload,(payload.version||0)+1); return payload; },
  async hostLogin(email,password) { if (USE_API) { const result = await apiRequest("/auth/login", { method: "POST", body: JSON.stringify({ email, password }) }); if (!['host', 'anfitrion', 'anfitrión', 'admin'].includes(result.user.role)) throw new Error("La cuenta no tiene permisos de anfitrión."); write("waia_host_session", result.user); return result.user; } const host=read(KEYS.hosts,[]).find((x)=>x.email.toLowerCase()===email.toLowerCase()&&x.password===password); if(!host) throw new Error("Credenciales del anfitrión demo incorrectas."); write("waia_host_session",{id:host.id,name:host.name,email:host.email}); return host; },
  async hostSession() { if (USE_API) { try { const result = await apiRequest("/auth/me"); return ['host', 'anfitrion', 'anfitrión', 'admin'].includes(result.user.role) ? result.user : null; } catch { return null; } } await sleep(); return read("waia_host_session",null); },
  async hostLogout() { if (USE_API) { try { await apiRequest("/auth/logout", { method: "POST" }); } finally { clearAuthStorage(); } } else clearAuthStorage(); },
  async hostDashboard() { const host=read(KEYS.hosts,[])[0]; const bookings=read(KEYS.bookings,[]); const ids=host?.experiences||[]; const hostExperiences=experiencesData.filter((x)=>ids.includes(x.id)); const hostBookings=bookings.filter((x)=>ids.includes(x.experienceId)); const revenue=hostBookings.filter((x)=>x.status==="confirmed").reduce((s,x)=>s+(Number(x.price)||0)*(Number(x.guests)||1),0); return {host,experiences:hostExperiences,bookings:hostBookings,revenue}; },
  async hostUpdateBooking(id,status) { const list=read(KEYS.bookings,[]).map((x)=>x.id===id?{...x,status,version:(x.version||1)+1,updatedAt:new Date().toISOString()}:x); write(KEYS.bookings,list); const item=list.find((x)=>x.id===id); if(item) await enqueueChange("booking",id,"update",item,item.version); return list; },
  async hostUpdateProfile(updates) { const hosts=read(KEYS.hosts,[]); const updated=hosts.map((x)=>x.id===1?{...x,...updates}:x); write(KEYS.hosts,updated); const item=updated[0]; if(item) await enqueueChange("host",item.id,"update",item); return item; },
  async register(data) { if (USE_API) { const result = await apiRequest("/auth/register", { method: "POST", body: JSON.stringify(data) }); write(KEYS.user, result.user); return result.user; } throw new Error("El modo local está deshabilitado."); },
};

export const storageKeys = KEYS;

api.refreshSession = async function refreshSession() {
  if (!USE_API) return read(KEYS.user, null);
  const result = await apiRequest("/auth/refresh", { method: "POST" });
  if (result.user) write(KEYS.user, result.user);
  return result.user || null;
};

api.hostDashboard = async function hostDashboard() {
  if (!USE_API) return { host: read(KEYS.hosts, [])[0], experiences: [], bookings: [], revenue: 0 };
  const result = await apiRequest("/host/dashboard");
  return { host: result.host, experiences: result.experiences || [], bookings: result.bookings || [], revenue: result.revenue || 0 };
};

api.hostCreateExperience = async function hostCreateExperience(payload) {
  const result = await apiRequest("/host/experiences", { method: "POST", body: payload instanceof FormData ? payload : JSON.stringify(payload) });
  return result;
};

import { useEffect, useState } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import { Button, Chip, TextField } from "@mui/material";
import DashboardRoundedIcon from "@mui/icons-material/DashboardRounded";
import LogoutRoundedIcon from "@mui/icons-material/LogoutRounded";
import AddRoundedIcon from "@mui/icons-material/AddRounded";
import ArrowForwardRoundedIcon from "@mui/icons-material/ArrowForwardRounded";
import CalendarMonthRoundedIcon from "@mui/icons-material/CalendarMonthRounded";
import TrendingUpRoundedIcon from "@mui/icons-material/TrendingUpRounded";
import VisibilityRoundedIcon from "@mui/icons-material/VisibilityRounded";
import StorefrontRoundedIcon from "@mui/icons-material/StorefrontRounded";
import toast from "react-hot-toast";
import { api } from "../../services/api";
import "./HostDashboard.css";

const tabs = [
  { id: "overview", label: "Resumen", icon: DashboardRoundedIcon },
  { id: "experiences", label: "Experiencias", icon: StorefrontRoundedIcon },
  { id: "bookings", label: "Reservas", icon: CalendarMonthRoundedIcon },
];

export default function HostDashboard() {
  const [session, setSession] = useState(undefined);
  const [data, setData] = useState(null);
  const [tab, setTab] = useState("overview");
  const [profile, setProfile] = useState({});
  const [showExperienceForm, setShowExperienceForm] = useState(false);
  const [experienceSearch, setExperienceSearch] = useState("");
  const [coordinates, setCoordinates] = useState({ latitude: "", longitude: "" });
  const [selectedImage, setSelectedImage] = useState(null);
  const nav = useNavigate();

  useEffect(() => {
    api.hostSession().then((currentSession) => {
      setSession(currentSession);
      if (currentSession) api.hostDashboard().then((dashboard) => {
        setData(dashboard);
        setProfile(dashboard.host || {});
      });
    });
  }, []);

  useEffect(() => {
    if (tab !== "experiences") return undefined;
    const button = [...document.querySelectorAll(".host-panel--full button")].find((item) => item.textContent.includes("Agregar experiencia"));
    if (!button) return undefined;
    const openForm = () => setShowExperienceForm(true);
    button.addEventListener("click", openForm);
    return () => button.removeEventListener("click", openForm);
  }, [tab]);

  if (session === undefined) return <div className="host-loading">Cargando panel...</div>;
  if (!session) return <Navigate to="/anfitrion/login" replace />;

  const refresh = () => api.hostDashboard().then((dashboard) => {
    setData(dashboard);
    setProfile(dashboard.host || {});
  });
  const allExperiences = data?.experiences || [];
  const experiences = allExperiences.filter((experience) => `${experience.title || ""} ${experience.location || ""} ${experience.department || ""}`.toLowerCase().includes(experienceSearch.toLowerCase().trim()));
  const bookings = data?.bookings || [];
  const confirmedBookings = bookings.filter((booking) => booking.status === "confirmed");
  const pendingBookings = bookings.filter((booking) => booking.status !== "confirmed");
  const firstName = session.name?.split(" ")[0] || "anfitrión";
  const revenue = Number(data?.revenue || 0);
  const useCurrentLocation = () => {
    if (!navigator.geolocation) { toast.error("Este navegador no permite obtener GPS."); return; }
    navigator.geolocation.getCurrentPosition((position) => { setCoordinates({ latitude: position.coords.latitude.toFixed(7), longitude: position.coords.longitude.toFixed(7) }); toast.success("UbicaciÃ³n GPS agregada"); }, () => toast.error("No se pudo obtener tu ubicaciÃ³n GPS."), { enableHighAccuracy: true, timeout: 10000 });
  };
  const createExperience = async (event) => {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    if (selectedImage) form.set("image", selectedImage);
    form.set("latitude", coordinates.latitude);
    form.set("longitude", coordinates.longitude);
    try {
      await api.hostCreateExperience(form);
      await refresh();
      setShowExperienceForm(false);
      toast.success("Experiencia guardada en la base de datos");
    } catch (error) { toast.error(error.message); }
  };
  return (
    <div className="host-dashboard">
      <aside className="host-sidebar">
        <div className="host-sidebar__brand"><span className="host-brand-mark"><DashboardRoundedIcon /></span><strong>WAIA</strong><small>para anfitriones</small></div>
        <nav aria-label="Navegación del panel">
          {tabs.map(({ id, label, icon: Icon }) => <button key={id} className={tab === id ? "active" : ""} onClick={() => setTab(id)}><Icon />{label}</button>)}
          <button className={tab === "profile" ? "active" : ""} onClick={() => setTab("profile")}><StorefrontRoundedIcon />Mi perfil</button>
        </nav>
        <div className="host-sidebar__help"><span>¿Necesitas ayuda?</span><button onClick={() => nav("/contacto")}>Contactar a WAIA <ArrowForwardRoundedIcon /></button></div>
        <button className="host-sidebar__logout" onClick={async () => { await api.hostLogout(); toast.success("Sesión cerrada"); nav("/anfitrion/login"); }}><LogoutRoundedIcon />Salir</button>
      </aside>

      <section className="host-main">
        <header className="host-top"><div><span>Panel de anfitrión</span><strong>Hola, {firstName} <span className="host-wave">✦</span></strong></div><Button variant="outlined" startIcon={<VisibilityRoundedIcon />} onClick={() => nav("/")}>Ver WAIA</Button></header>
        <div className="host-content">
          {tab === "experiences" && <div className="host-dashboard-search"><TextField size="small" label="Buscar experiencia" value={experienceSearch} onChange={(event) => setExperienceSearch(event.target.value)} placeholder="Título o ubicación" /></div>}
          {showExperienceForm && <div className="host-experience-tools"><div className="host-form-actions"><Button type="button" variant="outlined" onClick={useCurrentLocation}>Usar mi ubicación GPS</Button><span className="host-coordinate-status">{coordinates.latitude ? `${coordinates.latitude}, ${coordinates.longitude}` : "Ubicación no seleccionada"}</span></div><Button component="label" variant="outlined">{selectedImage ? `Imagen: ${selectedImage.name}` : "Subir imagen"}<input type="file" accept="image/jpeg,image/png,image/webp" hidden onChange={(event) => setSelectedImage(event.target.files?.[0] || null)} /></Button></div>}
          {showExperienceForm && <div className="host-panel host-experience-form-panel"><div className="host-panel__heading"><div><span className="eyebrow">Nueva publicación</span><h2>Agregar experiencia</h2><p className="host-panel__description">La información se guardará directamente en la base de datos.</p></div><button className="host-text-button" type="button" onClick={() => setShowExperienceForm(false)}>Cancelar</button></div><form className="host-experience-form" onSubmit={createExperience}><TextField name="title" label="Título de la experiencia" required fullWidth /><TextField name="location" label="Ubicación" required fullWidth /><TextField name="shortDescription" label="Descripción corta" required inputProps={{ minLength: 10, maxLength: 500 }} fullWidth /><TextField name="description" label="Descripción completa" multiline minRows={3} fullWidth /><div className="host-form-grid"><TextField name="priceUsd" label="Precio USD" type="number" inputProps={{ min: 0, step: "0.01" }} /><TextField name="durationMinutes" label="Duración (minutos)" type="number" inputProps={{ min: 0 }} /><TextField name="maxParticipants" label="Cupo máximo" type="number" inputProps={{ min: 0 }} /></div><Button variant="contained" type="submit">Guardar experiencia</Button></form></div>}
          {tab === "overview" && <>
            <div className="host-page-heading"><div><span className="eyebrow">Tu actividad</span><h1>Todo bajo control.</h1><p>Administra tus experiencias y recibe a más viajeros en Nicaragua.</p></div><Button variant="contained" startIcon={<AddRoundedIcon />} onClick={() => setTab("experiences")}>Nueva experiencia</Button></div>
            <div className="host-hero"><div><span className="pill">Perfil activo</span><h2>Haz que tu comunidad sea parte del viaje.</h2><p>Tu oferta está visible en WAIA. Mantén la información actualizada para que cada visitante encuentre una experiencia auténtica.</p><button className="host-hero__link" onClick={() => setTab("profile")}>Completar mi perfil <ArrowForwardRoundedIcon /></button></div><div className="host-hero__art"><span>✦</span><span>◌</span><span>↗</span></div></div>
            <div className="host-section-heading"><div><span className="eyebrow">Resumen</span><h2>El pulso de tu negocio</h2></div><button className="host-text-button" onClick={() => setTab("bookings")}>Ver reservas <ArrowForwardRoundedIcon /></button></div>
            <div className="host-kpis"><div className="host-kpi host-kpi--accent"><span className="host-kpi__icon"><StorefrontRoundedIcon /></span><span>Experiencias activas</span><strong>{experiences.length}</strong><small>Publicadas en WAIA</small></div><div className="host-kpi"><span className="host-kpi__icon"><CalendarMonthRoundedIcon /></span><span>Reservas confirmadas</span><strong>{confirmedBookings.length}</strong><small>{pendingBookings.length ? `${pendingBookings.length} por revisar` : "Todo al día"}</small></div><div className="host-kpi"><span className="host-kpi__icon"><TrendingUpRoundedIcon /></span><span>Ingresos estimados</span><strong>US${revenue.toFixed(2)}</strong><small>De reservas confirmadas</small></div></div>
            <div className="host-overview-grid"><div className="host-panel"><div className="host-panel__heading"><div><span className="eyebrow">Publicadas</span><h2>Tus experiencias</h2></div><button className="host-icon-button" onClick={() => setTab("experiences")} aria-label="Ver experiencias"><ArrowForwardRoundedIcon /></button></div>{experiences.slice(0, 3).map((experience) => <div className="host-row" key={experience.id}><div className="host-row__avatar">{experience.title?.charAt(0) || "E"}</div><div className="host-row__content"><strong>{experience.title}</strong><span>{experience.location || experience.department || "Nicaragua"}</span></div><Chip label={experience.isDemo ? "Demo" : "Activa"} size="small" className="host-chip" /></div>)}{!experiences.length && <p className="muted">Todavía no tienes experiencias publicadas.</p>}</div><div className="host-panel host-panel--activity"><div className="host-panel__heading"><div><span className="eyebrow">Últimos movimientos</span><h2>Actividad reciente</h2></div><CalendarMonthRoundedIcon className="host-panel__icon" /></div>{bookings.slice(0, 3).map((booking) => <div className="host-activity" key={booking.id}><span className={`host-activity__dot ${booking.status === "confirmed" ? "is-confirmed" : ""}`} /><div><strong>{booking.experienceTitle || "Nueva reserva"}</strong><span>{booking.date || "Fecha pendiente"} · {booking.guests || 1} personas</span></div></div>)}{!bookings.length && <div className="host-empty"><CalendarMonthRoundedIcon /><p>Aún no hay reservas.</p><span>Cuando llegue la primera, aparecerá aquí.</span></div>}</div></div>
          </>}

          {tab === "experiences" && <div className="host-panel host-panel--full"><div className="host-panel__heading"><div><span className="eyebrow">Catálogo</span><h1>Mis experiencias</h1><p className="host-panel__description">Presenta lo mejor de tu comunidad a los viajeros.</p></div><Button variant="contained" startIcon={<AddRoundedIcon />}>Agregar experiencia</Button></div>{experiences.map((experience) => <div className="host-row host-row--large" key={experience.id}><div className="host-row__avatar host-row__avatar--large">{experience.title?.charAt(0) || "E"}</div><div className="host-row__content"><strong>{experience.title}</strong><span>{experience.location || experience.department || "Nicaragua"} · Desde US${experience.price || 0}</span></div><Chip label={experience.isDemo ? "Demo" : "Activa"} size="small" className="host-chip" /></div>)}{!experiences.length && <div className="host-empty"><StorefrontRoundedIcon /><p>No tienes experiencias publicadas todavía.</p><span>Agrega tu primera experiencia para comenzar.</span></div>}</div>}

          {tab === "bookings" && <div className="host-panel host-panel--full"><div className="host-panel__heading"><div><span className="eyebrow">Gestión</span><h1>Reservas</h1><p className="host-panel__description">Confirma y organiza las próximas visitas.</p></div><span className="host-count-badge">{bookings.length} total</span></div>{bookings.map((booking) => <div className="host-row host-row--large" key={booking.id}><div className="host-row__avatar host-row__avatar--booking"><CalendarMonthRoundedIcon /></div><div className="host-row__content"><strong>{booking.experienceTitle}</strong><span>{booking.date} · {booking.guests || 1} personas</span></div><Button size="small" variant={booking.status === "confirmed" ? "outlined" : "contained"} onClick={async () => { await api.hostUpdateBooking(booking.id, booking.status === "confirmed" ? "cancelled" : "confirmed"); refresh(); }}>{booking.status === "confirmed" ? "Cancelar" : "Confirmar"}</Button></div>)}{!bookings.length && <div className="host-empty"><CalendarMonthRoundedIcon /><p>No hay reservas asociadas todavía.</p><span>Las nuevas solicitudes aparecerán en este espacio.</span></div>}</div>}

          {tab === "profile" && <div className="host-panel host-panel--full"><div className="host-panel__heading"><div><span className="eyebrow">Tu presencia</span><h1>Mi perfil</h1><p className="host-panel__description">Cuéntales a los viajeros quién hace especial tu experiencia.</p></div></div><div className="host-profile-header"><div className="host-profile-avatar">{profile.name?.charAt(0) || "A"}</div><div><strong>{profile.name || "Anfitrión WAIA"}</strong><span>{profile.email}</span></div></div><div className="host-profile-form"><TextField label="Nombre" value={profile.name || ""} onChange={(event) => setProfile({ ...profile, name: event.target.value })} /><TextField label="Correo" value={profile.email || ""} onChange={(event) => setProfile({ ...profile, email: event.target.value })} /><TextField label="Descripción" multiline minRows={4} value={profile.description || ""} onChange={(event) => setProfile({ ...profile, description: event.target.value })} /><Button className="host-save-button" variant="contained" onClick={async () => { await api.hostUpdateProfile(profile); refresh(); toast.success("Perfil guardado localmente"); }}>Guardar cambios</Button></div></div>}
        </div>
      </section>
    </div>
  );
}

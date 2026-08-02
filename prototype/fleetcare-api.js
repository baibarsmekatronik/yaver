// baibars FleetCare — prototip → sunucu bağlantı katmanı
//
// Bu dosyayı Claude Design projesine (support.js'in yanına) ekleyin ve
// aşağıdaki iki değeri kendi Supabase projenizden doldurun.
// anon key herkese açık bir anahtardır (RLS ile korunur) — gizli DEĞİLDİR,
// ama service_role anahtarını ASLA buraya koymayın.

const FLEETCARE_CONFIG = {
  supabaseUrl: "https://YOUR-PROJECT-REF.supabase.co", // Supabase > Settings > API > Project URL
  anonKey: "YOUR-ANON-KEY",                            // Supabase > Settings > API > anon public
};

// Tarayıcı başına rastgele bir istemci kimliği (kişisel veri değildir)
const FLEETCARE_CLIENT_ID = (() => {
  const key = "fleetcare_client_id";
  let id = localStorage.getItem(key);
  if (!id) {
    id = "proto-" + Math.random().toString(36).slice(2, 10);
    localStorage.setItem(key, id);
  }
  return id;
})();

async function fleetcareRequest(path, options = {}) {
  const res = await fetch(`${FLEETCARE_CONFIG.supabaseUrl}/rest/v1/${path}`, {
    ...options,
    headers: {
      apikey: FLEETCARE_CONFIG.anonKey,
      Authorization: `Bearer ${FLEETCARE_CONFIG.anonKey}`,
      "Content-Type": "application/json",
      Prefer: "return=representation",
      ...(options.headers || {}),
    },
  });
  if (!res.ok) {
    throw new Error(`Sunucu hatası ${res.status}: ${await res.text()}`);
  }
  return res.status === 204 ? null : res.json();
}

const fleetcare = {
  // Genel olay kaydı — prototipteki herhangi bir etkileşimi sunucuya yazar.
  // Örnek: fleetcare.logEvent("maintenance_done", { rule: "pervane-kontrol" })
  async logEvent(eventType, payload = {}) {
    return fleetcareRequest("prototype_events", {
      method: "POST",
      body: JSON.stringify({
        event_type: eventType,
        payload,
        client_id: FLEETCARE_CLIENT_ID,
      }),
    });
  },

  // Kayıtlı hava araçlarını sayaçlarıyla getirir.
  async getAircraft() {
    return fleetcareRequest(
      "aircraft?select=id,serial_no,model,total_sorties,total_flight_hours&order=serial_no"
    );
  },

  // Bir sorti kaydeder; sunucudaki tetikleyici sayaçları otomatik artırır.
  // Örnek: fleetcare.addFlight(aircraftId, { durationMin: 11, areaDa: 20 })
  async addFlight(aircraftId, { durationMin, areaDa, params } = {}) {
    return fleetcareRequest("flights", {
      method: "POST",
      body: JSON.stringify({
        aircraft_id: aircraftId,
        duration_min: durationMin ?? null,
        area_covered_da: areaDa ?? null,
        params: params ?? null,
        ended_at: new Date().toISOString(),
      }),
    });
  },
};

// Prototip HTML'inden erişim için:
window.fleetcare = fleetcare;

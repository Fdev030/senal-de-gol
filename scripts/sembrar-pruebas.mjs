// Carga datos en la base de pruebas (que debe estar vacía y con sql/00-esquema.sql ya ejecutado).
// - Copia de producción, solo leyendo, lo que no es personal: torneos, fechas, partidos y reglamento.
// - Crea el usuario VIP, tres usuarios falsos (Prueba1, Prueba2, Prueba3; contraseña "prueba123"), un grupo
//   "Grupo de prueba" (código PRUEBA) y pronósticos al azar de los tres para todos los partidos.
//
// Uso: node scripts/sembrar-pruebas.mjs <URL rest producción> <clave anon producción> <URL rest pruebas> <clave pruebas>
//      (las URL terminan en /rest/v1)
import { createHash } from 'node:crypto';

const [PURL, PKEY, TURL, TKEY] = process.argv.slice(2);
if (!TKEY) { console.error('Faltan argumentos (ver el comentario del principio).'); process.exit(1); }
if (PURL === TURL) { console.error('La base de pruebas no puede ser la de producción.'); process.exit(1); }

async function leer(tabla) {
  const r = await fetch(`${PURL}/${tabla}?select=*`, { headers: { apikey: PKEY, Authorization: `Bearer ${PKEY}` } });
  if (!r.ok) throw new Error(`${tabla}: ${await r.text()}`);
  return r.json();
}

async function cargar(tabla, filas) {
  for (let i = 0; i < filas.length; i += 500) {
    const r = await fetch(`${TURL}/${tabla}`, {
      method: 'POST',
      headers: { apikey: TKEY, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
      body: JSON.stringify(filas.slice(i, i + 500)),
    });
    if (!r.ok) throw new Error(`${tabla}: ${await r.text()}`);
  }
  console.log(tabla, filas.length);
}

// Mismo cálculo que hashPass() de public/index.html.
const hash = p => createHash('sha256').update(p + 'prode_salt_2025').digest('hex');

const torneos = await leer('torneos');
const fechas = await leer('fechas');
const partidos = await leer('partidos');
await cargar('torneos', torneos);
await cargar('fechas', fechas);
await cargar('partidos', partidos);
await cargar('reglamento', await leer('reglamento'));

const usuarios = [
  { id: '00000000-0000-0000-0000-000000000001', nombre: 'señaldegol', nombre_real: 'Administrador', password_hash: null },
  ...[1, 2, 3].map(n => ({
    id: `00000000-0000-0000-0000-00000000010${n}`,
    nombre: `Prueba${n}`,
    nombre_real: `Usuario Prueba ${n}`,
    password_hash: hash('prueba123'),
  })),
];
const jugadores = usuarios.slice(1);
await cargar('usuarios', usuarios);

const grupoId = '00000000-0000-0000-0000-000000000201';
await cargar('grupos', [{ id: grupoId, nombre: 'Grupo de prueba', descripcion: 'Datos inventados', codigo: 'PRUEBA', creador_id: jugadores[0].id }]);
await cargar('grupo_miembros', jugadores.map((u, i) => ({ grupo_id: grupoId, usuario_id: u.id, is_admin: i === 0 })));

const claveDeFecha = Object.fromEntries(fechas.map(f => [f.id, torneos.find(t => t.id === f.torneo_id)?.clave]));
let semilla = 7;
const goles = () => (semilla = (semilla * 16807) % 2147483647) % 4;
await cargar('pronosticos', jugadores.flatMap(u => partidos.filter(p => claveDeFecha[p.fecha_id]).map(p => ({
  usuario_id: u.id, partido_id: p.id, torneo_clave: claveDeFecha[p.fecha_id], goles_local: goles(), goles_visitante: goles(),
}))));

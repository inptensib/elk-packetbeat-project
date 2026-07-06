#!/usr/bin/env node
/**
 * import-4sics-dashboards.js
 *
 * Importe les dashboards Kibana 4SICS depuis le fichier NDJSON vers une
 * instance Kibana via l'API officielle Saved Objects.
 *
 * Utilisation :
 *   node import-4sics-dashboards.js
 *
 * Variables d'environnement optionnelles :
 *   KIBANA_URL       URL de Kibana (défaut : http://localhost:5601)
 *   KIBANA_USERNAME  Utilisateur Kibana (si sécurité activée)
 *   KIBANA_PASSWORD  Mot de passe Kibana (si sécurité activée)
 *
 * Compatibilité : Node.js 12+  (aucune dépendance externe requise)
 */

'use strict';

const fs   = require('fs');
const path = require('path');
const http = require('http');
const https = require('https');
const { URL } = require('url');

// ─── Configuration ────────────────────────────────────────────────────────────

const KIBANA_URL = (process.env.KIBANA_URL || 'http://localhost:5601').replace(/\/$/, '');
const USERNAME   = process.env.KIBANA_USERNAME || '';
const PASSWORD   = process.env.KIBANA_PASSWORD || '';
const NDJSON_FILE = path.join(__dirname, '4sics-dashboards.ndjson');
const IMPORT_PATH = '/api/saved_objects/_import?overwrite=true';

// ─── Helpers ──────────────────────────────────────────────────────────────────

function log(msg)  { process.stdout.write('[INFO]  ' + msg + '\n'); }
function ok(msg)   { process.stdout.write('[OK]    ' + msg + '\n'); }
function err(msg)  { process.stderr.write('[ERROR] ' + msg + '\n'); }
function warn(msg) { process.stdout.write('[WARN]  ' + msg + '\n'); }

/** Génère une frontière multipart unique */
function boundary() {
  return 'KibanaBoundary' + Math.random().toString(36).slice(2) + Date.now();
}

/**
 * Construit un corps multipart/form-data manuellement.
 * Retourne { body: Buffer, contentType: string }
 */
function buildMultipart(fileContent, filename, fileMime) {
  const b = boundary();
  const CRLF = '\r\n';
  const header = [
    '--' + b,
    'Content-Disposition: form-data; name="file"; filename="' + filename + '"',
    'Content-Type: ' + fileMime,
    '',
    ''
  ].join(CRLF);
  const footer = CRLF + '--' + b + '--' + CRLF;

  const body = Buffer.concat([
    Buffer.from(header, 'utf8'),
    fileContent,
    Buffer.from(footer, 'utf8')
  ]);

  return {
    body,
    contentType: 'multipart/form-data; boundary=' + b
  };
}

/**
 * Envoie une requête HTTP/HTTPS et retourne la réponse sous forme de Buffer.
 * Retourne { statusCode, body }
 */
function httpRequest(urlStr, options, body) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(urlStr);
    const lib = parsed.protocol === 'https:' ? https : http;

    const req = lib.request({
      hostname : parsed.hostname,
      port     : parsed.port || (parsed.protocol === 'https:' ? 443 : 80),
      path     : parsed.pathname + parsed.search,
      method   : options.method || 'GET',
      headers  : options.headers || {}
    }, (res) => {
      const chunks = [];
      res.on('data', chunk => chunks.push(chunk));
      res.on('end', () => resolve({
        statusCode: res.statusCode,
        body: Buffer.concat(chunks).toString('utf8')
      }));
    });

    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

// ─── Étape 1 : Vérifier le fichier NDJSON ────────────────────────────────────

function checkFile() {
  if (!fs.existsSync(NDJSON_FILE)) {
    err('Fichier introuvable : ' + NDJSON_FILE);
    err('Assurez-vous d\'exécuter ce script depuis le dossier exports/');
    process.exit(1);
  }
  const stat = fs.statSync(NDJSON_FILE);
  const kb   = (stat.size / 1024).toFixed(0);
  const lines = fs.readFileSync(NDJSON_FILE, 'utf8')
                  .split('\n').filter(l => l.trim()).length;
  ok('Fichier trouvé : ' + path.basename(NDJSON_FILE) + ' (' + kb + ' Ko, ' + lines + ' objets)');
  return fs.readFileSync(NDJSON_FILE);
}

// ─── Étape 2 : Vérifier que Kibana répond ────────────────────────────────────

async function checkKibana() {
  log('Vérification de Kibana : ' + KIBANA_URL + ' ...');
  let resp;
  try {
    resp = await httpRequest(KIBANA_URL + '/api/status', { method: 'GET' });
  } catch (e) {
    err('Impossible de joindre Kibana : ' + e.message);
    err('Vérifiez que la stack ELK est démarrée : ./scripts/start.sh');
    process.exit(1);
  }

  if (resp.statusCode !== 200) {
    err('Kibana répond avec le statut HTTP ' + resp.statusCode);
    process.exit(1);
  }

  let level = 'unknown';
  try { level = JSON.parse(resp.body).status.overall.level; } catch (_) {}

  if (level !== 'available') {
    warn('Kibana est en cours de démarrage (status=' + level + '). Patientez puis relancez.');
    process.exit(1);
  }
  ok('Kibana disponible (status=' + level + ')');
}

// ─── Étape 3 : Importer via l'API Saved Objects ──────────────────────────────

async function importDashboards(fileContent) {
  log('Import vers ' + KIBANA_URL + IMPORT_PATH + ' ...');

  const { body, contentType } = buildMultipart(
    fileContent,
    '4sics-dashboards.ndjson',
    'application/ndjson'
  );

  const headers = {
    'kbn-xsrf'     : 'true',
    'Content-Type' : contentType,
    'Content-Length': body.length
  };

  if (USERNAME && PASSWORD) {
    const token = Buffer.from(USERNAME + ':' + PASSWORD).toString('base64');
    headers['Authorization'] = 'Basic ' + token;
    log('Authentification activée pour l\'utilisateur : ' + USERNAME);
  }

  let resp;
  try {
    resp = await httpRequest(KIBANA_URL + IMPORT_PATH, { method: 'POST', headers }, body);
  } catch (e) {
    err('Erreur réseau lors de l\'import : ' + e.message);
    process.exit(1);
  }

  let result;
  try {
    result = JSON.parse(resp.body);
  } catch (_) {
    err('Réponse Kibana non parsable (statut HTTP ' + resp.statusCode + ')');
    err('Réponse brute : ' + resp.body.slice(0, 300));
    process.exit(1);
  }

  if (resp.statusCode !== 200) {
    err('Import échoué (HTTP ' + resp.statusCode + ') : ' + (result.message || resp.body.slice(0, 200)));
    process.exit(1);
  }

  // ─── Afficher le résultat ─────────────────────────────────────────────────

  const successCount = result.successCount || 0;
  const errors       = result.errors       || [];

  console.log('');
  console.log('════════════════════════════════════════════════════════');
  console.log('  Résultat de l\'import Kibana');
  console.log('════════════════════════════════════════════════════════');
  console.log('  Objets importés avec succès : ' + successCount);

  if (result.successResults && result.successResults.length > 0) {
    const dashboards = result.successResults.filter(r => r.type === 'dashboard');
    const vizes      = result.successResults.filter(r => r.type === 'lens');
    const views      = result.successResults.filter(r => r.type === 'index-pattern');
    if (views.length)     console.log('  Data views     : ' + views.length);
    if (vizes.length)     console.log('  Visualisations : ' + vizes.length);
    if (dashboards.length) {
      console.log('  Dashboards     : ' + dashboards.length);
      dashboards.forEach(d => {
        const name = d.meta && d.meta.title ? d.meta.title : (d.destinationId || d.id || '?');
        console.log('    - ' + name);
      });
    }
  }

  if (errors.length > 0) {
    console.log('');
    warn(errors.length + ' erreur(s) lors de l\'import :');
    errors.slice(0, 5).forEach(e => {
      warn('  [' + e.type + '/' + e.id + '] ' + (e.error && e.error.message ? e.error.message : JSON.stringify(e.error)));
    });
  }

  console.log('');
  console.log('  URL Kibana : ' + KIBANA_URL);
  console.log('  Aller dans : Kibana > Dashboard');
  console.log('');
  console.log('  Dashboards disponibles :');
  console.log('    - Dashboard 1 - Vue Globale Du Trafic ICS');
  console.log('    - Dashboard 2 - Analyse Des Equipements ICS');
  console.log('');
  console.log('  IMPORTANT : réglez la plage temporelle sur');
  console.log('    2015-10-20 → aujourd\'hui');
  console.log('  pour voir l\'intégralité des données.');
  console.log('════════════════════════════════════════════════════════');
  console.log('');

  if (errors.length > 0 && successCount === 0) {
    process.exit(1);
  }
}

// ─── Point d'entrée ──────────────────────────────────────────────────────────

(async () => {
  console.log('');
  console.log('════════════════════════════════════════════════════════');
  console.log('  Import Dashboards Kibana — 4SICS ELK Project');
  console.log('════════════════════════════════════════════════════════');
  console.log('');
  log('Node.js ' + process.version);
  log('Kibana cible : ' + KIBANA_URL);
  console.log('');

  const fileContent = checkFile();
  await checkKibana();
  await importDashboards(fileContent);
})();

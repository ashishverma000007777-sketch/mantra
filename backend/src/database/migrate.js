// backend/src/database/migrate.js
'use strict';

const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

async function runMigration() {
  const connectionString =
    process.env.MANTRA_DATABASE_URL ||
    process.env.DATABASE_URL ||
    'postgresql://postgres:postgres@localhost:5432/mantra_db';

  console.log(`[Mantra Migration] Connecting to target database: ${connectionString.replace(/:[^:@]*@/, ':****@')}`);

  const pool = new Pool({
    connectionString,
    connectionTimeoutMillis: 5000,
  });

  try {
    const client = await pool.connect();
    console.log('[Mantra Migration] Connected successfully. Reading schema.sql...');

    const schemaPath = path.resolve(__dirname, '../../database/schema.sql');
    const sql = fs.readFileSync(schemaPath, 'utf8');

    console.log('[Mantra Migration] Applying schema...');
    await client.query(sql);

    console.log('[Mantra Migration] Schema applied successfully! Verifying tables...');
    const result = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `);

    console.log('[Mantra Migration] Verified public tables:');
    result.rows.forEach(r => console.log(`  - ${r.table_name}`));

    client.release();
    await pool.end();
    console.log('[Mantra Migration] Migration completed without errors.');
    process.exit(0);
  } catch (err) {
    console.error('[Mantra Migration ERROR]:', err.message);
    if (err.code === 'ECONNREFUSED') {
      console.error('[Mantra Migration] PostgreSQL service is not reachable on the specified host/port.');
      console.error('[Mantra Migration] Verify MANTRA_DATABASE_URL or that the PostgreSQL service container is running.');
    }
    await pool.end().catch(() => {});
    process.exit(1);
  }
}

if (require.main === module) {
  runMigration();
}

module.exports = { runMigration };

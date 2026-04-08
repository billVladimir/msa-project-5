const { Client } = require("pg");
const fs = require("fs");
const path = require("path");

const DB_HOST = process.env.DB_HOST || "localhost";
const DB_PORT = process.env.DB_PORT || "5432";
const DB_NAME = process.env.DB_NAME || "logistics";
const DB_USER = process.env.DB_USER || "logistics";
const DB_PASSWORD = process.env.DB_PASSWORD || "logistics";
const TABLE_NAME = process.env.TABLE_NAME || "shipments";
const OUTPUT_DIR = process.env.OUTPUT_DIR || "/data/export";

function escapeCSV(value) {
  if (value === null || value === undefined) return "";
  const str = String(value);
  if (str.includes(",") || str.includes('"') || str.includes("\n")) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

async function exportTable() {
  const timestamp = Date.now();
  const date = new Date().toISOString().slice(0, 10);
  const fileName = `${TABLE_NAME}_${date}_${timestamp}.csv`;
  const outputPath = path.join(OUTPUT_DIR, fileName);

  console.log(`[INFO] Starting export of table "${TABLE_NAME}"`);
  console.log(`[INFO] Connecting to ${DB_HOST}:${DB_PORT}/${DB_NAME}`);

  const client = new Client({
    host: DB_HOST,
    port: parseInt(DB_PORT, 10),
    database: DB_NAME,
    user: DB_USER,
    password: DB_PASSWORD,
    connectionTimeoutMillis: 10000,
  });

  try {
    await client.connect();
    console.log("[INFO] Connected to PostgreSQL");

    const countResult = await client.query(
      `SELECT COUNT(*) as cnt FROM ${TABLE_NAME}`,
    );
    const totalRows = parseInt(countResult.rows[0].cnt, 10);
    console.log(`[INFO] Total rows in "${TABLE_NAME}": ${totalRows}`);

    const result = await client.query(`SELECT * FROM ${TABLE_NAME}`);
    const { rows, fields } = result;

    if (rows.length === 0) {
      console.log("[WARN] No data to export");
      process.exit(0);
    }

    fs.mkdirSync(OUTPUT_DIR, { recursive: true });

    const header = fields.map((f) => f.name).join(",");
    const csvRows = rows.map((row) =>
      fields.map((f) => escapeCSV(row[f.name])).join(","),
    );

    const csvContent = [header, ...csvRows].join("\n") + "\n";
    fs.writeFileSync(outputPath, csvContent, "utf-8");

    console.log(`[INFO] Exported ${rows.length} rows to ${outputPath}`);
    console.log(`[INFO] File size: ${fs.statSync(outputPath).size} bytes`);
    console.log("[INFO] Export completed successfully");
  } catch (error) {
    console.error(`[ERROR] Export failed: ${error.message}`);
    process.exit(1);
  } finally {
    await client.end();
  }
}

exportTable();

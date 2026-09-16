import { Pool } from "@neondatabase/serverless";
import { drizzle } from "drizzle-orm/neon-serverless";

const connectionString = process.env.DATABASE_URL;
if (!connectionString) throw new Error("DATABASE_URL is not configured");

const pool = new Pool({
  connectionString,
  max: Number(process.env.DB_POOL_MAX ?? 10),
});

export const db = drizzle({ client: pool });
export { pool };
export * as schema from "./schema";

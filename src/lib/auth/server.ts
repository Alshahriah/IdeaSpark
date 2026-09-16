import { createNeonAuth } from "@neondatabase/auth/next/server";

const baseUrl = process.env.NEON_AUTH_BASE_URL;
const cookieSecret = process.env.NEON_AUTH_COOKIE_SECRET;

if (!baseUrl) throw new Error("NEON_AUTH_BASE_URL is required");
if (!cookieSecret) throw new Error("NEON_AUTH_COOKIE_SECRET is required");

export const auth = createNeonAuth({
  baseUrl,
  cookies: {
    secret: cookieSecret,
    // sessionDataTtl: 300, // optional session_data cache TTL in seconds (default: 300)
  },
  // logLevel: 'silent', // disable Managed Better Auth logging
  // logLevel: 'debug',  // verbose proxy/upstream logging
});

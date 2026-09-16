import { eq } from "drizzle-orm";
import { db } from "@/db";
import { admins } from "@/db/schema";
import { auth } from "@/lib/auth/server";

export async function getAdminActor() {
  const { data: session } = await auth.getSession();
  const email = session?.user?.email?.trim().toLowerCase();
  if (!email) return null;

  const [admin] = await db
    .select()
    .from(admins)
    .where(eq(admins.email, email))
    .limit(1);

  return admin ?? null;
}

export async function isAdmin(): Promise<boolean> {
  return Boolean(await getAdminActor());
}

export async function requireAdminRole(
  allowed: Array<typeof admins.$inferSelect.role>,
) {
  const admin = await getAdminActor();
  if (!admin || !allowed.includes(admin.role)) {
    throw new Error("Unauthorized: insufficient admin role");
  }
  return admin;
}

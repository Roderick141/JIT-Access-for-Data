/**
 * AuthContext – calls GET /api/me on mount and provides the authenticated
 * user to the entire component tree.
 *
 * Derives the effective UI role from the database flags:
 *   "admin"    – IsAdmin = true
 *   "steward"  – IsDataSteward = true (but not admin)
 *   "approver" – IsApprover = true (but not admin or steward)
 *   "user"     – everyone else
 */
import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { fetchCurrentUser } from "@/api/endpoints";
import type { CurrentUser } from "@/api/types";

export type UserRole = "user" | "approver" | "steward" | "admin";

interface AuthState {
  user: CurrentUser | null;
  /** Derived UI role based on database flags */
  userRole: UserRole;
  /** Convenience flags derived from the user record */
  canApprove: boolean;
  canManage: boolean;
  isLoading: boolean;
  error: string | null;
  /** Re-fetch the user (e.g. after a role change) */
  refresh: () => void;
}

const AuthContext = createContext<AuthState>({
  user: null,
  userRole: "user",
  canApprove: false,
  canManage: false,
  isLoading: true,
  error: null,
  refresh: () => {},
});

function deriveRole(user: CurrentUser): UserRole {
  if (user.IsAdmin) return "admin";
  if (user.IsDataSteward) return "steward";
  if (user.IsApprover) return "approver";
  return "user";
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<CurrentUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = () => {
    setIsLoading(true);
    setError(null);
    fetchCurrentUser()
      .then((u) => {
        setUser(u);
      })
      .catch((err) => {
        setError(err.message ?? "Failed to load user.");
        setUser(null);
      })
      .finally(() => setIsLoading(false));
  };

  useEffect(() => {
    load();
  }, []);

  const userRole = user ? deriveRole(user) : "user";

  // Can this user approve requests? (approvers, stewards, admins)
  const canApprove = !!user && (!!user.IsApprover || !!user.IsDataSteward || !!user.IsAdmin);

  // Can this user manage roles/teams/users? (stewards and admins only)
  const canManage = !!user && (!!user.IsDataSteward || !!user.IsAdmin);

  return (
    <AuthContext.Provider
      value={{ user, userRole, canApprove, canManage, isLoading, error, refresh: load }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}

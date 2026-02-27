/**
 * Typed API endpoint functions.
 * Each function calls the FastAPI REST API via the thin fetch wrapper.
 */
import { api } from "./client";
import type {
  CurrentUser,
  Grant,
  UserRequest,
  RequestableRole,
  PendingApproval,
  ApproverRequestDetail,
  Role,
  Team,
  AdminUser,
  AuditLogEntry,
  AdminStats,
  LookupRow,
  DbRole,
  TeamMember,
  RoleUser,
} from "./types";

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

export const fetchCurrentUser = () => api.get<CurrentUser>("/api/me");

// ---------------------------------------------------------------------------
// User
// ---------------------------------------------------------------------------

export const fetchGrants = () => api.get<Grant[]>("/api/user/grants");

export const fetchUserRequests = () =>
  api.get<UserRequest[]>("/api/user/requests");

export const fetchRequestableRoles = () =>
  api.get<RequestableRole[]>("/api/roles/requestable");

export const submitAccessRequest = (payload: {
  roleIds: number[];
  durationMinutes: number;
  justification: string;
  ticketRef?: string;
}) => api.post<void>("/api/requests", payload);

export const cancelRequest = (requestId: number) =>
  api.post<void>(`/api/requests/${requestId}/cancel`);

// ---------------------------------------------------------------------------
// Approver
// ---------------------------------------------------------------------------

export const fetchPendingApprovals = () =>
  api.get<PendingApproval[]>("/api/approver/pending");

// Deprecated candidate: current UI uses /api/approver/pending only.
// Keep until a dedicated drill-down screen exists or endpoint is removed.
export const fetchApproverRequestDetail = (requestId: number) =>
  api.get<ApproverRequestDetail>(`/api/approver/requests/${requestId}`);

export const approveRequest = (requestId: number, comment?: string) =>
  api.post<void>(`/api/requests/${requestId}/approve`, { comment });

export const denyRequest = (requestId: number, comment: string) =>
  api.post<void>(`/api/requests/${requestId}/deny`, { comment });

// ---------------------------------------------------------------------------
// Admin
// ---------------------------------------------------------------------------

export const fetchAdminRoles = () => api.get<Role[]>("/api/admin/roles");

export const fetchAdminTeams = () => api.get<Team[]>("/api/admin/teams");

export const fetchAdminUsers = (params?: {
  search?: string;
  department?: string;
  role?: string;
  status?: string;
  page?: number;
  pageSize?: number;
}) => {
  const q = new URLSearchParams();
  if (params?.search) q.set("search", params.search);
  if (params?.department) q.set("department", params.department);
  if (params?.role) q.set("role", params.role);
  if (params?.status) q.set("status", params.status);
  if (params?.page) q.set("page", String(params.page));
  if (params?.pageSize) q.set("pageSize", String(params.pageSize));
  const qs = q.toString();
  return api.get<AdminUser[]>(`/api/admin/users${qs ? `?${qs}` : ""}`);
};

export const fetchAuditLogs = (params?: {
  search?: string;
  eventType?: string;
  startDate?: string;
  endDate?: string;
  page?: number;
  pageSize?: number;
}) => {
  const q = new URLSearchParams();
  if (params?.search) q.set("search", params.search);
  if (params?.eventType) q.set("eventType", params.eventType);
  if (params?.startDate) q.set("startDate", params.startDate);
  if (params?.endDate) q.set("endDate", params.endDate);
  if (params?.page) q.set("page", String(params.page));
  if (params?.pageSize) q.set("pageSize", String(params.pageSize));
  const qs = q.toString();
  return api.get<AuditLogEntry[]>(`/api/admin/audit-logs${qs ? `?${qs}` : ""}`);
};

export const fetchAdminStats = () => api.get<AdminStats>("/api/admin/stats");

export const fetchAdminLookups = () => api.get<LookupRow[]>("/api/admin/lookups");

export const createRole = (payload: Record<string, unknown>) =>
  api.post<void>("/api/admin/roles", payload);
export const updateRole = (roleId: number, payload: Record<string, unknown>) =>
  api.put<void>(`/api/admin/roles/${roleId}`, payload);
export const deleteRole = (roleId: number) =>
  api.delete<void>(`/api/admin/roles/${roleId}`);
export const toggleRole = (roleId: number, isEnabled: boolean) =>
  api.post<void>(`/api/admin/roles/${roleId}/toggle`, { isEnabled });

export const fetchRoleUsers = (roleId: number) =>
  api.get<RoleUser[]>(`/api/admin/roles/${roleId}/users`);
export const fetchRoleDbRoles = (roleId: number) =>
  api.get<DbRole[]>(`/api/admin/roles/${roleId}/db-roles`);
export const setRoleDbRoles = (roleId: number, dbRoleIds: number[]) =>
  api.put<void>(`/api/admin/roles/${roleId}/db-roles`, { dbRoleIds });
export const fetchRoleEligibilityRules = (roleId: number) =>
  api.get<Record<string, unknown>[]>(`/api/admin/roles/${roleId}/eligibility-rules`);
export const setRoleEligibilityRules = (roleId: number, rules: Record<string, unknown>[]) =>
  api.put<void>(`/api/admin/roles/${roleId}/eligibility-rules`, { rules });
export const fetchDbRoles = () => api.get<DbRole[]>("/api/admin/db-roles");

export const createTeam = (payload: Record<string, unknown>) =>
  api.post<void>("/api/admin/teams", payload);
export const updateTeam = (teamId: number, payload: Record<string, unknown>) =>
  api.put<void>(`/api/admin/teams/${teamId}`, payload);
export const deleteTeam = (teamId: number) =>
  api.delete<void>(`/api/admin/teams/${teamId}`);
export const fetchTeamMembers = (teamId: number) =>
  api.get<TeamMember[]>(`/api/admin/teams/${teamId}/members`);
export const setTeamMembers = (teamId: number, userIds: string[]) =>
  api.put<void>(`/api/admin/teams/${teamId}/members`, { userIds });

export const updateUserSystemRoles = (
  userId: string,
  payload: { isAdmin: boolean; isApprover: boolean; isDataSteward: boolean }
) => api.put<void>(`/api/admin/users/${userId}/system-roles`, payload);

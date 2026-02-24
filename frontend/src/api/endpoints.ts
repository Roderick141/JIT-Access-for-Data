/**
 * Typed API endpoint functions.
 * Each function calls the Flask REST API via the thin fetch wrapper.
 */
import { api } from "./client";
import type {
  CurrentUser,
  Grant,
  UserRequest,
  RequestableRole,
  PendingApproval,
  Role,
  Team,
  AdminUser,
  AuditLogEntry,
  AdminStats,
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
  durationDays: number;
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

export const fetchApproverRequestDetail = (requestId: number) =>
  api.get<PendingApproval>(`/api/approver/requests/${requestId}`);

export const approveRequest = (requestId: number, comment?: string) =>
  api.post<void>(`/api/requests/${requestId}/approve`, { comment });

export const denyRequest = (requestId: number, comment: string) =>
  api.post<void>(`/api/requests/${requestId}/deny`, { comment });

// ---------------------------------------------------------------------------
// Admin
// ---------------------------------------------------------------------------

export const fetchAdminRoles = () => api.get<Role[]>("/api/admin/roles");

export const fetchAdminTeams = () => api.get<Team[]>("/api/admin/teams");

export const fetchAdminUsers = () => api.get<AdminUser[]>("/api/admin/users");

export const fetchAuditLogs = () =>
  api.get<AuditLogEntry[]>("/api/admin/audit-logs");

export const fetchAdminStats = () => api.get<AdminStats>("/api/admin/stats");

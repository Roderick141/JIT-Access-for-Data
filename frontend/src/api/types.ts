/**
 * TypeScript interfaces matching the SQL Server column names returned by
 * the Flask API / stored procedures.
 *
 * Column names are PascalCase to match the database schema.
 */

// ---------------------------------------------------------------------------
// User / Auth
// ---------------------------------------------------------------------------

export interface CurrentUser {
  UserId: number;
  LoginName: string;
  GivenName: string | null;
  Surname: string | null;
  DisplayName: string;
  Email: string | null;
  Division: string | null;
  Department: string | null;
  JobTitle: string | null;
  SeniorityLevel: string | null;
  IsAdmin: boolean;
  IsApprover: boolean;
  IsDataSteward: boolean;
  IsActive: boolean;
}

// ---------------------------------------------------------------------------
// Grants  (sp_Grant_ListActiveForUser)
// ---------------------------------------------------------------------------

export interface Grant {
  GrantId: number;
  RequestId: number;
  RoleId: number;
  RoleName: string;
  RoleDescription?: string;
  Status: string;
  GrantedUtc: string;
  ExpiryUtc: string | null;
  SensitivityLevel?: string;
  [key: string]: unknown; // allow extra columns from the SP
}

// ---------------------------------------------------------------------------
// Requests  (sp_Request_ListForUser)
// ---------------------------------------------------------------------------

export interface UserRequest {
  RequestId: number;
  UserId: number;
  Status: string;
  RequestedDurationMinutes: number;
  Justification: string | null;
  TicketRef: string | null;
  CreatedUtc: string;
  UpdatedUtc: string | null;
  RoleNames?: string;
  RoleIds?: string;
  DecisionComment?: string | null;
  ApproverName?: string | null;
  DecisionUtc?: string | null;
  [key: string]: unknown;
}

// ---------------------------------------------------------------------------
// Requestable Roles  (sp_Role_ListRequestable)
// ---------------------------------------------------------------------------

export interface RequestableRole {
  RoleId: number;
  RoleName: string;
  RoleDescription: string | null;
  MaxDurationMinutes: number;
  SensitivityLevel: string;
  ApproverDisplayName?: string;
  [key: string]: unknown;
}

// ---------------------------------------------------------------------------
// Pending Approvals  (sp_Request_ListPendingForApprover)
// ---------------------------------------------------------------------------

export interface PendingApproval {
  RequestId: number;
  UserId: number;
  RequesterName: string;
  RequesterEmail?: string;
  RequesterDepartment?: string;
  RoleNames: string;
  RoleIds?: string;
  SensitivityLevel?: string;
  RequestedDurationMinutes: number;
  Justification: string | null;
  TicketRef?: string | null;
  CreatedUtc: string;
  Status: string;
  [key: string]: unknown;
}

// ---------------------------------------------------------------------------
// Admin: Roles
// ---------------------------------------------------------------------------

export interface Role {
  RoleId: number;
  RoleName: string;
  RoleDescription: string | null;
  SensitivityLevel: string;
  MaxDurationMinutes: number;
  IsActive: boolean;
  [key: string]: unknown;
}

// ---------------------------------------------------------------------------
// Admin: Teams
// ---------------------------------------------------------------------------

export interface Team {
  TeamId: number;
  TeamName: string;
  TeamDescription: string | null;
  IsActive: boolean;
  [key: string]: unknown;
}

// ---------------------------------------------------------------------------
// Admin: Users
// ---------------------------------------------------------------------------

export interface AdminUser {
  UserId: number;
  LoginName: string;
  GivenName: string | null;
  Surname: string | null;
  DisplayName: string;
  Email: string | null;
  Division: string | null;
  Department: string | null;
  JobTitle: string | null;
  SeniorityLevel: string | null;
  IsAdmin: boolean;
  IsApprover: boolean;
  IsDataSteward: boolean;
  IsActive: boolean;
  [key: string]: unknown;
}

// ---------------------------------------------------------------------------
// Admin: Audit Logs
// ---------------------------------------------------------------------------

export interface AuditLogEntry {
  AuditLogId: number;
  EventType: string;
  EventUtc: string;
  UserId?: number;
  Details?: string;
  [key: string]: unknown;
}

// ---------------------------------------------------------------------------
// Admin: Stats
// ---------------------------------------------------------------------------

export interface AdminStats {
  activeGrants: number;
  totalRoles: number;
  sensitiveRoles: number;
  totalUsers: number;
}

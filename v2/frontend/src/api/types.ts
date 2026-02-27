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
  UserId: string;
  UserContextVersionId?: number | null;
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
  IsEnabled?: boolean;
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
  UserId: string;
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
  SensitivityLevel: string;
  IconName: string;
  IconColor: string;
  MaxDurationMinutes: number;
  RequiresJustification: boolean;
  RequiresApproval: boolean;
  [key: string]: unknown;
}

// ---------------------------------------------------------------------------
// Pending Approvals  (sp_Request_ListPendingForApprover)
// ---------------------------------------------------------------------------

export interface PendingApproval {
  RequestId: number;
  UserId: string;
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

export interface ApproverRequestDetail {
  RequestId: number;
  UserId: string;
  RequestedDurationMinutes: number;
  Justification: string | null;
  TicketRef?: string | null;
  Status: string;
  UserDeptSnapshot?: string | null;
  UserTitleSnapshot?: string | null;
  CreatedUtc: string;
  UpdatedUtc?: string | null;
  RequesterName?: string;
  RequesterLoginName?: string;
  RequesterEmail?: string;
  RequesterDepartment?: string;
  RequesterDivision?: string;
  RequesterSeniority?: number | null;
  Roles?: Array<Record<string, unknown>>;
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
  IconName: string;
  IconColor: string;
  IsActive: boolean;
  IsEnabled: boolean;
  ConnectedUserCount?: number;
  ActiveGrantedUserCount?: number;
  PermissionCount?: number;
  PermissionNames?: string;
  [key: string]: unknown;
}

// ---------------------------------------------------------------------------
// Admin: Teams
// ---------------------------------------------------------------------------

export interface Team {
  TeamId: number;
  TeamName: string;
  TeamDescription: string | null;
  Department?: string | null;
  MemberCount?: number;
  IsActive: boolean;
  [key: string]: unknown;
}

// ---------------------------------------------------------------------------
// Admin: Users
// ---------------------------------------------------------------------------

export interface AdminUser {
  UserId: string;
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
  IsEnabled?: boolean;
  IsActive: boolean;
  TotalCount?: number;
  [key: string]: unknown;
}

// ---------------------------------------------------------------------------
// Admin: Audit Logs
// ---------------------------------------------------------------------------

export interface AuditLogEntry {
  TotalCount?: number;
  AuditLogId: number;
  EventType: string;
  EventUtc: string;
  UserId?: string;
  ActorDisplayName?: string;
  TargetDisplayName?: string;
  RequestId?: number;
  GrantId?: number;
  RoleName?: string;
  RoleNames?: string;
  DisplayMessage?: string;
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

export interface TeamMember {
  UserId: string;
  DisplayName: string;
  Email?: string;
}

export interface LookupRow {
  LookupType: "users" | "teams" | "departments" | "divisions";
  LookupValue: string;
  LookupLabel: string;
}

export interface DbRole {
  DbRoleId: number;
  DbRoleName: string;
  DatabaseName?: string;
}

export interface RoleUser {
  UserId: string;
  LoginName: string;
  DisplayName: string;
  Email?: string | null;
  Department?: string | null;
  HasActiveRole: boolean;
  GrantedDateUtc?: string | null;
  ExpiryDateUtc?: string | null;
}

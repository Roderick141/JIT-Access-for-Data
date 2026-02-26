import { useState, useEffect } from "react";
import {
  Plus, Edit, Trash2, Database, Globe, Users, Shield, Search, X,
  ChevronDown, ChevronRight, ChevronLeft, ChevronsRight, ChevronsLeft,
  Lock, Key, FileText, Briefcase, Settings, Server, Cloud, Package,
  Folder, BarChart, Layers, Mail, Bell, Calendar, CreditCard, Home,
  Phone, Camera, Image, Video, Music, Book, BookOpen, Clipboard, Code,
  Coffee, Cpu, Download, Upload, Filter, Flag, Gift, Heart, Inbox, Link,
  Map, MessageSquare, Monitor, Smartphone, Tablet, Paperclip, Printer,
  Radio, Rss, Send, Share2, ShoppingCart, Star, Tag, Target, Trash,
  TrendingUp, Truck, Tv, UserCheck, Wifi, Zap,
} from "lucide-react";
import {
  fetchAdminRoles,
  createRole,
  updateRole,
  deleteRole,
  toggleRole,
  fetchRoleUsers,
  fetchRoleDbRoles,
  setRoleDbRoles,
  fetchRoleEligibilityRules,
  setRoleEligibilityRules,
  fetchDbRoles,
  fetchAdminLookups,
} from "@/api/endpoints";
import type { Role, DbRole, LookupRow, RoleUser as ApiRoleUser } from "@/api/types";

// ─── Types ────────────────────────────────────────────────────────────────────

interface RoleMapped {
  id: number;
  name: string;
  description: string;
  enabled: boolean;
  type: "Public" | "Standard" | "Sensitive";
  users: number;
  permissions: string[];
  iconName: string;
  color: string;
  isSensitive: boolean;
}

interface RoleUser {
  id: number;
  name: string;
  email: string;
  department: string;
  hasActiveRole: boolean;
  grantedDate?: string;
  expiryDate?: string;
}

interface EligibilityRule {
  id: string;
  type: "User" | "Team" | "Division" | "Department";
  value: string;
  displayName: string;
  maxDuration: number;
  requiresJustification: boolean;
  requiresApproval: boolean;
  minimumSeniorityLevel: number;
}

// ─── Icon helpers ─────────────────────────────────────────────────────────────

const availableIcons = [
  { name: "Database", component: Database },
  { name: "Globe", component: Globe },
  { name: "Users", component: Users },
  { name: "Shield", component: Shield },
  { name: "Lock", component: Lock },
  { name: "Key", component: Key },
  { name: "FileText", component: FileText },
  { name: "Briefcase", component: Briefcase },
  { name: "Settings", component: Settings },
  { name: "Server", component: Server },
  { name: "Cloud", component: Cloud },
  { name: "Package", component: Package },
  { name: "Folder", component: Folder },
  { name: "BarChart", component: BarChart },
  { name: "Layers", component: Layers },
  { name: "Mail", component: Mail },
  { name: "Bell", component: Bell },
  { name: "Calendar", component: Calendar },
  { name: "CreditCard", component: CreditCard },
  { name: "Home", component: Home },
  { name: "Phone", component: Phone },
  { name: "Camera", component: Camera },
  { name: "Image", component: Image },
  { name: "Video", component: Video },
  { name: "Music", component: Music },
  { name: "Book", component: Book },
  { name: "BookOpen", component: BookOpen },
  { name: "Clipboard", component: Clipboard },
  { name: "Code", component: Code },
  { name: "Coffee", component: Coffee },
  { name: "Cpu", component: Cpu },
  { name: "Download", component: Download },
  { name: "Upload", component: Upload },
  { name: "Filter", component: Filter },
  { name: "Flag", component: Flag },
  { name: "Gift", component: Gift },
  { name: "Heart", component: Heart },
  { name: "Inbox", component: Inbox },
  { name: "Link", component: Link },
  { name: "Map", component: Map },
  { name: "MessageSquare", component: MessageSquare },
  { name: "Monitor", component: Monitor },
  { name: "Smartphone", component: Smartphone },
  { name: "Tablet", component: Tablet },
  { name: "Paperclip", component: Paperclip },
  { name: "Printer", component: Printer },
  { name: "Radio", component: Radio },
  { name: "Rss", component: Rss },
  { name: "Send", component: Send },
  { name: "Share2", component: Share2 },
  { name: "ShoppingCart", component: ShoppingCart },
  { name: "Star", component: Star },
  { name: "Tag", component: Tag },
  { name: "Target", component: Target },
  { name: "Trash", component: Trash },
  { name: "TrendingUp", component: TrendingUp },
  { name: "Truck", component: Truck },
  { name: "Tv", component: Tv },
  { name: "UserCheck", component: UserCheck },
  { name: "Wifi", component: Wifi },
  { name: "Zap", component: Zap },
];

const availableColors = [
  { name: "Blue", value: "bg-blue-500" },
  { name: "Purple", value: "bg-purple-500" },
  { name: "Green", value: "bg-green-500" },
  { name: "Red", value: "bg-red-500" },
  { name: "Teal", value: "bg-teal-500" },
  { name: "Orange", value: "bg-orange-500" },
  { name: "Pink", value: "bg-pink-500" },
  { name: "Indigo", value: "bg-indigo-500" },
  { name: "Cyan", value: "bg-cyan-500" },
  { name: "Amber", value: "bg-amber-500" },
];

function getIconComponent(iconName: string) {
  return availableIcons.find((i) => i.name === iconName)?.component ?? Database;
}

function mapRole(r: Role): RoleMapped {
  const sensitivity = (r.SensitivityLevel ?? "standard").toLowerCase();
  const isSensitive = sensitivity === "sensitive";
  const permissionNames = typeof r.PermissionNames === "string" && r.PermissionNames.length > 0
    ? r.PermissionNames.split("|").filter(Boolean)
    : [];
  return {
    id: r.RoleId,
    name: r.RoleName,
    description: r.RoleDescription ?? ((r.Description as string) ?? ""),
    enabled: r.IsEnabled,
    type: isSensitive ? "Sensitive" : "Standard",
    users: r.ConnectedUserCount ?? 0,
    permissions: permissionNames,
    iconName: r.IconName || (isSensitive ? "Shield" : "Database"),
    color: r.IconColor || (isSensitive ? "bg-red-500" : "bg-blue-500"),
    isSensitive,
  };
}

// ─── Component ────────────────────────────────────────────────────────────────

export function ManageRoles() {
  const [roles, setRoles] = useState<RoleMapped[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");

  // Modal visibility
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [createEditModalOpen, setCreateEditModalOpen] = useState(false);
  const [viewUsersModalOpen, setViewUsersModalOpen] = useState(false);
  const [editPermissionsModalOpen, setEditPermissionsModalOpen] = useState(false);
  const [editEligibilityRulesModalOpen, setEditEligibilityRulesModalOpen] = useState(false);

  const [selectedRole, setSelectedRole] = useState<RoleMapped | null>(null);
  const [isEditMode, setIsEditMode] = useState(false);

  // View Users modal
  const [viewUsersData, setViewUsersData] = useState<RoleUser[]>([]);
  const [userSearchQuery, setUserSearchQuery] = useState("");
  const [showOnlyActiveUsers, setShowOnlyActiveUsers] = useState(false);

  // Create / Edit form
  const [formData, setFormData] = useState<{
    name: string;
    description: string;
    type: "Public" | "Standard" | "Sensitive";
    icon: string;
    iconColor: string;
  }>({ name: "", description: "", type: "Standard", icon: "Database", iconColor: "bg-blue-500" });
  const [iconSearchQuery, setIconSearchQuery] = useState("");

  // Permissions dual-listbox
  const [allDbRoles, setAllDbRoles] = useState<DbRole[]>([]);
  const [availableDatabaseRoles, setAvailableDatabaseRoles] = useState<string[]>([]);
  const [selectedDatabaseRoles, setSelectedDatabaseRoles] = useState<string[]>([]);
  const [selectedAvailableItems, setSelectedAvailableItems] = useState<string[]>([]);
  const [selectedAssignedItems, setSelectedAssignedItems] = useState<string[]>([]);
  const [databaseRoleSearchQuery, setDatabaseRoleSearchQuery] = useState("");

  // Eligibility rules
  const [eligibilityRules, setEligibilityRules] = useState<EligibilityRule[]>([]);
  const [selectedRuleId, setSelectedRuleId] = useState<string | null>(null);
  const [isAddingRule, setIsAddingRule] = useState(false);
  const [newRuleType, setNewRuleType] = useState<"User" | "Team" | "Division" | "Department">("Department");
  const [newRuleValue, setNewRuleValue] = useState("");
  const [newRuleDisplayName, setNewRuleDisplayName] = useState("");
  const [ruleSearchQuery, setRuleSearchQuery] = useState("");
  const [isRuleDropdownOpen, setIsRuleDropdownOpen] = useState(false);
  const [newRuleConfig, setNewRuleConfig] = useState({
    maxDuration: 90,
    requiresJustification: true,
    requiresApproval: true,
    minimumSeniorityLevel: 1,
  });

  // Lookup data for eligibility rule dropdowns
  const [lookupData, setLookupData] = useState<{
    users: { id: string; name: string }[];
    teams: { id: string; name: string }[];
    divisions: { id: string; name: string }[];
    departments: { id: string; name: string }[];
  }>({ users: [], teams: [], divisions: [], departments: [] });

  // ── Load roles ──────────────────────────────────────────────────────────────
  const loadRoles = () => {
    setIsLoading(true);
    fetchAdminRoles()
      .then((data) => setRoles(data.map(mapRole)))
      .catch(console.error)
      .finally(() => setIsLoading(false));
  };

  useEffect(() => {
    loadRoles();
  }, []);

  // ── Handlers ────────────────────────────────────────────────────────────────
  const handleDeleteClick = (role: RoleMapped) => {
    setSelectedRole(role);
    setDeleteModalOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!selectedRole) return;
    try {
      await deleteRole(selectedRole.id);
      setDeleteModalOpen(false);
      setSelectedRole(null);
      loadRoles();
    } catch (err: unknown) {
      alert(`Delete failed: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const handleEditClick = (role: RoleMapped) => {
    setSelectedRole(role);
    setIsEditMode(true);
    setFormData({
      name: role.name,
      description: role.description,
      type: role.type,
      icon: role.iconName,
      iconColor: role.color,
    });
    setIconSearchQuery("");
    setCreateEditModalOpen(true);
  };

  const handleCreateClick = () => {
    setSelectedRole(null);
    setIsEditMode(false);
    setFormData({ name: "", description: "", type: "Standard", icon: "Database", iconColor: "bg-blue-500" });
    setEligibilityRules([]);
    setIconSearchQuery("");
    setCreateEditModalOpen(true);
  };

  const handleSaveRole = async () => {
    try {
      const payload = {
        roleName: formData.name,
        description: formData.description,
        sensitivityLevel: formData.type,
        iconName: formData.icon,
        iconColor: formData.iconColor,
      };
      if (isEditMode && selectedRole) {
        await updateRole(selectedRole.id, payload);
      } else {
        await createRole(payload);
      }
      setCreateEditModalOpen(false);
      loadRoles();
    } catch (err: unknown) {
      alert(`Save failed: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const handleToggleRoleStatus = async (role: RoleMapped) => {
    try {
      await toggleRole(role.id, !role.enabled);
      loadRoles();
    } catch (err: unknown) {
      alert(`Toggle failed: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const handleViewUsers = async (role: RoleMapped) => {
    setSelectedRole(role);
    setUserSearchQuery("");
    setShowOnlyActiveUsers(false);
    setViewUsersModalOpen(true);
    try {
      const users = await fetchRoleUsers(role.id);
      setViewUsersData(
        users.map((u: ApiRoleUser) => ({
          id: u.UserId,
          name: u.DisplayName,
          email: u.Email ?? "",
          department: u.Department ?? "",
          hasActiveRole: u.HasActiveRole,
          grantedDate: u.GrantedDateUtc ?? undefined,
          expiryDate: u.ExpiryDateUtc ?? undefined,
        }))
      );
    } catch {
      setViewUsersData([]);
    }
  };

  const handleEditPermissions = async (role: RoleMapped) => {
    setSelectedRole(role);
    setSelectedAvailableItems([]);
    setSelectedAssignedItems([]);
    setDatabaseRoleSearchQuery("");
    setEditPermissionsModalOpen(true);

    try {
      const [allDb, assigned] = await Promise.all([fetchDbRoles(), fetchRoleDbRoles(role.id)]);
      setAllDbRoles(allDb);
      const assignedNames = assigned.map((d: DbRole) => d.DbRoleName);
      setSelectedDatabaseRoles(assignedNames);
      setAvailableDatabaseRoles(allDb.map((d) => d.DbRoleName).filter((n) => !assignedNames.includes(n)));
    } catch {
      setAvailableDatabaseRoles([]);
      setSelectedDatabaseRoles([]);
    }
  };

  const handleSavePermissions = async () => {
    if (!selectedRole) return;
    try {
      const assignedIds = allDbRoles
        .filter((d) => selectedDatabaseRoles.includes(d.DbRoleName))
        .map((d) => d.DbRoleId);
      await setRoleDbRoles(selectedRole.id, assignedIds);
      loadRoles();
      setEditPermissionsModalOpen(false);
    } catch (err: unknown) {
      alert(`Save failed: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const handleEditEligibilityRules = async (role: RoleMapped) => {
    setSelectedRole(role);
    setSelectedRuleId(null);
    setIsAddingRule(false);
    setEditEligibilityRulesModalOpen(true);
    try {
      const [rawRules, rawLookups] = await Promise.all([
        fetchRoleEligibilityRules(role.id),
        fetchAdminLookups(),
      ]);

      const grouped: typeof lookupData = { users: [], teams: [], divisions: [], departments: [] };
      const seen: Record<string, Set<string>> = { users: new Set(), teams: new Set(), divisions: new Set(), departments: new Set() };
      for (const row of rawLookups as LookupRow[]) {
        const key = row.LookupType as keyof typeof grouped;
        if (grouped[key] && !seen[key].has(row.LookupValue)) {
          seen[key].add(row.LookupValue);
          grouped[key].push({ id: String(row.LookupValue), name: row.LookupLabel });
        }
      }
      setLookupData(grouped);

      const scopeToLookupKey: Record<string, keyof typeof grouped> = {
        User: "users", Team: "teams", Division: "divisions", Department: "departments",
      };

      setEligibilityRules(
        (rawRules as Record<string, unknown>[]).map((r, i) => {
          const scopeType = (r.ScopeType as string) ?? "Department";
          const scopeValue = r.ScopeValue != null ? String(r.ScopeValue) : "";
          const lookupArr = grouped[scopeToLookupKey[scopeType]] ?? [];
          const match = lookupArr.find((l) => l.id === scopeValue);
          return {
            id: r.EligibilityRuleId != null ? String(r.EligibilityRuleId) : String(i),
            type: scopeType as EligibilityRule["type"],
            value: scopeValue,
            displayName: match?.name ?? scopeValue,
            maxDuration: Math.round(((r.MaxDurationMinutes as number) ?? 1440) / 1440),
            requiresJustification: (r.RequiresJustification as boolean) ?? true,
            requiresApproval: (r.RequiresApproval as boolean) ?? true,
            minimumSeniorityLevel: (r.MinSeniorityLevel as number) ?? 1,
          };
        })
      );
    } catch {
      setEligibilityRules([]);
    }
  };

  const handleSelectRuleOption = (id: string, name: string) => {
    setNewRuleValue(id);
    setNewRuleDisplayName(name);
    setRuleSearchQuery(name);
    setIsRuleDropdownOpen(false);
  };

  const handleSaveEligibilityRules = async () => {
    if (!selectedRole) return;
    try {
      const payload = eligibilityRules.map((r) => ({
        scopeType: r.type,
        scopeValue: r.value || null,
        canRequest: true,
        priority: 0,
        minSeniorityLevel: r.minimumSeniorityLevel,
        maxDurationMinutes: r.maxDuration * 1440,
        requiresJustification: r.requiresJustification,
        requiresApproval: r.requiresApproval,
      }));
      await setRoleEligibilityRules(selectedRole.id, payload);
      setEditEligibilityRulesModalOpen(false);
    } catch (err: unknown) {
      alert(`Save failed: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const handleRemoveEligibilityRule = (ruleId: string) => {
    setEligibilityRules(eligibilityRules.filter((r) => r.id !== ruleId));
  };

  // ── Filter / sort ────────────────────────────────────────────────────────────
  const filteredRoles = roles
    .filter((role) => {
      const s = searchQuery.toLowerCase();
      return (
        role.name.toLowerCase().includes(s) ||
        role.description.toLowerCase().includes(s) ||
        role.type.toLowerCase().includes(s)
      );
    })
    .sort((a, b) => a.name.localeCompare(b.name));

  if (isLoading) {
    return <div className="p-8 text-sm text-muted-foreground">Loading roles...</div>;
  }

  return (
    <div className="space-y-6">
      {/* Header Actions */}
      <div className="flex items-center justify-between gap-3">
        <div className="relative max-w-md flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search roles by name, description, or permissions..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full rounded-lg border border-input bg-input-background py-2 pl-10 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </div>
        <button
          onClick={handleCreateClick}
          className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90"
        >
          <Plus className="h-4 w-4" />
          Create New Role
        </button>
      </div>

      {/* Roles Grid */}
      <div className="grid gap-4 md:grid-cols-2">
        {filteredRoles.map((role) => {
          const Icon = getIconComponent(role.iconName);
          return (
            <div key={role.id} className="rounded-lg border border-border bg-card p-5">
              <div className="flex items-start justify-between">
                <div className="flex gap-3 flex-1">
                  <div className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-lg ${role.color}`}>
                    <Icon className="h-6 w-6 text-white" />
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h3 className="text-card-foreground">{role.name}</h3>
                      <span
                        className={`rounded-full px-2 py-0.5 text-xs ${
                          role.isSensitive
                            ? "bg-red-500/10 text-red-600 dark:text-red-400"
                            : "bg-blue-500/10 text-blue-600 dark:text-blue-400"
                        }`}
                      >
                        {role.type}
                      </span>
                      {/* Enable/Disable Toggle */}
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          handleToggleRoleStatus(role);
                        }}
                        className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors ${
                          role.enabled ? "bg-green-500" : "bg-gray-300 dark:bg-gray-600"
                        }`}
                        title={role.enabled ? "Disable role" : "Enable role"}
                      >
                        <span
                          className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                            role.enabled ? "translate-x-4" : "translate-x-0.5"
                          }`}
                        />
                      </button>
                      <span className={`text-xs ${role.enabled ? "text-green-600 dark:text-green-400" : "text-muted-foreground"}`}>
                        {role.enabled ? "Enabled" : "Disabled"}
                      </span>
                    </div>
                    <p className="text-sm text-muted-foreground">{role.description}</p>
                    <div className="mt-2 flex flex-wrap gap-2 text-xs text-muted-foreground">
                      <span>{role.users} connected users</span>
                      <span>|</span>
                      <span>{role.permissions.length} permissions</span>
                    </div>
                  </div>
                </div>
                <div className="flex gap-1">
                  <button
                    onClick={() => handleEditClick(role)}
                    className="rounded-lg p-2 hover:bg-secondary"
                    title="Edit role"
                  >
                    <Edit className="h-4 w-4 text-muted-foreground" />
                  </button>
                  <button
                    onClick={() => handleDeleteClick(role)}
                    className="rounded-lg p-2 hover:bg-destructive/10"
                    title="Delete role"
                  >
                    <Trash2 className="h-4 w-4 text-destructive" />
                  </button>
                </div>
              </div>

              {role.permissions.length > 0 && (
                <div className="mt-4">
                  <p className="text-xs text-muted-foreground">Permissions:</p>
                  <div className="mt-2 flex flex-wrap gap-1">
                    {role.permissions.map((p, idx) => (
                      <span key={idx} className="rounded-full bg-secondary px-2 py-1 text-xs text-secondary-foreground">
                        {p}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              <div className="mt-4 flex gap-3 border-t border-border pt-4">
                <button onClick={() => handleViewUsers(role)} className="text-sm text-primary hover:underline">
                  View Users ({role.users})
                </button>
                <button onClick={() => handleEditPermissions(role)} className="text-sm text-primary hover:underline">
                  Edit Permissions
                </button>
                <button onClick={() => handleEditEligibilityRules(role)} className="text-sm text-primary hover:underline">
                  Edit Eligibility Rules
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {filteredRoles.length === 0 && (
        <div className="rounded-lg border border-border bg-card p-8 text-center">
          <p className="text-muted-foreground">No roles found matching your search criteria.</p>
        </div>
      )}

      {/* ── Delete Confirmation Modal ──────────────────────────────────────────── */}
      {deleteModalOpen && selectedRole && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md rounded-lg border border-border bg-card p-6 shadow-lg">
            <h3 className="text-lg text-card-foreground">Delete Role</h3>
            <p className="mt-2 text-sm text-muted-foreground">
              Are you sure you want to delete the role{" "}
              <span className="font-medium text-card-foreground">"{selectedRole.name}"</span>?
            </p>
            <p className="mt-2 text-sm text-destructive">This action cannot be undone.</p>
            <div className="mt-6 flex justify-end gap-3">
              <button
                onClick={() => { setDeleteModalOpen(false); setSelectedRole(null); }}
                className="rounded-lg border border-border bg-card px-4 py-2 text-sm text-foreground hover:bg-secondary"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmDelete}
                className="rounded-lg bg-destructive px-4 py-2 text-sm text-destructive-foreground hover:bg-destructive/90"
              >
                Delete Role
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Create / Edit Role Modal ───────────────────────────────────────────── */}
      {createEditModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-xl rounded-lg border border-border bg-card p-6 shadow-lg max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between">
              <h3 className="text-lg text-card-foreground">
                {isEditMode ? "Edit Role" : "Create New Role"}
              </h3>
              <button onClick={() => setCreateEditModalOpen(false)} className="rounded-lg p-1 hover:bg-secondary">
                <X className="h-5 w-5 text-muted-foreground" />
              </button>
            </div>

            <div className="mt-4 space-y-4">
              {/* Name and Role Type */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm text-card-foreground">
                    Role Name <span className="text-destructive">*</span>
                  </label>
                  <input
                    type="text"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    placeholder="Enter role name"
                    className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
                <div>
                  <label className="text-sm text-card-foreground">
                    Role Type <span className="text-destructive">*</span>
                  </label>
                  <select
                    value={formData.type}
                    onChange={(e) => setFormData({ ...formData, type: e.target.value as "Public" | "Standard" | "Sensitive" })}
                    className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  >
                    <option value="Public">Public</option>
                    <option value="Standard">Standard</option>
                    <option value="Sensitive">Sensitive</option>
                  </select>
                </div>
              </div>

              {/* Description */}
              <div>
                <label className="text-sm text-card-foreground">
                  Description <span className="text-destructive">*</span>
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="Describe what this role provides access to"
                  rows={2}
                  className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>

              {/* Icon Selection */}
              <div>
                <label className="text-sm text-card-foreground">
                  Icon <span className="text-destructive">*</span>
                </label>
                <div className="relative mt-1">
                  <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <input
                    type="text"
                    value={iconSearchQuery}
                    onChange={(e) => setIconSearchQuery(e.target.value)}
                    placeholder="Search icons..."
                    className="w-full rounded-lg border border-input bg-input-background py-2 pl-10 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
                <div className="mt-2 max-h-48 overflow-y-auto rounded-lg border border-border bg-secondary/30 p-2">
                  {(() => {
                    const filtered = availableIcons.filter((ico) =>
                      ico.name.toLowerCase().includes(iconSearchQuery.toLowerCase())
                    );
                    if (filtered.length === 0) {
                      return (
                        <p className="text-center text-sm text-muted-foreground py-4">
                          No icons found matching "{iconSearchQuery}"
                        </p>
                      );
                    }
                    return (
                      <div className="grid grid-cols-8 gap-2">
                        {filtered.map((ico) => {
                          const Ic = ico.component;
                          return (
                            <button
                              key={ico.name}
                              type="button"
                              onClick={() => { setFormData({ ...formData, icon: ico.name }); setIconSearchQuery(""); }}
                              className={`flex h-10 w-10 items-center justify-center rounded-lg border-2 transition-colors ${
                                formData.icon === ico.name
                                  ? "border-primary bg-primary/10"
                                  : "border-border bg-card hover:border-primary/50 hover:bg-secondary"
                              }`}
                              title={ico.name}
                            >
                              <Ic className={`h-5 w-5 ${formData.icon === ico.name ? "text-primary" : "text-muted-foreground"}`} />
                            </button>
                          );
                        })}
                      </div>
                    );
                  })()}
                </div>
              </div>

              {/* Color Selection */}
              <div>
                <label className="text-sm text-card-foreground">
                  Color <span className="text-destructive">*</span>
                </label>
                <div className="mt-2 grid grid-cols-10 gap-2">
                  {availableColors.map((c) => (
                    <button
                      key={c.value}
                      type="button"
                      onClick={() => setFormData({ ...formData, iconColor: c.value })}
                      className={`flex h-10 w-10 items-center justify-center rounded-lg border-2 transition-colors ${
                        formData.iconColor === c.value ? "border-card-foreground" : "border-transparent hover:border-border"
                      }`}
                      title={c.name}
                    >
                      <div className={`h-6 w-6 rounded ${c.value}`}></div>
                    </button>
                  ))}
                </div>
              </div>

              {/* Preview */}
              <div className="rounded-lg border border-border bg-secondary/30 p-3">
                <p className="text-xs text-muted-foreground mb-2">Preview</p>
                <div className="flex items-center gap-3">
                  <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-lg ${formData.iconColor}`}>
                    {(() => { const Ic = getIconComponent(formData.icon); return <Ic className="h-5 w-5 text-white" />; })()}
                  </div>
                  <div>
                    <p className="text-sm text-card-foreground">{formData.name || "Role Name"}</p>
                    <p className="text-xs text-muted-foreground">{formData.description || "Role description will appear here"}</p>
                  </div>
                </div>
              </div>
            </div>

            <div className="mt-6 flex justify-end gap-3">
              <button
                onClick={() => setCreateEditModalOpen(false)}
                className="rounded-lg border border-border bg-card px-4 py-2 text-sm text-foreground hover:bg-secondary"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveRole}
                disabled={!formData.name || !formData.description}
                className="rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isEditMode ? "Save Changes" : "Create Role"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── View Users Modal ───────────────────────────────────────────────────── */}
      {viewUsersModalOpen && selectedRole && (() => {
        const filtered = viewUsersData.filter((u) => {
          const s = userSearchQuery.toLowerCase();
          const matchesSearch =
            u.name.toLowerCase().includes(s) ||
            u.email.toLowerCase().includes(s) ||
            u.department.toLowerCase().includes(s);
          return matchesSearch && (showOnlyActiveUsers ? u.hasActiveRole : true);
        });
        const activeCount = viewUsersData.filter((u) => u.hasActiveRole).length;

        return (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
            <div className="w-full max-w-3xl rounded-lg border border-border bg-card p-6 shadow-lg max-h-[90vh] flex flex-col">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-lg text-card-foreground">Users for Role: {selectedRole.name}</h3>
                  <p className="text-sm text-muted-foreground">
                    {activeCount} active / {viewUsersData.length} eligible users
                  </p>
                </div>
                <button onClick={() => setViewUsersModalOpen(false)} className="rounded-lg p-1 hover:bg-secondary">
                  <X className="h-5 w-5 text-muted-foreground" />
                </button>
              </div>

              <div className="mt-4 space-y-3">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <input
                    type="text"
                    placeholder="Search by name, email, or department..."
                    value={userSearchQuery}
                    onChange={(e) => setUserSearchQuery(e.target.value)}
                    className="w-full rounded-lg border border-input bg-input-background py-2 pl-10 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
                <div className="flex items-center gap-4">
                  <label className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      checked={showOnlyActiveUsers}
                      onChange={(e) => setShowOnlyActiveUsers(e.target.checked)}
                      className="h-4 w-4 rounded border-input"
                    />
                    <span className="text-sm text-card-foreground">Show only users with active role</span>
                  </label>
                  <span className="text-xs text-muted-foreground">
                    ({filtered.length} {filtered.length === 1 ? "user" : "users"})
                  </span>
                </div>
              </div>

              <div className="mt-4 flex-1 overflow-y-auto">
                {filtered.length > 0 ? (
                  <div className="divide-y divide-border rounded-lg border border-border">
                    {filtered.map((user) => (
                      <div key={user.id} className="p-4">
                        <div className="flex items-start justify-between">
                          <div className="flex items-start gap-3">
                            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary text-xs text-primary-foreground">
                              {user.name.split(" ").map((n) => n[0]).join("")}
                            </div>
                            <div>
                              <div className="flex items-center gap-2">
                                <h4 className="text-sm text-card-foreground">{user.name}</h4>
                                {user.hasActiveRole ? (
                                  <span className="rounded-full bg-green-500/10 px-2 py-0.5 text-xs text-green-600 dark:text-green-400">
                                    Active
                                  </span>
                                ) : (
                                  <span className="rounded-full bg-secondary px-2 py-0.5 text-xs text-muted-foreground">
                                    Eligible
                                  </span>
                                )}
                              </div>
                              <p className="text-xs text-muted-foreground">{user.email}</p>
                              <p className="text-xs text-muted-foreground">{user.department}</p>
                            </div>
                          </div>
                          {user.hasActiveRole && user.grantedDate && (
                            <div className="text-right">
                              <p className="text-xs text-muted-foreground">Granted: {user.grantedDate}</p>
                              {user.expiryDate && (
                                <p className="text-xs text-muted-foreground">Expires: {user.expiryDate}</p>
                              )}
                            </div>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="rounded-lg border border-border bg-card p-8 text-center">
                    <p className="text-muted-foreground">No users found matching your criteria.</p>
                  </div>
                )}
              </div>

              <div className="mt-6 flex justify-end border-t border-border pt-4">
                <button
                  onClick={() => setViewUsersModalOpen(false)}
                  className="rounded-lg border border-border bg-card px-4 py-2 text-sm text-foreground hover:bg-secondary"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        );
      })()}

      {/* ── Edit Permissions Modal ─────────────────────────────────────────────── */}
      {editPermissionsModalOpen && selectedRole && (() => {
        const filteredAvailable = availableDatabaseRoles.filter((r) =>
          r.toLowerCase().includes(databaseRoleSearchQuery.toLowerCase())
        );

        const moveToSelected = () => {
          setSelectedDatabaseRoles([...selectedDatabaseRoles, ...selectedAvailableItems].sort());
          setAvailableDatabaseRoles(availableDatabaseRoles.filter((r) => !selectedAvailableItems.includes(r)));
          setSelectedAvailableItems([]);
        };
        const moveAllToSelected = () => {
          setSelectedDatabaseRoles([...selectedDatabaseRoles, ...availableDatabaseRoles].sort());
          setAvailableDatabaseRoles([]);
          setSelectedAvailableItems([]);
        };
        const moveToAvailable = () => {
          setAvailableDatabaseRoles([...availableDatabaseRoles, ...selectedAssignedItems].sort());
          setSelectedDatabaseRoles(selectedDatabaseRoles.filter((r) => !selectedAssignedItems.includes(r)));
          setSelectedAssignedItems([]);
        };
        const moveAllToAvailable = () => {
          setAvailableDatabaseRoles([...availableDatabaseRoles, ...selectedDatabaseRoles].sort());
          setSelectedDatabaseRoles([]);
          setSelectedAssignedItems([]);
        };

        return (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
            <div className="w-full max-w-5xl rounded-lg border border-border bg-card p-6 shadow-lg max-h-[90vh] overflow-hidden flex flex-col">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h3 className="text-lg text-card-foreground">Edit Permissions: {selectedRole.name}</h3>
                  <p className="text-sm text-muted-foreground">Select database roles to assign to this IAM role</p>
                </div>
                <button onClick={() => setEditPermissionsModalOpen(false)} className="rounded-lg p-1 hover:bg-secondary">
                  <X className="h-5 w-5 text-muted-foreground" />
                </button>
              </div>

              <div className="grid grid-cols-5 gap-4 flex-1 overflow-hidden">
                {/* Available */}
                <div className="col-span-2 flex flex-col border border-border rounded-lg overflow-hidden">
                  <div className="p-3 border-b border-border bg-secondary/30">
                    <label className="text-sm font-medium text-card-foreground">
                      Available Database Roles ({filteredAvailable.length})
                    </label>
                    <div className="mt-2 relative">
                      <Search className="absolute left-2 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                      <input
                        type="text"
                        value={databaseRoleSearchQuery}
                        onChange={(e) => setDatabaseRoleSearchQuery(e.target.value)}
                        placeholder="Search database roles..."
                        className="w-full pl-8 pr-3 py-1.5 rounded-lg border border-input bg-input-background text-sm text-foreground placeholder:text-muted-foreground"
                      />
                    </div>
                  </div>
                  <div className="flex-1 overflow-y-auto p-2 space-y-1">
                    {filteredAvailable.map((r) => (
                      <div
                        key={r}
                        onClick={() => {
                          setSelectedAvailableItems((prev) =>
                            prev.includes(r) ? prev.filter((x) => x !== r) : [...prev, r]
                          );
                        }}
                        className={`cursor-pointer rounded px-3 py-2 text-sm transition-colors ${
                          selectedAvailableItems.includes(r)
                            ? "bg-primary text-primary-foreground"
                            : "hover:bg-secondary/50 text-card-foreground"
                        }`}
                      >
                        {r}
                      </div>
                    ))}
                    {filteredAvailable.length === 0 && (
                      <p className="text-sm text-muted-foreground text-center py-4">
                        {databaseRoleSearchQuery ? "No roles found" : "All roles assigned"}
                      </p>
                    )}
                  </div>
                </div>

                {/* Buttons */}
                <div className="col-span-1 flex flex-col items-center justify-center gap-2">
                  <button onClick={moveToSelected} disabled={selectedAvailableItems.length === 0}
                    className="rounded-lg bg-primary px-3 py-2 text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed">
                    <ChevronRight className="h-5 w-5" />
                  </button>
                  <button onClick={moveAllToSelected} disabled={availableDatabaseRoles.length === 0}
                    className="rounded-lg bg-primary px-3 py-2 text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed">
                    <ChevronsRight className="h-5 w-5" />
                  </button>
                  <button onClick={moveToAvailable} disabled={selectedAssignedItems.length === 0}
                    className="rounded-lg bg-primary px-3 py-2 text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed">
                    <ChevronLeft className="h-5 w-5" />
                  </button>
                  <button onClick={moveAllToAvailable} disabled={selectedDatabaseRoles.length === 0}
                    className="rounded-lg bg-primary px-3 py-2 text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed">
                    <ChevronsLeft className="h-5 w-5" />
                  </button>
                </div>

                {/* Assigned */}
                <div className="col-span-2 flex flex-col border border-border rounded-lg overflow-hidden">
                  <div className="p-3 border-b border-border bg-secondary/30">
                    <label className="text-sm font-medium text-card-foreground">
                      Assigned Database Roles ({selectedDatabaseRoles.length})
                    </label>
                  </div>
                  <div className="flex-1 overflow-y-auto p-2 space-y-1">
                    {selectedDatabaseRoles.map((r) => (
                      <div
                        key={r}
                        onClick={() => {
                          setSelectedAssignedItems((prev) =>
                            prev.includes(r) ? prev.filter((x) => x !== r) : [...prev, r]
                          );
                        }}
                        className={`cursor-pointer rounded px-3 py-2 text-sm transition-colors ${
                          selectedAssignedItems.includes(r)
                            ? "bg-primary text-primary-foreground"
                            : "hover:bg-secondary/50 text-card-foreground"
                        }`}
                      >
                        {r}
                      </div>
                    ))}
                    {selectedDatabaseRoles.length === 0 && (
                      <p className="text-sm text-muted-foreground text-center py-4">No roles assigned yet</p>
                    )}
                  </div>
                </div>
              </div>

              <div className="mt-4 flex justify-end gap-3">
                <button onClick={() => setEditPermissionsModalOpen(false)}
                  className="rounded-lg border border-border bg-card px-4 py-2 text-sm text-foreground hover:bg-secondary">
                  Cancel
                </button>
                <button onClick={handleSavePermissions}
                  className="rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90">
                  Save Permissions
                </button>
              </div>
            </div>
          </div>
        );
      })()}

      {/* ── Edit Eligibility Rules Modal ────────────────────────────────────────── */}
      {editEligibilityRulesModalOpen && selectedRole && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-6xl rounded-lg border border-border bg-card p-6 shadow-lg max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-lg text-card-foreground">Edit Eligibility Rules: {selectedRole.name}</h3>
                <p className="text-sm text-muted-foreground">Define who can request this role and their access parameters</p>
              </div>
              <button onClick={() => setEditEligibilityRulesModalOpen(false)} className="rounded-lg p-1 hover:bg-secondary">
                <X className="h-5 w-5 text-muted-foreground" />
              </button>
            </div>

            <div className="grid grid-cols-5 gap-4">
              {/* Left: Rules list */}
              <div className="col-span-2 space-y-2">
                <div className="flex items-center justify-between mb-2">
                  <label className="text-sm text-card-foreground font-medium">
                    Eligibility Rules ({eligibilityRules.length})
                  </label>
                  <button
                    onClick={() => {
                      setIsAddingRule(true);
                      setSelectedRuleId(null);
                      setNewRuleType("Department");
                      setNewRuleValue("");
                      setNewRuleDisplayName("");
                      setRuleSearchQuery("");
                      setNewRuleConfig({ maxDuration: 90, requiresJustification: true, requiresApproval: true, minimumSeniorityLevel: 1 });
                    }}
                    className="rounded-lg bg-primary p-1.5 text-primary-foreground hover:bg-primary/90"
                  >
                    <Plus className="h-4 w-4" />
                  </button>
                </div>
                <div className="space-y-2 max-h-96 overflow-y-auto">
                  {eligibilityRules.map((rule) => (
                    <div
                      key={rule.id}
                      onClick={() => { setSelectedRuleId(rule.id); setIsAddingRule(false); }}
                      className={`cursor-pointer rounded-lg border-2 p-3 transition-colors ${
                        selectedRuleId === rule.id ? "border-primary bg-primary/10" : "border-border bg-card hover:border-primary/50"
                      }`}
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <span className="rounded bg-primary/20 px-2 py-0.5 text-xs text-primary font-medium">{rule.type}</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <p className="text-sm text-card-foreground font-medium truncate">{rule.displayName}</p>
                            <div className="flex flex-wrap gap-1 shrink-0">
                              <span className="text-xs text-muted-foreground">{rule.maxDuration}d</span>
                              <span className="text-xs text-muted-foreground">•</span>
                              <span className="text-xs text-muted-foreground">L{rule.minimumSeniorityLevel}+</span>
                              {rule.requiresJustification && (
                                <><span className="text-xs text-muted-foreground">•</span><span className="rounded bg-blue-500/10 px-1.5 py-0.5 text-xs text-blue-600 dark:text-blue-400">J</span></>
                              )}
                              {rule.requiresApproval && (
                                <><span className="text-xs text-muted-foreground">•</span><span className="rounded bg-amber-500/10 px-1.5 py-0.5 text-xs text-amber-600 dark:text-amber-400">A</span></>
                              )}
                            </div>
                          </div>
                        </div>
                        <button
                          onClick={(e) => { e.stopPropagation(); handleRemoveEligibilityRule(rule.id); }}
                          className="rounded p-1 hover:bg-destructive/10 shrink-0"
                        >
                          <X className="h-3.5 w-3.5 text-destructive" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Right: Rule config */}
              <div className="col-span-3">
                {isAddingRule ? (
                  <div className="rounded-lg border border-border bg-secondary/30 p-4 space-y-4">
                    <div className="flex items-center justify-between">
                      <h4 className="text-sm font-medium text-card-foreground">Add New Rule</h4>
                      <button onClick={() => setIsAddingRule(false)} className="text-xs text-muted-foreground hover:text-foreground">Cancel</button>
                    </div>
                    <div className="space-y-3">
                      <div>
                        <label className="text-xs text-muted-foreground">Rule Type</label>
                        <select
                          value={newRuleType}
                          onChange={(e) => {
                            setNewRuleType(e.target.value as "User" | "Team" | "Division" | "Department");
                            setNewRuleValue(""); setNewRuleDisplayName(""); setRuleSearchQuery("");
                          }}
                          className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm"
                        >
                          <option value="User">Specific User</option>
                          <option value="Team">Team</option>
                          <option value="Division">Division</option>
                          <option value="Department">Department</option>
                        </select>
                      </div>
                      <div className="relative">
                        <label className="text-xs text-muted-foreground">Select {newRuleType}</label>
                        <div className="relative">
                          <input
                            type="text"
                            value={ruleSearchQuery}
                            onChange={(e) => {
                              setRuleSearchQuery(e.target.value);
                              setIsRuleDropdownOpen(true);
                            }}
                            onFocus={() => setIsRuleDropdownOpen(true)}
                            placeholder={`Search ${newRuleType.toLowerCase()}...`}
                            className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 pr-8 text-sm"
                          />
                          <ChevronDown className="absolute right-2 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground pointer-events-none" />
                        </div>

                        {isRuleDropdownOpen && (() => {
                          const typeToKey: Record<string, keyof typeof lookupData> = {
                            User: "users", Team: "teams", Division: "divisions", Department: "departments",
                          };
                          const options = lookupData[typeToKey[newRuleType]] ?? [];
                          const filteredOptions = options.filter((o) =>
                            o.name.toLowerCase().includes(ruleSearchQuery.toLowerCase())
                          );

                          return (
                            <>
                              <div className="fixed inset-0 z-10" onClick={() => setIsRuleDropdownOpen(false)} />
                              <div className="absolute z-20 mt-1 w-full max-h-60 overflow-y-auto rounded-lg border border-border bg-card shadow-lg">
                                {filteredOptions.length > 0 ? (
                                  filteredOptions.map((option) => (
                                    <button
                                      key={option.id}
                                      type="button"
                                      onClick={() => handleSelectRuleOption(option.id, option.name)}
                                      className="w-full px-3 py-2 text-left text-sm text-foreground hover:bg-secondary"
                                    >
                                      {option.name}
                                    </button>
                                  ))
                                ) : (
                                  <div className="px-3 py-2 text-sm text-muted-foreground">
                                    No {newRuleType.toLowerCase()} found
                                  </div>
                                )}
                              </div>
                            </>
                          );
                        })()}
                      </div>
                      <div className="grid grid-cols-2 gap-3">
                        <div>
                          <label className="text-xs text-muted-foreground">Max Duration (days)</label>
                          <input type="number" value={newRuleConfig.maxDuration}
                            onChange={(e) => setNewRuleConfig({ ...newRuleConfig, maxDuration: parseInt(e.target.value) || 0 })}
                            className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm" />
                        </div>
                        <div>
                          <label className="text-xs text-muted-foreground">Min Seniority Level</label>
                          <input type="number" value={newRuleConfig.minimumSeniorityLevel}
                            onChange={(e) => setNewRuleConfig({ ...newRuleConfig, minimumSeniorityLevel: parseInt(e.target.value) || 1 })}
                            className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm" />
                        </div>
                      </div>
                      <div className="space-y-2">
                        <label className="flex items-center gap-2">
                          <input type="checkbox" checked={newRuleConfig.requiresJustification}
                            onChange={(e) => setNewRuleConfig({ ...newRuleConfig, requiresJustification: e.target.checked })}
                            className="h-4 w-4 rounded" />
                          <span className="text-sm text-card-foreground">Requires justification when requesting</span>
                        </label>
                        <label className="flex items-center gap-2">
                          <input type="checkbox" checked={newRuleConfig.requiresApproval}
                            onChange={(e) => setNewRuleConfig({ ...newRuleConfig, requiresApproval: e.target.checked })}
                            className="h-4 w-4 rounded" />
                          <span className="text-sm text-card-foreground">Requires approval from a data steward</span>
                        </label>
                      </div>
                      <button
                        onClick={() => {
                          if (!newRuleDisplayName || !newRuleValue) return;
                          const rule: EligibilityRule = {
                            id: Date.now().toString(),
                            type: newRuleType,
                            value: newRuleValue,
                            displayName: newRuleDisplayName,
                            ...newRuleConfig,
                          };
                          setEligibilityRules([...eligibilityRules, rule]);
                          setIsAddingRule(false);
                          setSelectedRuleId(rule.id);
                        }}
                        disabled={!newRuleDisplayName || !newRuleValue}
                        className="w-full rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        Add Rule
                      </button>
                    </div>
                  </div>
                ) : selectedRuleId && eligibilityRules.find((r) => r.id === selectedRuleId) ? (
                  (() => {
                    const sr = eligibilityRules.find((r) => r.id === selectedRuleId)!;
                    return (
                      <div className="space-y-4">
                        <div className="rounded-lg border border-border bg-card p-4">
                          <div className="flex items-center gap-3 mb-4">
                            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                              <Users className="h-5 w-5 text-primary" />
                            </div>
                            <div>
                              <p className="text-sm font-medium text-card-foreground">{sr.displayName}</p>
                              <p className="text-xs text-muted-foreground">{sr.type}</p>
                            </div>
                          </div>
                          <div className="space-y-3">
                            <div>
                              <label className="text-xs text-muted-foreground">Maximum Duration (days)</label>
                              <input type="number" value={sr.maxDuration}
                                onChange={(e) => setEligibilityRules(eligibilityRules.map((r) => r.id === sr.id ? { ...r, maxDuration: parseInt(e.target.value) || 0 } : r))}
                                className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm text-foreground" />
                              <p className="mt-1 text-xs text-muted-foreground">Users can request access for up to {sr.maxDuration} days</p>
                            </div>
                            <div>
                              <label className="text-xs text-muted-foreground">Minimum Seniority Level</label>
                              <input type="number" value={sr.minimumSeniorityLevel}
                                onChange={(e) => setEligibilityRules(eligibilityRules.map((r) => r.id === sr.id ? { ...r, minimumSeniorityLevel: parseInt(e.target.value) || 1 } : r))}
                                className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm text-foreground" />
                              <p className="mt-1 text-xs text-muted-foreground">Only users at level {sr.minimumSeniorityLevel}+ can request this role</p>
                            </div>
                            <div className="space-y-2 pt-2">
                              <label className="flex items-center gap-2">
                                <input type="checkbox" checked={sr.requiresJustification}
                                  onChange={(e) => setEligibilityRules(eligibilityRules.map((r) => r.id === sr.id ? { ...r, requiresJustification: e.target.checked } : r))}
                                  className="h-4 w-4 rounded" />
                                <span className="text-sm text-card-foreground">Requires justification when requesting</span>
                              </label>
                              <label className="flex items-center gap-2">
                                <input type="checkbox" checked={sr.requiresApproval}
                                  onChange={(e) => setEligibilityRules(eligibilityRules.map((r) => r.id === sr.id ? { ...r, requiresApproval: e.target.checked } : r))}
                                  className="h-4 w-4 rounded" />
                                <span className="text-sm text-card-foreground">Requires approval from a data steward</span>
                              </label>
                            </div>
                          </div>
                        </div>
                        <div className="rounded-lg border border-border bg-secondary/30 p-4">
                          <p className="text-xs text-muted-foreground mb-2">How users will see this:</p>
                          <div className="rounded-lg bg-card border border-border p-3">
                            <p className="text-sm text-card-foreground mb-1">Access Request</p>
                            <p className="text-xs text-muted-foreground mb-2">You're requesting access as part of: <strong>{sr.displayName}</strong></p>
                            <div className="flex gap-2 flex-wrap">
                              <span className="rounded bg-blue-500/10 px-2 py-1 text-xs text-blue-600">Max {sr.maxDuration} days</span>
                              {sr.requiresApproval && <span className="rounded bg-orange-500/10 px-2 py-1 text-xs text-orange-600">Approval Required</span>}
                              {sr.requiresJustification && <span className="rounded bg-purple-500/10 px-2 py-1 text-xs text-purple-600">Justification Required</span>}
                            </div>
                          </div>
                        </div>
                      </div>
                    );
                  })()
                ) : (
                  <div className="flex h-full items-center justify-center rounded-lg border-2 border-dashed border-border bg-secondary/30 p-8">
                    <p className="text-sm text-muted-foreground">Select a rule to edit or add a new one</p>
                  </div>
                )}
              </div>
            </div>

            <div className="mt-6 flex justify-end gap-3 border-t border-border pt-4">
              <button onClick={() => setEditEligibilityRulesModalOpen(false)}
                className="rounded-lg border border-border bg-card px-4 py-2 text-sm text-foreground hover:bg-secondary">
                Cancel
              </button>
              <button onClick={handleSaveEligibilityRules}
                className="rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90">
                Save Eligibility Rules
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

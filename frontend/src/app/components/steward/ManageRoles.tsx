import { useState } from "react";
import { Plus, Edit, Trash2, Database, Globe, Users, Shield, Search, X, ChevronDown, ChevronRight, ChevronLeft, ChevronsRight, ChevronsLeft, Lock, Key, FileText, Briefcase, Settings, Server, Cloud, Package, Folder, BarChart, Layers, Mail, Bell, Calendar, CreditCard, Home, Phone, Camera, Image, Video, Music, Book, BookOpen, Clipboard, Code, Coffee, Cpu, Download, Upload, Filter, Flag, Gift, Heart, Inbox, Link, Map, MessageSquare, Monitor, Smartphone, Tablet, Paperclip, Printer, Radio, Rss, Send, Share2, ShoppingCart, Star, Tag, Target, Trash, TrendingUp, Truck, Tv, UserCheck, Wifi, Zap } from "lucide-react";

interface Role {
  id: string;
  name: string;
  description: string;
  enabled: boolean;
  type: "Public" | "Standard" | "Sensitive";
  users: number;
  permissions: string[];
  icon: typeof Database | typeof Globe | typeof Users | typeof Shield;
  color: string;
  isSensitive: boolean;
}

interface RoleUser {
  id: string;
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

export function ManageRoles() {
  const [searchQuery, setSearchQuery] = useState("");
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [createEditModalOpen, setCreateEditModalOpen] = useState(false);
  const [viewUsersModalOpen, setViewUsersModalOpen] = useState(false);
  const [editPermissionsModalOpen, setEditPermissionsModalOpen] = useState(false);
  const [editEligibilityRulesModalOpen, setEditEligibilityRulesModalOpen] = useState(false);
  const [selectedRole, setSelectedRole] = useState<Role | null>(null);
  const [isEditMode, setIsEditMode] = useState(false);
  
  // View Users modal filters
  const [userSearchQuery, setUserSearchQuery] = useState("");
  const [showOnlyActiveUsers, setShowOnlyActiveUsers] = useState(false);
  
  // Form state for create/edit
  const [formData, setFormData] = useState<{
    name: string;
    description: string;
    type: "Public" | "Standard" | "Sensitive";
    icon: string;
    iconColor: string;
  }>({
    name: "",
    description: "",
    type: "Standard",
    icon: "Database",
    iconColor: "bg-blue-500",
  });

  // Permissions state (dual listbox)
  const [availableDatabaseRoles, setAvailableDatabaseRoles] = useState<string[]>([]);
  const [selectedDatabaseRoles, setSelectedDatabaseRoles] = useState<string[]>([]);
  const [selectedAvailableItems, setSelectedAvailableItems] = useState<string[]>([]);
  const [selectedAssignedItems, setSelectedAssignedItems] = useState<string[]>([]);
  const [databaseRoleSearchQuery, setDatabaseRoleSearchQuery] = useState("");
  
  // Legacy permissions state (kept for backward compatibility)
  const [permissionsList, setPermissionsList] = useState<string[]>([]);
  const [newPermission, setNewPermission] = useState("");

  // Icon search state
  const [iconSearchQuery, setIconSearchQuery] = useState("");

  // Eligibility rules state
  const [eligibilityRules, setEligibilityRules] = useState<EligibilityRule[]>([]);
  const [selectedRuleId, setSelectedRuleId] = useState<string | null>(null);
  const [isAddingRule, setIsAddingRule] = useState(false);
  const [newRuleType, setNewRuleType] = useState<"User" | "Team" | "Division" | "Department">("User");
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

  // Mock data for dropdowns
  const mockUsers = [
    { id: "USR-001", name: "John Smith" },
    { id: "USR-002", name: "Sarah Johnson" },
    { id: "USR-003", name: "Michael Chen" },
    { id: "USR-004", name: "Emily Rodriguez" },
    { id: "USR-005", name: "David Kim" },
  ];

  const mockTeams = [
    { id: "TEAM-001", name: "Finance Team" },
    { id: "TEAM-002", name: "Marketing Team" },
    { id: "TEAM-003", name: "Engineering Team" },
    { id: "TEAM-004", name: "Sales Team" },
  ];

  const mockDivisions = [
    { id: "DIV-001", name: "Corporate" },
    { id: "DIV-002", name: "Operations" },
    { id: "DIV-003", name: "Technology" },
  ];

  const mockDepartments = [
    { id: "DEPT-001", name: "Finance" },
    { id: "DEPT-002", name: "Accounting" },
    { id: "DEPT-003", name: "Marketing" },
    { id: "DEPT-004", name: "Engineering" },
    { id: "DEPT-005", name: "Human Resources" },
  ];

  // Mock database roles (simulating backend API)
  const mockDatabaseRoles = [
    "DB_READ_CUSTOMER_DATA",
    "DB_WRITE_CUSTOMER_DATA",
    "DB_DELETE_CUSTOMER_DATA",
    "DB_READ_FINANCIAL_RECORDS",
    "DB_WRITE_FINANCIAL_RECORDS",
    "DB_READ_EMPLOYEE_DATA",
    "DB_WRITE_EMPLOYEE_DATA",
    "DB_ADMIN_USERS",
    "DB_ADMIN_ROLES",
    "DB_READ_AUDIT_LOGS",
    "DB_WRITE_AUDIT_LOGS",
    "DB_EXECUTE_STORED_PROCEDURES",
    "DB_CREATE_TABLES",
    "DB_ALTER_TABLES",
    "DB_DROP_TABLES",
    "DB_BACKUP_DATABASE",
    "DB_RESTORE_DATABASE",
    "DB_READ_INVENTORY",
    "DB_WRITE_INVENTORY",
    "DB_READ_ORDERS",
    "DB_WRITE_ORDERS",
    "DB_READ_PRODUCTS",
    "DB_WRITE_PRODUCTS",
    "DB_READ_ANALYTICS",
    "DB_EXECUTE_REPORTS",
  ];

  // Available icons for roles
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

  // Available icon colors
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

  const getIconComponent = (iconName: string) => {
    const icon = availableIcons.find(i => i.name === iconName);
    return icon?.component || Database;
  };

  const [roles, setRoles] = useState<Role[]>([
    {
      id: "ROLE-001",
      name: "Finance Database Access",
      description: "Read access to financial data and reports",
      enabled: true,
      type: "Standard",
      users: 45,
      permissions: ["Read Finance Reports", "View Budget Data", "Access Expense Tracking"],
      icon: Database,
      color: "bg-blue-500",
      isSensitive: false,
    },
    {
      id: "ROLE-002",
      name: "Marketing Analytics",
      description: "Access to marketing dashboards and campaign data",
      enabled: true,
      type: "Standard",
      users: 67,
      permissions: ["View Campaign Analytics", "Access Social Media Metrics", "Read ROI Reports"],
      icon: Globe,
      color: "bg-purple-500",
      isSensitive: false,
    },
    {
      id: "ROLE-003",
      name: "HR Systems Access",
      description: "Access to HR management tools and employee data",
      enabled: true,
      type: "Sensitive",
      users: 23,
      permissions: ["View Employee Directory", "Access Time Off System", "Read Performance Reviews", "View Salary Data"],
      icon: Users,
      color: "bg-green-500",
      isSensitive: true,
    },
    {
      id: "ROLE-004",
      name: "Admin Panel - Full Access",
      description: "Complete administrative access for system management",
      enabled: false,
      type: "Sensitive",
      users: 8,
      permissions: ["Full User Management", "System Configuration", "Security Settings", "Audit Log Access"],
      icon: Shield,
      color: "bg-red-500",
      isSensitive: true,
    },
    {
      id: "ROLE-005",
      name: "Customer Support Portal",
      description: "Access to customer support tools and ticketing system",
      enabled: true,
      type: "Standard",
      users: 89,
      permissions: ["View Tickets", "Respond to Customers", "Access Knowledge Base"],
      icon: Users,
      color: "bg-teal-500",
      isSensitive: false,
    },
  ]);

  // Mock users for a role - all users eligible to request this role
  const mockRoleUsers: RoleUser[] = [
    {
      id: "USR-001",
      name: "John Smith",
      email: "john.smith@company.com",
      department: "Finance",
      hasActiveRole: true,
      grantedDate: "2025-12-01",
      expiryDate: "2026-03-01",
    },
    {
      id: "USR-002",
      name: "Sarah Johnson",
      email: "sarah.johnson@company.com",
      department: "Finance",
      hasActiveRole: true,
      grantedDate: "2026-01-15",
      expiryDate: "2026-04-15",
    },
    {
      id: "USR-003",
      name: "Michael Chen",
      email: "michael.chen@company.com",
      department: "Accounting",
      hasActiveRole: true,
      grantedDate: "2025-11-20",
      expiryDate: "2026-02-20",
    },
    {
      id: "USR-004",
      name: "Emily Rodriguez",
      email: "emily.rodriguez@company.com",
      department: "Finance",
      hasActiveRole: false,
    },
    {
      id: "USR-005",
      name: "David Kim",
      email: "david.kim@company.com",
      department: "Accounting",
      hasActiveRole: false,
    },
    {
      id: "USR-006",
      name: "Lisa Anderson",
      email: "lisa.anderson@company.com",
      department: "Finance",
      hasActiveRole: false,
    },
    {
      id: "USR-007",
      name: "James Wilson",
      email: "james.wilson@company.com",
      department: "Treasury",
      hasActiveRole: false,
    },
    {
      id: "USR-008",
      name: "Maria Garcia",
      email: "maria.garcia@company.com",
      department: "Accounting",
      hasActiveRole: false,
    },
  ];

  // Handler functions
  const handleDeleteClick = (role: Role) => {
    setSelectedRole(role);
    setDeleteModalOpen(true);
  };

  const handleConfirmDelete = () => {
    alert(`Role "${selectedRole?.name}" has been deleted`);
    setDeleteModalOpen(false);
    setSelectedRole(null);
  };

  const handleEditClick = (role: Role) => {
    setSelectedRole(role);
    setIsEditMode(true);
    
    // Get icon name from the role's icon component
    const iconName = availableIcons.find(i => i.component === role.icon)?.name || "Database";
    
    setFormData({
      name: role.name,
      description: role.description,
      type: role.type,
      icon: iconName,
      iconColor: role.color,
    });
    setIconSearchQuery("");
    setCreateEditModalOpen(true);
  };

  const handleCreateClick = () => {
    setSelectedRole(null);
    setIsEditMode(false);
    setFormData({
      name: "",
      description: "",
      type: "Standard",
      icon: "Database",
      iconColor: "bg-blue-500",
    });
    setEligibilityRules([]);
    setNewRuleType("User");
    setNewRuleValue("");
    setNewRuleDisplayName("");
    setRuleSearchQuery("");
    setIsRuleDropdownOpen(false);
    setIconSearchQuery("");
    setCreateEditModalOpen(true);
  };

  const handleSaveRole = () => {
    if (isEditMode) {
      alert(`Role "${formData.name}" has been updated with ${eligibilityRules.length} eligibility rules`);
    } else {
      alert(`New role "${formData.name}" has been created with ${eligibilityRules.length} eligibility rules`);
    }
    setCreateEditModalOpen(false);
  };

  const handleAddEligibilityRule = () => {
    if (!newRuleValue) return;

    const ruleId = `RULE-${Date.now()}`;

    const newRule: EligibilityRule = {
      id: ruleId,
      type: newRuleType,
      value: newRuleValue,
      displayName: newRuleDisplayName,
    };

    setEligibilityRules([...eligibilityRules, newRule]);
    setNewRuleValue("");
    setNewRuleDisplayName("");
    setRuleSearchQuery("");
    setIsRuleDropdownOpen(false);
  };

  const handleSelectRuleOption = (id: string, name: string) => {
    setNewRuleValue(id);
    setNewRuleDisplayName(name);
    setRuleSearchQuery(name);
    setIsRuleDropdownOpen(false);
  };

  const handleRemoveEligibilityRule = (ruleId: string) => {
    setEligibilityRules(eligibilityRules.filter(r => r.id !== ruleId));
  };

  const handleViewUsers = (role: Role) => {
    setSelectedRole(role);
    setUserSearchQuery("");
    setShowOnlyActiveUsers(false);
    setViewUsersModalOpen(true);
  };

  const handleEditPermissions = (role: Role) => {
    setSelectedRole(role);
    setPermissionsList([...role.permissions]);
    setNewPermission("");
    
    // Initialize dual listbox
    setSelectedDatabaseRoles([...role.permissions]);
    setAvailableDatabaseRoles(mockDatabaseRoles.filter(dbRole => !role.permissions.includes(dbRole)));
    setSelectedAvailableItems([]);
    setSelectedAssignedItems([]);
    setDatabaseRoleSearchQuery("");
    
    setEditPermissionsModalOpen(true);
  };

  const handleEditEligibilityRules = (role: Role) => {
    setSelectedRole(role);
    // Initialize with mock eligibility rules for demonstration
    setEligibilityRules([
      {
        id: "1",
        type: "Department",
        displayName: "Finance",
        value: "DEPT-001",
        maxDuration: 90,
        requiresJustification: true,
        requiresApproval: true,
        minimumSeniorityLevel: 3,
      },
      {
        id: "2",
        type: "Team",
        displayName: "Finance Team",
        value: "TEAM-001",
        maxDuration: 180,
        requiresJustification: false,
        requiresApproval: false,
        minimumSeniorityLevel: 1,
      },
    ]);
    setEditEligibilityRulesModalOpen(true);
  };

  const handleAddPermission = () => {
    if (newPermission.trim() && !permissionsList.includes(newPermission.trim())) {
      setPermissionsList([...permissionsList, newPermission.trim()]);
      setNewPermission("");
    }
  };

  const handleRemovePermission = (permission: string) => {
    setPermissionsList(permissionsList.filter(p => p !== permission));
  };

  const handleSavePermissions = () => {
    alert(`Permissions for "${selectedRole?.name}" have been updated`);
    setEditPermissionsModalOpen(false);
  };

  const handleToggleRoleStatus = (roleId: string) => {
    setRoles(roles.map(role => 
      role.id === roleId ? { ...role, enabled: !role.enabled } : role
    ));
  };

  // Search and filter logic
  const filteredRoles = roles
    .filter(role => {
      const searchLower = searchQuery.toLowerCase();
      return (
        role.name.toLowerCase().includes(searchLower) ||
        role.description.toLowerCase().includes(searchLower) ||
        role.type.toLowerCase().includes(searchLower) ||
        role.permissions.some(permission => permission.toLowerCase().includes(searchLower))
      );
    })
    .sort((a, b) => a.name.localeCompare(b.name));

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
        {filteredRoles.map((role, i) => {
          const Icon = role.icon;
          return (
            <div key={i} className="rounded-lg border border-border bg-card p-5">
              <div className="flex items-start justify-between">
                <div className="flex gap-3 flex-1">
                  <div className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-lg ${role.color}`}>
                    <Icon className="h-6 w-6 text-white" />
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
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
                          handleToggleRoleStatus(role.id);
                        }}
                        className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors ${
                          role.enabled ? 'bg-green-500' : 'bg-gray-300 dark:bg-gray-600'
                        }`}
                        title={role.enabled ? 'Disable role' : 'Enable role'}
                      >
                        <span
                          className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                            role.enabled ? 'translate-x-4' : 'translate-x-0.5'
                          }`}
                        />
                      </button>
                      <span className={`text-xs ${role.enabled ? 'text-green-600 dark:text-green-400' : 'text-muted-foreground'}`}>
                        {role.enabled ? 'Enabled' : 'Disabled'}
                      </span>
                    </div>
                    <p className="text-sm text-muted-foreground">{role.description}</p>
                    <div className="mt-2 flex flex-wrap gap-2 text-xs text-muted-foreground">
                      <span>{role.users} users</span>
                      <span>•</span>
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

              <div className="mt-4">
                <p className="text-xs text-muted-foreground">Permissions:</p>
                <div className="mt-2 flex flex-wrap gap-1">
                  {role.permissions.map((permission, idx) => (
                    <span
                      key={idx}
                      className="rounded-full bg-secondary px-2 py-1 text-xs text-secondary-foreground"
                    >
                      {permission}
                    </span>
                  ))}
                </div>
              </div>

              <div className="mt-4 flex gap-3 border-t border-border pt-4">
                <button 
                  onClick={() => handleViewUsers(role)}
                  className="text-sm text-primary hover:underline"
                >
                  View Users ({role.users})
                </button>
                <button 
                  onClick={() => handleEditPermissions(role)}
                  className="text-sm text-primary hover:underline"
                >
                  Edit Permissions
                </button>
                <button 
                  onClick={() => handleEditEligibilityRules(role)}
                  className="text-sm text-primary hover:underline"
                >
                  Edit Eligibility Rules
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* No results message */}
      {filteredRoles.length === 0 && (
        <div className="rounded-lg border border-border bg-card p-8 text-center">
          <p className="text-muted-foreground">No roles found matching your search criteria.</p>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {deleteModalOpen && selectedRole && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md rounded-lg border border-border bg-card p-6 shadow-lg">
            <h3 className="text-lg text-card-foreground">Delete Role</h3>
            <p className="mt-2 text-sm text-muted-foreground">
              Are you sure you want to delete the role <span className="font-medium text-card-foreground">"{selectedRole.name}"</span>?
            </p>
            <p className="mt-2 text-sm text-destructive">
              This action cannot be undone. {selectedRole.users} users currently have this role and will lose access.
            </p>

            <div className="mt-6 flex justify-end gap-3">
              <button
                onClick={() => {
                  setDeleteModalOpen(false);
                  setSelectedRole(null);
                }}
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

      {/* Create/Edit Role Modal */}
      {createEditModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-xl rounded-lg border border-border bg-card p-6 shadow-lg max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between">
              <h3 className="text-lg text-card-foreground">
                {isEditMode ? "Edit Role" : "Create New Role"}
              </h3>
              <button
                onClick={() => setCreateEditModalOpen(false)}
                className="rounded-lg p-1 hover:bg-secondary"
              >
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
                    const filteredIcons = availableIcons.filter((iconOption) =>
                      iconOption.name.toLowerCase().includes(iconSearchQuery.toLowerCase())
                    );
                    
                    if (filteredIcons.length === 0) {
                      return (
                        <p className="text-center text-sm text-muted-foreground py-4">
                          No icons found matching "{iconSearchQuery}"
                        </p>
                      );
                    }
                    
                    return (
                      <div className="grid grid-cols-8 gap-2">
                        {filteredIcons.map((iconOption) => {
                          const IconComponent = iconOption.component;
                          return (
                            <button
                              key={iconOption.name}
                              type="button"
                              onClick={() => {
                                setFormData({ ...formData, icon: iconOption.name });
                                setIconSearchQuery("");
                              }}
                              className={`flex h-10 w-10 items-center justify-center rounded-lg border-2 transition-colors ${
                                formData.icon === iconOption.name
                                  ? "border-primary bg-primary/10"
                                  : "border-border bg-card hover:border-primary/50 hover:bg-secondary"
                              }`}
                              title={iconOption.name}
                            >
                              <IconComponent className={`h-5 w-5 ${formData.icon === iconOption.name ? "text-primary" : "text-muted-foreground"}`} />
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
                  {availableColors.map((colorOption) => (
                    <button
                      key={colorOption.value}
                      type="button"
                      onClick={() => setFormData({ ...formData, iconColor: colorOption.value })}
                      className={`flex h-10 w-10 items-center justify-center rounded-lg border-2 transition-colors ${
                        formData.iconColor === colorOption.value
                          ? "border-card-foreground"
                          : "border-transparent hover:border-border"
                      }`}
                      title={colorOption.name}
                    >
                      <div className={`h-6 w-6 rounded ${colorOption.value}`}></div>
                    </button>
                  ))}
                </div>
              </div>

              {/* Icon Preview */}
              <div className="rounded-lg border border-border bg-secondary/30 p-3">
                <p className="text-xs text-muted-foreground mb-2">Preview</p>
                <div className="flex items-center gap-3">
                  <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-lg ${formData.iconColor}`}>
                    {(() => {
                      const SelectedIcon = getIconComponent(formData.icon);
                      return <SelectedIcon className="h-5 w-5 text-white" />;
                    })()}
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

      {/* View Users Modal */}
      {viewUsersModalOpen && selectedRole && (() => {
        // Filter users based on search and active status
        const filteredUsers = mockRoleUsers.filter(user => {
          const matchesSearch = 
            user.name.toLowerCase().includes(userSearchQuery.toLowerCase()) ||
            user.email.toLowerCase().includes(userSearchQuery.toLowerCase()) ||
            user.department.toLowerCase().includes(userSearchQuery.toLowerCase());
          
          const matchesActiveFilter = showOnlyActiveUsers ? user.hasActiveRole : true;
          
          return matchesSearch && matchesActiveFilter;
        });

        const activeUsersCount = mockRoleUsers.filter(u => u.hasActiveRole).length;
        const totalUsersCount = mockRoleUsers.length;

        return (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
            <div className="w-full max-w-3xl rounded-lg border border-border bg-card p-6 shadow-lg max-h-[90vh] flex flex-col">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-lg text-card-foreground">Users for Role: {selectedRole.name}</h3>
                  <p className="text-sm text-muted-foreground">
                    {activeUsersCount} active / {totalUsersCount} eligible users
                  </p>
                </div>
                <button
                  onClick={() => setViewUsersModalOpen(false)}
                  className="rounded-lg p-1 hover:bg-secondary"
                >
                  <X className="h-5 w-5 text-muted-foreground" />
                </button>
              </div>

              {/* Search and Filter */}
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
                    ({filteredUsers.length} {filteredUsers.length === 1 ? 'user' : 'users'})
                  </span>
                </div>
              </div>

              {/* Users List */}
              <div className="mt-4 flex-1 overflow-y-auto">
                {filteredUsers.length > 0 ? (
                  <div className="divide-y divide-border rounded-lg border border-border">
                    {filteredUsers.map((user) => (
                      <div key={user.id} className="p-4">
                        <div className="flex items-start justify-between">
                          <div className="flex items-start gap-3">
                            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary text-xs text-primary-foreground">
                              {user.name.split(" ").map(n => n[0]).join("")}
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
                          {user.hasActiveRole && user.grantedDate && user.expiryDate && (
                            <div className="text-right">
                              <p className="text-xs text-muted-foreground">Granted: {user.grantedDate}</p>
                              <p className="text-xs text-muted-foreground">Expires: {user.expiryDate}</p>
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

      {/* Edit Permissions Modal - Dual Listbox */}
      {editPermissionsModalOpen && selectedRole && (() => {
        const filteredAvailableRoles = availableDatabaseRoles.filter(role =>
          role.toLowerCase().includes(databaseRoleSearchQuery.toLowerCase())
        );

        const moveToSelected = () => {
          const itemsToMove = selectedAvailableItems;
          setSelectedDatabaseRoles([...selectedDatabaseRoles, ...itemsToMove].sort());
          setAvailableDatabaseRoles(availableDatabaseRoles.filter(r => !itemsToMove.includes(r)));
          setSelectedAvailableItems([]);
        };

        const moveAllToSelected = () => {
          setSelectedDatabaseRoles([...selectedDatabaseRoles, ...availableDatabaseRoles].sort());
          setAvailableDatabaseRoles([]);
          setSelectedAvailableItems([]);
        };

        const moveToAvailable = () => {
          const itemsToMove = selectedAssignedItems;
          setAvailableDatabaseRoles([...availableDatabaseRoles, ...itemsToMove].sort());
          setSelectedDatabaseRoles(selectedDatabaseRoles.filter(r => !itemsToMove.includes(r)));
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
                <button
                  onClick={() => setEditPermissionsModalOpen(false)}
                  className="rounded-lg p-1 hover:bg-secondary"
                >
                  <X className="h-5 w-5 text-muted-foreground" />
                </button>
              </div>

              {/* Dual Listbox */}
              <div className="grid grid-cols-5 gap-4 flex-1 overflow-hidden">
                {/* Available Database Roles */}
                <div className="col-span-2 flex flex-col border border-border rounded-lg overflow-hidden">
                  <div className="p-3 border-b border-border bg-secondary/30">
                    <label className="text-sm font-medium text-card-foreground">
                      Available Database Roles ({filteredAvailableRoles.length})
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
                    {filteredAvailableRoles.map((role) => (
                      <div
                        key={role}
                        onClick={() => {
                          if (selectedAvailableItems.includes(role)) {
                            setSelectedAvailableItems(selectedAvailableItems.filter(r => r !== role));
                          } else {
                            setSelectedAvailableItems([...selectedAvailableItems, role]);
                          }
                        }}
                        className={`cursor-pointer rounded px-3 py-2 text-sm transition-colors ${
                          selectedAvailableItems.includes(role)
                            ? "bg-primary text-primary-foreground"
                            : "hover:bg-secondary/50 text-card-foreground"
                        }`}
                      >
                        {role}
                      </div>
                    ))}
                    {filteredAvailableRoles.length === 0 && (
                      <p className="text-sm text-muted-foreground text-center py-4">
                        {databaseRoleSearchQuery ? "No roles found" : "All roles assigned"}
                      </p>
                    )}
                  </div>
                </div>

                {/* Transfer Buttons */}
                <div className="col-span-1 flex flex-col items-center justify-center gap-2">
                  <button
                    onClick={moveToSelected}
                    disabled={selectedAvailableItems.length === 0}
                    className="rounded-lg bg-primary px-3 py-2 text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed"
                    title="Add selected"
                  >
                    <ChevronRight className="h-5 w-5" />
                  </button>
                  <button
                    onClick={moveAllToSelected}
                    disabled={availableDatabaseRoles.length === 0}
                    className="rounded-lg bg-primary px-3 py-2 text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed"
                    title="Add all"
                  >
                    <ChevronsRight className="h-5 w-5" />
                  </button>
                  <button
                    onClick={moveToAvailable}
                    disabled={selectedAssignedItems.length === 0}
                    className="rounded-lg bg-primary px-3 py-2 text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed"
                    title="Remove selected"
                  >
                    <ChevronLeft className="h-5 w-5" />
                  </button>
                  <button
                    onClick={moveAllToAvailable}
                    disabled={selectedDatabaseRoles.length === 0}
                    className="rounded-lg bg-primary px-3 py-2 text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed"
                    title="Remove all"
                  >
                    <ChevronsLeft className="h-5 w-5" />
                  </button>
                </div>

                {/* Selected Database Roles */}
                <div className="col-span-2 flex flex-col border border-border rounded-lg overflow-hidden">
                  <div className="p-3 border-b border-border bg-secondary/30">
                    <label className="text-sm font-medium text-card-foreground">
                      Assigned Database Roles ({selectedDatabaseRoles.length})
                    </label>
                  </div>
                  <div className="flex-1 overflow-y-auto p-2 space-y-1">
                    {selectedDatabaseRoles.map((role) => (
                      <div
                        key={role}
                        onClick={() => {
                          if (selectedAssignedItems.includes(role)) {
                            setSelectedAssignedItems(selectedAssignedItems.filter(r => r !== role));
                          } else {
                            setSelectedAssignedItems([...selectedAssignedItems, role]);
                          }
                        }}
                        className={`cursor-pointer rounded px-3 py-2 text-sm transition-colors ${
                          selectedAssignedItems.includes(role)
                            ? "bg-primary text-primary-foreground"
                            : "hover:bg-secondary/50 text-card-foreground"
                        }`}
                      >
                        {role}
                      </div>
                    ))}
                    {selectedDatabaseRoles.length === 0 && (
                      <p className="text-sm text-muted-foreground text-center py-4">
                        No roles assigned yet
                      </p>
                    )}
                  </div>
                </div>
              </div>

              {/* Footer Buttons */}
              <div className="mt-4 flex justify-end gap-3">
                <button
                  onClick={() => setEditPermissionsModalOpen(false)}
                  className="rounded-lg border border-border bg-card px-4 py-2 text-sm text-foreground hover:bg-secondary"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSavePermissions}
                  className="rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90"
                >
                  Save Permissions
                </button>
              </div>
            </div>
          </div>
        );
      })()}

      {/* Edit Eligibility Rules Modal - Option 2: Side Panel Editor */}
      {editEligibilityRulesModalOpen && selectedRole && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-6xl rounded-lg border border-border bg-card p-6 shadow-lg max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-lg text-card-foreground">Edit Eligibility Rules: {selectedRole.name}</h3>
                <p className="text-sm text-muted-foreground">Define who can request this role and their access parameters</p>
              </div>
              <button
                onClick={() => setEditEligibilityRulesModalOpen(false)}
                className="rounded-lg p-1 hover:bg-secondary"
              >
                <X className="h-5 w-5 text-muted-foreground" />
              </button>
            </div>

            <div className="grid grid-cols-5 gap-4">
              {/* Left Panel: Rules List */}
              <div className="col-span-2 space-y-2">
                <div className="flex items-center justify-between mb-2">
                  <label className="text-sm text-card-foreground font-medium">
                    Eligibility Rules ({eligibilityRules.length})
                  </label>
                  <button
                    onClick={() => {
                      setIsAddingRule(true);
                      setSelectedRuleId(null);
                      setNewRuleType("User");
                      setNewRuleValue("");
                      setNewRuleDisplayName("");
                      setRuleSearchQuery("");
                      setNewRuleConfig({
                        maxDuration: 90,
                        requiresJustification: true,
                        requiresApproval: true,
                        minimumSeniorityLevel: 1,
                      });
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
                      onClick={() => {
                        setSelectedRuleId(rule.id);
                        setIsAddingRule(false);
                      }}
                      className={`cursor-pointer rounded-lg border-2 p-3 transition-colors ${
                        selectedRuleId === rule.id
                          ? "border-primary bg-primary/10"
                          : "border-border bg-card hover:border-primary/50"
                      }`}
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <span className="rounded bg-primary/20 px-2 py-0.5 text-xs text-primary font-medium">
                              {rule.type}
                            </span>
                          </div>
                          <div className="flex items-center gap-2">
                            <p className="text-sm text-card-foreground font-medium truncate">{rule.displayName}</p>
                            <div className="flex flex-wrap gap-1 shrink-0">
                              <span className="text-xs text-muted-foreground">{rule.maxDuration}d</span>
                              <span className="text-xs text-muted-foreground">•</span>
                              <span className="text-xs text-muted-foreground">L{rule.minimumSeniorityLevel}+</span>
                              {rule.requiresJustification && (
                                <>
                                  <span className="text-xs text-muted-foreground">•</span>
                                  <span className="rounded bg-blue-500/10 px-1.5 py-0.5 text-xs text-blue-600 dark:text-blue-400">J</span>
                                </>
                              )}
                              {rule.requiresApproval && (
                                <>
                                  <span className="text-xs text-muted-foreground">•</span>
                                  <span className="rounded bg-amber-500/10 px-1.5 py-0.5 text-xs text-amber-600 dark:text-amber-400">A</span>
                                </>
                              )}
                            </div>
                          </div>
                        </div>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            const updatedRules = eligibilityRules.filter(r => r.id !== rule.id);
                            setEligibilityRules(updatedRules);
                            if (selectedRuleId === rule.id) {
                              setSelectedRuleId(updatedRules[0]?.id || null);
                            }
                          }}
                          className="rounded p-1 hover:bg-destructive/10 shrink-0"
                        >
                          <X className="h-3.5 w-3.5 text-destructive" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Right Panel: Rule Configuration */}
              <div className="col-span-3">
                {isAddingRule ? (
                  <div className="rounded-lg border border-border bg-secondary/30 p-4 space-y-4">
                    <div className="flex items-center justify-between">
                      <h4 className="text-sm font-medium text-card-foreground">Add New Rule</h4>
                      <button
                        onClick={() => setIsAddingRule(false)}
                        className="text-xs text-muted-foreground hover:text-foreground"
                      >
                        Cancel
                      </button>
                    </div>

                    <div className="space-y-3">
                      <div>
                        <label className="text-xs text-muted-foreground">Rule Type</label>
                        <select
                          value={newRuleType}
                          onChange={(e) => {
                            setNewRuleType(e.target.value as "User" | "Team" | "Division" | "Department");
                            setNewRuleValue("");
                            setNewRuleDisplayName("");
                            setRuleSearchQuery("");
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

                        {/* Dropdown List */}
                        {isRuleDropdownOpen && (() => {
                          let options: { id: string; name: string }[] = [];
                          
                          switch (newRuleType) {
                            case "User":
                              options = mockUsers;
                              break;
                            case "Team":
                              options = mockTeams;
                              break;
                            case "Division":
                              options = mockDivisions;
                              break;
                            case "Department":
                              options = mockDepartments;
                              break;
                          }

                          const filteredOptions = options.filter(option =>
                            option.name.toLowerCase().includes(ruleSearchQuery.toLowerCase())
                          );

                          return (
                            <>
                              <div
                                className="fixed inset-0 z-10"
                                onClick={() => setIsRuleDropdownOpen(false)}
                              />
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
                          <input
                            type="number"
                            value={newRuleConfig.maxDuration}
                            onChange={(e) => setNewRuleConfig({ ...newRuleConfig, maxDuration: parseInt(e.target.value) || 0 })}
                            className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm"
                          />
                        </div>
                        <div>
                          <label className="text-xs text-muted-foreground">Min Seniority Level</label>
                          <input
                            type="number"
                            value={newRuleConfig.minimumSeniorityLevel}
                            onChange={(e) => setNewRuleConfig({ ...newRuleConfig, minimumSeniorityLevel: parseInt(e.target.value) || 1 })}
                            className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm"
                          />
                        </div>
                      </div>

                      <div className="space-y-2">
                        <label className="flex items-center gap-2">
                          <input
                            type="checkbox"
                            checked={newRuleConfig.requiresJustification}
                            onChange={(e) => setNewRuleConfig({ ...newRuleConfig, requiresJustification: e.target.checked })}
                            className="h-4 w-4 rounded"
                          />
                          <span className="text-sm text-card-foreground">Requires justification when requesting</span>
                        </label>
                        <label className="flex items-center gap-2">
                          <input
                            type="checkbox"
                            checked={newRuleConfig.requiresApproval}
                            onChange={(e) => setNewRuleConfig({ ...newRuleConfig, requiresApproval: e.target.checked })}
                            className="h-4 w-4 rounded"
                          />
                          <span className="text-sm text-card-foreground">Requires approval from a data steward</span>
                        </label>
                      </div>

                      <button
                        onClick={() => {
                          if (newRuleDisplayName && newRuleValue) {
                            const newRule: EligibilityRule = {
                              id: Date.now().toString(),
                              type: newRuleType,
                              value: newRuleValue,
                              displayName: newRuleDisplayName,
                              ...newRuleConfig,
                            };
                            setEligibilityRules([...eligibilityRules, newRule]);
                            setIsAddingRule(false);
                            setSelectedRuleId(newRule.id);
                          }
                        }}
                        disabled={!newRuleDisplayName || !newRuleValue}
                        className="w-full rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        Add Rule
                      </button>
                    </div>
                  </div>
                ) : selectedRuleId && eligibilityRules.find(r => r.id === selectedRuleId) ? (
                  (() => {
                    const selectedRule = eligibilityRules.find(r => r.id === selectedRuleId)!;
                    return (
                      <div className="space-y-4">
                        <div className="rounded-lg border border-border bg-card p-4 self-start">
                          <div className="flex items-center gap-3 mb-4">
                            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                              <Users className="h-5 w-5 text-primary" />
                            </div>
                            <div>
                              <p className="text-sm font-medium text-card-foreground">{selectedRule.displayName}</p>
                              <p className="text-xs text-muted-foreground">{selectedRule.type}</p>
                            </div>
                          </div>

                          <div className="space-y-3">
                            <div>
                              <label className="text-xs text-muted-foreground">Maximum Duration (days)</label>
                              <input
                                type="number"
                                value={selectedRule.maxDuration}
                                onChange={(e) => {
                                  const updated = eligibilityRules.map(r => 
                                    r.id === selectedRule.id ? { ...r, maxDuration: parseInt(e.target.value) || 0 } : r
                                  );
                                  setEligibilityRules(updated);
                                }}
                                className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm text-foreground"
                              />
                              <p className="mt-1 text-xs text-muted-foreground">
                                Users can request access for up to {selectedRule.maxDuration} days
                              </p>
                            </div>

                            <div>
                              <label className="text-xs text-muted-foreground">Minimum Seniority Level</label>
                              <input
                                type="number"
                                value={selectedRule.minimumSeniorityLevel}
                                onChange={(e) => {
                                  const updated = eligibilityRules.map(r => 
                                    r.id === selectedRule.id ? { ...r, minimumSeniorityLevel: parseInt(e.target.value) || 1 } : r
                                  );
                                  setEligibilityRules(updated);
                                }}
                                className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm text-foreground"
                              />
                              <p className="mt-1 text-xs text-muted-foreground">
                                Only users at level {selectedRule.minimumSeniorityLevel} or higher can request this role
                              </p>
                            </div>

                            <div className="space-y-2 pt-2">
                              <label className="flex items-center gap-2">
                                <input
                                  type="checkbox"
                                  checked={selectedRule.requiresJustification}
                                  onChange={(e) => {
                                    const updated = eligibilityRules.map(r => 
                                      r.id === selectedRule.id ? { ...r, requiresJustification: e.target.checked } : r
                                    );
                                    setEligibilityRules(updated);
                                  }}
                                  className="h-4 w-4 rounded"
                                />
                                <span className="text-sm text-card-foreground">Requires justification when requesting</span>
                              </label>
                              <label className="flex items-center gap-2">
                                <input
                                  type="checkbox"
                                  checked={selectedRule.requiresApproval}
                                  onChange={(e) => {
                                    const updated = eligibilityRules.map(r => 
                                      r.id === selectedRule.id ? { ...r, requiresApproval: e.target.checked } : r
                                    );
                                    setEligibilityRules(updated);
                                  }}
                                  className="h-4 w-4 rounded"
                                />
                                <span className="text-sm text-card-foreground">Requires approval from a data steward</span>
                              </label>
                            </div>
                          </div>
                        </div>

                        {/* Preview Section */}
                        <div className="rounded-lg border border-border bg-secondary/30 p-4">
                          <p className="text-xs text-muted-foreground mb-2">How users will see this:</p>
                          <div className="rounded-lg bg-card border border-border p-3">
                            <p className="text-sm text-card-foreground mb-1">Access Request</p>
                            <p className="text-xs text-muted-foreground mb-2">
                              You're requesting access as part of: <strong>{selectedRule.displayName}</strong>
                            </p>
                            <div className="flex gap-2 flex-wrap">
                              <span className="rounded bg-blue-500/10 px-2 py-1 text-xs text-blue-600">
                                Max {selectedRule.maxDuration} days
                              </span>
                              {selectedRule.requiresApproval && (
                                <span className="rounded bg-orange-500/10 px-2 py-1 text-xs text-orange-600">
                                  Approval Required
                                </span>
                              )}
                              {selectedRule.requiresJustification && (
                                <span className="rounded bg-purple-500/10 px-2 py-1 text-xs text-purple-600">
                                  Justification Required
                                </span>
                              )}
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
              <button
                onClick={() => setEditEligibilityRulesModalOpen(false)}
                className="rounded-lg border border-border bg-card px-4 py-2 text-sm text-foreground hover:bg-secondary"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  // Save eligibility rules (in real app, would make API call)
                  console.log("Saving eligibility rules:", eligibilityRules);
                  setEditEligibilityRulesModalOpen(false);
                }}
                className="rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90"
              >
                Save Eligibility Rules
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

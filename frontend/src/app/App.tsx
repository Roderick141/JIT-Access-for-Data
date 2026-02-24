import { useState } from "react";
import { Moon, Sun, Shield, Users, Key, Activity, FileText, Bell, Search, ChevronDown, ChevronRight, UserCircle, Clock, Send, CheckCircle } from "lucide-react";

// User components
import { UserOverview } from "./components/user/UserOverview";
import { UserRequestAccess } from "./components/user/UserRequestAccess";
import { UserApprovals } from "./components/user/UserApprovals";
import { UserHistory } from "./components/user/UserHistory";

// Steward/Admin components
import { StewardOverview } from "./components/steward/StewardOverview";
import { ManageRoles } from "./components/steward/ManageRoles";
import { ManageTeams } from "./components/steward/ManageTeams";
import { ManageUsers } from "./components/steward/ManageUsers";
import { AuditLogs } from "./components/steward/AuditLogs";

// Shared components for steward/admin "My Access"
import { MyActiveRoles } from "./components/shared/MyActiveRoles";

type UserRole = "user" | "steward" | "admin";

export default function App() {
  const [darkMode, setDarkMode] = useState(false);
  const [activeTab, setActiveTab] = useState("overview");
  const [userRole, setUserRole] = useState<UserRole>("user");
  const [myAccessOpen, setMyAccessOpen] = useState(false);

  // Mock pending approvals count - in real app, this would come from an API
  const pendingApprovalsCount = 3;

  const toggleTheme = () => {
    setDarkMode(!darkMode);
  };

  // Define navigation items based on role
  const getNavigationItems = () => {
    switch (userRole) {
      case "user":
        return [
          { id: "overview", label: "Overview", icon: Activity },
          { id: "request-access", label: "Request Access", icon: Send },
          { id: "approvals", label: "Approvals", icon: CheckCircle },
          { id: "history", label: "History", icon: Clock },
        ];
      case "steward":
      case "admin":
        return [
          { id: "overview", label: "Overview", icon: Activity },
          { 
            id: "my-access", 
            label: "My Access", 
            icon: UserCircle,
            submenu: [
              { id: "my-active-roles", label: "My Active Roles" },
              { id: "my-request-access", label: "Request Access" },
              { id: "my-history", label: "My History" },
            ]
          },
          { id: "approvals", label: "Approvals", icon: CheckCircle },
          { id: "manage-roles", label: "Manage Roles", icon: Key },
          { id: "manage-teams", label: "Manage Teams", icon: Users },
          { id: "manage-users", label: "Manage Users", icon: Users },
          { id: "audit", label: "Audit Logs", icon: FileText },
        ];
      default:
        return [];
    }
  };

  // Reset active tab when role changes
  const handleRoleChange = (role: UserRole) => {
    setUserRole(role);
    setMyAccessOpen(false);
    setActiveTab("overview");
  };

  const getUserRoleDisplay = () => {
    switch (userRole) {
      case "user":
        return { name: "John Doe", initials: "JD", role: "User" };
      case "steward":
        return { name: "Jane Smith", initials: "JS", role: "Data Steward" };
      case "admin":
        return { name: "Admin User", initials: "AD", role: "Administrator" };
    }
  };

  const handleTabClick = (tabId: string) => {
    if (tabId === "my-access") {
      setMyAccessOpen(!myAccessOpen);
    } else {
      setActiveTab(tabId);
      if (!tabId.startsWith("my-")) {
        setMyAccessOpen(false);
      }
    }
  };

  const userDisplay = getUserRoleDisplay();
  const navItems = getNavigationItems();

  return (
    <div className={darkMode ? "dark" : ""}>
      <div className="flex h-screen flex-col overflow-hidden bg-background">
        {/* Header */}
        <header className="flex-shrink-0 border-b border-border bg-card">
          <div className="flex h-16 items-center justify-between px-6">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary">
                <Shield className="h-6 w-6 text-primary-foreground" />
              </div>
              <div>
                <h1 className="text-foreground">SecureAccess IAM</h1>
                <p className="text-xs text-muted-foreground">Identity & Access Management</p>
              </div>
            </div>

            <div className="flex items-center gap-4">
              {/* Search - only for steward and admin */}
              {(userRole === "steward" || userRole === "admin") && (
                <div className="relative hidden md:block">
                  <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <input
                    type="text"
                    placeholder="Search users, roles, teams..."
                    className="w-80 rounded-lg border border-input bg-input-background py-2 pl-10 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
              )}

              {/* Role Switcher (for demo purposes) */}
              <div className="relative">
                <select
                  value={userRole}
                  onChange={(e) => handleRoleChange(e.target.value as UserRole)}
                  className="rounded-lg border border-input bg-input-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                >
                  <option value="user">Switch to User</option>
                  <option value="steward">Switch to Steward</option>
                  <option value="admin">Switch to Admin</option>
                </select>
              </div>

              {/* User Menu */}
              <div className="flex items-center gap-2 rounded-lg px-3 py-2">
                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-xs text-primary-foreground">
                  {userDisplay.initials}
                </div>
                <div className="hidden text-left md:block">
                  <div className="text-sm text-foreground">{userDisplay.name}</div>
                  <div className="text-xs text-muted-foreground">{userDisplay.role}</div>
                </div>
              </div>

              {/* Theme Toggle */}
              <button
                onClick={toggleTheme}
                className="rounded-lg bg-secondary p-2 hover:bg-accent"
                aria-label="Toggle theme"
              >
                {darkMode ? (
                  <Sun className="h-5 w-5 text-foreground" />
                ) : (
                  <Moon className="h-5 w-5 text-foreground" />
                )}
              </button>
            </div>
          </div>

          {/* Navigation */}
          <nav className="border-t border-border px-6">
            <div className="flex flex-col">
              <div className="flex gap-1">
                {navItems.map((tab) => {
                  const Icon = tab.icon;
                  const isActive = tab.submenu 
                    ? tab.submenu.some(sub => sub.id === activeTab) || (activeTab === "my-access" && myAccessOpen)
                    : activeTab === tab.id;
                  
                  const showBadge = tab.id === "approvals" && pendingApprovalsCount > 0;
                  
                  return (
                    <button
                      key={tab.id}
                      onClick={() => handleTabClick(tab.id)}
                      className={`flex items-center gap-2 border-b-2 px-4 py-3 text-sm transition-colors whitespace-nowrap ${
                        isActive
                          ? "border-primary text-primary"
                          : "border-transparent text-muted-foreground hover:text-foreground"
                      }`}
                    >
                      <Icon className="h-4 w-4" />
                      {tab.label}
                      {showBadge && (
                        <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-primary px-1.5 text-xs font-medium text-primary-foreground">
                          {pendingApprovalsCount}
                        </span>
                      )}
                      {tab.submenu && (
                        <ChevronRight className={`h-3 w-3 transition-transform ${myAccessOpen ? "rotate-90" : ""}`} />
                      )}
                    </button>
                  );
                })}
              </div>
              
              {/* Submenu for My Access */}
              {myAccessOpen && (userRole === "steward" || userRole === "admin") && (
                <div className="flex gap-1 border-t border-border bg-muted/30 py-1">
                  {navItems.find(item => item.id === "my-access")?.submenu?.map((subItem) => (
                    <button
                      key={subItem.id}
                      onClick={() => setActiveTab(subItem.id)}
                      className={`ml-12 px-4 py-2 text-sm transition-colors ${
                        activeTab === subItem.id
                          ? "text-primary"
                          : "text-muted-foreground hover:text-foreground"
                      }`}
                    >
                      {subItem.label}
                    </button>
                  ))}
                </div>
              )}
            </div>
          </nav>
        </header>

        {/* Main Content - Scrollable */}
        <main className="flex-1 overflow-y-auto p-6">
          <div className="mx-auto max-w-[1600px]">
            {/* User Views */}
            {userRole === "user" && (
              <>
                {activeTab === "overview" && <UserOverview />}
                {activeTab === "request-access" && <UserRequestAccess />}
                {activeTab === "approvals" && <UserApprovals />}
                {activeTab === "history" && <UserHistory />}
              </>
            )}

            {/* Data Steward & Admin Views */}
            {(userRole === "steward" || userRole === "admin") && (
              <>
                {activeTab === "overview" && <StewardOverview />}
                {activeTab === "my-active-roles" && <MyActiveRoles />}
                {activeTab === "my-request-access" && <UserRequestAccess />}
                {activeTab === "my-history" && <UserHistory />}
                {activeTab === "manage-roles" && <ManageRoles />}
                {activeTab === "approvals" && <UserApprovals />}
                {activeTab === "manage-teams" && <ManageTeams />}
                {activeTab === "manage-users" && <ManageUsers />}
                {activeTab === "audit" && <AuditLogs />}
              </>
            )}
          </div>
        </main>
      </div>
    </div>
  );
}

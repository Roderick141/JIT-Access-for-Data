import { useMemo, useState, useEffect } from "react";
import { Moon, Sun, Shield, Users, Key, Activity, FileText, Search, ChevronRight, UserCircle, Clock, Send, CheckCircle, type LucideIcon } from "lucide-react";

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
import { useAuth } from "@/contexts/AuthContext";
import { fetchPendingApprovals } from "@/api/endpoints";

type SubNavItem = { id: string; label: string; route: string };
type NavItem = { id: string; label: string; icon: LucideIcon; route?: string; submenu?: SubNavItem[] };

export default function App() {
  const { user, userRole, canApprove, canManage, isLoading, error } = useAuth();
  const [darkMode, setDarkMode] = useState(false);
  const [currentPath, setCurrentPath] = useState(() => window.location.pathname || "/");
  const [myAccessOpen, setMyAccessOpen] = useState(false);
  const [pendingApprovalsCount, setPendingApprovalsCount] = useState(0);

  const getDefaultPath = () => "/overview";

  const allowedPaths = useMemo(() => {
    if (canManage) {
      const paths = [
        "/overview",
        "/my-active-roles",
        "/my-request-access",
        "/my-history",
        "/manage-roles",
        "/manage-teams",
        "/manage-users",
        "/audit",
      ];
      if (canApprove) paths.push("/approvals");
      return new Set(paths);
    }

    const paths = ["/overview", "/request-access", "/history"];
    if (canApprove) paths.push("/approvals");
    return new Set(paths);
  }, [canApprove, canManage]);

  const navigate = (path: string) => {
    if (path === currentPath) return;
    window.history.pushState({}, "", path);
    setCurrentPath(path);
  };

  useEffect(() => {
    const onPop = () => setCurrentPath(window.location.pathname || "/");
    window.addEventListener("popstate", onPop);
    return () => window.removeEventListener("popstate", onPop);
  }, []);

  useEffect(() => {
    if (isLoading || error) return;
    const raw = window.location.pathname || "/";
    const normalized = raw === "/" ? getDefaultPath() : raw;
    const target = allowedPaths.has(normalized) ? normalized : getDefaultPath();
    if (target !== raw) {
      window.history.replaceState({}, "", target);
    }
    setCurrentPath(target);
    setMyAccessOpen(target.startsWith("/my-"));
  }, [allowedPaths, error, isLoading]);

  // Load pending approvals count for badge
  useEffect(() => {
    if (canApprove) {
      fetchPendingApprovals()
        .then((approvals) => {
          setPendingApprovalsCount(approvals.filter(a => a.Status?.toLowerCase() === "pending").length);
        })
        .catch(() => setPendingApprovalsCount(0));
    }
  }, [canApprove]);

  const toggleTheme = () => {
    setDarkMode(!darkMode);
  };

  const navItems: NavItem[] = useMemo(() => {
    if (canManage) {
      return [
        { id: "overview", label: "Overview", icon: Activity, route: "/overview" },
        {
          id: "my-access",
          label: "My Access",
          icon: UserCircle,
          submenu: [
            { id: "my-active-roles", label: "My Active Roles", route: "/my-active-roles" },
            { id: "my-request-access", label: "Request Access", route: "/my-request-access" },
            { id: "my-history", label: "My History", route: "/my-history" },
          ],
        },
        ...(canApprove ? [{ id: "approvals", label: "Approvals", icon: CheckCircle, route: "/approvals", submenu: undefined }] : []),
        { id: "manage-roles", label: "Manage Roles", icon: Key, route: "/manage-roles", submenu: undefined },
        { id: "manage-teams", label: "Manage Teams", icon: Users, route: "/manage-teams", submenu: undefined },
        { id: "manage-users", label: "Manage Users", icon: Users, route: "/manage-users", submenu: undefined },
        { id: "audit", label: "Audit Logs", icon: FileText, route: "/audit", submenu: undefined },
      ];
    }

    if (canApprove) {
      return [
        { id: "overview", label: "Overview", icon: Activity, route: "/overview", submenu: undefined },
        { id: "request-access", label: "Request Access", icon: Send, route: "/request-access", submenu: undefined },
        { id: "approvals", label: "Approvals", icon: CheckCircle, route: "/approvals", submenu: undefined },
        { id: "history", label: "History", icon: Clock, route: "/history", submenu: undefined },
      ];
    }

    return [
      { id: "overview", label: "Overview", icon: Activity, route: "/overview", submenu: undefined },
      { id: "request-access", label: "Request Access", icon: Send, route: "/request-access", submenu: undefined },
      { id: "history", label: "History", icon: Clock, route: "/history", submenu: undefined },
    ];
  }, [canApprove, canManage]);

  const getUserRoleDisplay = () => {
    const roleLabel =
      userRole === "admin"
        ? "Administrator"
        : userRole === "steward"
          ? "Data Steward"
          : userRole === "approver"
            ? "Approver"
            : "User";
    const name = user?.DisplayName ?? "Unknown User";
    const initials = name
      .split(" ")
      .map((p) => p[0])
      .join("")
      .slice(0, 2)
      .toUpperCase();
    return { name, initials, role: roleLabel };
  };

  const handleTabClick = (tab: NavItem) => {
    if (tab.id === "my-access") {
      setMyAccessOpen(!myAccessOpen);
    } else if (tab.route) {
      navigate(tab.route);
      } else {
      setMyAccessOpen(false);
    }
  };

  const userDisplay = getUserRoleDisplay();

  if (isLoading) {
    return <div className="p-8 text-sm text-muted-foreground">Loading user context...</div>;
  }
  if (error) {
    return <div className="p-8 text-sm text-destructive">Failed to load session: {error}</div>;
  }

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
                <p className="text-xs text-muted-foreground">Identity &amp; Access Management</p>
              </div>
            </div>

            <div className="flex items-center gap-4">
              {/* Search - only for steward and admin */}
              {canManage && (
                <div className="relative hidden md:block">
                  <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <input
                    type="text"
                    placeholder="Search users, roles, teams..."
                    className="w-80 rounded-lg border border-input bg-input-background py-2 pl-10 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
              )}

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
                    ? tab.submenu.some((sub) => sub.route === currentPath)
                    : tab.route === currentPath;

                  const showBadge = tab.id === "approvals" && pendingApprovalsCount > 0;

                  return (
                    <button
                      key={tab.id}
                      onClick={() => handleTabClick(tab)}
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
              {myAccessOpen && canManage && (
                <div className="flex gap-1 border-t border-border bg-muted/30 py-1">
                  {navItems.find((item) => item.id === "my-access")?.submenu?.map((subItem) => (
                    <button
                      key={subItem.id}
                      onClick={() => navigate(subItem.route)}
                      className={`ml-12 px-4 py-2 text-sm transition-colors ${
                        currentPath === subItem.route
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
            {/* User / Approver Views */}
            {!canManage && (
              <>
                {currentPath === "/overview" && <UserOverview />}
                {currentPath === "/request-access" && <UserRequestAccess />}
                {currentPath === "/approvals" && canApprove && <UserApprovals />}
                {currentPath === "/history" && <UserHistory />}
              </>
            )}

            {/* Data Steward & Admin Views */}
            {canManage && (
              <>
                {currentPath === "/overview" && <StewardOverview />}
                {currentPath === "/my-active-roles" && <MyActiveRoles />}
                {currentPath === "/my-request-access" && <UserRequestAccess />}
                {currentPath === "/my-history" && <UserHistory />}
                {currentPath === "/manage-roles" && <ManageRoles />}
                {currentPath === "/approvals" && canApprove && <UserApprovals />}
                {currentPath === "/manage-teams" && <ManageTeams />}
                {currentPath === "/manage-users" && <ManageUsers />}
                {currentPath === "/audit" && <AuditLogs />}
              </>
            )}

            {!allowedPaths.has(currentPath) && (
              <div className="rounded-lg border border-border bg-card p-6 text-sm text-muted-foreground">
                This page is not available for your role.
              </div>
            )}
          </div>
        </main>
      </div>
    </div>
  );
}

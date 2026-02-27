import { useState, useEffect, useCallback } from "react";
import { Search, Shield, UserCog } from "lucide-react";
import { fetchAdminUsers, fetchAdminLookups, updateUserSystemRoles } from "@/api/endpoints";
import type { AdminUser, LookupRow } from "@/api/types";

interface UserMapped {
  id: string;
  loginName: string;
  name: string;
  email: string;
  department: string;
  status: "Active" | "Inactive";
  isAdmin: boolean;
  isDataSteward: boolean;
  isApprover: boolean;
}

function mapUser(u: AdminUser): UserMapped {
  return {
    id: u.UserId,
    loginName: u.LoginName,
    name: u.DisplayName,
    email: u.Email ?? "",
    department: u.Department ?? "",
    status: (u.IsEnabled ?? u.IsActive) ? "Active" : "Inactive",
    isAdmin: u.IsAdmin,
    isDataSteward: u.IsDataSteward,
    isApprover: u.IsApprover,
  };
}

export function ManageUsers() {
  const [users, setUsers] = useState<UserMapped[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [isLoading, setIsLoading] = useState(true);

  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(25);
  const [searchQuery, setSearchQuery] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [departmentFilter, setDepartmentFilter] = useState("");
  const [roleFilter, setRoleFilter] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [departmentOptions, setDepartmentOptions] = useState<string[]>([]);

  const [editModalOpen, setEditModalOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<UserMapped | null>(null);
  const [editForm, setEditForm] = useState({
    isAdmin: false,
    isDataSteward: false,
    isApprover: false,
  });

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearch(searchQuery), 300);
    return () => clearTimeout(timer);
  }, [searchQuery]);

  const loadUsers = useCallback(() => {
    setIsLoading(true);
    fetchAdminUsers({
      search: debouncedSearch,
      department: departmentFilter,
      role: roleFilter,
      status: statusFilter,
      page: currentPage,
      pageSize,
    })
      .then((data) => {
        setUsers(data.map(mapUser));
        setTotalCount(data.length > 0 && data[0].TotalCount != null ? data[0].TotalCount : data.length);
      })
      .catch(console.error)
      .finally(() => setIsLoading(false));
  }, [debouncedSearch, departmentFilter, roleFilter, statusFilter, currentPage, pageSize]);

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  useEffect(() => {
    fetchAdminLookups()
      .then((rows) => {
        const departments = (rows as LookupRow[])
          .filter((r) => r.LookupType === "departments")
          .map((r) => r.LookupValue)
          .filter(Boolean);
        setDepartmentOptions(Array.from(new Set(departments)).sort((a, b) => a.localeCompare(b)));
      })
      .catch(() => setDepartmentOptions([]));
  }, []);

  useEffect(() => {
    setCurrentPage(1);
  }, [debouncedSearch, departmentFilter, roleFilter, statusFilter, pageSize]);

  const handleEditUser = (user: UserMapped) => {
    setSelectedUser(user);
    setEditForm({
      isAdmin: user.isAdmin,
      isDataSteward: user.isDataSteward,
      isApprover: user.isApprover,
    });
    setEditModalOpen(true);
  };

  const handleSaveUser = async () => {
    if (!selectedUser) return;
    try {
      await updateUserSystemRoles(String(selectedUser.id), {
        isAdmin: editForm.isAdmin,
        isApprover: editForm.isApprover,
        isDataSteward: editForm.isDataSteward,
      });
      setEditModalOpen(false);
      loadUsers();
    } catch (err: unknown) {
      alert(`Update failed: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const startIndex = (currentPage - 1) * pageSize + 1;
  const endIndex = Math.min(startIndex + users.length - 1, totalCount);
  const activeCount = users.filter((u) => u.status === "Active").length;

  const pageNumbers = (): number[] => {
    const pages: number[] = [];
    const maxVisible = 5;
    let start = Math.max(1, currentPage - Math.floor(maxVisible / 2));
    const end = Math.min(totalPages, start + maxVisible - 1);
    start = Math.max(1, end - maxVisible + 1);
    for (let i = start; i <= end; i++) pages.push(i);
    return pages;
  };

  if (isLoading && users.length === 0) {
    return <div className="p-8 text-sm text-muted-foreground">Loading users...</div>;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="rounded-lg border border-border bg-card p-4">
        <div className="flex items-start gap-3">
          <UserCog className="h-5 w-5 text-primary mt-0.5" />
          <div>
            <h3 className="text-sm text-card-foreground">User Management</h3>
            <p className="text-xs text-muted-foreground mt-1">
              Users are synced from Active Directory. You can assign system roles: Administrator, Data Steward, or Approver.
            </p>
          </div>
        </div>
      </div>

      {/* Summary */}
      <div className="grid gap-4 md:grid-cols-2">
        <div className="rounded-lg border border-border bg-card p-4">
          <p className="text-sm text-muted-foreground">Total Users</p>
          <p className="mt-1 text-2xl text-card-foreground">{totalCount.toLocaleString()}</p>
        </div>
        <div className="rounded-lg border border-border bg-card p-4">
          <p className="text-sm text-muted-foreground">Active (this page)</p>
          <p className="mt-1 text-2xl text-green-500">{activeCount}</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="relative max-w-md">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search users..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full rounded-lg border border-input bg-input-background py-2 pl-10 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </div>
        <div className="flex flex-wrap gap-3">
          <select
            value={departmentFilter}
            onChange={(e) => setDepartmentFilter(e.target.value)}
            className="rounded-lg border border-input bg-input-background px-4 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          >
            <option value="">All Departments</option>
            {departmentOptions.map((dept) => (
              <option key={dept} value={dept}>
                {dept}
              </option>
            ))}
          </select>
          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="rounded-lg border border-input bg-input-background px-4 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          >
            <option value="">All System Roles</option>
            <option value="admin">Administrator</option>
            <option value="steward">Data Steward</option>
            <option value="approver">Approver</option>
          </select>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="rounded-lg border border-input bg-input-background px-4 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          >
            <option value="">All Status</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>
      </div>

      {/* Users Table */}
      <div className="rounded-lg border border-border bg-card overflow-hidden">
        {isLoading && (
          <div className="h-1 w-full overflow-hidden bg-muted">
            <div className="h-full w-1/3 animate-pulse bg-primary rounded" />
          </div>
        )}
        <table className="w-full">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="px-6 py-3 text-left text-xs text-muted-foreground">User</th>
              <th className="px-6 py-3 text-left text-xs text-muted-foreground">Department</th>
              <th className="px-6 py-3 text-left text-xs text-muted-foreground">System Roles</th>
              <th className="px-6 py-3 text-left text-xs text-muted-foreground">Status</th>
              <th className="px-6 py-3 text-left text-xs text-muted-foreground">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-muted/50">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-sm text-primary-foreground">
                      {user.name.split(" ").map((n) => n[0]).join("").slice(0, 2)}
                    </div>
                    <div>
                      <p className="text-sm text-card-foreground">{user.name}</p>
                      <p className="text-xs text-muted-foreground">{user.email}</p>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span className="text-sm text-card-foreground">{user.department}</span>
                </td>
                <td className="px-6 py-4">
                  <div className="flex flex-wrap gap-1">
                    {user.isAdmin && (
                      <span className="rounded-full bg-purple-500/10 px-2 py-1 text-xs text-purple-600 dark:text-purple-400">
                        Admin
                      </span>
                    )}
                    {user.isDataSteward && (
                      <span className="rounded-full bg-blue-500/10 px-2 py-1 text-xs text-blue-600 dark:text-blue-400">
                        Data Steward
                      </span>
                    )}
                    {user.isApprover && (
                      <span className="rounded-full bg-green-500/10 px-2 py-1 text-xs text-green-600 dark:text-green-400">
                        Approver
                      </span>
                    )}
                    {!user.isAdmin && !user.isDataSteward && !user.isApprover && (
                      <span className="rounded-full bg-gray-500/10 px-2 py-1 text-xs text-gray-600 dark:text-gray-400">
                        User
                      </span>
                    )}
                  </div>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-2">
                    <div className={`h-2 w-2 rounded-full ${user.status === "Active" ? "bg-green-500" : "bg-gray-400"}`}></div>
                    <span className="text-sm text-card-foreground">{user.status}</span>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <button
                    onClick={() => handleEditUser(user)}
                    className="rounded-lg p-2 hover:bg-secondary"
                    title="Edit system roles"
                  >
                    <Shield className="h-4 w-4 text-muted-foreground" />
                  </button>
                </td>
              </tr>
            ))}
            {users.length === 0 && !isLoading && (
              <tr>
                <td colSpan={5} className="px-6 py-8 text-center text-sm text-muted-foreground">
                  No users found matching your filters.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <p className="text-sm text-muted-foreground">
            Showing {totalCount > 0 ? startIndex : 0}-{endIndex} of {totalCount.toLocaleString()} users
          </p>
          <div className="flex items-center gap-2">
            <label className="text-sm text-muted-foreground">Show:</label>
            <select
              value={pageSize}
              onChange={(e) => setPageSize(Number(e.target.value))}
              className="rounded-lg border border-input bg-input-background px-3 py-1 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
            >
              <option value="10">10</option>
              <option value="25">25</option>
              <option value="50">50</option>
              <option value="100">100</option>
            </select>
          </div>
        </div>
        {totalPages > 1 && (
          <div className="flex gap-2">
            <button
              onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
              disabled={currentPage === 1}
              className="rounded-lg border border-border bg-card px-3 py-1 text-sm text-foreground hover:bg-secondary disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Previous
            </button>
            {pageNumbers().map((p) => (
              <button
                key={p}
                onClick={() => setCurrentPage(p)}
                className={`rounded-lg px-3 py-1 text-sm ${
                  p === currentPage
                    ? "bg-primary text-primary-foreground"
                    : "border border-border bg-card text-foreground hover:bg-secondary"
                }`}
              >
                {p}
              </button>
            ))}
            <button
              onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
              disabled={currentPage === totalPages}
              className="rounded-lg border border-border bg-card px-3 py-1 text-sm text-foreground hover:bg-secondary disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Next
            </button>
          </div>
        )}
      </div>

      {/* Edit System Roles Modal */}
      {editModalOpen && selectedUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-lg border border-border bg-card p-6 shadow-lg">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-lg text-card-foreground">Edit System Roles</h3>
                <p className="text-sm text-muted-foreground mt-1">{selectedUser.name}</p>
              </div>
              <button onClick={() => setEditModalOpen(false)} className="rounded-lg p-1 hover:bg-secondary text-muted-foreground hover:text-foreground">
                &times;
              </button>
            </div>

            <div className="space-y-4">
              <p className="text-xs text-muted-foreground">
                Assign system-level roles to this user. These roles control access to administrative functions.
              </p>

              <div className="space-y-3">
                <label className="flex items-start gap-3 rounded-lg border border-border p-3 hover:bg-secondary/30 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={editForm.isAdmin}
                    onChange={(e) => setEditForm({ ...editForm, isAdmin: e.target.checked })}
                    className="mt-0.5 h-4 w-4 rounded border-input"
                  />
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className="text-sm text-card-foreground">Administrator</span>
                      <span className="rounded-full bg-purple-500/10 px-2 py-0.5 text-xs text-purple-600 dark:text-purple-400">
                        Full Access
                      </span>
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      Complete system access including user management, audit logs, and all configuration.
                    </p>
                  </div>
                </label>

                <label className="flex items-start gap-3 rounded-lg border border-border p-3 hover:bg-secondary/30 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={editForm.isDataSteward}
                    onChange={(e) => setEditForm({ ...editForm, isDataSteward: e.target.checked })}
                    className="mt-0.5 h-4 w-4 rounded border-input"
                  />
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className="text-sm text-card-foreground">Data Steward</span>
                      <span className="rounded-full bg-blue-500/10 px-2 py-0.5 text-xs text-blue-600 dark:text-blue-400">
                        Manage Roles &amp; Teams
                      </span>
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      Can manage roles, teams, view approvals, and configure access rules.
                    </p>
                  </div>
                </label>

                <label className="flex items-start gap-3 rounded-lg border border-border p-3 hover:bg-secondary/30 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={editForm.isApprover}
                    onChange={(e) => setEditForm({ ...editForm, isApprover: e.target.checked })}
                    className="mt-0.5 h-4 w-4 rounded border-input"
                  />
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className="text-sm text-card-foreground">Approver</span>
                      <span className="rounded-full bg-green-500/10 px-2 py-0.5 text-xs text-green-600 dark:text-green-400">
                        Approve Requests
                      </span>
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      Can approve or reject access requests for roles within their domain.
                    </p>
                  </div>
                </label>
              </div>
            </div>

            <div className="mt-6 flex gap-3">
              <button
                onClick={() => setEditModalOpen(false)}
                className="flex-1 rounded-lg border border-border bg-card px-4 py-2 text-sm text-foreground hover:bg-secondary"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveUser}
                className="flex-1 rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90"
              >
                Save Changes
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

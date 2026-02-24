import { useState } from "react";
import { Search, MoreVertical, Shield, UserCog } from "lucide-react";

export function ManageUsers() {
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState<number | "all">(10);
  const [searchQuery, setSearchQuery] = useState("");
  const users = [
    {
      name: "Sarah Johnson",
      email: "sarah.johnson@company.com",
      department: "IT",
      status: "Active",
      isAdmin: true,
      isDataSteward: false,
      isApprover: true,
    },
    {
      name: "Mike Chen",
      email: "mike.chen@company.com",
      department: "Marketing",
      status: "Active",
      isAdmin: false,
      isDataSteward: true,
      isApprover: true,
    },
    {
      name: "Emily Davis",
      email: "emily.davis@company.com",
      department: "Sales",
      status: "Active",
      isAdmin: false,
      isDataSteward: false,
      isApprover: true,
    },
    {
      name: "John Smith",
      email: "john.smith@company.com",
      department: "Finance",
      status: "Inactive",
      isAdmin: false,
      isDataSteward: false,
      isApprover: false,
    },
    {
      name: "Lisa Wang",
      email: "lisa.wang@company.com",
      department: "Engineering",
      status: "Active",
      isAdmin: false,
      isDataSteward: true,
      isApprover: true,
    },
    {
      name: "Robert Brown",
      email: "robert.brown@company.com",
      department: "Support",
      status: "Active",
      isAdmin: false,
      isDataSteward: false,
      isApprover: false,
    },
  ];

  const [editModalOpen, setEditModalOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [editForm, setEditForm] = useState({
    isAdmin: false,
    isDataSteward: false,
    isApprover: false,
  });

  const handleEditUser = (user: any) => {
    setSelectedUser(user);
    setEditForm({
      isAdmin: user.isAdmin,
      isDataSteward: user.isDataSteward,
      isApprover: user.isApprover,
    });
    setEditModalOpen(true);
  };

  const handleSaveUser = () => {
    alert(`Updated roles for ${selectedUser.name}:\n- Administrator: ${editForm.isAdmin ? 'Yes' : 'No'}\n- Data Steward: ${editForm.isDataSteward ? 'Yes' : 'No'}\n- Approver: ${editForm.isApprover ? 'Yes' : 'No'}`);
    setEditModalOpen(false);
  };

  // Search and filter logic
  const filteredUsers = users.filter(user => {
    const searchLower = searchQuery.toLowerCase();
    return (
      user.name.toLowerCase().includes(searchLower) ||
      user.email.toLowerCase().includes(searchLower) ||
      user.department.toLowerCase().includes(searchLower)
    );
  });

  // Pagination logic
  const totalUsers = 2847; // Total number of users in system
  const displayedUsers = itemsPerPage === "all" ? filteredUsers : filteredUsers.slice(0, itemsPerPage);
  const totalPages = itemsPerPage === "all" ? 1 : Math.ceil(filteredUsers.length / itemsPerPage);
  const startIndex = itemsPerPage === "all" ? 1 : (currentPage - 1) * itemsPerPage + 1;
  const endIndex = itemsPerPage === "all" ? filteredUsers.length : Math.min(startIndex + displayedUsers.length - 1, filteredUsers.length);

  const handleItemsPerPageChange = (value: string) => {
    if (value === "all") {
      setItemsPerPage("all");
    } else {
      setItemsPerPage(Number(value));
    }
    setCurrentPage(1);
  };

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
          <p className="mt-1 text-2xl text-card-foreground">{totalUsers}</p>
        </div>
        <div className="rounded-lg border border-border bg-card p-4">
          <p className="text-sm text-muted-foreground">Active Users</p>
          <p className="mt-1 text-2xl text-green-500">
            {users.filter(u => u.status === "Active").length}
          </p>
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
            onChange={(e) => {
              setSearchQuery(e.target.value);
              setCurrentPage(1);
            }}
            className="w-full rounded-lg border border-input bg-input-background py-2 pl-10 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </div>
        <div className="flex flex-wrap gap-3">
          <select className="rounded-lg border border-input bg-input-background px-4 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring">
            <option>All Departments</option>
            <option>IT</option>
            <option>Marketing</option>
            <option>Sales</option>
            <option>Finance</option>
            <option>Engineering</option>
            <option>Support</option>
          </select>
          <select className="rounded-lg border border-input bg-input-background px-4 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring">
            <option>All System Roles</option>
            <option>Administrator</option>
            <option>Data Steward</option>
            <option>Approver</option>
          </select>
          <select className="rounded-lg border border-input bg-input-background px-4 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring">
            <option>All Status</option>
            <option>Active</option>
            <option>Inactive</option>
          </select>
        </div>
      </div>

      {/* Users Table */}
      <div className="rounded-lg border border-border bg-card overflow-hidden">
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
            {displayedUsers.map((user, i) => (
              <tr key={i} className="hover:bg-muted/50">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-sm text-primary-foreground">
                      {user.name.split(" ").map(n => n[0]).join("")}
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
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <p className="text-sm text-muted-foreground">
            Showing {startIndex}-{endIndex} of {filteredUsers.length.toLocaleString()} users
            {searchQuery && ` (filtered from ${totalUsers.toLocaleString()} total)`}
          </p>
          <div className="flex items-center gap-2">
            <label className="text-sm text-muted-foreground">Show:</label>
            <select
              value={itemsPerPage}
              onChange={(e) => handleItemsPerPageChange(e.target.value)}
              className="rounded-lg border border-input bg-input-background px-3 py-1 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
            >
              <option value="10">10</option>
              <option value="25">25</option>
              <option value="50">50</option>
              <option value="all">All</option>
            </select>
          </div>
        </div>
        {itemsPerPage !== "all" && (
          <div className="flex gap-2">
            <button
              onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
              disabled={currentPage === 1}
              className="rounded-lg border border-border bg-card px-3 py-1 text-sm text-foreground hover:bg-secondary disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Previous
            </button>
            <button className="rounded-lg bg-primary px-3 py-1 text-sm text-primary-foreground">{currentPage}</button>
            <button className="rounded-lg border border-border bg-card px-3 py-1 text-sm text-foreground hover:bg-secondary">
              {currentPage + 1}
            </button>
            <button className="rounded-lg border border-border bg-card px-3 py-1 text-sm text-foreground hover:bg-secondary">
              {currentPage + 2}
            </button>
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
                <p className="text-sm text-muted-foreground mt-1">
                  {selectedUser.name}
                </p>
              </div>
              <button
                onClick={() => setEditModalOpen(false)}
                className="rounded-lg p-1 hover:bg-secondary"
              >
                <MoreVertical className="h-5 w-5 text-muted-foreground rotate-90" />
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
                        Manage Roles & Teams
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

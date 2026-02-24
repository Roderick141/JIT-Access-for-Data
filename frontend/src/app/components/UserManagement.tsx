import { Plus, Search, MoreVertical, Mail, Shield, Clock, CheckCircle, XCircle } from "lucide-react";

export function UserManagement() {
  const users = [
    {
      name: "Sarah Johnson",
      email: "sarah.johnson@company.com",
      role: "Administrator",
      status: "Active",
      lastActive: "2 minutes ago",
      mfa: true,
    },
    {
      name: "Mike Chen",
      email: "mike.chen@company.com",
      role: "Developer",
      status: "Active",
      lastActive: "15 minutes ago",
      mfa: true,
    },
    {
      name: "Emily Davis",
      email: "emily.davis@company.com",
      role: "Analyst",
      status: "Active",
      lastActive: "1 hour ago",
      mfa: false,
    },
    {
      name: "John Smith",
      email: "john.smith@company.com",
      role: "Developer",
      status: "Inactive",
      lastActive: "3 days ago",
      mfa: true,
    },
    {
      name: "Lisa Wang",
      email: "lisa.wang@company.com",
      role: "Manager",
      status: "Active",
      lastActive: "30 minutes ago",
      mfa: true,
    },
    {
      name: "Robert Brown",
      email: "robert.brown@company.com",
      role: "Support",
      status: "Active",
      lastActive: "2 hours ago",
      mfa: false,
    },
  ];

  const getRoleBadgeColor = (role: string) => {
    switch (role) {
      case "Administrator":
        return "bg-purple-500/10 text-purple-600 dark:text-purple-400";
      case "Manager":
        return "bg-blue-500/10 text-blue-600 dark:text-blue-400";
      case "Developer":
        return "bg-green-500/10 text-green-600 dark:text-green-400";
      default:
        return "bg-gray-500/10 text-gray-600 dark:text-gray-400";
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-foreground">User Management</h2>
          <p className="text-sm text-muted-foreground">Manage user accounts and permissions</p>
        </div>
        <button className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90">
          <Plus className="h-4 w-4" />
          Add User
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search users..."
            className="w-full rounded-lg border border-input bg-input-background py-2 pl-10 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </div>
        <select className="rounded-lg border border-input bg-input-background px-4 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring">
          <option>All Roles</option>
          <option>Administrator</option>
          <option>Manager</option>
          <option>Developer</option>
          <option>Analyst</option>
          <option>Support</option>
        </select>
        <select className="rounded-lg border border-input bg-input-background px-4 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring">
          <option>All Status</option>
          <option>Active</option>
          <option>Inactive</option>
        </select>
      </div>

      {/* Users Table */}
      <div className="rounded-lg border border-border bg-card overflow-hidden">
        <table className="w-full">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="px-6 py-3 text-left text-xs text-muted-foreground">User</th>
              <th className="px-6 py-3 text-left text-xs text-muted-foreground">Role</th>
              <th className="px-6 py-3 text-left text-xs text-muted-foreground">Status</th>
              <th className="px-6 py-3 text-left text-xs text-muted-foreground">MFA</th>
              <th className="px-6 py-3 text-left text-xs text-muted-foreground">Last Active</th>
              <th className="px-6 py-3 text-left text-xs text-muted-foreground">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {users.map((user, i) => (
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
                  <span className={`rounded-full px-2 py-1 text-xs ${getRoleBadgeColor(user.role)}`}>
                    {user.role}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-2">
                    <div className={`h-2 w-2 rounded-full ${user.status === "Active" ? "bg-green-500" : "bg-gray-400"}`}></div>
                    <span className="text-sm text-card-foreground">{user.status}</span>
                  </div>
                </td>
                <td className="px-6 py-4">
                  {user.mfa ? (
                    <CheckCircle className="h-5 w-5 text-green-500" />
                  ) : (
                    <XCircle className="h-5 w-5 text-gray-400" />
                  )}
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-2">
                    <Clock className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm text-muted-foreground">{user.lastActive}</span>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <button className="rounded-lg p-2 hover:bg-secondary">
                    <MoreVertical className="h-4 w-4 text-muted-foreground" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">Showing 6 of 2,847 users</p>
        <div className="flex gap-2">
          <button className="rounded-lg border border-border bg-card px-3 py-1 text-sm text-foreground hover:bg-secondary">
            Previous
          </button>
          <button className="rounded-lg bg-primary px-3 py-1 text-sm text-primary-foreground">1</button>
          <button className="rounded-lg border border-border bg-card px-3 py-1 text-sm text-foreground hover:bg-secondary">
            2
          </button>
          <button className="rounded-lg border border-border bg-card px-3 py-1 text-sm text-foreground hover:bg-secondary">
            3
          </button>
          <button className="rounded-lg border border-border bg-card px-3 py-1 text-sm text-foreground hover:bg-secondary">
            Next
          </button>
        </div>
      </div>
    </div>
  );
}

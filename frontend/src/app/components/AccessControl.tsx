import { Plus, Search, MoreVertical, Lock, Users, Database, Globe } from "lucide-react";

export function AccessControl() {
  const policies = [
    {
      name: "Full Admin Access",
      description: "Complete system access with all permissions",
      type: "System",
      users: 8,
      resources: "All",
      icon: Lock,
      color: "bg-red-500",
    },
    {
      name: "Developer Access",
      description: "Read/write access to development resources",
      type: "Custom",
      users: 45,
      resources: "Development, Staging",
      icon: Database,
      color: "bg-green-500",
    },
    {
      name: "Read-Only Access",
      description: "View-only access to all resources",
      type: "System",
      users: 120,
      resources: "All (Read)",
      icon: Globe,
      color: "bg-blue-500",
    },
    {
      name: "Finance Team",
      description: "Access to financial data and reports",
      type: "Custom",
      users: 12,
      resources: "Finance Database",
      icon: Users,
      color: "bg-purple-500",
    },
  ];

  const roles = [
    { name: "Administrator", users: 8, permissions: 127 },
    { name: "Manager", users: 24, permissions: 45 },
    { name: "Developer", users: 156, permissions: 32 },
    { name: "Analyst", users: 89, permissions: 18 },
    { name: "Support", users: 67, permissions: 15 },
  ];

  const permissions = [
    { resource: "User Management", read: true, write: true, delete: true },
    { resource: "Access Policies", read: true, write: true, delete: false },
    { resource: "Audit Logs", read: true, write: false, delete: false },
    { resource: "System Settings", read: true, write: true, delete: true },
    { resource: "API Keys", read: true, write: true, delete: true },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-foreground">Access Control</h2>
          <p className="text-sm text-muted-foreground">Manage roles, policies, and permissions</p>
        </div>
        <button className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90">
          <Plus className="h-4 w-4" />
          New Policy
        </button>
      </div>

      {/* Policies Grid */}
      <div>
        <h3 className="mb-4 text-card-foreground">Access Policies</h3>
        <div className="grid gap-4 md:grid-cols-2">
          {policies.map((policy, i) => {
            const Icon = policy.icon;
            return (
              <div key={i} className="rounded-lg border border-border bg-card p-5">
                <div className="flex items-start justify-between">
                  <div className="flex gap-3">
                    <div className={`flex h-12 w-12 items-center justify-center rounded-lg ${policy.color}`}>
                      <Icon className="h-6 w-6 text-white" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <h4 className="text-card-foreground">{policy.name}</h4>
                        <span className="rounded-full bg-secondary px-2 py-0.5 text-xs text-secondary-foreground">
                          {policy.type}
                        </span>
                      </div>
                      <p className="mt-1 text-sm text-muted-foreground">{policy.description}</p>
                      <div className="mt-3 flex gap-4 text-xs text-muted-foreground">
                        <span>{policy.users} users</span>
                        <span>•</span>
                        <span>{policy.resources}</span>
                      </div>
                    </div>
                  </div>
                  <button className="rounded-lg p-1 hover:bg-secondary">
                    <MoreVertical className="h-4 w-4 text-muted-foreground" />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Roles Table */}
      <div>
        <h3 className="mb-4 text-card-foreground">Roles</h3>
        <div className="rounded-lg border border-border bg-card overflow-hidden">
          <table className="w-full">
            <thead className="border-b border-border bg-muted/50">
              <tr>
                <th className="px-6 py-3 text-left text-xs text-muted-foreground">Role Name</th>
                <th className="px-6 py-3 text-left text-xs text-muted-foreground">Users</th>
                <th className="px-6 py-3 text-left text-xs text-muted-foreground">Permissions</th>
                <th className="px-6 py-3 text-left text-xs text-muted-foreground">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {roles.map((role, i) => (
                <tr key={i} className="hover:bg-muted/50">
                  <td className="px-6 py-4">
                    <span className="text-sm text-card-foreground">{role.name}</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm text-muted-foreground">{role.users}</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm text-muted-foreground">{role.permissions} permissions</span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex gap-2">
                      <button className="text-xs text-primary hover:underline">Edit</button>
                      <button className="text-xs text-muted-foreground hover:text-foreground">Delete</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Permission Matrix */}
      <div>
        <h3 className="mb-4 text-card-foreground">Permission Matrix (Admin Role)</h3>
        <div className="rounded-lg border border-border bg-card overflow-hidden">
          <table className="w-full">
            <thead className="border-b border-border bg-muted/50">
              <tr>
                <th className="px-6 py-3 text-left text-xs text-muted-foreground">Resource</th>
                <th className="px-6 py-3 text-center text-xs text-muted-foreground">Read</th>
                <th className="px-6 py-3 text-center text-xs text-muted-foreground">Write</th>
                <th className="px-6 py-3 text-center text-xs text-muted-foreground">Delete</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {permissions.map((perm, i) => (
                <tr key={i} className="hover:bg-muted/50">
                  <td className="px-6 py-4">
                    <span className="text-sm text-card-foreground">{perm.resource}</span>
                  </td>
                  <td className="px-6 py-4 text-center">
                    <input
                      type="checkbox"
                      checked={perm.read}
                      readOnly
                      className="h-4 w-4 rounded border-border text-primary focus:ring-2 focus:ring-ring"
                    />
                  </td>
                  <td className="px-6 py-4 text-center">
                    <input
                      type="checkbox"
                      checked={perm.write}
                      readOnly
                      className="h-4 w-4 rounded border-border text-primary focus:ring-2 focus:ring-ring"
                    />
                  </td>
                  <td className="px-6 py-4 text-center">
                    <input
                      type="checkbox"
                      checked={perm.delete}
                      readOnly
                      className="h-4 w-4 rounded border-border text-primary focus:ring-2 focus:ring-ring"
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

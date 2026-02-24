import { Shield, Clock, CheckCircle, AlertCircle } from "lucide-react";

export function UserOverview() {
  const activeRolesRaw = [
    {
      name: "Employee Portal Access",
      description: "Standard employee access to company portal and basic resources",
      grantedDate: "2025-06-15",
      expiryDate: "Never",
      status: "Active",
    },
    {
      name: "Customer Support Portal",
      description: "Read and respond to customer support tickets",
      grantedDate: "2026-02-04",
      expiryDate: "2026-08-04",
      status: "Active",
    },
    {
      name: "Marketing Reports Access",
      description: "View marketing analytics and campaign reports",
      grantedDate: "2025-11-20",
      expiryDate: "2026-05-20",
      status: "Expiring Soon",
    },
  ];

  // Sort roles: Expiring Soon first, then Active. Both groups sorted A-Z
  const activeRoles = activeRolesRaw.sort((a, b) => {
    if (a.status === "Expiring Soon" && b.status !== "Expiring Soon") return -1;
    if (a.status !== "Expiring Soon" && b.status === "Expiring Soon") return 1;
    return a.name.localeCompare(b.name);
  });

  const pendingRequests = [
    {
      id: "REQ-1247",
      roleName: "Finance Database - Read Access",
      requestedDate: "2026-02-09",
      status: "Pending Approval",
    },
    {
      id: "REQ-1245",
      roleName: "Marketing Analytics Dashboard",
      requestedDate: "2026-02-08",
      status: "Pending Approval",
    },
  ];

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid gap-4 md:grid-cols-3">
        <div className="rounded-lg border border-border bg-card p-6">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-green-500">
              <Shield className="h-6 w-6 text-white" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Active Roles</p>
              <p className="text-3xl text-card-foreground">{activeRoles.length}</p>
            </div>
          </div>
        </div>
        <div className="rounded-lg border border-border bg-card p-6">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-orange-500">
              <Clock className="h-6 w-6 text-white" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Pending Requests</p>
              <p className="text-3xl text-card-foreground">{pendingRequests.length}</p>
            </div>
          </div>
        </div>
        <div className="rounded-lg border border-border bg-card p-6">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-yellow-500">
              <AlertCircle className="h-6 w-6 text-white" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Expiring Soon</p>
              <p className="text-3xl text-card-foreground">1</p>
            </div>
          </div>
        </div>
      </div>

      {/* Active Roles and Pending Requests - Side by Side */}
      <div className="grid gap-6 lg:grid-cols-2">
        {/* Active Roles */}
        <div className="rounded-lg border border-border bg-card">
          <div className="border-b border-border p-4">
            <h3 className="text-card-foreground">Active Roles</h3>
            <p className="text-sm text-muted-foreground">Roles currently assigned to you</p>
          </div>
          <div className="divide-y divide-border">
            {activeRoles.map((role, i) => (
              <div key={i} className="px-4 py-3">
                <div className="flex items-start justify-between gap-3">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <h4 className="text-sm text-card-foreground">{role.name}</h4>
                      <span
                        className={`rounded-full px-2 py-0.5 text-xs ${
                          role.status === "Active"
                            ? "bg-green-500/10 text-green-600 dark:text-green-400"
                            : "bg-yellow-500/10 text-yellow-600 dark:text-yellow-400"
                        }`}
                      >
                        {role.status}
                      </span>
                    </div>
                    <p className="mt-0.5 text-xs text-muted-foreground line-clamp-1">{role.description}</p>
                    <div className="mt-1 flex gap-3 text-xs text-muted-foreground">
                      <span>Granted: {role.grantedDate}</span>
                      <span>•</span>
                      <span className={role.status === "Expiring Soon" ? "text-yellow-600 dark:text-yellow-400" : ""}>
                        Expires: {role.expiryDate}
                      </span>
                    </div>
                  </div>
                  {role.status === "Expiring Soon" && (
                    <button className="text-xs text-primary hover:underline whitespace-nowrap">
                      Request Extension
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Pending Requests */}
        <div className="rounded-lg border border-border bg-card">
          <div className="border-b border-border p-4">
            <h3 className="text-card-foreground">Pending Requests</h3>
            <p className="text-sm text-muted-foreground">Access requests awaiting approval</p>
          </div>
          {pendingRequests.length > 0 ? (
            <div className="divide-y divide-border">
              {pendingRequests.map((request, i) => (
                <div key={i} className="px-4 py-3">
                  <div className="flex items-center justify-between gap-3">
                    <div className="flex items-center gap-2 min-w-0 flex-1">
                      <Clock className="h-4 w-4 text-orange-500 flex-shrink-0" />
                      <div className="min-w-0">
                        <h4 className="text-sm text-card-foreground truncate">{request.roleName}</h4>
                        <p className="text-xs text-muted-foreground">
                          {request.id} • {request.requestedDate}
                        </p>
                      </div>
                    </div>
                    <span className="rounded-full bg-orange-500/10 px-2 py-0.5 text-xs text-orange-600 dark:text-orange-400 whitespace-nowrap">
                      {request.status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="p-8 text-center">
              <CheckCircle className="mx-auto h-12 w-12 text-muted-foreground" />
              <p className="mt-2 text-sm text-muted-foreground">No pending requests</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

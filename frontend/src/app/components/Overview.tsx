import { Users, Key, Shield, AlertTriangle, TrendingUp, CheckCircle } from "lucide-react";

export function Overview() {
  const stats = [
    { label: "Total Users", value: "2,847", change: "+12%", icon: Users, color: "bg-blue-500" },
    { label: "Active Sessions", value: "1,294", change: "+8%", icon: Shield, color: "bg-green-500" },
    { label: "Access Policies", value: "186", change: "+5", icon: Key, color: "bg-purple-500" },
    { label: "Security Alerts", value: "7", change: "-3", icon: AlertTriangle, color: "bg-orange-500" },
  ];

  const recentActivity = [
    { user: "Sarah Johnson", action: "Logged in", time: "2 minutes ago", status: "success" },
    { user: "Mike Chen", action: "Password changed", time: "15 minutes ago", status: "success" },
    { user: "Emily Davis", action: "Failed login attempt", time: "23 minutes ago", status: "warning" },
    { user: "System", action: "New policy created", time: "1 hour ago", status: "info" },
    { user: "Alex Turner", action: "Role updated to Admin", time: "2 hours ago", status: "success" },
  ];

  const accessRequests = [
    { user: "John Smith", resource: "Finance Database", status: "pending" },
    { user: "Lisa Wang", resource: "Admin Panel", status: "pending" },
    { user: "Robert Brown", resource: "API Keys", status: "approved" },
    { user: "Maria Garcia", resource: "Production Environment", status: "rejected" },
  ];

  return (
    <div className="space-y-6">
      {/* Stats Grid */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <div key={stat.label} className="rounded-lg border border-border bg-card p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground">{stat.label}</p>
                  <p className="mt-2 text-3xl text-card-foreground">{stat.value}</p>
                  <div className="mt-2 flex items-center gap-1">
                    <TrendingUp className="h-3 w-3 text-green-500" />
                    <span className="text-xs text-green-500">{stat.change}</span>
                  </div>
                </div>
                <div className={`flex h-12 w-12 items-center justify-center rounded-lg ${stat.color}`}>
                  <Icon className="h-6 w-6 text-white" />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Recent Activity */}
        <div className="rounded-lg border border-border bg-card">
          <div className="border-b border-border p-4">
            <h3 className="text-card-foreground">Recent Activity</h3>
            <p className="text-sm text-muted-foreground">Latest user actions and system events</p>
          </div>
          <div className="divide-y divide-border">
            {recentActivity.map((activity, i) => (
              <div key={i} className="flex items-center justify-between p-4">
                <div className="flex items-center gap-3">
                  <div
                    className={`h-2 w-2 rounded-full ${
                      activity.status === "success"
                        ? "bg-green-500"
                        : activity.status === "warning"
                        ? "bg-orange-500"
                        : "bg-blue-500"
                    }`}
                  ></div>
                  <div>
                    <p className="text-sm text-card-foreground">{activity.user}</p>
                    <p className="text-xs text-muted-foreground">{activity.action}</p>
                  </div>
                </div>
                <span className="text-xs text-muted-foreground">{activity.time}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Access Requests */}
        <div className="rounded-lg border border-border bg-card">
          <div className="border-b border-border p-4">
            <h3 className="text-card-foreground">Access Requests</h3>
            <p className="text-sm text-muted-foreground">Pending and recent access decisions</p>
          </div>
          <div className="divide-y divide-border">
            {accessRequests.map((request, i) => (
              <div key={i} className="p-4">
                <div className="flex items-start justify-between">
                  <div>
                    <p className="text-sm text-card-foreground">{request.user}</p>
                    <p className="text-xs text-muted-foreground">{request.resource}</p>
                  </div>
                  <span
                    className={`rounded-full px-2 py-1 text-xs ${
                      request.status === "pending"
                        ? "bg-yellow-500/10 text-yellow-600 dark:text-yellow-400"
                        : request.status === "approved"
                        ? "bg-green-500/10 text-green-600 dark:text-green-400"
                        : "bg-red-500/10 text-red-600 dark:text-red-400"
                    }`}
                  >
                    {request.status}
                  </span>
                </div>
                {request.status === "pending" && (
                  <div className="mt-3 flex gap-2">
                    <button className="rounded bg-primary px-3 py-1 text-xs text-primary-foreground hover:bg-primary/90">
                      Approve
                    </button>
                    <button className="rounded border border-border px-3 py-1 text-xs text-foreground hover:bg-secondary">
                      Reject
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Security Score */}
      <div className="rounded-lg border border-border bg-card p-6">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-card-foreground">Security Posture</h3>
            <p className="text-sm text-muted-foreground">Overall system security health</p>
          </div>
          <div className="text-right">
            <div className="flex items-center gap-2">
              <CheckCircle className="h-5 w-5 text-green-500" />
              <span className="text-3xl text-green-500">92%</span>
            </div>
            <p className="text-xs text-muted-foreground">Excellent</p>
          </div>
        </div>
        <div className="mt-4 h-2 overflow-hidden rounded-full bg-secondary">
          <div className="h-full w-[92%] bg-green-500"></div>
        </div>
        <div className="mt-4 grid gap-3 md:grid-cols-3">
          <div className="flex items-center gap-2">
            <div className="h-2 w-2 rounded-full bg-green-500"></div>
            <span className="text-xs text-muted-foreground">MFA Adoption: 94%</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="h-2 w-2 rounded-full bg-green-500"></div>
            <span className="text-xs text-muted-foreground">Password Strength: 89%</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="h-2 w-2 rounded-full bg-yellow-500"></div>
            <span className="text-xs text-muted-foreground">Inactive Users: 7%</span>
          </div>
        </div>
      </div>
    </div>
  );
}

import { Download, Search, Filter, AlertCircle, CheckCircle, Info, XCircle } from "lucide-react";

export function AuditLogs() {
  const logs = [
    {
      timestamp: "2026-02-09 14:23:45",
      user: "Sarah Johnson",
      action: "User Login",
      resource: "Authentication Service",
      status: "Success",
      ip: "192.168.1.105",
      type: "success",
    },
    {
      timestamp: "2026-02-09 14:15:32",
      user: "Mike Chen",
      action: "Password Changed",
      resource: "User Profile",
      status: "Success",
      ip: "192.168.1.89",
      type: "success",
    },
    {
      timestamp: "2026-02-09 14:02:18",
      user: "Emily Davis",
      action: "Failed Login Attempt",
      resource: "Authentication Service",
      status: "Failed",
      ip: "203.45.67.12",
      type: "warning",
    },
    {
      timestamp: "2026-02-09 13:45:09",
      user: "System Admin",
      action: "Policy Created",
      resource: "Access Policy: Developer Access",
      status: "Success",
      ip: "192.168.1.1",
      type: "info",
    },
    {
      timestamp: "2026-02-09 13:30:55",
      user: "Alex Turner",
      action: "Role Updated",
      resource: "User: alex.turner@company.com",
      status: "Success",
      ip: "192.168.1.45",
      type: "info",
    },
    {
      timestamp: "2026-02-09 13:12:33",
      user: "Unknown",
      action: "Unauthorized Access",
      resource: "Admin Panel",
      status: "Blocked",
      ip: "185.220.101.67",
      type: "error",
    },
    {
      timestamp: "2026-02-09 12:58:21",
      user: "Lisa Wang",
      action: "API Key Generated",
      resource: "API Management",
      status: "Success",
      ip: "192.168.1.67",
      type: "success",
    },
    {
      timestamp: "2026-02-09 12:45:11",
      user: "Robert Brown",
      action: "User Created",
      resource: "User: new.user@company.com",
      status: "Success",
      ip: "192.168.1.23",
      type: "success",
    },
  ];

  const getStatusIcon = (type: string) => {
    switch (type) {
      case "success":
        return <CheckCircle className="h-5 w-5 text-green-500" />;
      case "warning":
        return <AlertCircle className="h-5 w-5 text-orange-500" />;
      case "error":
        return <XCircle className="h-5 w-5 text-red-500" />;
      case "info":
        return <Info className="h-5 w-5 text-blue-500" />;
      default:
        return <Info className="h-5 w-5 text-gray-500" />;
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "Success":
        return "bg-green-500/10 text-green-600 dark:text-green-400";
      case "Failed":
        return "bg-orange-500/10 text-orange-600 dark:text-orange-400";
      case "Blocked":
        return "bg-red-500/10 text-red-600 dark:text-red-400";
      default:
        return "bg-gray-500/10 text-gray-600 dark:text-gray-400";
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-foreground">Audit Logs</h2>
          <p className="text-sm text-muted-foreground">Track all system activities and security events</p>
        </div>
        <button className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90">
          <Download className="h-4 w-4" />
          Export Logs
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search logs..."
            className="w-full rounded-lg border border-input bg-input-background py-2 pl-10 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </div>
        <select className="rounded-lg border border-input bg-input-background px-4 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring">
          <option>All Actions</option>
          <option>Login</option>
          <option>Logout</option>
          <option>Create</option>
          <option>Update</option>
          <option>Delete</option>
        </select>
        <select className="rounded-lg border border-input bg-input-background px-4 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring">
          <option>All Status</option>
          <option>Success</option>
          <option>Failed</option>
          <option>Blocked</option>
        </select>
        <select className="rounded-lg border border-input bg-input-background px-4 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring">
          <option>Last 24 Hours</option>
          <option>Last 7 Days</option>
          <option>Last 30 Days</option>
          <option>Custom Range</option>
        </select>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-4">
        <div className="rounded-lg border border-border bg-card p-4">
          <div className="flex items-center gap-2">
            <CheckCircle className="h-5 w-5 text-green-500" />
            <span className="text-sm text-muted-foreground">Success</span>
          </div>
          <p className="mt-2 text-2xl text-card-foreground">1,847</p>
        </div>
        <div className="rounded-lg border border-border bg-card p-4">
          <div className="flex items-center gap-2">
            <AlertCircle className="h-5 w-5 text-orange-500" />
            <span className="text-sm text-muted-foreground">Warnings</span>
          </div>
          <p className="mt-2 text-2xl text-card-foreground">23</p>
        </div>
        <div className="rounded-lg border border-border bg-card p-4">
          <div className="flex items-center gap-2">
            <XCircle className="h-5 w-5 text-red-500" />
            <span className="text-sm text-muted-foreground">Errors</span>
          </div>
          <p className="mt-2 text-2xl text-card-foreground">7</p>
        </div>
        <div className="rounded-lg border border-border bg-card p-4">
          <div className="flex items-center gap-2">
            <Info className="h-5 w-5 text-blue-500" />
            <span className="text-sm text-muted-foreground">Info</span>
          </div>
          <p className="mt-2 text-2xl text-card-foreground">456</p>
        </div>
      </div>

      {/* Logs Table */}
      <div className="rounded-lg border border-border bg-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="border-b border-border bg-muted/50">
              <tr>
                <th className="px-6 py-3 text-left text-xs text-muted-foreground">Timestamp</th>
                <th className="px-6 py-3 text-left text-xs text-muted-foreground">User</th>
                <th className="px-6 py-3 text-left text-xs text-muted-foreground">Action</th>
                <th className="px-6 py-3 text-left text-xs text-muted-foreground">Resource</th>
                <th className="px-6 py-3 text-left text-xs text-muted-foreground">Status</th>
                <th className="px-6 py-3 text-left text-xs text-muted-foreground">IP Address</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {logs.map((log, i) => (
                <tr key={i} className="hover:bg-muted/50">
                  <td className="px-6 py-4">
                    <span className="text-sm text-muted-foreground font-mono">{log.timestamp}</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm text-card-foreground">{log.user}</span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      {getStatusIcon(log.type)}
                      <span className="text-sm text-card-foreground">{log.action}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm text-muted-foreground">{log.resource}</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`rounded-full px-2 py-1 text-xs ${getStatusBadge(log.status)}`}>
                      {log.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm text-muted-foreground font-mono">{log.ip}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">Showing 8 of 2,333 audit logs</p>
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

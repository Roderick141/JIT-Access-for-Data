import { useState } from "react";
import { CheckCircle, XCircle, Clock, RotateCcw } from "lucide-react";

export function UserHistory() {
  const [statusFilter, setStatusFilter] = useState("all");
  const [timePeriodFilter, setTimePeriodFilter] = useState("30");

  const historyItems = [
    {
      id: "REQ-1247",
      roles: ["Finance Database - Read Access"],
      requestedDate: "2026-02-09",
      status: "pending",
      comment: "Need access to generate quarterly reports for stakeholder presentation",
    },
    {
      id: "REQ-1245",
      roles: ["Marketing Analytics Dashboard"],
      requestedDate: "2026-02-08",
      status: "pending",
      comment: "Required for cross-team collaboration on campaign analysis",
    },
    {
      id: "REQ-1243",
      roles: ["Developer Tools Access"],
      requestedDate: "2026-02-07",
      status: "approved",
      approvedDate: "2026-02-07",
      approver: "Jane Smith",
      comment: "Moving to development team, need tools access",
    },
    {
      id: "REQ-1240",
      roles: ["Admin Panel Access"],
      requestedDate: "2026-02-05",
      status: "denied",
      deniedDate: "2026-02-06",
      approver: "Jane Smith",
      denialReason: "Insufficient business justification. Please provide more details on specific use case.",
      comment: "General administrative tasks",
    },
    {
      id: "REQ-1238",
      roles: ["Customer Support Portal"],
      requestedDate: "2026-02-04",
      status: "approved",
      approvedDate: "2026-02-04",
      approver: "Michael Chen",
      comment: "Assisting support team during busy season",
    },
    {
      id: "REQ-1235",
      roles: ["Marketing Reports Access"],
      requestedDate: "2026-01-15",
      status: "revoked",
      revokedDate: "2026-02-01",
      revokedBy: "System Admin",
      revokedReason: "Access expired after project completion",
      comment: "Temporary access for Q4 campaign analysis",
    },
  ];

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "approved":
        return <CheckCircle className="h-5 w-5 text-green-500" />;
      case "denied":
        return <XCircle className="h-5 w-5 text-red-500" />;
      case "pending":
        return <Clock className="h-5 w-5 text-orange-500" />;
      case "revoked":
        return <RotateCcw className="h-5 w-5 text-gray-500" />;
      default:
        return <Clock className="h-5 w-5 text-gray-500" />;
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "approved":
        return "bg-green-500/10 text-green-600 dark:text-green-400";
      case "denied":
        return "bg-red-500/10 text-red-600 dark:text-red-400";
      case "pending":
        return "bg-orange-500/10 text-orange-600 dark:text-orange-400";
      case "revoked":
        return "bg-gray-500/10 text-gray-600 dark:text-gray-400";
      default:
        return "bg-gray-500/10 text-gray-600 dark:text-gray-400";
    }
  };

  const getStatusLabel = (status: string) => {
    return status.charAt(0).toUpperCase() + status.slice(1);
  };

  const filterByTimePeriod = (items: typeof historyItems) => {
    if (timePeriodFilter === "all") return items;

    const today = new Date("2026-02-11"); // Current date from context
    const daysToFilter = parseInt(timePeriodFilter);

    return items.filter((item) => {
      const requestDate = new Date(item.requestedDate);
      const diffTime = today.getTime() - requestDate.getTime();
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
      return diffDays <= daysToFilter;
    });
  };

  const filterByStatus = (items: typeof historyItems) => {
    if (statusFilter === "all") return items;
    return items.filter((item) => item.status === statusFilter);
  };

  const filteredItems = filterByStatus(filterByTimePeriod(historyItems));

  return (
    <div className="space-y-6">
      {/* Filters */}
      <div className="flex flex-wrap gap-3">
        <select 
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="rounded-lg border border-input bg-input-background px-4 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
        >
          <option value="all">All Status</option>
          <option value="pending">Pending</option>
          <option value="approved">Approved</option>
          <option value="denied">Denied</option>
          <option value="revoked">Revoked</option>
        </select>
        <select 
          value={timePeriodFilter}
          onChange={(e) => setTimePeriodFilter(e.target.value)}
          className="rounded-lg border border-input bg-input-background px-4 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
        >
          <option value="30">Last 30 Days</option>
          <option value="7">Last 7 Days</option>
          <option value="90">Last 90 Days</option>
          <option value="all">All Time</option>
        </select>
      </div>

      {/* History List */}
      <div className="space-y-3">
        {filteredItems.length === 0 ? (
          <div className="rounded-lg border border-border bg-card p-8 text-center">
            <p className="text-sm text-muted-foreground">No history items found matching the selected filters.</p>
          </div>
        ) : (
          filteredItems.map((item) => (
          <div key={item.id} className="rounded-lg border border-border bg-card p-4">
            <div className="flex items-start gap-3">
              {getStatusIcon(item.status)}
              <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <h3 className="text-sm text-card-foreground truncate">
                        {item.roles.length === 1 ? item.roles[0] : `${item.roles.length} Roles`}
                      </h3>
                      <span className={`rounded-full px-2 py-0.5 text-xs ${getStatusBadge(item.status)} whitespace-nowrap`}>
                        {getStatusLabel(item.status)}
                      </span>
                    </div>
                    <p className="mt-0.5 text-xs text-muted-foreground">{item.id} • {item.requestedDate}</p>
                  </div>
                </div>

                {item.roles.length > 1 && (
                  <div className="mt-2">
                    <div className="flex flex-wrap gap-1">
                      {item.roles.map((role, idx) => (
                        <span
                          key={idx}
                          className="rounded-full bg-secondary px-2 py-0.5 text-xs text-secondary-foreground"
                        >
                          {role}
                        </span>
                      ))}
                    </div>
                  </div>
                )}

                <p className="mt-2 text-xs text-muted-foreground line-clamp-2">{item.comment}</p>

                {item.status === "approved" && (
                  <div className="mt-2 rounded-lg bg-green-500/10 p-2">
                    <p className="text-xs text-muted-foreground">
                      Approved by {item.approver} on {item.approvedDate}
                    </p>
                  </div>
                )}

                {item.status === "denied" && item.denialReason && (
                  <div className="mt-2 rounded-lg bg-red-500/10 p-2">
                    <p className="text-xs text-muted-foreground">
                      Denied by {item.approver} on {item.deniedDate}
                    </p>
                    <p className="mt-1 text-xs text-red-600 dark:text-red-400 line-clamp-2">{item.denialReason}</p>
                  </div>
                )}

                {item.status === "revoked" && item.revokedReason && (
                  <div className="mt-2 rounded-lg bg-gray-500/10 p-2">
                    <p className="text-xs text-muted-foreground">
                      Revoked by {item.revokedBy} on {item.revokedDate}
                    </p>
                    <p className="mt-1 text-xs text-muted-foreground line-clamp-2">{item.revokedReason}</p>
                  </div>
                )}

                {item.status === "pending" && (
                  <div className="mt-2">
                    <button className="text-xs text-destructive hover:underline">
                      Cancel Request
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
          ))
        )}
      </div>
    </div>
  );
}

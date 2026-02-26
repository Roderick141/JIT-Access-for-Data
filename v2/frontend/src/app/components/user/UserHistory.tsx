import { useState, useEffect } from "react";
import { CheckCircle, XCircle, Clock, RotateCcw, Ban, Zap } from "lucide-react";
import { fetchUserRequests, cancelRequest } from "@/api/endpoints";
import type { UserRequest } from "@/api/types";
import { formatDateAmsterdam, parseUtcLike } from "@/app/components/shared/dateTime";

function formatDate(utc: string | null | undefined): string {
  return formatDateAmsterdam(utc, "");
}

interface HistoryItem {
  id: string;
  requestId: number;
  roles: string[];
  requestedDate: string;
  requestedDateUtc: string | null;
  status: string;
  comment: string;
  approvedDate?: string;
  deniedDate?: string;
  cancelledDate?: string;
  revokedDate?: string;
  approver?: string;
  revokedBy?: string;
  denialReason?: string;
  revokedReason?: string;
}

function mapRequest(r: UserRequest): HistoryItem {
  const rawStatus = (r.Status ?? "").toLowerCase();
  // API may use "denied" or "rejected" – normalise both to "denied"
  const status = rawStatus === "rejected" ? "denied" : rawStatus;
  const roles = r.RoleNames
    ? r.RoleNames.split(",").map((s) => s.trim()).filter(Boolean)
    : [];

  const item: HistoryItem = {
    id: `REQ-${r.RequestId}`,
    requestId: r.RequestId,
    roles,
    requestedDate: formatDate(r.CreatedUtc),
    requestedDateUtc: r.CreatedUtc ?? null,
    status,
    comment: r.Justification ?? "",
  };

  if (status === "approved") {
    item.approvedDate = formatDate(r.DecisionUtc ?? r.UpdatedUtc);
    item.approver = r.ApproverName ?? undefined;
  }
  if (status === "autoapproved") {
    item.approvedDate = formatDate(r.DecisionUtc ?? r.UpdatedUtc ?? r.CreatedUtc);
  }
  if (status === "denied") {
    item.deniedDate = formatDate(r.DecisionUtc ?? r.UpdatedUtc);
    item.approver = r.ApproverName ?? undefined;
    item.denialReason = r.DecisionComment ?? undefined;
  }
  if (status === "cancelled") {
    item.cancelledDate = formatDate(r.UpdatedUtc);
  }
  if (status === "revoked") {
    item.revokedDate = formatDate(r.UpdatedUtc);
    item.revokedBy = r.ApproverName ?? "System";
    item.revokedReason = r.DecisionComment ?? undefined;
  }

  return item;
}

export function UserHistory() {
  const [statusFilter, setStatusFilter] = useState("all");
  const [timePeriodFilter, setTimePeriodFilter] = useState("30");
  const [historyItems, setHistoryItems] = useState<HistoryItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const loadRequests = () => {
    setIsLoading(true);
    fetchUserRequests()
      .then((data) => setHistoryItems(data.map(mapRequest)))
      .catch(console.error)
      .finally(() => setIsLoading(false));
  };

  useEffect(() => {
    loadRequests();
  }, []);

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "approved":
        return <CheckCircle className="h-5 w-5 text-green-500" />;
      case "autoapproved":
        return <Zap className="h-5 w-5 text-blue-500" />;
      case "denied":
        return <XCircle className="h-5 w-5 text-red-500" />;
      case "pending":
        return <Clock className="h-5 w-5 text-orange-500" />;
      case "cancelled":
        return <Ban className="h-5 w-5 text-gray-500" />;
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
      case "autoapproved":
        return "bg-blue-500/10 text-blue-600 dark:text-blue-400";
      case "denied":
        return "bg-red-500/10 text-red-600 dark:text-red-400";
      case "pending":
        return "bg-orange-500/10 text-orange-600 dark:text-orange-400";
      case "cancelled":
        return "bg-gray-500/10 text-gray-600 dark:text-gray-400";
      case "revoked":
        return "bg-gray-500/10 text-gray-600 dark:text-gray-400";
      default:
        return "bg-gray-500/10 text-gray-600 dark:text-gray-400";
    }
  };

  const getStatusLabel = (status: string) => {
    if (status === "autoapproved") return "Auto Approved";
    return status.charAt(0).toUpperCase() + status.slice(1);
  };

  const filterByTimePeriod = (items: HistoryItem[]) => {
    if (timePeriodFilter === "all") return items;
    const today = new Date();
    const daysToFilter = parseInt(timePeriodFilter);
    return items.filter((item) => {
      const requestDate = parseUtcLike(item.requestedDateUtc);
      if (!requestDate) return false;
      const diffDays = Math.ceil((today.getTime() - requestDate.getTime()) / (1000 * 60 * 60 * 24));
      return diffDays <= daysToFilter;
    });
  };

  const filterByStatus = (items: HistoryItem[]) => {
    if (statusFilter === "all") return items;
    return items.filter((item) => item.status === statusFilter);
  };

  const handleCancelRequest = async (requestId: number) => {
    try {
      await cancelRequest(requestId);
      loadRequests();
    } catch (err: unknown) {
      alert(`Failed to cancel request: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const filteredItems = filterByStatus(filterByTimePeriod(historyItems));

  if (isLoading) {
    return <div className="p-8 text-sm text-muted-foreground">Loading history...</div>;
  }

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
          <option value="autoapproved">Auto Approved</option>
          <option value="denied">Denied</option>
          <option value="cancelled">Cancelled</option>
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
                        <span
                          className={`rounded-full px-2 py-0.5 text-xs ${getStatusBadge(item.status)} whitespace-nowrap`}
                        >
                          {getStatusLabel(item.status)}
                        </span>
                      </div>
                      <p className="mt-0.5 text-xs text-muted-foreground">
                        {item.id} • {item.requestedDate}
                      </p>
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

                  {item.comment && (
                    <p className="mt-2 text-xs text-muted-foreground line-clamp-2">{item.comment}</p>
                  )}

                  {item.status === "approved" && (
                    <div className="mt-2 rounded-lg bg-green-500/10 p-2">
                      <p className="text-xs text-muted-foreground">
                        Approved{item.approver ? ` by ${item.approver}` : ""}{item.approvedDate ? ` on ${item.approvedDate}` : ""}
                      </p>
                    </div>
                  )}

                  {item.status === "autoapproved" && (
                    <div className="mt-2 rounded-lg bg-blue-500/10 p-2">
                      <p className="text-xs text-muted-foreground">
                        Auto-approved{item.approvedDate ? ` on ${item.approvedDate}` : ""}
                      </p>
                    </div>
                  )}

                  {item.status === "denied" && (
                    <div className="mt-2 rounded-lg bg-red-500/10 p-2">
                      <p className="text-xs text-muted-foreground">
                        Denied{item.approver ? ` by ${item.approver}` : ""}{item.deniedDate ? ` on ${item.deniedDate}` : ""}
                      </p>
                      {item.denialReason && (
                        <p className="mt-1 text-xs text-red-600 dark:text-red-400 line-clamp-2">{item.denialReason}</p>
                      )}
                    </div>
                  )}

                  {item.status === "cancelled" && (
                    <div className="mt-2 rounded-lg bg-gray-500/10 p-2">
                      <p className="text-xs text-muted-foreground">
                        Cancelled{item.cancelledDate ? ` on ${item.cancelledDate}` : ""}
                      </p>
                    </div>
                  )}

                  {item.status === "revoked" && item.revokedReason && (
                    <div className="mt-2 rounded-lg bg-gray-500/10 p-2">
                      <p className="text-xs text-muted-foreground">
                        Revoked{item.revokedBy ? ` by ${item.revokedBy}` : ""}{item.revokedDate ? ` on ${item.revokedDate}` : ""}
                      </p>
                      <p className="mt-1 text-xs text-muted-foreground line-clamp-2">{item.revokedReason}</p>
                    </div>
                  )}

                  {item.status === "pending" && (
                    <div className="mt-2">
                      <button
                        onClick={() => handleCancelRequest(item.requestId)}
                        className="text-xs text-destructive hover:underline"
                      >
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

import { useState, useEffect } from "react";
import { Key, ShieldAlert, CheckCircle, XCircle, Clock, User, MessageSquare, AlertTriangle } from "lucide-react";
import {
  fetchAdminStats,
  fetchPendingApprovals,
  fetchAuditLogs,
  approveRequest,
  denyRequest,
} from "@/api/endpoints";
import type { AdminStats, PendingApproval, AuditLogEntry } from "@/api/types";

interface MappedApproval {
  id: number;
  displayId: string;
  user: { name: string; email: string };
  roles: { name: string; sensitive: boolean }[];
  comment: string;
  duration: number;
}

function mapApproval(a: PendingApproval): MappedApproval {
  const roles = (a.RoleNames ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean)
    .map((name) => ({
      name,
      sensitive: (a.SensitivityLevel ?? "").toLowerCase() === "sensitive",
    }));

  return {
    id: a.RequestId,
    displayId: `REQ-${a.RequestId}`,
    user: {
      name: a.RequesterName ?? "Unknown",
      email: a.RequesterEmail ?? "",
    },
    roles,
    comment: a.Justification ?? "",
    duration: Math.floor((a.RequestedDurationMinutes ?? 0) / 1440) || 1,
  };
}

interface ActivityItem {
  type: string;
  user: string;
  action: string;
  details: string;
  time: string;
}

function mapAuditEntry(e: AuditLogEntry): ActivityItem {
  const eventType = (e.EventType ?? "").toLowerCase();
  let type = "default";
  if (eventType.includes("approv")) type = "approval";
  else if (eventType.includes("deny") || eventType.includes("reject")) type = "rejection";
  else if (eventType.includes("role") && eventType.includes("creat")) type = "role-created";
  else if (eventType.includes("user")) type = "user-added";

  const time = e.EventUtc ? new Date(e.EventUtc).toLocaleString() : "";

  return {
    type,
    user: String(e.UserId ?? "System"),
    action: e.EventType ?? "Event",
    details: e.Details ?? "",
    time,
  };
}

export function StewardOverview() {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [pendingApprovals, setPendingApprovals] = useState<MappedApproval[]>([]);
  const [recentActivity, setRecentActivity] = useState<ActivityItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const [rejectionModalOpen, setRejectionModalOpen] = useState(false);
  const [approvalCommentModalOpen, setApprovalCommentModalOpen] = useState(false);
  const [selectedRequest, setSelectedRequest] = useState<number | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [approvalComment, setApprovalComment] = useState("");

  const loadData = () => {
    setIsLoading(true);
    Promise.all([
      fetchAdminStats(),
      fetchPendingApprovals(),
      fetchAuditLogs(),
    ])
      .then(([s, p, a]) => {
        setStats(s);
        setPendingApprovals(
          p.filter((r) => (r.Status ?? "").toLowerCase() === "pending").map(mapApproval)
        );
        setRecentActivity(a.slice(0, 5).map(mapAuditEntry));
      })
      .catch(console.error)
      .finally(() => setIsLoading(false));
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleApprove = async (requestId: number) => {
    try {
      await approveRequest(requestId);
      loadData();
    } catch (err: unknown) {
      alert(`Failed to approve: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const handleApproveWithComment = (requestId: number) => {
    setSelectedRequest(requestId);
    setApprovalCommentModalOpen(true);
  };

  const handleReject = (requestId: number) => {
    setSelectedRequest(requestId);
    setRejectionModalOpen(true);
  };

  const confirmApprovalWithComment = async () => {
    if (!approvalComment || selectedRequest === null) return;
    try {
      await approveRequest(selectedRequest, approvalComment);
      setApprovalCommentModalOpen(false);
      setSelectedRequest(null);
      setApprovalComment("");
      loadData();
    } catch (err: unknown) {
      alert(`Failed to approve: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const confirmRejection = async () => {
    if (!rejectionReason || selectedRequest === null) return;
    try {
      await denyRequest(selectedRequest, rejectionReason);
      setRejectionModalOpen(false);
      setSelectedRequest(null);
      setRejectionReason("");
      loadData();
    } catch (err: unknown) {
      alert(`Failed to reject: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const getActivityIcon = (type: string) => {
    switch (type) {
      case "approval":
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case "rejection":
        return <XCircle className="h-4 w-4 text-red-500" />;
      case "role-created":
        return <Key className="h-4 w-4 text-blue-500" />;
      case "user-added":
        return <User className="h-4 w-4 text-purple-500" />;
      default:
        return <Clock className="h-4 w-4 text-gray-500" />;
    }
  };

  const kpiData = [
    {
      label: "Roles Active",
      value: stats ? String(stats.activeGrants) : "—",
      icon: Key,
      color: "bg-green-500",
    },
    {
      label: "Sensitive Roles Active",
      value: stats ? String(stats.sensitiveRoles) : "—",
      icon: ShieldAlert,
      color: "bg-red-500",
    },
  ];

  if (isLoading) {
    return <div className="p-8 text-sm text-muted-foreground">Loading overview...</div>;
  }

  return (
    <div className="space-y-6">
      {/* KPI Tiles */}
      <div className="grid gap-4 md:grid-cols-2">
        {kpiData.map((kpi, i) => {
          const Icon = kpi.icon;
          return (
            <button
              key={i}
              className="rounded-lg border border-border bg-card p-6 text-left transition-all hover:border-primary hover:shadow-sm"
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground">{kpi.label}</p>
                  <p className="mt-2 text-3xl text-card-foreground">{kpi.value}</p>
                </div>
                <div className={`flex h-12 w-12 items-center justify-center rounded-lg ${kpi.color}`}>
                  <Icon className="h-6 w-6 text-white" />
                </div>
              </div>
            </button>
          );
        })}
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Pending Approvals */}
        <div className="rounded-lg border border-border bg-card">
          <div className="border-b border-border p-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-card-foreground">Pending Approvals</h3>
                <p className="text-sm text-muted-foreground">
                  {pendingApprovals.length} requests awaiting review
                </p>
              </div>
              <span className="flex h-8 w-8 items-center justify-center rounded-full bg-orange-500 text-sm text-white">
                {pendingApprovals.length}
              </span>
            </div>
          </div>
          {pendingApprovals.length === 0 ? (
            <div className="p-8 text-center">
              <CheckCircle className="mx-auto h-12 w-12 text-muted-foreground" />
              <p className="mt-2 text-sm text-muted-foreground">No pending approvals</p>
            </div>
          ) : (
            <div className="divide-y divide-border">
              {pendingApprovals.map((request) => (
                <div key={request.id} className="p-4">
                  <div className="flex items-start gap-3">
                    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary text-xs text-primary-foreground">
                      {request.user.name.split(" ").map((n) => n[0]).join("")}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-start justify-between">
                        <div>
                          <h4 className="text-sm text-card-foreground">{request.user.name}</h4>
                          <p className="text-xs text-muted-foreground">{request.user.email}</p>
                        </div>
                        <span className="text-xs text-muted-foreground">#{request.displayId}</span>
                      </div>

                      <div className="mt-2">
                        <p className="text-xs text-muted-foreground">
                          Requested Role{request.roles.length > 1 ? "s" : ""}:
                        </p>
                        <div className="mt-1 flex flex-wrap gap-1">
                          {request.roles.map((role, idx) => (
                            <span
                              key={idx}
                              className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs ${
                                role.sensitive
                                  ? "bg-destructive/10 text-destructive"
                                  : "bg-primary/10 text-primary"
                              }`}
                            >
                              {role.name}
                              {role.sensitive && <AlertTriangle className="h-3 w-3" />}
                            </span>
                          ))}
                        </div>
                      </div>

                      <div className="mt-2 rounded-lg bg-muted/50 p-2">
                        <div className="flex items-start gap-2">
                          <MessageSquare className="h-3 w-3 mt-0.5 text-muted-foreground" />
                          <p className="text-xs text-muted-foreground line-clamp-2">{request.comment}</p>
                        </div>
                      </div>

                      <div className="mt-3 flex items-center justify-between">
                        <div className="flex items-center gap-1 text-xs text-muted-foreground">
                          <Clock className="h-3 w-3" />
                          <span>
                            Duration: {request.duration} {request.duration === 1 ? "day" : "days"}
                          </span>
                        </div>
                        <div className="flex gap-2">
                          <button
                            onClick={() => handleApprove(request.id)}
                            className="flex items-center gap-1 rounded bg-green-500 px-3 py-1 text-xs text-white hover:bg-green-600"
                          >
                            <CheckCircle className="h-3 w-3" />
                            Approve
                          </button>
                          <button
                            onClick={() => handleApproveWithComment(request.id)}
                            className="flex items-center gap-1 rounded border border-green-500 bg-card px-3 py-1 text-xs text-green-600 hover:bg-green-50 dark:hover:bg-green-950"
                          >
                            <MessageSquare className="h-3 w-3" />
                            Approve with Comment
                          </button>
                          <button
                            onClick={() => handleReject(request.id)}
                            className="flex items-center gap-1 rounded border border-border bg-card px-3 py-1 text-xs text-foreground hover:bg-destructive hover:text-destructive-foreground hover:border-destructive"
                          >
                            <XCircle className="h-3 w-3" />
                            Reject
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Recent Activity */}
        <div className="rounded-lg border border-border bg-card">
          <div className="border-b border-border p-4">
            <h3 className="text-card-foreground">Recent Activity</h3>
            <p className="text-sm text-muted-foreground">Latest actions in the system</p>
          </div>
          {recentActivity.length === 0 ? (
            <div className="p-8 text-center">
              <p className="text-sm text-muted-foreground">No recent activity</p>
            </div>
          ) : (
            <div className="divide-y divide-border">
              {recentActivity.map((activity, i) => (
                <div key={i} className="p-4">
                  <div className="flex items-start gap-3">
                    {getActivityIcon(activity.type)}
                    <div className="flex-1">
                      <p className="text-sm text-card-foreground">{activity.action}</p>
                      <p className="text-xs text-muted-foreground">{activity.details}</p>
                      <div className="mt-1 flex items-center gap-2 text-xs text-muted-foreground">
                        <span>{activity.user}</span>
                        <span>•</span>
                        <span>{activity.time}</span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Approval with Comment Modal */}
      {approvalCommentModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md rounded-lg border border-border bg-card p-6 shadow-lg">
            <h3 className="text-lg text-card-foreground">Approve with Comment</h3>
            <p className="mt-1 text-sm text-muted-foreground">
              Add a comment for request #REQ-{selectedRequest}
            </p>
            <div className="mt-4">
              <label className="text-sm text-card-foreground">
                Approval Comment <span className="text-destructive">*</span>
              </label>
              <textarea
                value={approvalComment}
                onChange={(e) => setApprovalComment(e.target.value)}
                placeholder="Add any notes or conditions for this approval..."
                rows={4}
                className="mt-2 w-full rounded-lg border border-input bg-input-background p-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div className="mt-6 flex justify-end gap-3">
              <button
                onClick={() => {
                  setApprovalCommentModalOpen(false);
                  setSelectedRequest(null);
                  setApprovalComment("");
                }}
                className="rounded-lg border border-border bg-card px-4 py-2 text-sm text-foreground hover:bg-secondary"
              >
                Cancel
              </button>
              <button
                onClick={confirmApprovalWithComment}
                disabled={!approvalComment}
                className="rounded-lg bg-green-500 px-4 py-2 text-sm text-white hover:bg-green-600 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Confirm Approval
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Rejection Modal */}
      {rejectionModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md rounded-lg border border-border bg-card p-6 shadow-lg">
            <h3 className="text-lg text-card-foreground">Reject Request</h3>
            <p className="mt-1 text-sm text-muted-foreground">
              Please provide a reason for rejecting request #REQ-{selectedRequest}
            </p>
            <div className="mt-4">
              <label className="text-sm text-card-foreground">
                Rejection Reason <span className="text-destructive">*</span>
              </label>
              <textarea
                value={rejectionReason}
                onChange={(e) => setRejectionReason(e.target.value)}
                placeholder="Explain why this request is being rejected..."
                rows={4}
                className="mt-2 w-full rounded-lg border border-input bg-input-background p-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div className="mt-6 flex justify-end gap-3">
              <button
                onClick={() => {
                  setRejectionModalOpen(false);
                  setSelectedRequest(null);
                  setRejectionReason("");
                }}
                className="rounded-lg border border-border bg-card px-4 py-2 text-sm text-foreground hover:bg-secondary"
              >
                Cancel
              </button>
              <button
                onClick={confirmRejection}
                disabled={!rejectionReason}
                className="rounded-lg bg-destructive px-4 py-2 text-sm text-destructive-foreground hover:bg-destructive/90 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Confirm Rejection
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

import { useState, useMemo } from "react";
import { Search, CheckCircle, XCircle, Clock, MessageSquare, AlertTriangle } from "lucide-react";

type ApprovalStatus = "pending" | "approved" | "rejected";
type Sensitivity = "standard" | "sensitive";

interface ApprovalRequest {
  id: string;
  requesterId: string;
  requesterName: string;
  requesterEmail: string;
  requesterDepartment: string;
  roles: string[];
  sensitivity: Sensitivity;
  duration: number;
  requestDate: string;
  justification: string;
  status: ApprovalStatus;
}

export function UserApprovals() {
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<"all" | ApprovalStatus>("pending");
  const [rejectionModalOpen, setRejectionModalOpen] = useState(false);
  const [approvalCommentModalOpen, setApprovalCommentModalOpen] = useState(false);
  const [selectedRequest, setSelectedRequest] = useState<string | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [approvalComment, setApprovalComment] = useState("");

  const approvalRequests: ApprovalRequest[] = [
    {
      id: "REQ-2301",
      requesterId: "USR-445",
      requesterName: "Sarah Johnson",
      requesterEmail: "sarah.johnson@company.com",
      requesterDepartment: "Marketing",
      roles: ["Marketing Analytics"],
      sensitivity: "standard",
      duration: 90,
      requestDate: "2026-02-12",
      justification: "Need access to analyze Q1 campaign performance and prepare reports for the leadership team. This will help optimize our marketing spend and improve ROI.",
      status: "pending",
    },
    {
      id: "REQ-2298",
      requesterId: "USR-521",
      requesterName: "Michael Chen",
      requesterEmail: "michael.chen@company.com",
      requesterDepartment: "Finance",
      roles: ["Finance Database Access", "Financial Reports"],
      sensitivity: "sensitive",
      duration: 30,
      requestDate: "2026-02-11",
      justification: "Require temporary access to reconcile Q4 financial statements and prepare audit documentation. Working with external auditors who need this data urgently.",
      status: "pending",
    },
    {
      id: "REQ-2295",
      requesterId: "USR-389",
      requesterName: "Emily Rodriguez",
      requesterEmail: "emily.rodriguez@company.com",
      requesterDepartment: "Operations",
      roles: ["Document Repository"],
      sensitivity: "standard",
      duration: 180,
      requestDate: "2026-02-10",
      justification: "New role as Operations Coordinator requires access to standard operating procedures, policy documents, and process documentation to effectively manage daily operations.",
      status: "pending",
    },
    {
      id: "REQ-2287",
      requesterId: "USR-612",
      requesterName: "David Park",
      requesterEmail: "david.park@company.com",
      requesterDepartment: "IT",
      roles: ["Analytics Platform"],
      sensitivity: "sensitive",
      duration: 60,
      requestDate: "2026-02-08",
      justification: "Supporting data migration project that requires access to analytics platform to validate data integrity and set up new dashboards for the sales team.",
      status: "approved",
    },
    {
      id: "REQ-2280",
      requesterId: "USR-734",
      requesterName: "Jennifer Lee",
      requesterEmail: "jennifer.lee@company.com",
      requesterDepartment: "Sales",
      roles: ["CRM Access"],
      sensitivity: "standard",
      duration: 365,
      requestDate: "2026-02-05",
      justification: "New hire in sales team, need permanent access to CRM for managing customer relationships and tracking sales pipeline.",
      status: "rejected",
    },
  ];

  const filteredRequests = useMemo(() => {
    let filtered = approvalRequests.filter(request => {
      const matchesStatus = statusFilter === "all" || request.status === statusFilter;
      const searchLower = searchQuery.toLowerCase();
      const matchesSearch = searchQuery === "" || 
        request.requesterName.toLowerCase().includes(searchLower) ||
        request.roles.some(role => role.toLowerCase().includes(searchLower)) ||
        request.requesterDepartment.toLowerCase().includes(searchLower) ||
        request.id.toLowerCase().includes(searchLower);
      
      return matchesStatus && matchesSearch;
    });

    return filtered.sort((a, b) => {
      // Pending first, then by date (newest first)
      if (a.status === "pending" && b.status !== "pending") return -1;
      if (a.status !== "pending" && b.status === "pending") return 1;
      return new Date(b.requestDate).getTime() - new Date(a.requestDate).getTime();
    });
  }, [searchQuery, statusFilter]);

  const handleApprove = (requestId: string) => {
    alert(`Approved request ${requestId}`);
  };

  const handleApproveWithComment = (requestId: string) => {
    setSelectedRequest(requestId);
    setApprovalCommentModalOpen(true);
  };

  const handleReject = (requestId: string) => {
    setSelectedRequest(requestId);
    setRejectionModalOpen(true);
  };

  const confirmApprovalWithComment = () => {
    if (approvalComment) {
      alert(`Request ${selectedRequest} approved with comment: ${approvalComment}`);
      setApprovalCommentModalOpen(false);
      setSelectedRequest(null);
      setApprovalComment("");
    }
  };

  const confirmRejection = () => {
    if (rejectionReason) {
      alert(`Request ${selectedRequest} rejected with reason: ${rejectionReason}`);
      setRejectionModalOpen(false);
      setSelectedRequest(null);
      setRejectionReason("");
    }
  };

  const pendingCount = approvalRequests.filter(r => r.status === "pending").length;

  return (
    <div className="space-y-6">
      {/* Header Stats */}
      <div className="grid gap-4 md:grid-cols-3">
        <div className="rounded-lg border border-border bg-card p-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-orange-500">
              <Clock className="h-5 w-5 text-white" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Pending Approvals</p>
              <p className="text-2xl text-card-foreground">{pendingCount}</p>
            </div>
          </div>
        </div>
        <div className="rounded-lg border border-border bg-card p-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-green-500">
              <CheckCircle className="h-5 w-5 text-white" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Approved (Last 30 days)</p>
              <p className="text-2xl text-card-foreground">
                {approvalRequests.filter(r => r.status === "approved").length}
              </p>
            </div>
          </div>
        </div>
        <div className="rounded-lg border border-border bg-card p-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-red-500">
              <XCircle className="h-5 w-5 text-white" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Rejected (Last 30 days)</p>
              <p className="text-2xl text-card-foreground">
                {approvalRequests.filter(r => r.status === "rejected").length}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div className="relative max-w-md flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search by requester, role, or request ID..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full rounded-lg border border-input bg-input-background py-2 pl-10 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </div>

        <div className="flex gap-2">
          <button
            onClick={() => setStatusFilter("all")}
            className={`rounded-lg px-4 py-2 text-sm transition-colors ${
              statusFilter === "all"
                ? "bg-primary text-primary-foreground"
                : "border border-border bg-card text-foreground hover:bg-secondary"
            }`}
          >
            All
          </button>
          <button
            onClick={() => setStatusFilter("pending")}
            className={`rounded-lg px-4 py-2 text-sm transition-colors ${
              statusFilter === "pending"
                ? "bg-primary text-primary-foreground"
                : "border border-border bg-card text-foreground hover:bg-secondary"
            }`}
          >
            Pending ({pendingCount})
          </button>
          <button
            onClick={() => setStatusFilter("approved")}
            className={`rounded-lg px-4 py-2 text-sm transition-colors ${
              statusFilter === "approved"
                ? "bg-primary text-primary-foreground"
                : "border border-border bg-card text-foreground hover:bg-secondary"
            }`}
          >
            Approved
          </button>
          <button
            onClick={() => setStatusFilter("rejected")}
            className={`rounded-lg px-4 py-2 text-sm transition-colors ${
              statusFilter === "rejected"
                ? "bg-primary text-primary-foreground"
                : "border border-border bg-card text-foreground hover:bg-secondary"
            }`}
          >
            Rejected
          </button>
        </div>
      </div>

      {/* Approvals List */}
      <div className="rounded-lg border border-border bg-card">
        {filteredRequests.length > 0 ? (
          <div className="divide-y divide-border">
            {filteredRequests.map((request) => (
              <div key={request.id} className="p-4">
                <div className="flex items-start gap-3">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary text-xs text-primary-foreground">
                    {request.requesterName.split(" ").map(n => n[0]).join("")}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-start justify-between">
                      <div>
                        <h4 className="text-sm text-card-foreground">{request.requesterName}</h4>
                        <p className="text-xs text-muted-foreground">{request.requesterEmail}</p>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs text-muted-foreground">#{request.id}</span>
                        {request.status !== "pending" && (
                          <span
                            className={`rounded-full px-2.5 py-0.5 text-xs ${
                              request.status === "approved"
                                ? "bg-green-500/10 text-green-600 dark:text-green-400"
                                : "bg-red-500/10 text-red-600 dark:text-red-400"
                            }`}
                          >
                            {request.status.charAt(0).toUpperCase() + request.status.slice(1)}
                          </span>
                        )}
                      </div>
                    </div>

                    <div className="mt-2">
                      <p className="text-xs text-muted-foreground">Requested Role{request.roles.length > 1 ? "s" : ""}:</p>
                      <div className="mt-1 flex flex-wrap gap-1">
                        {request.roles.map((role, idx) => (
                          <span
                            key={idx}
                            className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs ${
                              request.sensitivity === "sensitive"
                                ? "bg-destructive/10 text-destructive"
                                : "bg-primary/10 text-primary"
                            }`}
                          >
                            {role}
                            {request.sensitivity === "sensitive" && (
                              <AlertTriangle className="h-3 w-3" />
                            )}
                          </span>
                        ))}
                      </div>
                    </div>

                    <div className="mt-2 rounded-lg bg-muted/50 p-2">
                      <div className="flex items-start gap-2">
                        <MessageSquare className="h-3 w-3 mt-0.5 text-muted-foreground" />
                        <p className="text-xs text-muted-foreground line-clamp-2">{request.justification}</p>
                      </div>
                    </div>

                    <div className="mt-3 flex items-center justify-between">
                      <div className="flex items-center gap-1 text-xs text-muted-foreground">
                        <Clock className="h-3 w-3" />
                        <span>Duration: {request.duration} {request.duration === 1 ? 'day' : 'days'}</span>
                      </div>
                      {request.status === "pending" && (
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
                      )}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="p-12 text-center">
            <CheckCircle className="mx-auto h-12 w-12 text-muted-foreground" />
            <p className="mt-3 text-sm text-muted-foreground">
              {searchQuery || statusFilter !== "pending" 
                ? "No requests found matching your criteria"
                : "No pending approvals at this time"}
            </p>
          </div>
        )}
      </div>

      {/* Approval with Comment Modal */}
      {approvalCommentModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md rounded-lg border border-border bg-card p-6 shadow-lg">
            <h3 className="text-lg text-card-foreground">Approve with Comment</h3>
            <p className="mt-1 text-sm text-muted-foreground">
              Add a comment for request #{selectedRequest}
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
              Please provide a reason for rejecting request #{selectedRequest}
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

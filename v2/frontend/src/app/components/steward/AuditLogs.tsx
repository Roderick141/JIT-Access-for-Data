import { useEffect, useState } from "react";
import { fetchAuditLogs } from "@/api/endpoints";
import type { AuditLogEntry } from "@/api/types";
import { formatDateTimeMinute, toAuditActor, toAuditSummary, toFriendlyAuditEvent } from "@/app/components/shared/auditDisplay";

const PAGE_SIZE = 25;

export function AuditLogs() {
  const [rows, setRows] = useState<AuditLogEntry[]>([]);
  const [search, setSearch] = useState("");
  const [eventType, setEventType] = useState("");
  const [page, setPage] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = () => {
    setLoading(true);
    setError(null);
    fetchAuditLogs({ search, eventType, page, pageSize: PAGE_SIZE })
      .then((data) => {
        setRows(data);
        setTotalCount(data.length > 0 && data[0].TotalCount != null ? Number(data[0].TotalCount) : 0);
      })
      .catch((e) => setError(e.message ?? "Failed to load audit logs."))
      .finally(() => setLoading(false));
  };
  useEffect(load, [search, eventType, page]);

  const pageCount = Math.max(1, Math.ceil(totalCount / PAGE_SIZE));
  const hasNextPage = page < pageCount;
  const eventTypes = Array.from(new Set(rows.map((x) => String(x.EventType ?? "")))).filter(Boolean);

  function exportCsv() {
    const header = ["AuditLogId", "Time", "Event", "Actor", "Target", "Role", "Summary", "RawDetails"];
    const lines = [header.join(",")].concat(
      rows.map((r) =>
        [
          r.AuditLogId,
          `"${String(formatDateTimeMinute(r.EventUtc)).replaceAll('"', '""')}"`,
          `"${String(toFriendlyAuditEvent(r.EventType)).replaceAll('"', '""')}"`,
          `"${String(toAuditActor(r)).replaceAll('"', '""')}"`,
          `"${String(r.TargetDisplayName ?? "").replaceAll('"', '""')}"`,
          `"${String(r.RoleName ?? r.RoleNames ?? "").replaceAll('"', '""')}"`,
          `"${String(toAuditSummary(r)).replaceAll('"', '""')}"`,
          `"${String(r.Details ?? "").replaceAll('"', '""')}"`,
        ].join(",")
      )
    );
    const blob = new Blob([lines.join("\n")], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "audit_logs.csv";
    a.click();
    URL.revokeObjectURL(url);
  }

  if (loading) return <div className="text-sm text-muted-foreground">Loading audit logs...</div>;

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap gap-2">
        <input
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
          placeholder="Search audit logs..."
          className="rounded-lg border border-input bg-input-background px-3 py-2 text-sm"
        />
        <select
          value={eventType}
          onChange={(e) => {
            setEventType(e.target.value);
            setPage(1);
          }}
          className="rounded-lg border border-input bg-input-background px-3 py-2 text-sm"
        >
          <option value="">All event types</option>
          {eventTypes.map((x) => (
            <option key={x} value={x}>
              {x}
            </option>
          ))}
        </select>
        <button onClick={exportCsv} className="rounded-lg bg-primary px-3 py-2 text-sm text-primary-foreground">
          Export CSV
        </button>
      </div>

      <div className="rounded-lg border border-border bg-card">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-left text-muted-foreground">
            <tr>
              <th className="p-3">Time</th>
              <th className="p-3">Event</th>
              <th className="p-3">Actor</th>
              <th className="p-3">Target</th>
              <th className="p-3">Summary</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.AuditLogId} className="border-b border-border">
                <td className="p-3">{formatDateTimeMinute(r.EventUtc)}</td>
                <td className="p-3">{toFriendlyAuditEvent(r.EventType)}</td>
                <td className="p-3">{toAuditActor(r)}</td>
                <td className="p-3">{r.TargetDisplayName ?? "-"}</td>
                <td className="p-3">{toAuditSummary(r) || "-"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="flex items-center gap-2 text-xs">
        <button disabled={page <= 1} onClick={() => setPage((p) => p - 1)} className="rounded border px-2 py-1 disabled:opacity-50">
          Prev
        </button>
        <span>Page {page} / {pageCount}</span>
        <button
          disabled={!hasNextPage}
          onClick={() => setPage((p) => p + 1)}
          className="rounded border px-2 py-1 disabled:opacity-50"
        >
          Next
        </button>
      </div>

      {error && <div className="text-sm text-destructive">{error}</div>}
    </div>
  );
}


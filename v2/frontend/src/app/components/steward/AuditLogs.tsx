import { useEffect, useMemo, useState } from "react";
import { fetchAuditLogs } from "@/api/endpoints";
import type { AuditLogEntry } from "@/api/types";

const PAGE_SIZE = 25;

export function AuditLogs() {
  const [rows, setRows] = useState<AuditLogEntry[]>([]);
  const [search, setSearch] = useState("");
  const [eventType, setEventType] = useState("");
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = () => {
    setLoading(true);
    fetchAuditLogs()
      .then(setRows)
      .catch((e) => setError(e.message ?? "Failed to load audit logs."))
      .finally(() => setLoading(false));
  };
  useEffect(load, []);

  const filtered = useMemo(
    () =>
      rows.filter((r) => {
        const byType = !eventType || String(r.EventType) === eventType;
        const s = search.toLowerCase();
        const bySearch =
          !s ||
          String(r.EventType ?? "").toLowerCase().includes(s) ||
          String(r.Details ?? "").toLowerCase().includes(s) ||
          String(r.AuditLogId ?? "").toLowerCase().includes(s);
        return byType && bySearch;
      }),
    [rows, search, eventType]
  );

  const pageCount = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const paged = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);
  const eventTypes = Array.from(new Set(rows.map((x) => String(x.EventType ?? "")))).filter(Boolean);

  function exportCsv() {
    const header = ["AuditLogId", "EventUtc", "EventType", "UserId", "Details"];
    const lines = [header.join(",")].concat(
      filtered.map((r) =>
        [
          r.AuditLogId,
          `"${String(r.EventUtc ?? "").replaceAll('"', '""')}"`,
          `"${String(r.EventType ?? "").replaceAll('"', '""')}"`,
          r.UserId ?? "",
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
          onChange={(e) => setSearch(e.target.value)}
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
              <th className="p-3">Details</th>
            </tr>
          </thead>
          <tbody>
            {paged.map((r) => (
              <tr key={r.AuditLogId} className="border-b border-border">
                <td className="p-3">{new Date(r.EventUtc).toLocaleString()}</td>
                <td className="p-3">{r.EventType}</td>
                <td className="p-3">{r.UserId ?? "-"}</td>
                <td className="p-3">{String(r.Details ?? "").slice(0, 120)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="flex items-center gap-2 text-xs">
        <button disabled={page <= 1} onClick={() => setPage((p) => p - 1)} className="rounded border px-2 py-1 disabled:opacity-50">
          Prev
        </button>
        <span>
          Page {page} / {pageCount}
        </span>
        <button
          disabled={page >= pageCount}
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


import type { AuditLogEntry } from "@/api/types";
import { formatDateTimeMinuteAmsterdam } from "@/app/components/shared/dateTime";

export function formatDateTimeMinute(value?: string | null): string {
  return formatDateTimeMinuteAmsterdam(value);
}

export function toFriendlyAuditEvent(eventType?: string | null): string {
  if (!eventType) return "Event";
  if (eventType === "Approved") return "Request Approved";
  if (eventType === "Denied") return "Request Denied";
  if (eventType === "RequestCreated") return "Request Created";
  if (eventType === "RequestCancelled") return "Request Cancelled";
  if (eventType === "GrantIssued") return "Grant Issued";
  if (eventType === "GrantExpired") return "Grant Expired";
  return eventType;
}

export function toAuditSummary(entry: AuditLogEntry): string {
  return String(entry.DisplayMessage ?? entry.Details ?? "");
}

export function toAuditActor(entry: AuditLogEntry): string {
  return String(entry.ActorDisplayName ?? entry.UserId ?? "System");
}

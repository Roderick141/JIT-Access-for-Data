export function parseUtcLike(value?: string | null): Date | null {
  if (!value) return null;
  const hasZone = /[zZ]|[+\-]\d{2}:\d{2}$/.test(value);
  const normalized = value.includes(" ") ? value.replace(" ", "T") : value;
  const parsed = new Date(hasZone ? normalized : `${normalized}Z`);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

export function formatDateTimeMinuteAmsterdam(value?: string | null): string {
  const source = parseUtcLike(value);
  if (!source) return value ? String(value) : "";
  const rounded = new Date(Math.round(source.getTime() / 60000) * 60000);

  return new Intl.DateTimeFormat("nl-NL", {
    timeZone: "Europe/Amsterdam",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).format(rounded);
}

export function formatDateAmsterdam(value?: string | null, empty = "Never"): string {
  const source = parseUtcLike(value);
  if (!source) return value ? String(value) : empty;
  return new Intl.DateTimeFormat("nl-NL", {
    timeZone: "Europe/Amsterdam",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(source);
}

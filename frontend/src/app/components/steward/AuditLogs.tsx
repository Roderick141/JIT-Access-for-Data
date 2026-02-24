import { FileText } from "lucide-react";

export function AuditLogs() {
  return (
    <div className="space-y-6">
      {/* Placeholder */}
      <div className="rounded-lg border border-border bg-card p-12 text-center">
        <FileText className="mx-auto h-16 w-16 text-muted-foreground" />
        <h3 className="mt-4 text-lg text-card-foreground">Audit Logs</h3>
        <p className="mt-2 text-sm text-muted-foreground">
          This feature will be implemented later. It will track all user activities, access changes, and system events.
        </p>
        <div className="mt-6 inline-flex flex-col items-start gap-2 rounded-lg bg-muted/50 p-4 text-left">
          <p className="text-xs text-muted-foreground">Planned features:</p>
          <ul className="space-y-1 text-xs text-muted-foreground">
            <li>• User login/logout tracking</li>
            <li>• Access request approvals and rejections</li>
            <li>• Role and permission changes</li>
            <li>• System configuration changes</li>
            <li>• Advanced filtering and search</li>
            <li>• Export capabilities</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

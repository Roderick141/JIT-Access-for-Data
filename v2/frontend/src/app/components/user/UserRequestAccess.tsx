import { useState, useMemo, useEffect } from "react";
import { Search, Database, Shield, ArrowUpDown, Clock, AlertTriangle, Star } from "lucide-react";
import { fetchRequestableRoles, submitAccessRequest } from "@/api/endpoints";
import type { RequestableRole } from "@/api/types";

type SortField = "name" | "sensitivity" | "maxDuration";
type SortDirection = "asc" | "desc";

function getRoleIcon(sensitivityLevel: string) {
  return sensitivityLevel?.toLowerCase() === "sensitive" ? Shield : Database;
}

function getRoleColor(sensitivityLevel: string) {
  return sensitivityLevel?.toLowerCase() === "sensitive" ? "bg-red-500" : "bg-blue-500";
}

export function UserRequestAccess() {
  const [roles, setRoles] = useState<RequestableRole[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [selectedRoles, setSelectedRoles] = useState<number[]>([]);
  const [justification, setJustification] = useState("");
  const [duration, setDuration] = useState("30");
  const [ticketNumber, setTicketNumber] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [sortField, setSortField] = useState<SortField>("name");
  const [sortDirection, setSortDirection] = useState<SortDirection>("asc");
  const [favoriteRoles, setFavoriteRoles] = useState<Set<string>>(new Set());
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Load roles from API
  useEffect(() => {
    setIsLoading(true);
    fetchRequestableRoles()
      .then((data) => {
        setRoles(data);
        setLoadError(null);
      })
      .catch((err) => setLoadError(err.message ?? "Failed to load roles."))
      .finally(() => setIsLoading(false));
  }, []);

  // Load favorites from localStorage on mount
  useEffect(() => {
    const storedFavorites = localStorage.getItem("iam-favorite-roles");
    if (storedFavorites) {
      try {
        const parsed = JSON.parse(storedFavorites);
        setFavoriteRoles(new Set(parsed));
      } catch (e) {
        console.error("Failed to parse favorites from localStorage", e);
      }
    }
  }, []);

  // Save favorites to localStorage whenever they change
  useEffect(() => {
    localStorage.setItem("iam-favorite-roles", JSON.stringify(Array.from(favoriteRoles)));
  }, [favoriteRoles]);

  const toggleFavorite = (roleId: number) => {
    const key = String(roleId);
    setFavoriteRoles((prev) => {
      const next = new Set(prev);
      if (next.has(key)) {
        next.delete(key);
      } else {
        next.add(key);
      }
      return next;
    });
  };

  // Calculate max allowed duration based on selected roles (in days)
  const maxAllowedDuration = useMemo(() => {
    if (selectedRoles.length === 0) return 365;
    const selected = roles.filter((r) => selectedRoles.includes(r.RoleId));
    if (selected.length === 0) return 365;
    const minMinutes = Math.min(...selected.map((r) => r.MaxDurationMinutes));
    return Math.floor(minMinutes / 1440) || 1;
  }, [selectedRoles, roles]);

  // Update duration when selected roles change
  useEffect(() => {
    if (selectedRoles.length > 0) {
      setDuration(String(maxAllowedDuration));
    }
  }, [selectedRoles, maxAllowedDuration]);

  const toggleRoleSelection = (roleId: number) => {
    if (selectedRoles.includes(roleId)) {
      setSelectedRoles(selectedRoles.filter((id) => id !== roleId));
    } else {
      setSelectedRoles([...selectedRoles, roleId]);
    }
  };

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDirection(sortDirection === "asc" ? "desc" : "asc");
    } else {
      setSortField(field);
      setSortDirection("asc");
    }
  };

  const filteredAndSortedRoles = useMemo(() => {
    let filtered = roles.filter((role) => {
      const searchLower = searchQuery.toLowerCase();
      return (
        role.RoleName.toLowerCase().includes(searchLower) ||
        (role.RoleDescription ?? "").toLowerCase().includes(searchLower) ||
        role.SensitivityLevel.toLowerCase().includes(searchLower)
      );
    });

    const favorites = filtered.filter((r) => favoriteRoles.has(String(r.RoleId)));
    const nonFavorites = filtered.filter((r) => !favoriteRoles.has(String(r.RoleId)));

    const sortRoles = (list: typeof filtered) =>
      [...list].sort((a, b) => {
        let cmp = 0;
        switch (sortField) {
          case "name":
            cmp = a.RoleName.localeCompare(b.RoleName);
            break;
          case "sensitivity":
            cmp = a.SensitivityLevel.localeCompare(b.SensitivityLevel);
            break;
          case "maxDuration":
            cmp = a.MaxDurationMinutes - b.MaxDurationMinutes;
            break;
        }
        return sortDirection === "asc" ? cmp : -cmp;
      });

    return [...sortRoles(favorites), ...sortRoles(nonFavorites)];
  }, [searchQuery, sortField, sortDirection, favoriteRoles, roles]);

  const anyRequiresJustification = useMemo(() => {
    if (selectedRoles.length === 0) return false;
    return roles
      .filter((r) => selectedRoles.includes(r.RoleId))
      .some((r) => r.RequiresJustification);
  }, [selectedRoles, roles]);

  const hasJustification = justification.trim().length > 0;
  const hasTicket = ticketNumber.trim().length > 0;
  const justificationSatisfied = !anyRequiresJustification || hasJustification || hasTicket;

  const handleSubmitRequest = async () => {
    if (selectedRoles.length === 0 || !duration || !justificationSatisfied) return;
    setIsSubmitting(true);
    try {
      await submitAccessRequest({
        roleIds: selectedRoles,
        durationMinutes: parseInt(duration) * 1440,
        justification: justification || undefined as unknown as string,
        ticketRef: ticketNumber || undefined,
      });
      setSelectedRoles([]);
      setJustification("");
      setDuration("30");
      setTicketNumber("");
    } catch (err: unknown) {
      alert(`Failed to submit request: ${err instanceof Error ? err.message : String(err)}`);
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isLoading) {
    return <div className="p-8 text-sm text-muted-foreground">Loading roles...</div>;
  }
  if (loadError) {
    return <div className="p-8 text-sm text-destructive">Error: {loadError}</div>;
  }

  return (
    <div className="space-y-6">
      {/* Search */}
      <div className="relative max-w-md">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <input
          type="text"
          placeholder="Search roles by name, description, or approver..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full rounded-lg border border-input bg-input-background py-2 pl-10 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
        />
      </div>

      {/* Selected Roles Summary */}
      {selectedRoles.length > 0 && (
        <div className="rounded-lg border border-primary bg-primary/5 p-3">
          <div className="flex items-center justify-between">
            <div>
              <h4 className="text-sm text-card-foreground">Selected Roles ({selectedRoles.length})</h4>
              <p className="text-xs text-muted-foreground">
                {roles
                  .filter((r) => selectedRoles.includes(r.RoleId))
                  .map((r) => r.RoleName)
                  .join(", ")}
              </p>
            </div>
            <button onClick={() => setSelectedRoles([])} className="text-sm text-destructive hover:underline">
              Clear All
            </button>
          </div>
        </div>
      )}

      {/* Main Content - Table and Form Side by Side */}
      <div className="flex gap-6 items-start">
        {/* Available Roles Table */}
        <div className={selectedRoles.length > 0 ? "flex-1" : "w-full"}>
          <div className="mb-3 flex items-center justify-between">
            <h3 className="text-card-foreground">Available Roles</h3>
            <span className="text-sm text-muted-foreground">
              {filteredAndSortedRoles.length}{" "}
              {filteredAndSortedRoles.length === 1 ? "role" : "roles"}
            </span>
          </div>

          <div className="overflow-hidden rounded-lg border border-border bg-card">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="border-b border-border bg-muted/50">
                  <tr>
                    <th className="w-12 p-3 text-left">
                      <input
                        type="checkbox"
                        checked={
                          selectedRoles.length === filteredAndSortedRoles.length &&
                          filteredAndSortedRoles.length > 0
                        }
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedRoles(filteredAndSortedRoles.map((r) => r.RoleId));
                          } else {
                            setSelectedRoles([]);
                          }
                        }}
                        className="h-4 w-4 cursor-pointer rounded border-2 border-input bg-input-background accent-primary focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
                      />
                    </th>
                    <th className="w-12"></th>
                    <th className="w-12"></th>
                    <th
                      className="cursor-pointer p-3 text-left text-sm text-muted-foreground hover:text-foreground"
                      onClick={() => handleSort("name")}
                    >
                      <div className="flex items-center gap-2">
                        Role Name
                        <ArrowUpDown className="h-3 w-3" />
                      </div>
                    </th>
                    <th className="p-3 text-left text-sm text-muted-foreground">Description</th>
                    <th
                      className="cursor-pointer p-3 text-left text-sm text-muted-foreground hover:text-foreground"
                      onClick={() => handleSort("sensitivity")}
                    >
                      <div className="flex items-center gap-2">
                        Sensitivity
                        <ArrowUpDown className="h-3 w-3" />
                      </div>
                    </th>
                    <th
                      className="cursor-pointer p-3 text-left text-sm text-muted-foreground hover:text-foreground"
                      onClick={() => handleSort("maxDuration")}
                    >
                      <div className="flex items-center gap-2">
                        Max Duration
                        <ArrowUpDown className="h-3 w-3" />
                      </div>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {filteredAndSortedRoles.map((role) => {
                    const Icon = getRoleIcon(role.SensitivityLevel);
                    const color = getRoleColor(role.SensitivityLevel);
                    const isSelected = selectedRoles.includes(role.RoleId);
                    const isFavorite = favoriteRoles.has(String(role.RoleId));
                    const isSensitive = role.SensitivityLevel?.toLowerCase() === "sensitive";
                    const maxDays = Math.floor(role.MaxDurationMinutes / 1440) || 1;

                    return (
                      <tr
                        key={role.RoleId}
                        onClick={() => toggleRoleSelection(role.RoleId)}
                        className={`cursor-pointer border-b border-border transition-colors hover:bg-muted/50 ${
                          isSelected ? "bg-primary/5" : ""
                        }`}
                      >
                        <td className="p-3" onClick={(e) => e.stopPropagation()}>
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => toggleRoleSelection(role.RoleId)}
                            className="h-4 w-4 cursor-pointer rounded border-2 border-input bg-input-background accent-primary focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
                          />
                        </td>
                        <td className="p-3">
                          <div className={`flex h-8 w-8 items-center justify-center rounded ${color}`}>
                            <Icon className="h-4 w-4 text-white" />
                          </div>
                        </td>
                        <td className="p-3" onClick={(e) => e.stopPropagation()}>
                          <button
                            onClick={() => toggleFavorite(role.RoleId)}
                            className="transition-colors hover:scale-110"
                            aria-label={isFavorite ? "Remove from favorites" : "Add to favorites"}
                          >
                            <Star
                              className={`h-4 w-4 ${
                                isFavorite
                                  ? "fill-yellow-500 text-yellow-500"
                                  : "text-muted-foreground hover:text-yellow-500"
                              }`}
                            />
                          </button>
                        </td>
                        <td className="p-3 text-sm text-card-foreground">{role.RoleName}</td>
                        <td className="p-3 text-sm text-muted-foreground">
                          <span className="line-clamp-2">{role.RoleDescription ?? ""}</span>
                        </td>
                        <td className="p-3">
                          <span
                            className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs ${
                              isSensitive
                                ? "bg-destructive/10 text-destructive"
                                : "bg-muted text-muted-foreground"
                            }`}
                          >
                            {isSensitive && <AlertTriangle className="h-3 w-3" />}
                            {isSensitive ? "Sensitive" : "Standard"}
                          </span>
                        </td>
                        <td className="p-3 text-sm text-muted-foreground">
                          <div className="flex items-center gap-1">
                            <Clock className="h-3 w-3" />
                            {maxDays} days
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                  {filteredAndSortedRoles.length === 0 && (
                    <tr>
                      <td colSpan={7} className="p-8 text-center text-sm text-muted-foreground">
                        No roles found matching your search criteria
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Sticky Request Form Sidebar */}
        {selectedRoles.length > 0 && (
          <div className="w-[380px] flex-shrink-0">
            <div className="sticky top-6">
              <div className="rounded-lg border border-primary bg-card p-5">
                <h3 className="text-card-foreground">Submit Request</h3>
                <p className="mt-1 text-sm text-muted-foreground">
                  You are requesting access to {selectedRoles.length} role
                  {selectedRoles.length > 1 ? "s" : ""}
                </p>

                <div className="mt-4">
                  <label className="text-sm text-card-foreground">
                    Access Duration (days) <span className="text-destructive">*</span>
                  </label>
                  <div className="mt-2 flex items-center gap-2">
                    <Clock className="h-4 w-4 text-muted-foreground" />
                    <input
                      type="number"
                      min="1"
                      max={maxAllowedDuration}
                      value={duration}
                      onChange={(e) => {
                        const val = parseInt(e.target.value);
                        if (val <= maxAllowedDuration) {
                          setDuration(e.target.value);
                        }
                      }}
                      className="w-20 rounded-lg border border-input bg-input-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                    />
                    <span className="text-sm text-muted-foreground">days</span>
                  </div>
                  <p className="mt-1 text-xs text-muted-foreground">
                    Maximum allowed: {maxAllowedDuration} days
                  </p>
                </div>

                <div className="mt-4">
                  <label className="text-sm text-card-foreground">
                    Business Justification {anyRequiresJustification && !hasTicket && <span className="text-destructive">*</span>}
                  </label>
                  <textarea
                    value={justification}
                    onChange={(e) => setJustification(e.target.value)}
                    placeholder="Please provide a detailed business justification for this access request. Include specific use cases and how this access will help you perform your job duties."
                    rows={6}
                    className="mt-2 w-full rounded-lg border border-input bg-input-background p-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                  {anyRequiresJustification && (
                    <p className="mt-1 text-xs text-muted-foreground">
                      A justification or ticket reference is required for the selected role(s)
                    </p>
                  )}
                </div>

                <div className="mt-4">
                  <label className="text-sm text-card-foreground">
                    Ticket Reference {anyRequiresJustification && !hasJustification && <span className="text-destructive">*</span>}
                  </label>
                  <input
                    type="text"
                    value={ticketNumber}
                    onChange={(e) => setTicketNumber(e.target.value)}
                    placeholder="e.g., TICKET-12345"
                    className="mt-2 w-full rounded-lg border border-input bg-input-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>

                {anyRequiresJustification && !justificationSatisfied && (
                  <p className="mt-2 text-xs text-destructive">
                    Please provide either a justification or a ticket reference
                  </p>
                )}

                <div className="mt-4 flex flex-col gap-2">
                  <button
                    onClick={handleSubmitRequest}
                    disabled={!duration || !justificationSatisfied || isSubmitting}
                    className="w-full rounded-lg bg-primary px-6 py-2 text-sm text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isSubmitting ? "Submitting..." : "Submit Request"}
                  </button>
                  <button
                    onClick={() => {
                      setSelectedRoles([]);
                      setJustification("");
                      setDuration("30");
                      setTicketNumber("");
                    }}
                    className="w-full rounded-lg border border-border bg-card px-6 py-2 text-sm text-foreground hover:bg-secondary"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

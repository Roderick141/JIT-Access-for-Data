import { useState, useMemo, useEffect } from "react";
import { Search, Database, Users, Globe, Shield, FileText, Calendar, ArrowUpDown, Check, Clock, AlertTriangle, Star } from "lucide-react";

type SortField = "name" | "sensitivity" | "maxDuration";
type SortDirection = "asc" | "desc";
type Sensitivity = "standard" | "sensitive";

export function UserRequestAccess() {
  const [selectedRoles, setSelectedRoles] = useState<string[]>([]);
  const [justification, setJustification] = useState("");
  const [duration, setDuration] = useState("30");
  const [ticketNumber, setTicketNumber] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [sortField, setSortField] = useState<SortField>("name");
  const [sortDirection, setSortDirection] = useState<SortDirection>("asc");
  const [favoriteRoles, setFavoriteRoles] = useState<Set<string>>(new Set());

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

  const toggleFavorite = (roleId: string) => {
    setFavoriteRoles(prev => {
      const newFavorites = new Set(prev);
      if (newFavorites.has(roleId)) {
        newFavorites.delete(roleId);
      } else {
        newFavorites.add(roleId);
      }
      return newFavorites;
    });
  };

  const availableRoles = [
    {
      id: "finance-db",
      name: "Finance Database Access",
      description: "Read access to financial data and reports",
      approver: "Finance Team Lead",
      sensitivity: "sensitive" as Sensitivity,
      maxDuration: 90,
      icon: Database,
      color: "bg-blue-500",
    },
    {
      id: "marketing-analytics",
      name: "Marketing Analytics",
      description: "Access to marketing dashboards and campaign data",
      approver: "Marketing Manager",
      sensitivity: "standard" as Sensitivity,
      maxDuration: 180,
      icon: Globe,
      color: "bg-purple-500",
    },
    {
      id: "hr-systems",
      name: "HR Systems Access",
      description: "Access to HR management tools and employee data",
      approver: "HR Director",
      sensitivity: "sensitive" as Sensitivity,
      maxDuration: 60,
      icon: Users,
      color: "bg-green-500",
    },
    {
      id: "admin-limited",
      name: "Admin Panel - Limited",
      description: "Limited administrative access for system management",
      approver: "System Administrator",
      sensitivity: "sensitive" as Sensitivity,
      maxDuration: 30,
      icon: Shield,
      color: "bg-red-500",
    },
    {
      id: "doc-repo",
      name: "Document Repository",
      description: "Access to shared company documents and files",
      approver: "Department Manager",
      sensitivity: "standard" as Sensitivity,
      maxDuration: 365,
      icon: FileText,
      color: "bg-teal-500",
    },
    {
      id: "crm-access",
      name: "CRM Access",
      description: "Access to customer relationship management system",
      approver: "Sales Director",
      sensitivity: "standard" as Sensitivity,
      maxDuration: 180,
      icon: Users,
      color: "bg-orange-500",
    },
    {
      id: "analytics-platform",
      name: "Analytics Platform",
      description: "Full access to business intelligence and analytics tools",
      approver: "Data Team Lead",
      sensitivity: "sensitive" as Sensitivity,
      maxDuration: 90,
      icon: Database,
      color: "bg-indigo-500",
    },
    {
      id: "code-repo",
      name: "Code Repository Access",
      description: "Access to source code repositories and version control",
      approver: "Engineering Manager",
      sensitivity: "standard" as Sensitivity,
      maxDuration: 365,
      icon: FileText,
      color: "bg-gray-500",
    },
  ];

  // Calculate max allowed duration based on selected roles
  const maxAllowedDuration = useMemo(() => {
    if (selectedRoles.length === 0) return 365;
    
    const selectedRoleObjects = availableRoles.filter(role => selectedRoles.includes(role.id));
    const minDuration = Math.min(...selectedRoleObjects.map(role => role.maxDuration));
    return minDuration;
  }, [selectedRoles]);

  // Update duration when selected roles change
  useEffect(() => {
    if (selectedRoles.length > 0) {
      setDuration(String(maxAllowedDuration));
    }
  }, [selectedRoles, maxAllowedDuration]);

  const toggleRoleSelection = (roleId: string) => {
    if (selectedRoles.includes(roleId)) {
      setSelectedRoles(selectedRoles.filter(id => id !== roleId));
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
    let filtered = availableRoles.filter(role => {
      const searchLower = searchQuery.toLowerCase();
      return (
        role.name.toLowerCase().includes(searchLower) ||
        role.description.toLowerCase().includes(searchLower) ||
        role.approver.toLowerCase().includes(searchLower) ||
        role.sensitivity.toLowerCase().includes(searchLower)
      );
    });

    // First separate favorites from non-favorites
    const favorites = filtered.filter(role => favoriteRoles.has(role.id));
    const nonFavorites = filtered.filter(role => !favoriteRoles.has(role.id));

    // Sort each group independently
    const sortRoles = (roles: typeof filtered) => {
      return roles.sort((a, b) => {
        let comparison = 0;
        
        switch (sortField) {
          case "name":
            comparison = a.name.localeCompare(b.name);
            break;
          case "sensitivity":
            comparison = a.sensitivity.localeCompare(b.sensitivity);
            break;
          case "maxDuration":
            comparison = a.maxDuration - b.maxDuration;
            break;
        }

        return sortDirection === "asc" ? comparison : -comparison;
      });
    };

    // Sort both groups and concatenate: favorites first, then non-favorites
    return [...sortRoles(favorites), ...sortRoles(nonFavorites)];
  }, [searchQuery, sortField, sortDirection, favoriteRoles]);

  const handleSubmitRequest = () => {
    if (selectedRoles.length > 0 && justification && duration && ticketNumber) {
      const selectedRoleNames = availableRoles
        .filter(role => selectedRoles.includes(role.id))
        .map(role => role.name)
        .join(", ");
      
      alert(`Request submitted for:\n${selectedRoleNames}\n\nDuration: ${duration} days\n\nTicket Number: ${ticketNumber}\n\nJustification: ${justification}`);
      setSelectedRoles([]);
      setJustification("");
      setDuration("30");
      setTicketNumber("");
    }
  };

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
                {availableRoles
                  .filter(role => selectedRoles.includes(role.id))
                  .map(role => role.name)
                  .join(", ")}
              </p>
            </div>
            <button
              onClick={() => setSelectedRoles([])}
              className="text-sm text-destructive hover:underline"
            >
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
            {filteredAndSortedRoles.length} {filteredAndSortedRoles.length === 1 ? 'role' : 'roles'}
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
                      checked={selectedRoles.length === filteredAndSortedRoles.length && filteredAndSortedRoles.length > 0}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedRoles(filteredAndSortedRoles.map(r => r.id));
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
                  <th className="p-3 text-left text-sm text-muted-foreground">
                    Description
                  </th>
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
                  const Icon = role.icon;
                  const isSelected = selectedRoles.includes(role.id);
                  const isFavorite = favoriteRoles.has(role.id);

                  return (
                    <tr
                      key={role.id}
                      onClick={() => toggleRoleSelection(role.id)}
                      className={`cursor-pointer border-b border-border transition-colors hover:bg-muted/50 ${
                        isSelected ? "bg-primary/5" : ""
                      }`}
                    >
                      <td className="p-3" onClick={(e) => e.stopPropagation()}>
                        <input
                          type="checkbox"
                          checked={isSelected}
                          onChange={() => toggleRoleSelection(role.id)}
                          className="h-4 w-4 cursor-pointer rounded border-2 border-input bg-input-background accent-primary focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
                        />
                      </td>
                      <td className="p-3">
                        <div className={`flex h-8 w-8 items-center justify-center rounded ${role.color}`}>
                          <Icon className="h-4 w-4 text-white" />
                        </div>
                      </td>
                      <td className="p-3" onClick={(e) => e.stopPropagation()}>
                        <button
                          onClick={() => toggleFavorite(role.id)}
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
                      <td className="p-3 text-sm text-card-foreground">
                        {role.name}
                      </td>
                      <td className="p-3 text-sm text-muted-foreground">
                        <span className="line-clamp-2">{role.description}</span>
                      </td>
                      <td className="p-3">
                        <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs ${
                          role.sensitivity === "sensitive" 
                            ? "bg-destructive/10 text-destructive" 
                            : "bg-muted text-muted-foreground"
                        }`}>
                          {role.sensitivity === "sensitive" && <AlertTriangle className="h-3 w-3" />}
                          {role.sensitivity === "sensitive" ? "Sensitive" : "Standard"}
                        </span>
                      </td>
                      <td className="p-3 text-sm text-muted-foreground">
                        <div className="flex items-center gap-1">
                          <Clock className="h-3 w-3" />
                          {role.maxDuration} days
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
                  You are requesting access to {selectedRoles.length} role{selectedRoles.length > 1 ? "s" : ""}
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
                    Business Justification <span className="text-destructive">*</span>
                  </label>
                  <textarea
                    value={justification}
                    onChange={(e) => setJustification(e.target.value)}
                    placeholder="Please provide a detailed business justification for this access request. Include specific use cases and how this access will help you perform your job duties."
                    rows={6}
                    className="mt-2 w-full rounded-lg border border-input bg-input-background p-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                  <p className="mt-1 text-xs text-muted-foreground">
                    A clear justification helps expedite the approval process
                  </p>
                </div>

                <div className="mt-4">
                  <label className="text-sm text-card-foreground">
                    Ticket Number <span className="text-destructive">*</span>
                  </label>
                  <input
                    type="text"
                    value={ticketNumber}
                    onChange={(e) => setTicketNumber(e.target.value)}
                    placeholder="e.g., TICKET-12345"
                    className="mt-2 w-full rounded-lg border border-input bg-input-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>

                <div className="mt-4 flex flex-col gap-2">
                  <button
                    onClick={handleSubmitRequest}
                    disabled={!justification || !duration || !ticketNumber}
                    className="w-full rounded-lg bg-primary px-6 py-2 text-sm text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Submit Request
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

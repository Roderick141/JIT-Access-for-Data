import { useState } from "react";
import { Plus, Users, Edit, Trash2, UserPlus, Search } from "lucide-react";

export function ManageTeams() {
  const [searchQuery, setSearchQuery] = useState("");
  const teams = [
    {
      name: "Finance Team",
      description: "Financial operations and reporting",
      members: 12,
      roles: ["Finance Database Access", "Expense Management"],
      lead: "Sarah Johnson",
      department: "Finance",
    },
    {
      name: "Marketing Team",
      description: "Marketing and communications",
      members: 24,
      roles: ["Marketing Analytics", "Social Media Tools", "Campaign Management"],
      lead: "Michael Chen",
      department: "Marketing",
    },
    {
      name: "Development Team",
      description: "Software development and engineering",
      members: 45,
      roles: ["Developer Tools", "Code Repository Access"],
      lead: "Lisa Wang",
      department: "Engineering",
    },
    {
      name: "HR Team",
      description: "Human resources and people operations",
      members: 8,
      roles: ["HR Systems Access", "Employee Data"],
      lead: "Robert Brown",
      department: "Human Resources",
    },
    {
      name: "Sales Team",
      description: "Sales and business development",
      members: 34,
      roles: ["CRM Access", "Sales Analytics"],
      lead: "Emily Davis",
      department: "Sales",
    },
  ];

  // Search and filter logic
  const filteredTeams = teams.filter(team => {
    const searchLower = searchQuery.toLowerCase();
    return (
      team.name.toLowerCase().includes(searchLower) ||
      team.description.toLowerCase().includes(searchLower) ||
      team.department.toLowerCase().includes(searchLower) ||
      team.lead.toLowerCase().includes(searchLower) ||
      team.roles.some(role => role.toLowerCase().includes(searchLower))
    );
  });

  return (
    <div className="space-y-6">
      {/* Header Actions */}
      <div className="flex items-center justify-between gap-3">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search teams by name, department, lead, or roles..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full rounded-lg border border-input bg-input-background py-2 pl-10 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </div>
        <button className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90">
          <Plus className="h-4 w-4" />
          Create New Team
        </button>
      </div>

      {/* Teams Grid */}
      <div className="grid gap-4 md:grid-cols-2">
        {filteredTeams.map((team, i) => (
          <div key={i} className="rounded-lg border border-border bg-card p-5">
            <div className="flex items-start justify-between">
              <div className="flex gap-3 flex-1">
                <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-primary">
                  <Users className="h-6 w-6 text-primary-foreground" />
                </div>
                <div className="flex-1">
                  <h3 className="text-card-foreground">{team.name}</h3>
                  <p className="text-sm text-muted-foreground">{team.description}</p>
                  <div className="mt-2 flex flex-wrap gap-2 text-xs text-muted-foreground">
                    <span>{team.members} members</span>
                    <span>•</span>
                    <span>{team.department}</span>
                  </div>
                </div>
              </div>
              <div className="flex gap-1">
                <button className="rounded-lg p-2 hover:bg-secondary">
                  <Edit className="h-4 w-4 text-muted-foreground" />
                </button>
                <button className="rounded-lg p-2 hover:bg-destructive/10">
                  <Trash2 className="h-4 w-4 text-destructive" />
                </button>
              </div>
            </div>

            <div className="mt-4 text-sm">
              <span className="text-muted-foreground">Team Lead:</span>
              <span className="ml-2 text-card-foreground">{team.lead}</span>
            </div>

            <div className="mt-4">
              <p className="text-xs text-muted-foreground">Assigned Roles:</p>
              <div className="mt-2 flex flex-wrap gap-1">
                {team.roles.map((role, idx) => (
                  <span
                    key={idx}
                    className="rounded-full bg-secondary px-2 py-1 text-xs text-secondary-foreground"
                  >
                    {role}
                  </span>
                ))}
              </div>
            </div>

            <div className="mt-4 flex gap-3 border-t border-border pt-4">
              <button className="flex items-center gap-1 text-sm text-primary hover:underline">
                <UserPlus className="h-3 w-3" />
                Add Members
              </button>
              <button className="text-sm text-primary hover:underline">
                View Details
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* No results message */}
      {filteredTeams.length === 0 && (
        <div className="rounded-lg border border-border bg-card p-8 text-center">
          <p className="text-muted-foreground">No teams found matching your search criteria.</p>
        </div>
      )}
    </div>
  );
}

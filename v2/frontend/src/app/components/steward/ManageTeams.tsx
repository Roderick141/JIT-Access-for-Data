import { useState, useEffect } from "react";
import { Plus, Users, Edit, Trash2, UserPlus, Search, X } from "lucide-react";
import {
  fetchAdminTeams,
  createTeam,
  updateTeam,
  deleteTeam,
  fetchTeamMembers,
} from "@/api/endpoints";
import type { Team, TeamMember } from "@/api/types";

interface TeamMapped {
  id: number;
  name: string;
  description: string;
  members: number;
  roles: string[];
  lead: string;
  department: string;
  isActive: boolean;
}

function mapTeam(t: Team): TeamMapped {
  return {
    id: t.TeamId,
    name: t.TeamName,
    description: t.TeamDescription ?? "",
    members: 0,
    roles: [],
    lead: "",
    department: String(t["Department"] ?? t["TeamDepartment"] ?? ""),
    isActive: t.IsActive,
  };
}

export function ManageTeams() {
  const [teams, setTeams] = useState<TeamMapped[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");

  // Create / Edit modal
  const [createEditModalOpen, setCreateEditModalOpen] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [selectedTeam, setSelectedTeam] = useState<TeamMapped | null>(null);
  const [formData, setFormData] = useState({ name: "", description: "", department: "" });

  // Delete modal
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);

  // Members modal
  const [membersModalOpen, setMembersModalOpen] = useState(false);
  const [membersData, setMembersData] = useState<TeamMember[]>([]);

  const loadTeams = () => {
    setIsLoading(true);
    fetchAdminTeams()
      .then((data) => setTeams(data.map(mapTeam)))
      .catch(console.error)
      .finally(() => setIsLoading(false));
  };

  useEffect(() => {
    loadTeams();
  }, []);

  // ── Handlers ────────────────────────────────────────────────────────────────
  const handleCreateClick = () => {
    setSelectedTeam(null);
    setIsEditMode(false);
    setFormData({ name: "", description: "", department: "" });
    setCreateEditModalOpen(true);
  };

  const handleEditClick = (team: TeamMapped) => {
    setSelectedTeam(team);
    setIsEditMode(true);
    setFormData({ name: team.name, description: team.description, department: team.department });
    setCreateEditModalOpen(true);
  };

  const handleSaveTeam = async () => {
    try {
      const payload = {
        teamName: formData.name,
        description: formData.description,
        department: formData.department,
      };
      if (isEditMode && selectedTeam) {
        await updateTeam(selectedTeam.id, payload);
      } else {
        await createTeam(payload);
      }
      setCreateEditModalOpen(false);
      loadTeams();
    } catch (err: unknown) {
      alert(`Save failed: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const handleDeleteClick = (team: TeamMapped) => {
    setSelectedTeam(team);
    setDeleteModalOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!selectedTeam) return;
    try {
      await deleteTeam(selectedTeam.id);
      setDeleteModalOpen(false);
      setSelectedTeam(null);
      loadTeams();
    } catch (err: unknown) {
      alert(`Delete failed: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const handleViewMembers = async (team: TeamMapped) => {
    setSelectedTeam(team);
    setMembersModalOpen(true);
    try {
      const members = await fetchTeamMembers(team.id);
      setMembersData(members);
    } catch {
      setMembersData([]);
    }
  };

  // ── Filter ───────────────────────────────────────────────────────────────────
  const filteredTeams = teams.filter((team) => {
    const s = searchQuery.toLowerCase();
    return (
      team.name.toLowerCase().includes(s) ||
      team.description.toLowerCase().includes(s) ||
      team.department.toLowerCase().includes(s)
    );
  });

  if (isLoading) {
    return <div className="p-8 text-sm text-muted-foreground">Loading teams...</div>;
  }

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
        <button
          onClick={handleCreateClick}
          className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90"
        >
          <Plus className="h-4 w-4" />
          Create New Team
        </button>
      </div>

      {/* Teams Grid */}
      <div className="grid gap-4 md:grid-cols-2">
        {filteredTeams.map((team) => (
          <div key={team.id} className="rounded-lg border border-border bg-card p-5">
            <div className="flex items-start justify-between">
              <div className="flex gap-3 flex-1">
                <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-primary">
                  <Users className="h-6 w-6 text-primary-foreground" />
                </div>
                <div className="flex-1">
                  <h3 className="text-card-foreground">{team.name}</h3>
                  <p className="text-sm text-muted-foreground">{team.description}</p>
                  <div className="mt-2 flex flex-wrap gap-2 text-xs text-muted-foreground">
                    {team.members > 0 && <span>{team.members} members</span>}
                    {team.members > 0 && team.department && <span>•</span>}
                    {team.department && <span>{team.department}</span>}
                  </div>
                </div>
              </div>
              <div className="flex gap-1">
                <button
                  onClick={() => handleEditClick(team)}
                  className="rounded-lg p-2 hover:bg-secondary"
                  title="Edit team"
                >
                  <Edit className="h-4 w-4 text-muted-foreground" />
                </button>
                <button
                  onClick={() => handleDeleteClick(team)}
                  className="rounded-lg p-2 hover:bg-destructive/10"
                  title="Delete team"
                >
                  <Trash2 className="h-4 w-4 text-destructive" />
                </button>
              </div>
            </div>

            {team.lead && (
              <div className="mt-4 text-sm">
                <span className="text-muted-foreground">Team Lead:</span>
                <span className="ml-2 text-card-foreground">{team.lead}</span>
              </div>
            )}

            {team.roles.length > 0 && (
              <div className="mt-4">
                <p className="text-xs text-muted-foreground">Assigned Roles:</p>
                <div className="mt-2 flex flex-wrap gap-1">
                  {team.roles.map((role, idx) => (
                    <span key={idx} className="rounded-full bg-secondary px-2 py-1 text-xs text-secondary-foreground">
                      {role}
                    </span>
                  ))}
                </div>
              </div>
            )}

            <div className="mt-4 flex gap-3 border-t border-border pt-4">
              <button
                onClick={() => handleViewMembers(team)}
                className="flex items-center gap-1 text-sm text-primary hover:underline"
              >
                <UserPlus className="h-3 w-3" />
                Add Members
              </button>
              <button
                onClick={() => handleViewMembers(team)}
                className="text-sm text-primary hover:underline"
              >
                View Details
              </button>
            </div>
          </div>
        ))}
      </div>

      {filteredTeams.length === 0 && (
        <div className="rounded-lg border border-border bg-card p-8 text-center">
          <p className="text-muted-foreground">No teams found matching your search criteria.</p>
        </div>
      )}

      {/* ── Create / Edit Modal ───────────────────────────────────────────────── */}
      {createEditModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-lg border border-border bg-card p-6 shadow-lg">
            <div className="flex items-center justify-between">
              <h3 className="text-lg text-card-foreground">
                {isEditMode ? "Edit Team" : "Create New Team"}
              </h3>
              <button onClick={() => setCreateEditModalOpen(false)} className="rounded-lg p-1 hover:bg-secondary">
                <X className="h-5 w-5 text-muted-foreground" />
              </button>
            </div>

            <div className="mt-4 space-y-4">
              <div>
                <label className="text-sm text-card-foreground">
                  Team Name <span className="text-destructive">*</span>
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="Enter team name"
                  className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
              <div>
                <label className="text-sm text-card-foreground">Description</label>
                <textarea
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="Describe this team"
                  rows={2}
                  className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
              <div>
                <label className="text-sm text-card-foreground">Department</label>
                <input
                  type="text"
                  value={formData.department}
                  onChange={(e) => setFormData({ ...formData, department: e.target.value })}
                  placeholder="e.g., Finance"
                  className="mt-1 w-full rounded-lg border border-input bg-input-background p-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
            </div>

            <div className="mt-6 flex justify-end gap-3">
              <button
                onClick={() => setCreateEditModalOpen(false)}
                className="rounded-lg border border-border bg-card px-4 py-2 text-sm text-foreground hover:bg-secondary"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveTeam}
                disabled={!formData.name}
                className="rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isEditMode ? "Save Changes" : "Create Team"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Delete Modal ──────────────────────────────────────────────────────── */}
      {deleteModalOpen && selectedTeam && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md rounded-lg border border-border bg-card p-6 shadow-lg">
            <h3 className="text-lg text-card-foreground">Delete Team</h3>
            <p className="mt-2 text-sm text-muted-foreground">
              Are you sure you want to delete the team{" "}
              <span className="font-medium text-card-foreground">"{selectedTeam.name}"</span>?
            </p>
            <p className="mt-2 text-sm text-destructive">This action cannot be undone.</p>
            <div className="mt-6 flex justify-end gap-3">
              <button
                onClick={() => { setDeleteModalOpen(false); setSelectedTeam(null); }}
                className="rounded-lg border border-border bg-card px-4 py-2 text-sm text-foreground hover:bg-secondary"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmDelete}
                className="rounded-lg bg-destructive px-4 py-2 text-sm text-destructive-foreground hover:bg-destructive/90"
              >
                Delete Team
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Members Modal ─────────────────────────────────────────────────────── */}
      {membersModalOpen && selectedTeam && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-lg rounded-lg border border-border bg-card p-6 shadow-lg max-h-[80vh] flex flex-col">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-lg text-card-foreground">Members: {selectedTeam.name}</h3>
                <p className="text-sm text-muted-foreground">{membersData.length} members</p>
              </div>
              <button onClick={() => setMembersModalOpen(false)} className="rounded-lg p-1 hover:bg-secondary">
                <X className="h-5 w-5 text-muted-foreground" />
              </button>
            </div>

            <div className="mt-4 flex-1 overflow-y-auto">
              {membersData.length > 0 ? (
                <div className="divide-y divide-border rounded-lg border border-border">
                  {membersData.map((member) => (
                    <div key={member.UserId} className="p-3">
                      <div className="flex items-center gap-3">
                        <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary text-xs text-primary-foreground">
                          {member.DisplayName.split(" ").map((n) => n[0]).join("").slice(0, 2)}
                        </div>
                        <div>
                          <p className="text-sm text-card-foreground">{member.DisplayName}</p>
                          {member.Email && <p className="text-xs text-muted-foreground">{member.Email}</p>}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="rounded-lg border border-border bg-card p-8 text-center">
                  <p className="text-muted-foreground">No members found.</p>
                </div>
              )}
            </div>

            <div className="mt-4 flex justify-end border-t border-border pt-4">
              <button
                onClick={() => setMembersModalOpen(false)}
                className="rounded-lg border border-border bg-card px-4 py-2 text-sm text-foreground hover:bg-secondary"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

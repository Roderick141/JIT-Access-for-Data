import json

from fastapi import APIRouter, Depends, Query

from auth import get_current_user, require_manager
from db import execute_sp
from schemas.common import success

router = APIRouter(prefix="/api/admin", tags=["admin"])


@router.get("/stats")
def stats(user=Depends(get_current_user)):
    require_manager(user)
    rows = execute_sp("jit.sp_Stats_Dashboard")
    if rows:
        return success(rows[0])
    return success({"activeGrants": 0, "totalRoles": 0, "sensitiveRoles": 0, "totalUsers": 0})


@router.get("/lookups")
def lookups(user=Depends(get_current_user)):
    require_manager(user)
    rows = execute_sp("jit.sp_LookupValues")
    return success(rows or [])


@router.get("/roles")
def roles(user=Depends(get_current_user)):
    require_manager(user)
    rows = execute_sp("jit.sp_Role_ListWithStats")
    return success(rows or [])


@router.post("/roles")
def role_create(payload: dict, user=Depends(get_current_user)):
    require_manager(user)
    execute_sp(
        "jit.sp_Role_Create",
        {
            "RoleName": payload.get("roleName"),
            "Description": payload.get("description"),
            "SensitivityLevel": payload.get("sensitivityLevel", "Standard"),
            "IconName": payload.get("iconName", "Database"),
            "IconColor": payload.get("iconColor", "bg-blue-500"),
            "ActorUserId": user["UserId"],
        },
        fetch=False,
    )
    return success(message="Role created.")


@router.put("/roles/{role_id}")
def role_update(role_id: int, payload: dict, user=Depends(get_current_user)):
    require_manager(user)
    execute_sp(
        "jit.sp_Role_Update",
        {
            "RoleId": role_id,
            "RoleName": payload.get("roleName"),
            "Description": payload.get("description"),
            "SensitivityLevel": payload.get("sensitivityLevel", "Standard"),
            "IconName": payload.get("iconName", "Database"),
            "IconColor": payload.get("iconColor", "bg-blue-500"),
            "ActorUserId": user["UserId"],
        },
        fetch=False,
    )
    return success(message="Role updated.")


@router.delete("/roles/{role_id}")
def role_delete(role_id: int, user=Depends(get_current_user)):
    require_manager(user)
    execute_sp("jit.sp_Role_Delete", {"RoleId": role_id, "ActorUserId": user["UserId"]}, fetch=False)
    return success(message="Role deleted.")


@router.post("/roles/{role_id}/toggle")
def role_toggle(role_id: int, payload: dict, user=Depends(get_current_user)):
    require_manager(user)
    execute_sp(
        "jit.sp_Role_ToggleEnabled",
        {"RoleId": role_id, "IsEnabled": payload.get("isEnabled", True), "ActorUserId": user["UserId"]},
        fetch=False,
    )
    return success(message="Role updated.")


@router.get("/roles/{role_id}/users")
def role_users(role_id: int, user=Depends(get_current_user)):
    require_manager(user)
    rows = execute_sp("jit.sp_Role_ListUsers", {"RoleId": role_id})
    return success(rows or [])


@router.get("/roles/{role_id}/db-roles")
def role_db_roles(role_id: int, user=Depends(get_current_user)):
    require_manager(user)
    rows = execute_sp("jit.sp_Role_GetDbRoles", {"RoleId": role_id})
    return success(rows or [])


@router.put("/roles/{role_id}/db-roles")
def role_set_db_roles(role_id: int, payload: dict, user=Depends(get_current_user)):
    require_manager(user)
    db_ids = payload.get("dbRoleIds", [])
    execute_sp(
        "jit.sp_Role_SetDbRoles",
        {"RoleId": role_id, "DbRoleIdsCsv": ",".join([str(x) for x in db_ids]), "ActorUserId": user["UserId"]},
        fetch=False,
    )
    return success(message="DB role mappings updated.")


@router.get("/roles/{role_id}/eligibility-rules")
def role_rules(role_id: int, user=Depends(get_current_user)):
    require_manager(user)
    rows = execute_sp("jit.sp_Role_GetEligibilityRules", {"RoleId": role_id})
    return success(rows or [])


@router.put("/roles/{role_id}/eligibility-rules")
def role_set_rules(role_id: int, payload: dict, user=Depends(get_current_user)):
    require_manager(user)
    execute_sp(
        "jit.sp_Role_SetEligibilityRules",
        {"RoleId": role_id, "RulesJson": json.dumps(payload.get("rules", [])), "ActorUserId": user["UserId"]},
        fetch=False,
    )
    return success(message="Eligibility rules updated.")


@router.get("/db-roles")
def db_roles(user=Depends(get_current_user)):
    require_manager(user)
    rows = execute_sp("jit.sp_DbRole_ListAvailable")
    return success(rows or [])


@router.get("/teams")
def teams(user=Depends(get_current_user)):
    require_manager(user)
    rows = execute_sp("jit.sp_Team_ListWithStats")
    return success(rows or [])


@router.post("/teams")
def team_create(payload: dict, user=Depends(get_current_user)):
    require_manager(user)
    execute_sp(
        "jit.sp_Team_Create",
        {
            "TeamName": payload.get("teamName"),
            "Description": payload.get("description"),
            "Department": payload.get("department"),
            "ActorUserId": user["UserId"],
        },
        fetch=False,
    )
    return success(message="Team created.")


@router.put("/teams/{team_id}")
def team_update(team_id: int, payload: dict, user=Depends(get_current_user)):
    require_manager(user)
    execute_sp(
        "jit.sp_Team_Update",
        {
            "TeamId": team_id,
            "TeamName": payload.get("teamName"),
            "Description": payload.get("description"),
            "Department": payload.get("department"),
            "ActorUserId": user["UserId"],
        },
        fetch=False,
    )
    return success(message="Team updated.")


@router.delete("/teams/{team_id}")
def team_delete(team_id: int, user=Depends(get_current_user)):
    require_manager(user)
    execute_sp("jit.sp_Team_Delete", {"TeamId": team_id, "ActorUserId": user["UserId"]}, fetch=False)
    return success(message="Team deleted.")


@router.get("/teams/{team_id}/members")
def team_members(team_id: int, user=Depends(get_current_user)):
    require_manager(user)
    rows = execute_sp("jit.sp_Team_GetMembers", {"TeamId": team_id})
    return success(rows or [])


@router.put("/teams/{team_id}/members")
def team_set_members(team_id: int, payload: dict, user=Depends(get_current_user)):
    require_manager(user)
    execute_sp(
        "jit.sp_Team_SetMembers",
        {"TeamId": team_id, "UserIdsCsv": ",".join(payload.get("userIds", [])), "ActorUserId": user["UserId"]},
        fetch=False,
    )
    return success(message="Team members updated.")


@router.get("/users")
def users(
    user=Depends(get_current_user),
    search: str = "",
    department: str = "",
    role: str = "",
    status: str = "",
    page: int = Query(default=1, ge=1),
    pageSize: int = Query(default=25, ge=1, le=500),
):
    require_manager(user)
    rows = execute_sp(
        "jit.sp_User_ListPaginated",
        {
            "Search": search,
            "Department": department,
            "Role": role,
            "Status": status,
            "PageNumber": page,
            "PageSize": pageSize,
        },
    )
    return success(rows or [])


@router.put("/users/{user_id}/system-roles")
def user_roles(user_id: str, payload: dict, user=Depends(get_current_user)):
    require_manager(user)
    execute_sp(
        "jit.sp_User_UpdateSystemRoles",
        {
            "UserId": user_id,
            "IsAdmin": payload.get("isAdmin", False),
            "IsApprover": payload.get("isApprover", False),
            "IsDataSteward": payload.get("isDataSteward", False),
            "ActorUserId": user["UserId"],
        },
        fetch=False,
    )
    return success(message="User roles updated.")


@router.get("/audit-logs")
def audit_logs(
    user=Depends(get_current_user),
    search: str = "",
    eventType: str = "",
    startDate: str = "",
    endDate: str = "",
    page: int = Query(default=1, ge=1),
    pageSize: int = Query(default=50, ge=1, le=500),
):
    require_manager(user)
    rows = execute_sp(
        "jit.sp_AuditLog_ListPaginated",
        {
            "Search": search,
            "EventType": eventType,
            "StartDate": startDate or None,
            "EndDate": endDate or None,
            "PageNumber": page,
            "PageSize": pageSize,
        },
    )
    return success(rows or [])


from fastapi import APIRouter, Depends

from auth import get_current_user, require_approver
from db import execute_query, execute_sp
from schemas.common import success

router = APIRouter(prefix="/api/approver", tags=["approver"])


@router.get("/pending")
def pending(user=Depends(get_current_user)):
    require_approver(user)
    rows = execute_sp("jit.sp_Request_ListPendingForApprover", {"ApproverUserId": user["UserId"]})
    return success(rows or [])


@router.get("/requests/{request_id}")
def request_detail(request_id: int, user=Depends(get_current_user)):
    require_approver(user)
    rows = execute_query(
        """
        SELECT
            r.RequestId, r.UserId, r.RequestedDurationMinutes, r.Justification, r.TicketRef,
            r.Status, r.UserDeptSnapshot, r.UserTitleSnapshot, r.CreatedUtc, r.UpdatedUtc,
            u.DisplayName AS RequesterName, u.LoginName AS RequesterLoginName,
            u.Email AS RequesterEmail, u.Department AS RequesterDepartment,
            u.Division AS RequesterDivision, u.SeniorityLevel AS RequesterSeniority
        FROM jit.Requests r
        INNER JOIN jit.Users u ON u.UserId = r.UserId
        WHERE r.RequestId = ?
        """,
        [request_id],
    )
    detail = rows[0] if rows else None
    roles = execute_sp("jit.sp_Request_GetRoles", {"RequestId": request_id})
    if detail is not None:
        detail["Roles"] = roles or []
    return success(detail)

